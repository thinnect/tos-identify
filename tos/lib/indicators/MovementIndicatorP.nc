/**
 * Control Indicator based on MovementStart and MovementEnd events.
 * @author Raido Pahtma
 * @license MIT
 */
generic module MovementIndicatorP() {
	uses {
		interface Notify<float> as MovementStart;
		interface Notify<float> as MovementEnd;
		interface StdControl as IndicatorControl;
		interface Boot;
	}
}
implementation {

	event void Boot.booted() {
		call MovementStart.enable();
		call MovementEnd.enable();
	}

	event void MovementStart.notify(float value) {
		call IndicatorControl.start();
	}

	event void MovementEnd.notify(float value) {
		call IndicatorControl.stop();
	}

}
