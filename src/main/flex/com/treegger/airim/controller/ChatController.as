package com.treegger.airim.controller
{
	import com.treegger.airim.model.ChatContent;
	import com.treegger.airim.model.Contact;
	import com.treegger.airim.model.UserAccount;
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
	import flash.events.EventDispatcher;
	import flash.events.TimerEvent;
	import flash.utils.ByteArray;
	import flash.utils.Timer;
	
	import mx.collections.ArrayCollection;
	import mx.events.CollectionEvent;
	import mx.events.CollectionEventKind;

	public class ChatController extends EventDispatcher
	{

		public static const MESSAGE_TYPE_STRATUS_VIDEO_REQUEST:String = "stratusVideoRequest";
		public static const MESSAGE_TYPE_STRATUS_FILE_REQUEST:String = "stratusFileRequest";
		
		private var wsConnector:WSConnector; 
		
		private var roster:Roster;
		
		[ArrayElementType("Contact")]
		[Bindable]
		public var contacts:ArrayCollection;
		
		public var exitState:Boolean = false;

		
		public function ChatController()
		{
			wsConnector = new WSConnector();
			wsConnector.onHandshake = onHandshake;
			wsConnector.onMessage = onMessage;
			//wsConnector.connect( "wss", "xmpp.treegger.com", 443, "/tg-1.0" );
			wsConnector.connect( "wss", "xmpp.treegger.com", 443, "/tg-1.0" );
		}
		
		[Bindable(event=ChatEvent.UNREAD_CONTENTS_CHANGE)]
		public function get unreadContents():uint
		{
			var unread:uint = 0;
			for each( var contact:Contact in contacts )
			{
				unread += contact.unreadContents;
			}
			return unread;
		}
		private function contactsChangeHandler( event:CollectionEvent ):void
		{
			var contact:Contact;
			if( event.kind == CollectionEventKind.ADD )
			{
				for each( contact in event.items )
				{
					contact.addEventListener( 'hasUnreadContentChanged', hasUnreadContentChangedHandler );
				}
			}
			else if( event.kind == CollectionEventKind.REMOVE )
			{
				for each( contact in event.items )
				{
					contact.removeEventListener( 'hasUnreadContentChanged', hasUnreadContentChangedHandler );
				}
				
			}
		}
		
		private function hasUnreadContentChangedHandler( event:Event ):void
		{
			dispatchEvent( new ChatEvent( ChatEvent.UNREAD_CONTENTS_CHANGE ) );
		}
		
		
		public function close():void
		{
			pingTimer.stop();
			wsConnector.close();
			authenticated = false;
			exitState = true;
		}
		
		private var pingTimer:Timer;
		private function onHandshake():void
		{
			 pingTimer = new Timer( 30*1000 );
			 pingTimer.addEventListener(TimerEvent.TIMER, ping );
			 pingTimer.start();
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
		
		private function onMessage( message:WebSocketMessage ):void
		{
			if( message.hasAuthenticateResponse )
			{
				authenticated = message.authenticateResponse.hasSessionId;
				sendPresence();
				dispatchEvent( new ChatEvent( ChatEvent.AUTHENTICATION ) );
			}
			else if( message.hasRoster )
			{
				roster = message.roster;
				if( roster )
				{
					contacts = new ArrayCollection();
					contacts.addEventListener(CollectionEvent.COLLECTION_CHANGE, contactsChangeHandler );
				}
				dispatchEvent( new ChatEvent( ChatEvent.ROSTER ) );
			}
			else if( message.hasPresence )
			{
				var presence:Presence = message.presence;
				var contact:Contact = findContactByJID( presence.from );
			 		
				var foundContact:Boolean = contact != null;
			
				
				if( presence.hasType && presence.type.toLowerCase() == "unavailable" )
				{
					if( contact ) contacts.removeItemAt(contacts.getItemIndex( contact ) );
				}
				else
				{
					if( !foundContact )
					{
						const item:RosterItem = findRosterItemByJID( presence.from );
						if( item )
						{
							contact = new Contact();
							contact.jidWithoutRessource = jidWithoutResource( item.jid );
							contact.name = item.name;
						}
					}
					if( contact )
					{
						
						contact.status = presence.status;
						contact.type = presence.type;
						contact.show = presence.show;
						
					}
					if( !foundContact ) contacts.addItem( contact );
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
					if( textMessage.type == MESSAGE_TYPE_STRATUS_VIDEO_REQUEST )
					{
						targetContact.stratusId = textMessage.thread;
						chatEvent = new ChatEvent( ChatEvent.STRATUSVIDEO );
					}
					else if( textMessage.type == MESSAGE_TYPE_STRATUS_FILE_REQUEST )
					{
						targetContact.stratusId = textMessage.thread;
						chatEvent = new ChatEvent( ChatEvent.STRATUSFILE );
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
					
					chatEvent.targetContact = targetContact;					
					dispatchEvent( chatEvent );
				}
			}
		}
		
		private function setVCard( vcard:VCardResponse ):void
		{
			for each( var contact:Contact in contacts )
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
			vcardRequest.username = contact.jidWithoutRessource;
			
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
		
		public function authenticate( userAccount:UserAccount ):void
		{
			const authReq:AuthenticateRequest = new AuthenticateRequest();
			
			authReq.username = userAccount.username+'@'+userAccount.socialNetwork.toLocaleLowerCase();
			authReq.password = userAccount.password;
			authReq.resource = 'AirIM';
			currentJID = authReq.username+"/" +authReq.resource;
			
			currentContact = new Contact();
			currentContact.name = userAccount.username;  
			currentContact.jidWithoutRessource = authReq.username;  
			
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