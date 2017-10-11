
		// GPIO interface for active low button used to trigger identify
		interface GeneralIO as ButtonIO;
		// Interrupt interface for active low button used to trigger identify
		interface GpioInterrupt as ButtonInterrupt;

	components new TimerMilliC() as BlinkTimer;
	IdentifyP.BlinkTimer -> BlinkTimer;


generic module IdleBlinkingLedIndicatorP(uint32_t time_boot_indicate_s, uint32_t period_blink_s) {
	provides interface StdControl as IndicatorControl;
	uses {
		interface Timer<TMilli> as BlinkTimer;
		interface GeneralIO as ButtonIO;
		interface GpioInterrupt as ButtonInterrupt;
				interface Boot;
	}
}
implementation {

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

		if(period_blink_s > 0) {
			call BlinkTimer.startOneShot(SEC_TMILLI(period_blink_s));
		}

		call BlinkTimer.stop();

	async event void ButtonInterrupt.fired() {
		call ButtonInterrupt.disable();
		post fired();
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

	default async command void ButtonIO.makeInput() { }
	default async command void ButtonIO.set() { }
	default async command error_t ButtonInterrupt.enableFallingEdge() { return ELAST; }

}
