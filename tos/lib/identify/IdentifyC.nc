/**
 * Identify protocol configuration, trigger identification activity from radio packets.
 *
 * @author Raido Pahtma
 * @license MIT
 */
#include "IdentifyProtocol.h"
#ifdef STACK_BEAT
#include "sTack.h"
#endif // STACK_BEAT
generic configuration IdentifyC(uint32_t min_indentify_s, uint32_t max_indentify_s) {
	uses {
		interface StdControl as IndicatorControl;
	}
}
implementation {

	components new IdentifyP(min_indentify_s, max_indentify_s);
	IdentifyP.IndicatorControl = IndicatorControl;

#ifdef STACK_BEAT
	#warning STACK_BEAT
	components ActiveMessageC as RadioC;
	IdentifyP.Receive -> RadioC.Receive[AMID_IDENTIFY_PROTOCOL];

	components new PSenderAMC(AMID_IDENTIFY_PROTOCOL, ST_MODE_PRIORITY) as AMSenderC;
#else
	components new AMReceiverC(AMID_IDENTIFY_PROTOCOL);
	IdentifyP.Receive -> AMReceiverC;

	components new AMSenderC(AMID_IDENTIFY_PROTOCOL);
#endif

	IdentifyP.AMSend -> AMSenderC;
	IdentifyP.AMPacket -> AMSenderC;
	IdentifyP.Packet -> AMSenderC;

	components GlobalPoolC;
	IdentifyP.MsgPool -> GlobalPoolC.Pool;

	components new TimerMilliC() as IdentifyTimer;
	IdentifyP.Timer -> IdentifyTimer;

	components AuthPasswordParameterC;
	IdentifyP.CheckAuth -> AuthPasswordParameterC;

}
