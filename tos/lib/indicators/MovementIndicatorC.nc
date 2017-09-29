/**
 * Control Indicator based on MovementStart and MovementEnd events.
 * @author Raido Pahtma
 * @license MIT
 */
generic configuration MovementIndicatorC() {
	uses {
		interface Notify<float> as MovementStart;
		interface Notify<float> as MovementEnd;
		interface StdControl as IndicatorControl;
	}
}
implementation {

	components new MovementIndicatorP();

	IndicatorControl = MovementIndicatorP.IndicatorControl;
	MovementStart = MovementIndicatorP.MovementStart;
	MovementEnd = MovementIndicatorP.MovementEnd;

	components MainC;
	MovementIndicatorP.Boot -> MainC;

}
