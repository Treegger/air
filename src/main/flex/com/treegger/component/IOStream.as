package com.treegger.component
{
	import flash.events.NetStatusEvent;
	import flash.net.NetConnection;
	import flash.net.NetStream;

	public class IOStream
	{
		
		public var output:NetStream;
		public var input:NetStream;
			
		
		public function connect( netConnection:NetConnection, remoteStratusId:String, streamName:String ):void
		{
			input = new NetStream( netConnection, remoteStratusId );
			input.addEventListener( NetStatusEvent.NET_STATUS, inputStreamHandler );
			input.play( streamName );
			
			output = new NetStream( netConnection, NetStream.DIRECT_CONNECTIONS);
			output.addEventListener(NetStatusEvent.NET_STATUS, outputStreamHandler );
			output.publish( streamName );			
		}
		
		private function outputStreamHandler(event:NetStatusEvent ):void
		{
			trace("Outgoing stream event: " + event.info.code + "\n");
			switch (event.info.code)
			{
				case "NetStream.Play.Start":
					break;
			}
		}
		
		private function inputStreamHandler(event:NetStatusEvent):void
		{
			trace("Incoming stream event: " + event.info.code + "\n");
			switch (event.info.code)
			{
				case "NetStream.Play.UnpublishNotify":
					hangup();
					break;
			}
		}
		
		
		private function hangup():void
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