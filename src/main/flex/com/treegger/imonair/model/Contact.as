package com.treegger.imonair.model
{
	import com.treegger.protobuf.Presence;
	
	import flash.events.EventDispatcher;
	
	import mx.collections.ArrayCollection;
	import mx.events.CollectionEvent;

	[Bindable]
	public class Contact extends EventDispatcher
	{
		public var name:String;
		public var nickname:String;
		
		public var jidWithoutRessource:String;
		
		private var presences:ArrayCollection = new ArrayCollection();
		
		public function resetPresences():void
		{
			presences.removeAll();
		}
		public function addPresence( presence:Presence ):void
		{
			var i:int=0;
			for each( var p:Presence in presences )
			{
				if( p.from == presence.from )
				{
					presences.removeItemAt( i );
					break;
				}
				i++
			}
			if( ! ( presence.hasType && presence.type.toLowerCase() == "unavailable" ) )
			{
				presences.addItem( presence );
			}
			
			dispatchEvent( new Event( 'statusColorChanged' ) );
		}
		public function get significantePresence():Presence
		{
			var presence:Presence;
			for each( presence in presences )
			{
				if( ( !presence.hasType || presence.type == "" ) 
					&& ( !presence.hasShow || presence.show == "" ) )
					return presence;
					
			}
			
			for each( presence in presences )
			{
				if( presence.hasShow && presence.show.length > 0 )
					return presence;
			}
			
			for each( presence in presences )
			{
				return presence;
			}
			
			return null;
		}
		
		public function get screenname():String
		{
			var i:int = jidWithoutRessource.indexOf('@');
			if( i > 0 ) return jidWithoutRessource.substr( 0, i );
			return jidWithoutRessource;
		}
		
		public function get type():String
		{
			const presence:Presence = significantePresence;
			if( presence && presence.hasType ) return presence.type;
			return "";
		}

		public function get status():String
		{
			const presence:Presence = significantePresence;
			if( presence && presence.hasStatus ) return presence.status;
			return "";
		}
		
		
		public function get show():String
		{
			const presence:Presence = significantePresence;
			if( presence && presence.hasShow ) return presence.show.toLocaleLowerCase();
			return "";
		}
		
		public var vCardFetched:Boolean;
		public var photoURL:String;
		
		public var stratusId:String;
		
		[ArrayElementType("com.treegger.imonair.model.ChatContent")]
		public var chatContents:ArrayCollection;
		

		
		public function Contact()
		{
			chatContents = new ArrayCollection();
			chatContents.addEventListener(CollectionEvent.COLLECTION_CHANGE, function( event:CollectionEvent ):void
			{
				dispatchEvent( new Event( 'statusColorChanged' ) );
				dispatchEvent( new Event( 'hasUnreadContentChanged' ) );
			});
		}
		
		
		public function setAllContentRead():void
		{
			for each( var chatContent:ChatContent in chatContents )
			{
				chatContent.read = true;
			}
			dispatchEvent( new Event( 'statusColorChanged' ) );
			dispatchEvent( new Event( 'hasUnreadContentChanged' ) );
		}
		
		public function get available():Boolean
		{
			return !( away || dnd ) && type != "unavailable";
		}
		
		public function get away():Boolean
		{
			return show && ( show == "away" || show == "xa" );    
		}
		public function get dnd():Boolean
		{
			return show && ( show == "dnd" );    
		}
		
		[Bindable(event='hasUnreadContentChanged')]
		public function get unreadContents():uint
		{
			var unread:uint = 0;
			for each( var chatContent:ChatContent in chatContents )
			{
				if( chatContent.read == false ) unread++;
			}
			return unread;
		}

		private var _composing:Boolean = false;
		public function set composing( value:Boolean ):void
		{
			_composing = value;
			dispatchEvent( new Event( 'statusColorChanged' ) );
		}
		public function get composing():Boolean
		{
			return _composing;
		}
		
		[Bindable(event='hasUnreadContentChanged')]
		public function get hasUnreadContent():Boolean
		{
			for each( var chatContent:ChatContent in chatContents )
			{
				if( chatContent.read == false ) return true;
			}
			return false;
		}
		
		[Bindable(event='statusColorChanged')]
		public function get statusColor():uint
		{
			if( composing ) return 0xff00ff;
			else if( hasUnreadContent ) return 0x0000ff;
			else if( available ) return 0x00aa00;
			else if( away ) return 0xFF8000;
			else if( dnd ) return 0xff0000;
			return 0xeeeeee
		}
	}
}