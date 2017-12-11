#define SMAC

configuration SmacApp{
}
implementation{
	components MainC, SmacC as App, LedsC, RandomC;//, new DemoSensorC();
	components ActiveMessageC;
	components TossimActiveMessageC;
	components MAC_SMAC;
	
	components new AMReceiverC(AM_ANNONCE) as Annonce_AMR;
  	components new AMSenderC(AM_ANNONCE) as Annonce_AMS;
  	components new AMReceiverC(AM_NEWCYCLE) as NewCycle_AMR;
  	components new AMSenderC(AM_NEWCYCLE) as NewCycle_AMS;
  	components new AMReceiverC(AM_DATA) as DATA_AMR;
  	components new AMSenderC(AM_DATA) as DATA_AMS;
  	components new AMReceiverC(AM_AGGREGATION) as Aggregate_AMR;
  	components new AMSenderC(AM_AGGREGATION) as Aggregate_AMS;

  	components new TimerMilliC() as annonceTimer;
  	components new TimerMilliC() as appearanceTimer;
  	components new TimerMilliC() as NewCycleTimer;
  	components new TimerMilliC() as SendDataTimer;
  	components new TimerMilliC() as AggregateTimer;
	
	App.Boot -> MainC.Boot;
	App.Leds -> LedsC;
	App.Random -> RandomC;
	//App.Read -> DemoSensorC;
	App.iSMAC->MAC_SMAC.iSMAC;

	App.RadioControl -> ActiveMessageC;
	App.TossimPacket -> TossimActiveMessageC;
	App.PacketAcknowledgements -> ActiveMessageC;
	App.Packet -> ActiveMessageC;
	App.AMPacket -> ActiveMessageC;
	
	App.Annonce -> annonceTimer;
  	App.Appearance -> appearanceTimer;
  	App.NewCycle -> NewCycleTimer;
  	App.Aggregate -> AggregateTimer;
	App.SendData -> SendDataTimer;
	
	App.Annonce_ReceiveMsg -> Annonce_AMR;
  	App.Annonce_SendMsg -> Annonce_AMS;

	App.NewCycle_ReceiveMsg -> NewCycle_AMR;
  	App.NewCycle_SendMsg -> NewCycle_AMS;
	App.Data_ReceiveMsg -> DATA_AMR;
  	App.Data_SendMsg -> DATA_AMS;
	App.Aggregate_ReceiveMsg -> Aggregate_AMR;
  	App.Aggregate_SendMsg -> Aggregate_AMS;
}