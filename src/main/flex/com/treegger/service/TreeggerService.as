package com.treegger.service
{
	import com.treegger.protobuf.AuthenticateRequest;
	import com.treegger.protobuf.WebSocketMessage;
	import com.treegger.websocket.WSConnector;
	
	import flash.utils.ByteArray;

	public class TreeggerService
	{
		private const wsConnector:WSConnector = new WSConnector();
		
		public function TreeggerService()
		{
		}
		public function connect():void
		{
			wsConnector.connect( "wss", "xmpp.treegger.com", 443, "/tg-1.0" );
		}
		
		public function authenticate( user:String, socialNetwork:String, password:String, resource:String  ):void
		{
			const wsMessage:WebSocketMessage = new WebSocketMessage();
			
			
			const authReq:AuthenticateRequest = new AuthenticateRequest();
			authReq.username = user+'@'+socialNetwork;
			authReq.password = password;
			authReq.resource = resource;
			
			wsMessage.authenticateRequest = authReq;
			
			const buffer:ByteArray = new ByteArray()
			wsMessage.writeExternal( buffer );
			
			wsConnector.send( buffer );
		}
	}
}