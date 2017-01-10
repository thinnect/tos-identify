/**
 * LED indicator control with StdControl.
 *
 * @author Raido Pahtma
 * @license Thinnect
 */
generic configuration SteadyLedIndicatorC(bool inverted) {
	provides interface StdControl as IndicatorControl;
	uses interface GeneralIO;
}
implementation {

	components new SteadyLedIndicatorP(inverted);
	IndicatorControl = SteadyLedIndicatorP.IndicatorControl;
	SteadyLedIndicatorP.GeneralIO = GeneralIO;

	components MainC;
	SteadyLedIndicatorP.Boot -> MainC.Boot;

}
