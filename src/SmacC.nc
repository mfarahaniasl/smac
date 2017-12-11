#include "smac.h"

module SmacC{
	uses {
	    interface SplitControl as RadioControl;
	    interface Leds;
	    interface Boot;
	    interface Random;
	    interface iSMAC;
	    
	    interface TossimPacket;
	    interface Packet;
	    interface AMPacket;
	    interface PacketAcknowledgements;
	    
	    interface Receive 	as Annonce_ReceiveMsg;
		interface AMSend 	as Annonce_SendMsg;	
	  	interface Receive 	as NewCycle_ReceiveMsg;
  		interface AMSend 	as NewCycle_SendMsg;
	  	interface Receive 	as Data_ReceiveMsg;
  		interface AMSend 	as Data_SendMsg;
	  	interface Receive 	as Aggregate_ReceiveMsg;
  		interface AMSend 	as Aggregate_SendMsg;
  		
  		interface Timer<TMilli> as Annonce;		//Annonce timers interface
	    interface Timer<TMilli> as Appearance;	//Appearance timers interface
	    interface Timer<TMilli> as NewCycle;	//Aggregate timers interface
	    interface Timer<TMilli> as SendData;	//Aggregate timers interface
	    interface Timer<TMilli> as Aggregate;	//Aggregate timers interface
  	}
}
implementation{
	message_t packet;
	uint16_t	_timeTick=1;
	uint16_t	_timeTick_annonce=0;
	uint16_t	_timeTick_newCycle=0;
	uint16_t	_timeTick_aggregate=0;
	uint16_t	_timeTick_data=0;
	bool 	radio_locked = FALSE;
	bool	isAppearance = FALSE;
	bool	seeBaseStation = FALSE;	
	bool	hasCH = FALSE;
	uint8_t	myState = 0;
	uint16_t		myCH_ID;
	
	uint8_t		BaseStation_rssi;
	uint8_t		req_id;
	uint8_t		req_type;
	uint8_t		res_id;
	
	uint8_t		memberCount = 0 ;
	uint8_t		memberCount_received = 0 ;
	uint8_t		myData = 0;
	uint16_t	aggregate_val;
	bool		macIsActive=FALSE;
	
	//inline functions
	inline uint8_t getRssi(message_t* m) {
		#ifdef TOSSIM
			return call TossimPacket.strength(m);
		#else
			return 0;//call CC2420Packet.getRssi(m);
		#endif 
	}
	
	event void Boot.booted() {
		uint16_t rdm;
		
		if (TOS_NODE_ID == BASE_STATION_ADDRESS){
			atomic {myState = IS_BASE_STATION;}
			call iSMAC.setFollower(0);
			//call Annonce.startPeriodic(ANNONCE_INT_BS) ;
			_timeTick_annonce=_timeTick + 1;
		}
		else{
			atomic {myState = IS_MOTE;}
			
			rdm = call Random.rand16();
  			rdm %= (5000 - 0);			//%(Max-Min)
  			rdm += 3000;					//+Min
  			
  			call Appearance.startOneShot(rdm);
		}

		//call iSMAC.keepAlive(1);
		dbg("DebugApp","\t Note booted as %s. \t@%s\n", (myState==IS_MOTE)?"Member":((myState==IS_CH)?"CH":(myState==IS_BASE_STATION)?"BaseStation":"Unkhown"), sim_time_string());
  	}

  	event void RadioControl.startDone(error_t err) {
    	if (err == SUCCESS) {
      		//macIsActive=TRUE;
      		
      		dbg("DebugApp","\t Radio Start done. @%s\t\n", sim_time_string());
    	}
	}
	
	event void RadioControl.stopDone(error_t err) {
		//radio_locked=TRUE;
		macIsActive=FALSE;
		dbg("DebugApp","\t Radio Stop done. \t@%s\n", sim_time_string());
	}
	
	event void 	iSMAC.activationChanged(uint8_t status){

	}
	
	event void iSMAC.readyTransmite(){
		uint16_t rdm;
		
		_timeTick++;
		
		if(_timeTick==_timeTick_annonce){
			rdm = call Random.rand16();
			rdm %= (50-0);   	//%(Max-Min)
			rdm += 0;			//+Min
			
			call Annonce.startOneShot(rdm);
			_timeTick_annonce=_timeTick + ANNONCE_BS;
		}
		
		if(_timeTick==_timeTick_newCycle){
			rdm = call Random.rand16();
			rdm %= (50-0);   	//%(Max-Min)
			rdm += 0;			//+Min
			
			call NewCycle.startOneShot(rdm);
			_timeTick_newCycle=_timeTick + NEW_CYCLE_TICK;
		}
		
		if(_timeTick==_timeTick_aggregate){
			rdm = call Random.rand16();
			rdm %= (50-0);   	//%(Max-Min)
			rdm += 0;			//+Min
			
			call Aggregate.startOneShot(rdm);
		}
		
		if(_timeTick==_timeTick_data){
			rdm = call Random.rand16();
			rdm %= (50-0);   	//%(Max-Min)
			rdm += 0;			//+Min
			
			call SendData.startOneShot(rdm);
		}
		
		//dbg("DebugApp","\t Ready to transmite(%i). \t@%s\n",_timeTick, sim_time_string());
	}
	
	event void iSMAC.activated(){
		macIsActive=TRUE;
		
		
		//dbg("DebugApp","\t Radio become alive and time tick is %i. \t@%s\n",_timeTick, sim_time_string());
	}
	
	event void iSMAC.syncReceived(uint16_t node_id){
		dbg("DebugApp","\t New sync received from %i. \t@%s\n", node_id, sim_time_string());
		if(myState==IS_MOTE && !hasCH){
			if(!isAppearance){
		  		if(call Appearance.isRunning())
		  			call Appearance.stop();
		  		isAppearance=TRUE;	
	  		}	

		  	call iSMAC.keepAlive(0);

			myState=IS_MOTE;
			myCH_ID=node_id;
			hasCH=TRUE;
			
			dbg("DebugApp","\t Node %i joined to %i as member. \t@%s\n",TOS_NODE_ID,myCH_ID, sim_time_string());
			dbg("DebugGraph",";%i;%i;Mote;1 \n",TOS_NODE_ID,myCH_ID);
	  	}
	}

  	event void Annonce.fired(){
		int i;
		if (radio_locked) {
			//dbg("DebugApp","\t Radio was locked. \t@%s\n", sim_time_string());
			
			return;}
		else{
			annonce_msg_t* rsm;
			rsm = (annonce_msg_t*)call Packet.getPayload(&packet, sizeof(annonce_msg_t));

	      	dbg("DebugApp","\t Annonce timer Fired. \t@%s\n", sim_time_string());
	      	
	      	if (rsm == NULL) { return; }
			else if(myState != IS_MOTE ){
				rsm->ID_MEMBER = (unsigned char)TOS_NODE_ID;  		
	      		rsm->state = myState;
				rsm->type = 1;

	      		dbg("DebugApp","\t Node annonce as %s. \t@%s\n", (myState==IS_MOTE)?"Sonsor":((myState==IS_CH)?"CH":(myState==IS_BASE_STATION)?"BaseStation":"Unkhown"), sim_time_string());
	      		
	      		if (call Annonce_SendMsg.send(AM_BROADCAST_ADDR, &packet, sizeof(annonce_msg_t)) == SUCCESS) {radio_locked = TRUE;}
			}
		}
	}
	
	event void Appearance.fired(){
		dbg("DebugApp","\t Appearance fired. \t@%s\n", sim_time_string());
		
		if(myState == IS_MOTE && !hasCH && !seeBaseStation){
			call iSMAC.setFollower(1);
			dbg("DebugApp","\t Appearance fired but i'm mote too. \t@%s\n", sim_time_string());
		}
		isAppearance=TRUE;
	}

	event void NewCycle.fired(){
		if (radio_locked) {return;}
		else{
			annonce_msg_t* rsm;
			rsm = (annonce_msg_t*)call Packet.getPayload(&packet, sizeof(annonce_msg_t));

	      	if (rsm == NULL) { return; }
			else{
				rsm->ID_MEMBER = (unsigned char)TOS_NODE_ID;
	      		rsm->state = myState;
	      		rsm->type = 2; //new cycle
	      		
				aggregate_val = 0;
				memberCount_received = 0;
							
				dbg("DebugApp","\t New cycle started by CH %i.\t@%s\n", TOS_NODE_ID, sim_time_string());
				
				_timeTick_aggregate=_timeTick + AGGREGATE_DUR;
				
	      		if (call NewCycle_SendMsg.send(AM_BROADCAST_ADDR, &packet, sizeof(annonce_msg_t)) == SUCCESS) {radio_locked = TRUE;}
			}
		}
	}
	
	event void SendData.fired(){ 
		//send to My CH		
		if (radio_locked) {return;}
		else{
			data_msg_t* rsm;
			rsm = (data_msg_t*)call Packet.getPayload(&packet, sizeof(data_msg_t));

	      	if (rsm == NULL) { return; }
			else{
				uint8_t randNo =(uint8_t) (call Random.rand16()%250);	
				
				rsm->data = randNo;
				dbg("DebugApp","\t Send data to My CH(%i). \t@%s\n",myCH_ID, sim_time_string());

				if (call Data_SendMsg.send(myCH_ID, &packet, sizeof(data_msg_t)) == SUCCESS) {radio_locked = TRUE;}
			}
		}
	}

	event void Aggregate.fired(){ 
		uint8_t data;
		
		if(myState != IS_CH)
			return;
		//send to BaseStation		
		dbg("DebugApp","\t Aggrigate received data. \t@%s\n", sim_time_string());	
		if (radio_locked) {return;}
		else{
			aggregate_msg_t* rsm;
			rsm = (aggregate_msg_t*)call Packet.getPayload(&packet, sizeof(aggregate_msg_t));

	      	if (rsm == NULL) { return; }
			else{
				if (memberCount_received==0)
					data =0;
				else
					data = (uint8_t)(aggregate_val/memberCount_received);
				
				rsm->data=data;
				dbg("DebugApp","\t Send aggrigated data(%i) to BaseStation. \t@%s\n", data,sim_time_string());

				if (call Aggregate_SendMsg.send(BASE_STATION_ADDRESS, &packet, sizeof(admission_msg_t)) == SUCCESS) {radio_locked = TRUE;}
			}
		}
	}
	
	//***********************************************************************
	event void Annonce_SendMsg.sendDone(message_t *msg, error_t error){
		if (&packet == msg) { radio_locked = FALSE; }
	}

  	//Recieve new annonce from BS or CH
  	event message_t* Annonce_ReceiveMsg.receive(message_t* msg, 
				   void* payload, uint8_t len) {
    	call Leds.led1Toggle();

    	if (len != sizeof(annonce_msg_t)) {return msg;}
    	else {
      		annonce_msg_t* rsm = (annonce_msg_t*)payload;
      		uint8_t source_ID = call AMPacket.source(msg);
      		int8_t	strength  = call TossimPacket.strength(msg);
      		uint8_t rState = rsm->state;

      		dbg("RecivedPacket","\t;%s \t;%i \t;%i \t;%i \t;Recieve New Packet.\n", sim_time_string(), TOS_NODE_ID, source_ID, strength);

			if(rsm->type==1){
				if(rState == IS_BASE_STATION && !seeBaseStation && !isAppearance) {
			  		seeBaseStation = TRUE;
			  		dbg("DebugApp","\t I see BaseStation. \t@%s\n", sim_time_string());
			  		dbg("DebugApp","\t BaseStation link strong is %i. \t@%s\n", strength, sim_time_string());
			  		dbg("DebugGraph",";%i;%i;CH;1 \n",TOS_NODE_ID,BASE_STATION_ADDRESS);
			  		
			  		if(!isAppearance){
				  		if(call Appearance.isRunning())
				  			call Appearance.stop();
				  			
				  		isAppearance=TRUE;
				  		
				  		call iSMAC.keepAlive(0);
						call iSMAC.setSynchronizer(1);
						call iSMAC.setFollower(0);
						
						myState=IS_CH;
						_timeTick_newCycle=_timeTick + NEW_CYCLE_TICK;
				  	}
			  	}
			}

		  	return msg;
    	}
  	}

  	event void NewCycle_SendMsg.sendDone(message_t *msg, error_t error){
		if (&packet == msg) { radio_locked = FALSE; }
	}
	
	event message_t* NewCycle_ReceiveMsg.receive(message_t* msg, 
				   void* payload, uint8_t len) {
		uint16_t rdm;
		
		if (len != sizeof(annonce_msg_t)) {return msg;}
  	else {
    		annonce_msg_t* rsm = (annonce_msg_t*)payload;
    		int8_t	strength  = call TossimPacket.strength(msg);
    		uint8_t source_ID = call AMPacket.source(msg);
		uint8_t rMember = rsm->ID_MEMBER;
		uint8_t rState = rsm->state;
		
		dbg("RecivedPacket","\t;%s \t;%i \t;%i \t;%i \t;Recieve New Packet.\n", sim_time_string(), TOS_NODE_ID, source_ID, strength);

		if(source_ID != myCH_ID)
			return msg;

		dbg("DebugApp","\t Received new cycle trig from my CH(%i). \t@%s\n",source_ID ,sim_time_string());

		_timeTick_data=_timeTick+DATA_DUR;
			return msg;
		}
	}
  	
  	event void Data_SendMsg.sendDone(message_t *msg, error_t error){
		if (&packet == msg) { radio_locked = FALSE; }
	}
	
	event message_t* Data_ReceiveMsg.receive(message_t* msg, 
				   void* payload, uint8_t len) {
		if (len != sizeof(data_msg_t)) {return msg;}
  	else {
    		data_msg_t* rsm = (data_msg_t*)payload;
    		int8_t	strength  = call TossimPacket.strength(msg);
    		uint8_t source_ID = call AMPacket.source(msg);
		uint8_t rData = rsm->data;
		
		dbg("RecivedPacket","\t;%s \t;%i \t;%i \t;%i \t;Recieve New Packet. \n", sim_time_string(), TOS_NODE_ID, source_ID, strength);
		dbg("DebugApp","\t Received new data from %i. \t@%s\n",source_ID, sim_time_string());
		
		aggregate_val += rData;
		memberCount_received++;
		
			return msg;
		}
	}
  	
  	event void Aggregate_SendMsg.sendDone(message_t *msg, error_t error){
		if (&packet == msg) { radio_locked = FALSE; }
	}
	
	event message_t* Aggregate_ReceiveMsg.receive(message_t* msg, 
				   void* payload, uint8_t len) {
		if (len != sizeof(aggregate_msg_t)) {return msg;}
  	else {
    		aggregate_msg_t* rsm = (aggregate_msg_t*)payload;
    		int8_t	strength  = call TossimPacket.strength(msg);
    		uint8_t source_ID = call AMPacket.source(msg);
    		uint8_t rData = rsm->data;
		
		dbg("RecivedPacket","\t;%s \t;%i \t;%i \t;%i \t;Recieve New Packet.\n", sim_time_string(), TOS_NODE_ID, source_ID, strength);
		dbg("DebugApp","\t Received aggregated value from %i = %i . \t@%s\n",source_ID,rData, sim_time_string());
		
			return msg;
		}		   	
	}
}
