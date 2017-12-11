#ifndef SMAC_H
#define SMAC_H



#define NEW_CYCLE_TICK		100  //3 Second
#define ANNONCE_BS			5
#define AGGREGATE_DUR		3 
#define DATA_DUR			1 
#define IS_MOTE			1
#define IS_CH			2
#define IS_BASE_STATION		3


enum{
	AM_ANNONCE 		= 200, //AM_BROADCAST_ADDR,
	AM_REQUEST 		= 201, //AM_BROADCAST_ADDR,
	AM_ADMISSION	= 202,
	AM_NEWCYCLE		= 203,
	AM_DATA			= 204,
	AM_AGGREGATION 	= 205,
	//TOS_BCAST_ADDR = 255,
	BASE_STATION_ADDRESS = 0,
	    
    LEACH_ROUND_LENGTH = 100000,            // 7 minutes pour l'intervalle de temps de chaque round
	LEACH_ANNONCE_LENGTH = 10000,           // 1 minutes qu'il attend le CH pour annocner qu'il est CH
	LEACH_ORGANISATION_LENGTH = 40000,      // 40 seconde pour que chaque memebre renvoya au CH qu'il fera parti de son groupe
	LEACH_SLOT_LENGTH=1000,                 // chaque 1 seconde un memebre envoie la donn�e dans son slot
	
	RADIO_MAX_POWER	= 31
};

typedef nx_struct annonce_msg {
  	nx_uint8_t 		ID_MEMBER;				//Node Identifier
  	nx_uint8_t 		state;					//0:Member	1:CH	2:BaseStation
  	nx_uint8_t 		type;					//
} annonce_msg_t;

typedef nx_struct req_msg {
	nx_uint8_t 	ID_MEMBER;  		//Node Identifier
    nx_uint8_t	type;				// Type: 0 for join, 1 for disjoin
}req_msg_t;

typedef nx_struct admission_msg {
	nx_uint8_t 	ID_MEMBER;  			//Node Identifier
}admission_msg_t;

typedef nx_struct data_msg {
	nx_uint8_t 	ID_MEMBER;  			//Node Identifier
	nx_uint8_t 	data;  			//Node Identifier
    nx_uint8_t 	power;					//Member Power
}data_msg_t;

typedef nx_struct aggregate_msg {
	nx_uint8_t 	data;  			//Node Identifier
}aggregate_msg_t;
#endif /* SMAC_H */
