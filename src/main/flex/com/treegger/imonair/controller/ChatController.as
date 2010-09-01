package com.treegger.imonair.controller
{
	import com.treegger.component.Notification;
	import com.treegger.component.StratusConnector;
	import com.treegger.imonair.model.ChatContent;
	import com.treegger.imonair.model.Contact;
	import com.treegger.imonair.model.UserAccount;
	import com.treegger.protobuf.AuthenticateRequest;
	import com.treegger.protobuf.Ping;
	import com.treegger.protobuf.Presence;
	import com.treegger.protobuf.Roster;
	import com.treegger.protobuf.RosterItem;
	import com.treegger.protobuf.TextMessage;
	import com.treegger.protobuf.VCardRequest;
	import com.treegger.protobuf.VCardResponse;
	import com.treegger.protobuf.WebSocketMessage;
	import com.treegger.websocket.WSConnector;
	
	import flash.events.DataEvent;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.TimerEvent;
	import flash.utils.ByteArray;
	import flash.utils.Timer;
	import flash.utils.setTimeout;
	
	import mx.collections.ArrayCollection;
	import mx.events.CollectionEvent;
	import mx.events.CollectionEventKind;
	import mx.events.DynamicEvent;

	public class ChatController extends EventDispatcher
	{
		public static const MESSAGE_TYPE_STRATUS_REQUEST:String = "stratusRequest";

		private var wsConnector:WSConnector; 
		
		private var roster:Roster;
		
		[ArrayElementType("com.treegger.imonair.model.Contact")]
		[Bindable]
		public var onlineContacts:ArrayCollection = new ArrayCollection();
		
		[ArrayElementType("com.treegger.imonair.model.Contact")]
		[Bindable]
		public var contacts:ArrayCollection = new ArrayCollection();
		
		private var _stratusConnector:StratusConnector;
		[Inject]
		public function set stratusConnector(value:StratusConnector):void
		{
			_stratusConnector = value;
			var chatEvent:ChatEvent;
			stratusConnector.addEventListener( ChatEvent.STRATUSFILE, function( event:DynamicEvent ):void
			{
				chatEvent = new ChatEvent( ChatEvent.STRATUSFILE );
				chatEvent.targetContact = event.contact;					
				dispatchEvent( chatEvent );
			});
			stratusConnector.addEventListener( ChatEvent.STRATUSVIDEO, function( event:DynamicEvent ):void
			{
				chatEvent = new ChatEvent( ChatEvent.STRATUSVIDEO );
				chatEvent.targetContact = event.contact;					
				dispatchEvent( chatEvent );
			});
		}
		public function get stratusConnector():StratusConnector
		{
			return _stratusConnector;
		}
		
		public var exitState:Boolean = false;
		public var connectingState:Boolean = false;
		
		private var currentSessionId:String;
		
		public function ChatController()
		{
			connect();
		}
		
		
		public function connect():void
		{
			trace( "Connect" );
			connectingState = true;
			wsConnector = new WSConnector();
			wsConnector.onHandshake = onSocketHandshake;
			wsConnector.onMessage = onSocketMessage;
			wsConnector.onError = onSocketError;
			wsConnector.onClose = onSocketClose;
			//wsConnector.connect( "wss", "xmpp.treegger.com", 443, "/tg-1.0" );
			wsConnector.connect( "wss", "xmpp.treegger.com", 443, "/tg-1.0" );	
		}
		
		
		[Bindable(event=ChatEvent.UNREAD_CONTENTS_CHANGE)]
		public function get unreadContents():uint
		{
			var unread:uint = 0;
			for each( var contact:Contact in onlineContacts )
			{
				unread += contact.unreadContents;
			}
			return unread;
		}
		private function onlineContactsChangeHandler( event:CollectionEvent ):void
		{
			var contact:Contact;
			if( event.kind == CollectionEventKind.ADD || event.kind == CollectionEventKind.REMOVE || event.kind == CollectionEventKind.RESET || event.kind == CollectionEventKind.REPLACE ) 
			{
				for each( contact in event.items )
				{
					contact.removeEventListener( 'hasUnreadContentChanged', hasUnreadContentChangedHandler );
					contact.addEventListener( 'hasUnreadContentChanged', hasUnreadContentChangedHandler );
				}
			}
		}
		
		private function hasUnreadContentChangedHandler( event:Event ):void
		{
			dispatchEvent( new ChatEvent( ChatEvent.UNREAD_CONTENTS_CHANGE ) );
		}
		
		
		public function close( exit:Boolean = false ):void
		{
			wsConnector.onHandshake = null;
			wsConnector.onMessage = null;
			wsConnector.onError = null;
			wsConnector.onClose = null;

			pingTimer.stop();
			wsConnector.close();
			authenticated = false;
			exitState = exit;
		}
		
		private var pingTimer:Timer;
		private function onSocketHandshake():void
		{
			connectingState = false;
			retryConnectionCount = 0;
		 	pingTimer = new Timer( 30*1000 );
			pingTimer.addEventListener(TimerEvent.TIMER, ping );
			pingTimer.start();

			dispatchEvent( new ChatEvent( ChatEvent.HANDSHAKED ) );
		}
		
		private var pingId:int = 0;
		private function ping(event:TimerEvent):void
		{
			const ping:Ping = new Ping();
			ping.id = pingId.toString();
			pingId++;
			const wsMessage:WebSocketMessage = new WebSocketMessage();
			wsMessage.ping = ping;
			trace( "Ping id " + ping.id );
			send( wsMessage );			
		}
		

		private var retryConnectionCount:Number;
		private function onSocketError( error:Error=null ):void
		{
			trace( "Socket Error... reconnecting...");
			if( connectingState ) setTimeout( reconnect, 1000*60 );
			else reconnect();
			connectingState = false;
		}
		private function onSocketClose( event:Event=null ):void
		{
			trace( "Socket Close... reconnecting...");
			if( connectingState ) setTimeout( reconnect, 1000*60 );
			else reconnect();
			connectingState = false;
		}
		
		private function reconnect():void
		{

			if( onlineContacts )
			{
				for each( var contact:Contact in onlineContacts )
				{
					contact.type = 'unavailable';
				}
				onlineContacts.removeAll();
			}
			if( pingTimer ) pingTimer.stop();
			wsConnector.close();
			authenticated = false;

			
			var delay:Number = 0;
			if( retryConnectionCount )
			{
				delay = retryConnectionCount * 10 * 1000;
				if( delay > 10*60*1000 ) delay = 10*60*1000;  
			}
			retryConnectionCount++;
			
			
			
			if( delay > 1 )
			{
				new Notification( "Network interruption", "Connecting in " + (delay/1000) + " seconds...", 1 );
				trace( "Connecting in "+(delay/1000)+"sec...");
				setTimeout( connect , delay );
			}
			else
			{
				trace( "Connecting...");
				new Notification( "Network interruption", "Reconnecting...", 1 );
				connect();
			}
		}
		
		private function onSocketMessage( message:WebSocketMessage ):void
		{
			if( message.hasAuthenticateResponse )
			{
				authenticated = message.authenticateResponse.hasSessionId;
				if( authenticated )
				{
					currentSessionId = message.authenticateResponse.sessionId;
				}
				else
				{
					currentSessionId = null;
				}
				sendPresence();
				dispatchEvent( new ChatEvent( ChatEvent.AUTHENTICATION ) );
			}
			else if( message.hasBindResponse )
			{
				authenticated = message.bindResponse.hasSessionId;
				if( authenticated )
				{
					currentSessionId = message.bindResponse.sessionId;
				}
				else
				{
					currentSessionId = null;
				}
				sendPresence();
				dispatchEvent( new ChatEvent( ChatEvent.AUTHENTICATION ) );
				
			}
			else if( message.hasRoster )
			{
				roster = message.roster;
				var contact:Contact;
				if( roster )
				{
					for each( var rosterItem:RosterItem in roster.item )
					{
						contact = findContactByJID( rosterItem.jid );
						if( contact == null )
						{
	 						contact = new Contact();
							contact.name = rosterItem.name;
							contact.jidWithoutRessource = rosterItem.jid;
							contacts.addItem( contact );
						}
					}
					onlineContacts.removeEventListener(CollectionEvent.COLLECTION_CHANGE, onlineContactsChangeHandler );
					onlineContacts.addEventListener(CollectionEvent.COLLECTION_CHANGE, onlineContactsChangeHandler );
				}
				dispatchEvent( new ChatEvent( ChatEvent.ROSTER ) );
			}
			else if( message.hasPresence )
			{
				var presence:Presence = message.presence;
				contact = findContactByJID( presence.from );
			 		
				var online:Boolean = onlineContacts.contains( contact );
			
				
				if( presence.hasType && presence.type.toLowerCase() == "unavailable" )
				{
					if( contact )
					{
						contact.status = presence.status;
						contact.type = presence.type;
						contact.show = presence.show;
					}
					if( online )
						onlineContacts.removeItemAt(onlineContacts.getItemIndex( contact ) );
				}
				else
				{
					contact.status = presence.status;
					contact.type = presence.type;
					contact.show = presence.show;
					if( !online ) onlineContacts.addItem( contact );
				}
			}
			else if( message.hasVcardResponse )
			{
				setVCard( message.vcardResponse );
			}
			else if( message.hasTextMessage )
			{
				
				const textMessage:TextMessage = message.textMessage;
				const targetContact:Contact = findContactByJID( textMessage.fromUser );
				if( targetContact )
				{
					var chatEvent:ChatEvent;
					

					if( textMessage.type == MESSAGE_TYPE_STRATUS_REQUEST )
					{
						stratusConnector.handshake( targetContact, textMessage.thread );
					}
					else if( textMessage.hasComposing && textMessage.composing )
					{
						targetContact.composing = true;
						chatEvent = new ChatEvent( ChatEvent.TEXTMESSAGE_COMPOSING );
					}
					else if( textMessage.hasGone && textMessage.gone )
					{
						targetContact.composing = false;
						chatEvent = new ChatEvent( ChatEvent.TEXTMESSAGE_GONE );
					}
					else if( textMessage.hasInactive && textMessage.inactive )
					{
						targetContact.composing = false;
						chatEvent = new ChatEvent( ChatEvent.TEXTMESSAGE_INACTIVE );
					}
					else if( textMessage.hasPaused && textMessage.paused )
					{
						targetContact.composing = false;
						chatEvent = new ChatEvent( ChatEvent.TEXTMESSAGE_PAUSED );
					}
					else
					{
						targetContact.composing = false;
						if( textMessage.hasBody )
						{
							const chatContent:ChatContent = new ChatContent();
							chatContent.time = new Date();
							chatContent.from = targetContact.name;
							chatContent.message = textMessage.body;
							targetContact.chatContents.addItem( chatContent );
							chatEvent = new ChatEvent( ChatEvent.TEXTMESSAGE );
						}
						else
						{
							chatEvent = new ChatEvent( ChatEvent.TEXTMESSAGE_ACTIVE );		
						}
					}
					
					if( chatEvent )
					{
						chatEvent.targetContact = targetContact;					
						dispatchEvent( chatEvent );
					}
				}
			}
		}
		
		private function setVCard( vcard:VCardResponse ):void
		{
			for each( var contact:Contact in onlineContacts )
			{
				if( contact.jidWithoutRessource == vcard.fromUser )
				{
					contact.vCardFetched = true;
					contact.name = vcard.fn;
					contact.nickname = vcard.nickname;
					contact.photoURL = vcard.photoExternal;
				}
			}
			if( currentContact.jidWithoutRessource == vcard.fromUser )
			{
				currentContact.vCardFetched = true;
				currentContact.name = vcard.fn;
				currentContact.photoURL = vcard.photoExternal;
			}
		}

		private function findRosterItemByJID( jid:String ):RosterItem
		{
			if( roster.item ) for each( var item:RosterItem in roster.item )
			{
				if( item.jid == jidWithoutResource( jid ) )
				{
					return item;
				}
			}
			return null;
		}
		
		public function findContactByJID( jid:String ):Contact
		{
			for each( var contact:Contact in contacts )
			{
				if( contact.jidWithoutRessource == jidWithoutResource( jid ) )
				{
					return contact;
				}
			}
			return null;
		}
		
		private function jidWithoutResource( jid:String ):String
		{
			const i:int =  jid.indexOf( '/' );
			if( i > 0 ) return jid.substr( 0, i );
			return jid;
		}
		
		private var currentJID:String;
		
		[Bindable]
		public var currentContact:Contact;
			
		private var _autheticated:Boolean = false;
		public function get authenticated():Boolean
		{
			return _autheticated;
		}
		public function set authenticated( value:Boolean ):void
		{
			_autheticated = value;
			if( !value )
			{
				currentJID = null;
				currentContact = null;
			}
			
		}
		
		public function requestVCard( contact:Contact ):void
		{
			const vcardRequest:VCardRequest = new VCardRequest();
			vcardRequest.username = contact.screenname;
			
			const wsMessage:WebSocketMessage = new WebSocketMessage();
			wsMessage.vcardRequest = vcardRequest;
			send( wsMessage );
		}

		public function sendTextMessage( to:String, body:String, type:String = null, thread:String = null ):void
		{
			if( authenticated )
			{
				const textMessage:TextMessage = new TextMessage();
				textMessage.fromUser = currentJID;
				textMessage.toUser = to;
				textMessage.body = body;
				textMessage.type = type;
				textMessage.thread = thread;
				textMessage.active = true;
				
				const wsMessage:WebSocketMessage = new WebSocketMessage();
				wsMessage.textMessage = textMessage;
				trace( "TextMessage: " +  textMessage );
				send( wsMessage );
			}
			
		}
		public function sendStateNotificationMessage( to:String, composing:Boolean, paused:Boolean, active:Boolean, gone:Boolean ):void
		{
			const textMessage:TextMessage = new TextMessage();
			textMessage.fromUser = currentJID;
			textMessage.toUser = to;
			textMessage.type = 'chat';

			textMessage.composing = composing;
			textMessage.active = active;
			textMessage.paused = paused;
			textMessage.gone = gone;

			const wsMessage:WebSocketMessage = new WebSocketMessage();
			wsMessage.textMessage = textMessage;
			send( wsMessage );
		}
		
		public function sendPresence(  type:String=null, show:String=null, status:String=null ):void
		{
			if( authenticated )
			{
				const presence:Presence = new Presence();
				presence.from = currentJID;
				presence.type = type;
				presence.show = show;
				presence.status = status;
				
				
				const wsMessage:WebSocketMessage = new WebSocketMessage();
				wsMessage.presence = presence;
				trace( "Presence: " +  presence );
				send( wsMessage );
			}
			
		}
		
		public function disconnect( newSession:Boolean=false ):void
		{
			sendPresence( "unavailable" );
			contacts.removeAll();
			onlineContacts.removeAll();
			if( newSession ) currentSessionId = null;
			close();			
		}
		
		public function authenticate( userAccount:UserAccount, newSession:Boolean=false ):void
		{
			if( authenticated )
			{
				disconnect( newSession );
				connect();
			}

			
			const authReq:AuthenticateRequest = new AuthenticateRequest();
			

			const socialNetwork:String = userAccount.socialNetwork.toLocaleLowerCase();
			var username:String = userAccount.username;


			if( socialNetwork == 'foursquare' )
			{
				username = username.replace( /\@/g, '#' );
			}


			authReq.username = username+'@'+socialNetwork;
			authReq.password = userAccount.password;
			authReq.resource = 'IMonAir';
			authReq.sessionId = currentSessionId;
			
			currentJID = authReq.username.toLowerCase()+"/" +authReq.resource;
			
			currentContact = new Contact();
			currentContact.name = userAccount.username;  
			currentContact.jidWithoutRessource = authReq.username.toLowerCase();  
			
			const wsMessage:WebSocketMessage = new WebSocketMessage();
			wsMessage.authenticateRequest = authReq;
			trace( "Authenticating: " +  authReq.username );
			send( wsMessage );			
		}
		
		
		private function send( wsMessage:WebSocketMessage ):void
		{
			if( ! exitState )
			{
				const buffer:ByteArray = new ByteArray()
				wsMessage.writeExternal( buffer );
				wsConnector.send( buffer );
			}
		}
	}
}