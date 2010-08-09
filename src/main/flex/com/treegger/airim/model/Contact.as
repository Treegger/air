package com.treegger.airim.model
{
	import flash.events.EventDispatcher;
	
	import mx.collections.ArrayCollection;
	import mx.events.CollectionEvent;

	[Bindable]
	public class Contact extends EventDispatcher
	{
		public var name:String;
		public var nickname:String;
		
		public var jidWithoutRessource:String;
		
		
		public var type:String;
		
		public var _status:String;
		public function set status( value:String ):void
		{
			_status = value;
			dispatchEvent( new Event( 'statusColorChanged' ) );
		}
		public function get status():String
		{
			return _status;
		}
		
		
		private var _show:String;
		public function set show( value:String ):void
		{
			_show = value;
			dispatchEvent( new Event( 'statusColorChanged' ) );
		}
		public function get show():String
		{
			return _show;
		}
		
		public var vCardFetched:Boolean;
		public var photoURL:String;
		
		public var stratusId:String;
		
		[ArrayElementType("ChatContent")]
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
			return !( away || dnd );
		}
		
		public function get away():Boolean
		{
			return _show && ( _show.toLocaleLowerCase() == "away" || _show.toLocaleLowerCase() == "xa" );    
		}
		public function get dnd():Boolean
		{
			return _show && ( _show.toLocaleLowerCase() == "dnd" );    
		}
		
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