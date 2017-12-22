/**
 * Identify protocol module, trigger identification activity from radio packets.
 *
 * @author Raido Pahtma
 * @license MIT
 */
#include "IdentifyProtocol.h"
#include "sec_tmilli.h"
generic module IdentifyP(uint32_t min_indentify_s, uint32_t max_indentify_s) {
	uses {
		interface StdControl as IndicatorControl;

		interface Timer<TMilli>;

		interface AMSend;
		interface AMPacket;
		interface Packet;
		interface Receive;

		interface Pool<message_t> as MsgPool;

		interface CheckAuth;
	}
}
implementation {

	#define __MODUUL__ "idntf"
	#define __LOG_LEVEL__ ( LOG_LEVEL_IdentifyP & BASE_LOG_LEVEL )
	#include "log.h"

	bool m_radio_busy = FALSE;
	am_addr_t m_client = 0;

	void sendMessage(am_addr_t destination, uint8_t err_idfy) {
		if(m_radio_busy == FALSE) {
			message_t* msg = call MsgPool.get();
			if(msg != NULL) {
				uint8_t length = 0;

				call Packet.clear(msg);

				switch(err_idfy) {
					case IDFY_ERROR_GENERIC:
					case IDFY_ERROR_VERSION:
					case IDFY_ERROR_UNAUTHORIZED:
					case IDFY_ERROR_PACKET:
					{
						idfy_error_msg_t* p = (idfy_error_msg_t*)call AMSend.getPayload(msg, sizeof(idfy_error_msg_t));
						if(p != NULL) {
							p->version = IDFY_VERSION;
							p->header = IDFY_HEADER_ERROR;
							p->code = err_idfy;
							p->msg_len = 0;
							length = sizeof(idfy_error_msg_t);
						}
					}
					break;
					default: // IDFY_ERROR_NONE
					{
						idfy_status_msg_t* p = (idfy_status_msg_t*)call AMSend.getPayload(msg, sizeof(idfy_status_msg_t));
						if(p != NULL) {
							p->version = IDFY_VERSION;
							p->header = IDFY_HEADER_REPORT;
							if(call Timer.isRunning()) {
								p->remaining = call Timer.gett0() + call Timer.getdt() - call Timer.getNow();
								p->value = 100;
							}
							else {
								p->remaining = 0;
								p->value = 0;
							}
							length = sizeof(idfy_status_msg_t);
						}
					}
				}

				if((length > 0) && (call AMSend.send(destination, msg, length) == SUCCESS)) {
					m_radio_busy = TRUE;
				}
				else {
					warn1("snd");
					call MsgPool.put(msg);
				}
			}
		}
	}

	event void Timer.fired() {
		call IndicatorControl.stop();
		sendMessage(m_client, IDFY_ERROR_NONE);
	}

	event void AMSend.sendDone(message_t* msg, error_t err) {
		debug1("snt %u", err);
		call MsgPool.put(msg);
		m_radio_busy = FALSE;
	}

	event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len) {
		if(m_radio_busy == FALSE) {
			if(len > sizeof(idfy_request_msg_t)) {
				idfy_request_msg_t* p = ((idfy_request_msg_t*)payload);
				if(p->version == IDFY_VERSION) {
					switch(p->header) {
						case IDFY_HEADER_STATUS:
							sendMessage(call AMPacket.source(msg), IDFY_ERROR_NONE);
							break;
						case IDFY_HEADER_CONTROL:
							if(len == sizeof(idfy_control_msg_t)) {
								idfy_control_msg_t* cm = (idfy_control_msg_t*)payload;
								if(call CheckAuth.good((uint8_t*)(cm->auth), 16)) {
									info1("cntrl %u", cm->value);
									m_client = call AMPacket.source(msg);
									if(cm->value == 0) {
										call Timer.startOneShot(0);
									}
									else {
										uint32_t period = cm->period;
										if(period < SEC_TMILLI(min_indentify_s)) {
											period = SEC_TMILLI(min_indentify_s);
										}
										else if(period > SEC_TMILLI(max_indentify_s)) {
											period = SEC_TMILLI(max_indentify_s);
										}
										call Timer.startOneShot(period);
										call IndicatorControl.start();
										sendMessage(m_client, IDFY_ERROR_NONE);
									}
								}
								else {
									sendMessage(call AMPacket.source(msg), IDFY_ERROR_UNAUTHORIZED);
									// TODO block for some time to limit bruteforce
								}
							}
							else err1("len %u", len);
							break;
						default:
							warn1("hdr %02X", header);
							sendMessage(call AMPacket.source(msg), IDFY_ERROR_PACKET);
					}
				}
				else {
					sendMessage(call AMPacket.source(msg), IDFY_ERROR_VERSION);
				}
			}
			else {
				sendMessage(call AMPacket.source(msg), IDFY_ERROR_PACKET);
			}
		}
		else warn1("rbsy");

		return msg;
	}

}
