package com.treegger.airim.controller
{
	import flash.events.EventDispatcher;
	
	import mx.collections.ArrayCollection;

	[Bindable]
	public class Contact extends EventDispatcher
	{
		public var name:String;
		
		public var jid:String;
		
		public var type:String;
		public var status:String;
		
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
		
		
		public var textMessages:ArrayCollection = new ArrayCollection();
		
		public var stratusId:String;
		
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
		
		[Bindable(event='statusColorChanged')]
		public function get statusColor():uint
		{
			if( available ) return 0x00aa00;
			else if( away ) return 0xFF8000;
			else if( dnd ) return 0xff0000;
			return 0xeeeeee
		}
	}
}