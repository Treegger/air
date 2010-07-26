package com.treegger.airim.controller
{
	[Bindable]
	public class Contact
	{
		public var name:String;
		
		public var jid:String;
		
		public var type:String;
		public var status:String;
		public var show:String;
		
		public function get available():Boolean
		{
			return !( away || dnd );
		}
		
		public function get away():Boolean
		{
			return show && ( show.toLocaleLowerCase() == "away" || show.toLocaleLowerCase() == "xa" );    
		}
		public function get dnd():Boolean
		{
			return show && ( show.toLocaleLowerCase() == "dnd" );    
		}
	}
}