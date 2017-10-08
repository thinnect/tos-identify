/**
 * @author Raido Pahtma
 * @license Thinnect
 */
#include "IdentifyProtocol.h"
generic module IdentifyP(uint32_t time_indentify_s, uint32_t period_blink_s, uint32_t time_boot_indicate_s) {
	uses {
		interface GeneralIO as ButtonIO;
		interface GpioInterrupt as ButtonInterrupt;

		interface StdControl as IndicatorControl;

		interface Timer<TMilli> as IdentifyTimer;
		interface Timer<TMilli> as BlinkTimer;

		interface AMSend;
		interface AMPacket;
		interface Packet;
		interface Receive;

		interface Boot;
	}
}
implementation {

	#define __MODUUL__ "idntf"
	#define __LOG_LEVEL__ ( LOG_LEVEL_LEDControlP & BASE_LOG_LEVEL )
	#include "log.h"

	message_t m_msg;
	am_addr_t m_client = 0;
	bool m_radio_busy = FALSE;
	bool m_active = FALSE;
	bool m_blink = FALSE;

	event void Boot.booted() {
		call ButtonIO.makeInput();
		call ButtonIO.set(); // pull-up

		call ButtonInterrupt.enableFallingEdge();

		if(time_boot_indicate_s > 0) {
			m_blink = TRUE;
			call IndicatorControl.start();
			call BlinkTimer.startOneShot(SEC_TMILLI(time_boot_indicate_s));
		}
		else if(period_blink_s > 0) {
			call BlinkTimer.startOneShot(0);
		}
	}

	event void BlinkTimer.fired() {
		if(m_blink) {
			m_blink = FALSE;
			call IndicatorControl.stop();
			if(period_blink_s > 0) {
				call BlinkTimer.startOneShot(SEC_TMILLI(period_blink_s));
			}
		} else {
			m_blink = TRUE;
			call IndicatorControl.start();
			call BlinkTimer.startOneShot(10);
		}
	}

	event void IdentifyTimer.fired() {
		m_active = FALSE;
		m_blink = FALSE;
		call IndicatorControl.stop();
		call ButtonInterrupt.enableFallingEdge();
		if(period_blink_s > 0) {
			call BlinkTimer.startOneShot(SEC_TMILLI(period_blink_s));
		}
	}

	task void fired() {
		m_active = TRUE;
		call BlinkTimer.stop();
		call IdentifyTimer.startOneShot(SEC_TMILLI(time_indentify_s));
		call IndicatorControl.start();
	}

	async event void ButtonInterrupt.fired() {
		call ButtonInterrupt.disable();
		post fired();
	}

	task void sendStatus() {
		if(m_radio_busy == FALSE) {
			status_msg_t* msg = (status_msg_t*)call AMSend.getPayload(&m_msg, sizeof(status_msg_t));
			call Packet.clear(&m_msg);
			msg->header = HEADER_REPORT;
			msg->value = m_active ? 100: 0;

			if(call AMSend.send(m_client, &m_msg, sizeof(status_msg_t)) == SUCCESS) {
				debug1("snd");
				m_radio_busy = TRUE;
			}
		}
		else post sendStatus();
	}

	event void AMSend.sendDone(message_t* m, error_t err) {
		debug1("snt %u", err);
		m_radio_busy = FALSE;
	}

	event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len) {
		if(m_radio_busy == FALSE) {
			uint8_t header = ((uint8_t*)payload)[0];
			switch(header) {
				case HEADER_STATUS:
					m_client = call AMPacket.source(msg);
					post sendStatus();
					break;
				case HEADER_CONTROL:
					if(len == sizeof(control_msg_t)) {
						control_msg_t* message = (control_msg_t*)payload;
						info1("cntrl %u", message->value);
						if(message->value == 0) {
							call IdentifyTimer.startOneShot(0);
						}
						else {
							post fired();
						}
						m_client = call AMPacket.source(msg);
						post sendStatus();
					}
					else err1("len %u", len);
					break;
				default:
					warn1("hdr %02X", header);
			}
		}
		else warn1("rbsy");

		return msg;
	}

	default async command void ButtonIO.makeInput() { }
	default async command void ButtonIO.set() { }
	default async command error_t ButtonInterrupt.enableFallingEdge() { return ELAST; }

}
