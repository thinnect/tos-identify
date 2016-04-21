/**
 * @author Raido Pahtma
 * @license Thinnect
 */
generic configuration IdentifyC(uint32_t g_indentify_time_s, uint32_t g_blink_period_s) {
	uses interface StdControl as IndicatorControl;
}
implementation {

	enum {
		AMID_LED_CONTROL = 0xEF,
		PRIORITY_LED_CONTROL = 5
	};

	components new IdentifyP(g_indentify_time_s, g_blink_period_s) as Module;
	Module.IndicatorControl = IndicatorControl;

	components MainC;
	Module.Boot -> MainC;

	components HplAtm128GeneralIOC as Pins;
	Module.SwitchIO -> Pins.PortE6;

	components AtmegaExtInterruptC as Interrupts;
	Module.SwitchInterrupt -> Interrupts.GpioInterrupt[6];

#ifdef STACK_BEAT
	#warning STACK_BEAT
	components ActiveMessageC as RadioC;
	Module.Receive -> RadioC.Receive[AMID_LED_CONTROL];

	components new PSenderAMC(AMID_LED_CONTROL, PRIORITY_LED_CONTROL) as AMSenderC;
#else
	components new AMReceiverC(AMID_LED_CONTROL);
	Module.Receive -> AMReceiverC;

	components new AMSenderC(AMID_LED_CONTROL);
#endif

	Module.AMSend -> AMSenderC;
	Module.AMPacket -> AMSenderC;
	Module.Packet -> AMSenderC;

	components new TimerMilliC() as IdentifyTimer;
	Module.IdentifyTimer -> IdentifyTimer;

	components new TimerMilliC() as BlinkTimer;
	Module.BlinkTimer -> BlinkTimer;

}
