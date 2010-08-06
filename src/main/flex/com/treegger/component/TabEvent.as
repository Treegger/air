package com.treegger.component
{
	import flash.events.Event;

	public class TabEvent extends Event
	{
		public var data:Object;
		public var dropText:String;
		public function TabEvent( name:String, bubble:Boolean, data:Object, dropText:String = null )
		{
			super( name, bubble );
			this.data = data;
			this.dropText = dropText;
		}
	}
}