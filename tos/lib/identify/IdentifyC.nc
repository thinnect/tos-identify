/**
 * Identify protocol module. Trigger identify from radio packets or alternatively
 * from a physical button on the device. Button wiring is optional.
 *
 * @author Raido Pahtma
 * @license MIT
 */
#include "IdentifyProtocol.h"
#ifdef STACK_BEAT
#include "sTack.h"
#endif // STACK_BEAT
generic configuration IdentifyC(uint32_t time_indentify_s, uint32_t period_blink_s, uint32_t time_boot_indicate_s) {
	uses {
		interface StdControl as IndicatorControl;

		// GPIO interface for active low button used to trigger identify
		interface GeneralIO as ButtonIO;
		// Interrupt interface for active low button used to trigger identify
		interface GpioInterrupt as ButtonInterrupt;
	}
}
implementation {

	components new IdentifyP(time_indentify_s, period_blink_s, time_boot_indicate_s) as Module;
	Module.IndicatorControl = IndicatorControl;
	Module.ButtonInterrupt = ButtonInterrupt;
	Module.ButtonIO = ButtonIO;

	components MainC;
	Module.Boot -> MainC;

#ifdef STACK_BEAT
	#warning STACK_BEAT
	components ActiveMessageC as RadioC;
	Module.Receive -> RadioC.Receive[AMID_IDENTIFY_PROTOCOL];

	components new PSenderAMC(AMID_IDENTIFY_PROTOCOL, ST_MODE_PRIORITY) as AMSenderC;
#else
	components new AMReceiverC(AMID_IDENTIFY_PROTOCOL);
	Module.Receive -> AMReceiverC;

	components new AMSenderC(AMID_IDENTIFY_PROTOCOL);
#endif

	Module.AMSend -> AMSenderC;
	Module.AMPacket -> AMSenderC;
	Module.Packet -> AMSenderC;

	components new TimerMilliC() as IdentifyTimer;
	Module.IdentifyTimer -> IdentifyTimer;

	components new TimerMilliC() as BlinkTimer;
	Module.BlinkTimer -> BlinkTimer;

}
