package com.treegger.airim.controller
{
	import com.treegger.protobuf.AuthenticateRequest;
	import com.treegger.protobuf.Presence;
	import com.treegger.protobuf.Roster;
	import com.treegger.protobuf.RosterItem;
	import com.treegger.protobuf.WebSocketMessage;
	import com.treegger.util.preferences.UserAccount;
	import com.treegger.websocket.WSConnector;
	
	import flash.events.DataEvent;
	import flash.events.EventDispatcher;
	import flash.utils.ByteArray;
	
	import mx.collections.ArrayCollection;

	public class ChatController extends EventDispatcher
	{
		
		private var wsConnector:WSConnector; 

		
		
		private var roster:Roster;
		
		[Bindable]
		public var contacts:ArrayCollection;
		

		
		public function ChatController()
		{
			wsConnector = new WSConnector();
			wsConnector.onMessage = onMessage;
			wsConnector.connect( "wss", "xmpp.treegger.com", 443, "/tg-1.0" );
			
		}
		
		
		private function onMessage( message:WebSocketMessage ):void
		{
			if( message.hasAuthenticateResponse )
			{
				_autheticated = message.authenticateResponse.hasSessionId;
				dispatchEvent( new ChatEvent( ChatEvent.AUTHENTICATION ) );
			}
			else if( message.hasRoster )
			{
				roster = message.roster;
				if( roster )
				{
					contacts = new ArrayCollection();
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
							contact.jid = jidWithoutResource( item.jid );
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
		
		private function findContactByJID( jid:String ):Contact
		{
			for each( var contact:Contact in contacts )
			{
				if( contact.jid == jidWithoutResource( jid ) )
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
		
		private var _autheticated:Boolean = false;
		public function get authenticated():Boolean
		{
			return _autheticated;
		}
		
		
		public function authenticate( userAccount:UserAccount ):void
		{
			const wsMessage:WebSocketMessage = new WebSocketMessage();
			const authReq:AuthenticateRequest = new AuthenticateRequest();
			authReq.username = userAccount.username+'@'+userAccount.socialNetwork.toLocaleLowerCase();
			authReq.password = userAccount.password;
			authReq.resource = 'AirIM';
			
			wsMessage.authenticateRequest = authReq;
			
			const buffer:ByteArray = new ByteArray()
			wsMessage.writeExternal( buffer );
			
			trace( "Authenticating: " +  authReq.username );
			wsConnector.send( buffer );
		}
	}
}