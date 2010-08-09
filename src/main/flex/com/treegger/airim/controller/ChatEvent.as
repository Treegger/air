package com.treegger.airim.controller
{
	import com.netease.protobuf.Message;
	
	import flash.events.Event;
	import com.treegger.airim.model.Contact;

	public class ChatEvent extends Event
	{
		
		
		public static const HANDSHAKED:String = "HANDSHAKED";
		
		public static const AUTHENTICATION:String = "AUTHENTICATION";
		public static const ROSTER:String = "ROSTER";
		
		public static const TEXTMESSAGE:String = "TEXTMESSAGE";
		
		public static const TEXTMESSAGE_COMPOSING:String = "TEXTMESSAGE_COMPOSING";
		public static const TEXTMESSAGE_GONE:String = "TEXTMESSAGE_GONE";
		public static const TEXTMESSAGE_ACTIVE:String = "TEXTMESSAGE_ACTIVE";
		public static const TEXTMESSAGE_INACTIVE:String = "TEXTMESSAGE_INACTIVE";
		public static const TEXTMESSAGE_PAUSED:String = "TEXTMESSAGE_PAUSED";
		
		public static const STRATUSVIDEO:String = "STRATUSVIDEO";
		public static const STRATUSFILE:String = "STRATUSFILE";

		public static const UNREAD_CONTENTS_CHANGE:String = "unreadContentsChanged";

		public var targetContact:Contact;
		
		public function ChatEvent( type:String )
		{
			super( type );
		}
		
	}
}