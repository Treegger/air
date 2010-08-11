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
	
	import mx.events.DynamicEvent;

	
	public class StratusConnector extends EventDispatcher
	{
		private var connectUrl:String = "rtmfp://stratus.rtmfp.net";
		private const developerKey:String = PrivateProperties.STRATUS_DEVELOPER_KEY;

		// this is the connection to rtmfp server
		public var netConnection:NetConnection;
		
		public static const CONNECTION_SUCCESS:String="CONNECTION_SUCCESS";
		public static const CONNECTION_FAILURE:String="CONNECTION_FAILURE";
		public static const CONNECTION_CLOSE:String="CONNECTION_CLOSE";
		

		private var connecting:Boolean = false;
		
		[Inject]
		public var chatController:ChatController;
		
		public function StratusConnector()
		{
		}
		

		private function remoteCallHandler( data:Object ):void
		{
			trace( "Remote called " + data.remoteEvent + data.remoteObject );
			const e:DynamicEvent = new DynamicEvent( data.remoteEvent );
			e.data = data.remoteObject;
			this.dispatchEvent( e );
		}
			
		public function connect( contact:Contact, callBack:Function ):void
		{
			if( netConnection )
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
				netConnection = new NetConnection();
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
				ioStream.outputConnect( netConnection, IOStream.FILE_STREAM, false );
	
				ioStream.output.client = {
					onPeerConnect: function( remoteStream:NetStream ):Boolean
					{
						trace( "Peer Connect");
						ioStream.inputConnect( netConnection, remoteStream.farID, IOStream.FILE_STREAM, false );
						ioStream.input.client =  {
								remoteCall: remoteCallHandler
						};
						callBack( contact, ioStream );
						return true;
					}					
				
				}				
			}
		}
		
		
		public function handshake( contact:Contact, remoteId:String ):void
		{
			
			if( netConnection != null )
			{
				_handshake( contact, remoteId );
			}
			else
			{
				netConnection = new NetConnection();
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
			ioStream.outputConnect( netConnection, IOStream.FILE_STREAM, false );
			
			ioStream.inputConnect( netConnection, remoteId, IOStream.FILE_STREAM, false );
			ioStream.input.client = {
				remoteCall: remoteCallHandler
			};

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
					netConnection = null;
					break;
			}
		}

		


		
		
		
		
	}
}