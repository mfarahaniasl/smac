interface iSMAC{
  command 	error_t	keepAlive(uint8_t status);
  //command error_t	stop();
  command 	void	setSynchronizer(uint8_t status);
  command 	void	setFollower(uint8_t status);
  event 	void	activated();
  event 	void	readyTransmite();
  event   void	activationChanged(uint8_t status);	//1=is active 0=isn't active
  event 	void 	syncReceived(uint16_t node_id);
  //event	void	isBorder();
}
