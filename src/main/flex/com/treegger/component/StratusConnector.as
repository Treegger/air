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
		

		private var connecting:Boolean = false;
		
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
				if( connecting )
				{
					addEventListener( CONNECTION_SUCCESS, function( event:Event ):void
					{
						ioConnect( contact, callBack );
					});
				}
				else
				{
					ioConnect( contact, callBack );
				}
			}
			else
			{
				connecting = true;
				const netConnection:NetConnection = new NetConnection();
				setNetConnection( contact, netConnection );
				netConnection.addEventListener( NetStatusEvent.NET_STATUS, netConnectionHandler );
				addEventListener( CONNECTION_SUCCESS, function( event:Event ):void
				{
					chatController.sendTextMessage( contact.jidWithoutRessource, null, ChatController.MESSAGE_TYPE_STRATUS_REQUEST, netConnection.nearID );
					ioConnect( contact, callBack );
				});

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
		
		private const contactStreams:Object = {};
		private function ioConnect( contact:Contact, callBack:Function ):void
		{
			var ioStream:IOStream = contactStreams[contact.jidWithoutRessource];
			if( ioStream )
			{
				callBack( contact, ioStream );
			}
			else
			{
			 	ioStream = new IOStream();
				contactStreams[contact.jidWithoutRessource] = ioStream;
				ioStream.outputConnect( getNetConnection( contact ), IOStream.FILE_STREAM, {
					onPeerConnect: function( remoteStream:NetStream ):Boolean
					{
						trace( "Peer Connect");
						ioStream.inputConnect( getNetConnection( contact ), remoteStream.farID, IOStream.FILE_STREAM, { remoteCall: remoteCallHandler }, false );
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
				_handshake( contact, remoteId );
			}
			else
			{
				const netConnection:NetConnection = new NetConnection();
				setNetConnection( contact, netConnection );
				netConnection.addEventListener( NetStatusEvent.NET_STATUS, netConnectionHandler );
				addEventListener( CONNECTION_SUCCESS, function( event:Event ):void
				{
					_handshake( contact, remoteId );
				});
				
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
		private function _handshake(contact:Contact, remoteId:String ):void
		{
			var ioStream:IOStream = new IOStream();
			contactStreams[contact.jidWithoutRessource] = ioStream;
			
			
			ioStream.outputConnect( getNetConnection( contact ), IOStream.FILE_STREAM, {
				onPeerConnect: function( remoteStream:NetStream ):Boolean
				{
					trace( "Peer Handshake Connect");
					return true;
				}
			}, false );
				
				

			ioStream.inputConnect( getNetConnection( contact ), remoteId, IOStream.FILE_STREAM, { remoteCall: remoteCallHandler }, false );

			
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
			connecting = false;
			trace("NetConnection event: " + event.info.code + "\n");
			
			switch (event.info.code)
			{
				case "NetConnection.Connect.Success":
					dispatchEvent( new Event(CONNECTION_SUCCESS) );
					break;
				
				case "NetStream.Connect.Closed":
					dispatchEvent( new Event(CONNECTION_CLOSE) );
					trace( event.info.stream.info );
					for( var key:Object in netConnections )
					{
						trace( "JID " + key );
						if( netConnections[ key ] == event.info.stream )
						{
							trace( "Found stream" );
							netConnections[ key ] = null;
							const ioStream:IOStream = contactStreams[key];				
							ioStream.hangup();
							contactStreams[key];
							break;
						}
					}
					//netConnection = null;
					
					break;
			}
		}

		


		
		
		
		
	}
}