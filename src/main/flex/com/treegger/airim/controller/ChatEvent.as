package com.treegger.airim.controller
{
	import com.netease.protobuf.Message;
	
	import flash.events.Event;

	public class ChatEvent extends Event
	{
		public static const AUTHENTICATION:String = "AUTHENTICATION";
		public static const ROSTER:String = "ROSTER";
		public static const TEXTMESSAGE:String = "TEXTMESSAGE";

		public var targetContact:Contact;
		
		public function ChatEvent( type:String )
		{
			super( type );
		}
		
	}
}