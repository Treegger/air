package com.treegger.component
{
	import com.treegger.airim.PrivateProperties;
	import com.treegger.airim.controller.ChatController;
	import com.treegger.airim.model.Contact;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.NetStatusEvent;
	import flash.net.NetConnection;
	import flash.net.NetStream;
	import flash.net.getClassByAlias;
	import flash.utils.setTimeout;
	
	import mx.events.DynamicEvent;
	import mx.rpc.mxml.Concurrency;

	
	public class StratusConnector extends EventDispatcher
	{
		private var connectUrl:String = "rtmfp://stratus.rtmfp.net";
		private const developerKey:String = PrivateProperties.STRATUS_DEVELOPER_KEY;

		// this is the connections to rtmfp server
		public var netConnections:Object={};
		
		public static const CONNECTION_SUCCESS:String="CONNECTION_SUCCESS";
		public static const CONNECTION_FAILURE:String="CONNECTION_FAILURE";
		public static const CONNECTION_CLOSE:String="CONNECTION_CLOSE";
		
		private static const NETSTREAM_NAME:String="airim";

		
		[Inject]
		public var chatController:ChatController;
		
		public function StratusConnector()
		{
		}
		
		private function getNetConnection( contact:Contact):NetConnection
		{
			return netConnections[contact.jidWithoutRessource];
		}
		private function setNetConnection( contact:Contact, netConnection:NetConnection ):void
		{
			netConnections[contact.jidWithoutRessource] = netConnection;
		}

			
		public function connect( contact:Contact, callBack:Function ):void
		{
			if( getNetConnection( contact ) )
			{
					ioConnect( contact, callBack );
			}
			else
			{
				const netConnection:NetConnection = new NetConnection();
				setNetConnection( contact, netConnection );
				netConnection.addEventListener( NetStatusEvent.NET_STATUS, netConnectionHandler );

				const successConnectHandler:Function = function ( event:Event ):void
				{
					removeEventListener( CONNECTION_SUCCESS,  successConnectHandler );
					chatController.sendTextMessage( contact.jidWithoutRessource, null, ChatController.MESSAGE_TYPE_STRATUS_REQUEST, netConnection.nearID );
					ioConnect( contact, callBack );
				}
				addEventListener( CONNECTION_SUCCESS,  successConnectHandler );

				try
				{
					netConnection.connect( connectUrl + "/" + developerKey );
				}
				catch (e:ArgumentError)
				{
					dispatchEvent( new Event(CONNECTION_FAILURE) );
				}
			}
		}
		
		private const ioStreams:Object = {};
		private function ioConnect( contact:Contact, callBack:Function ):void
		{
			var ioStream:IOStream = ioStreams[contact.jidWithoutRessource];
			if( ioStream )
			{
				callBack( contact, ioStream );
			}
			else
			{
			 	ioStream = new IOStream();
				ioStreams[contact.jidWithoutRessource] = ioStream;
				ioStream.outputConnect( getNetConnection( contact ), NETSTREAM_NAME, {
					onPeerConnect: function( remoteStream:NetStream ):Boolean
					{
						trace( "Peer Connect");
						ioStream.inputConnect( getNetConnection( contact ), remoteStream.farID, NETSTREAM_NAME, { remoteCall: remoteCallHandler }, false );
						setTimeout( function():void { callBack( contact, ioStream ) }, 100 );
						return true;
					}					
					
				}, false );
			}
		}
		
		
		public function handshake( contact:Contact, remoteId:String ):void
		{
			
			if( getNetConnection( contact ) != null )
			{
				connectedHandshake( contact, remoteId );
			}
			else
			{
				const netConnection:NetConnection = new NetConnection();
				setNetConnection( contact, netConnection );
				netConnection.addEventListener( NetStatusEvent.NET_STATUS, netConnectionHandler );
				
				const successConnectHandler:Function = function ( event:Event ):void
				{
					removeEventListener( CONNECTION_SUCCESS,  successConnectHandler );
					connectedHandshake( contact, remoteId );
				};
				addEventListener( CONNECTION_SUCCESS, successConnectHandler );
				
				try
				{
					netConnection.connect( connectUrl + "/" + developerKey );
				}
				catch (e:ArgumentError)
				{
					dispatchEvent( new Event(CONNECTION_FAILURE) );
				}
			}
			
		}
		private function connectedHandshake(contact:Contact, remoteId:String ):void
		{
			var ioStream:IOStream = new IOStream();
			ioStreams[contact.jidWithoutRessource] = ioStream;
			
			
			ioStream.outputConnect( getNetConnection( contact ), NETSTREAM_NAME, {
				onPeerConnect: function( remoteStream:NetStream ):Boolean
				{
					trace( "Peer Handshake Connect");
					return true;
				}
			}, false );
				
				

			ioStream.inputConnect( getNetConnection( contact ), remoteId, NETSTREAM_NAME, { remoteCall: remoteCallHandler }, false );

			
		}

		private function remoteCallHandler( data:Object ):void
		{
			trace( "Remote called " + data.remoteEvent +" / " + data.remoteObject );
			const e:DynamicEvent = new DynamicEvent( data.remoteEvent );
			e.data = data.remoteObject;
			this.dispatchEvent( e );
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
					var key:Object;
					var ioStream:IOStream;
					for( key in netConnections )
					{
						if( netConnections[ key ] == event.info.stream )
						{
							trace( "Cleanup " +key+" connection streams" );
							netConnections[ key ] = null;
							ioStream = ioStreams[key];				
							ioStream.hangup();
							ioStreams[key] = null;
							break;
						}
					}
					for( key in ioStreams )
					{
						ioStream = ioStreams[ key ]; 
						if( ioStream.input == event.info.stream || ioStream.output == event.info.stream )
						{
							trace( "Cleanup " +key+" io streams" );
							ioStream.hangup();
							ioStreams[key] = null;
							
							if( netConnections[ key ] )
							{
								(netConnections[ key ] as NetConnection).close();
								netConnections[ key ] = null;
							}							
							break;
						}						
					}
					
					//netConnection = null;
					
					break;
			}
		}

		


		
		
		
		
	}
}