/**
 * LED indicator control with StdControl.
 *
 * @author Raido Pahtma
 * @license Thinnect
 */
generic module SteadyLedIndicatorP(bool inverted) {
	provides interface StdControl as IndicatorControl;
	uses {
		interface Boot;
		interface GeneralIO;
	}
}
implementation {

	event void Boot.booted() {
		if(inverted) {
			call GeneralIO.set();
		}
		else {
			call GeneralIO.clr();
		}
		call GeneralIO.makeOutput();
	}

	command error_t IndicatorControl.start() {
		if(inverted) {
			call GeneralIO.clr();
		}
		else {
			call GeneralIO.set();
		}
		return SUCCESS;
	}

	command error_t IndicatorControl.stop() {
		if(inverted) {
			call GeneralIO.set();
		}
		else {
			call GeneralIO.clr();
		}
		return SUCCESS;
	}

}
