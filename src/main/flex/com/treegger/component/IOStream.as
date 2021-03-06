package com.treegger.component
{
	import flash.events.NetStatusEvent;
	import flash.net.NetConnection;
	import flash.net.NetStream;

	public class IOStream
	{
		
		public var output:NetStream;
		public var input:NetStream;
		
		
		public var peerConnectTimeout:uint = 10*1000;

		public function duplexConnect( netConnection:NetConnection, remoteStratusId:String, streamName:String, dataReliable:Boolean=false ):void
		{
			outputConnect( netConnection, streamName, null, dataReliable );
			inputConnect( netConnection, remoteStratusId, streamName, null, dataReliable );
		}
		public function outputConnect( netConnection:NetConnection, streamName:String, client:Object, dataReliable:Boolean ):void
		{
			output = new NetStream( netConnection, NetStream.DIRECT_CONNECTIONS);
			//if( dataReliable ) output.dataReliable = dataReliable;
			if( client ) output.client = client;
			output.addEventListener(NetStatusEvent.NET_STATUS, outputStreamHandler );
			output.publish( streamName );
		}
		
		
		public function inputConnect( netConnection:NetConnection, remoteStratusId:String, streamName:String, client:Object, dataReliable:Boolean ):void
		{
			input = new NetStream( netConnection, remoteStratusId );
			//if( dataReliable ) input.dataReliable = dataReliable;
			if( client ) input.client = client;
			input.addEventListener( NetStatusEvent.NET_STATUS, inputStreamHandler );
			input.play( streamName );			
		}
		
		private function connectTimeoutHandler(receiveStream:NetStream):void {
			
			trace( "Timeout connection on inputStream " + receiveStream.info );
		}
		
		
		private function onPeerConnectHandler(subscriber:NetStream):Boolean 
		{
			trace( "Peer connect " + subscriber.info );
			return true;
		}
		
		private function outputStreamHandler(event:NetStatusEvent ):void
		{
			trace("Output stream event: " + event.info.code + "\n");
			switch (event.info.code)
			{
				case "NetStream.Play.Start":
					break;
			}
		}
		
		private function inputStreamHandler(event:NetStatusEvent):void
		{
			trace("Input stream event: " + event.info.code + "\n");
			switch (event.info.code)
			{
				case "NetStream.Play.UnpublishNotify":
					hangup();
					break;
			}
		}
		
		
		public function hangup():void
		{
			trace("Hanging");
			
			
			if (input)
			{
				input.close();
				input.removeEventListener(NetStatusEvent.NET_STATUS, inputStreamHandler);
			}
			
			if (output )
			{
				output.close();
				output.removeEventListener(NetStatusEvent.NET_STATUS, outputStreamHandler);
			}
			
			output = null;
			input = null;
			
		}
	}
}