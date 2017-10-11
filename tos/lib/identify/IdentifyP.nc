/**
 * Identify protocol module, trigger identification activity from radio packets.
 *
 * @author Raido Pahtma
 * @license MIT
 */
#include "IdentifyProtocol.h"
generic module IdentifyP(uint32_t min_indentify_s, uint32_t max_indentify_s) {
	uses {
		interface StdControl as IndicatorControl;

		interface Timer<TMilli>;

		interface AMSend;
		interface AMPacket;
		interface Packet;
		interface Receive;

		interface Pool<message_t> as MsgPool;

		// TODO auth retrieval interface
	}
}
implementation {

	#define __MODUUL__ "idntf"
	#define __LOG_LEVEL__ ( LOG_LEVEL_IdentifyP & BASE_LOG_LEVEL )
	#include "log.h"

	message_t* m_msg = NULL;
	am_addr_t m_client = 0;

	uint8_t m_auth[16] = {'s', 't', 'r', 'e', 'e', 't', 'l', 'i', 'g', 'h', 't', 's', 0 ,  0 ,  0 ,  0 };

	void sendMessage(am_addr_t destination, uint8_t err_idfy) {
		if(m_msg == NULL) {
			m_msg = call MsgPool.get();
			if(m_msg != NULL) {
				uint8_t length = 0;

				call Packet.clear(m_msg);

				switch(err_idfy) {
					case IDFY_ERROR_GENERIC:
					case IDFY_ERROR_VERSION:
					case IDFY_ERROR_UNAUTHORIZED:
					case IDFY_ERROR_PACKET:
					{
						idfy_error_msg_t* p = (idfy_error_msg_t*)call AMSend.getPayload(m_msg, sizeof(idfy_error_msg_t));
						p->version = IDFY_VERSION;
						p->header = IDFY_HEADER_ERROR;
						p->code = err_idfy;
						p->msg_len = 0;
						length = sizeof(idfy_error_msg_t);
					}
					break;
					default: // IDFY_ERROR_NONE
					{
						idfy_status_msg_t* p = (idfy_status_msg_t*)call AMSend.getPayload(m_msg, sizeof(idfy_status_msg_t));
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

				if(call AMSend.send(destination, m_msg, length) != SUCCESS) {
					warn1("snd");
					call MsgPool.put(m_msg);
					m_msg = NULL;
				}
			}
		}
	}

	event void Timer.fired() {
		call IndicatorControl.stop();
		sendMessage(m_client, IDFY_ERROR_NONE);
	}

	event void AMSend.sendDone(message_t* m, error_t err) {
		debug1("snt %u", err);
		call MsgPool.put(m_msg);
		m_msg = NULL;
	}

	bool authGood(uint8_t* auth) {
		return memcmp(auth, m_auth, sizeof(m_auth)) == 0;
	}

	event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len) {
		if(m_msg == NULL) {
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
								if(authGood((uint8_t*)(cm->auth))) {
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
