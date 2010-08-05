package com.treegger.airim.controller
{
	import com.netease.protobuf.Message;
	
	import flash.events.Event;
	import com.treegger.airim.model.Contact;

	public class ChatEvent extends Event
	{
		public static const AUTHENTICATION:String = "AUTHENTICATION";
		public static const ROSTER:String = "ROSTER";
		public static const TEXTMESSAGE:String = "TEXTMESSAGE";
		public static const STRATUSVIDEO:String = "STRATUSVIDEO";

		public static const UNREAD_CONTENTS_CHANGE:String = "unreadContentsChanged";

		public var targetContact:Contact;
		
		public function ChatEvent( type:String )
		{
			super( type );
		}
		
	}
}