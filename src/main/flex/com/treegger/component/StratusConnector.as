package com.treegger.component
{
	import com.treegger.airim.PrivateProperties;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.NetStatusEvent;
	import flash.net.NetConnection;

	
	public class StratusConnector extends EventDispatcher
	{
		private var connectUrl:String = "rtmfp://stratus.rtmfp.net";
		private const developerKey:String = PrivateProperties.STRATUS_DEVELOPER_KEY;

		// this is the connection to rtmfp server
		public var netConnection:NetConnection;
		
		public static const CONNECTION_SUCCESS:String="CONNECTION_SUCCESS";
		public static const CONNECTION_FAILURE:String="CONNECTION_FAILURE";
		public static const CONNECTION_CLOSE:String="CONNECTION_CLOSE";

		public function connect():void
		{
			trace( "Connecting" );
			netConnection = new NetConnection();
			netConnection.addEventListener( NetStatusEvent.NET_STATUS, netConnectionHandler );
			
			try
			{
				netConnection.connect( connectUrl + "/" + developerKey );
			}
			catch (e:ArgumentError)
			{
				dispatchEvent( new Event(CONNECTION_FAILURE) );
			}
		}
		private function netConnectionHandler(event:NetStatusEvent):void
		{
			trace("NetConnection event: " + event.info.code + "\n");
			
			switch (event.info.code)
			{
				case "NetConnection.Connect.Success":
					dispatchEvent( new Event(CONNECTION_SUCCESS) );
					break;
				
				case "NetStream.Connect.Closed":
					dispatchEvent( new Event(CONNECTION_CLOSE) );
					break;
			}
		}

		


	}
}