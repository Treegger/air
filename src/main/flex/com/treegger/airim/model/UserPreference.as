package com.treegger.airim.model
{
	[RemoteClass]
	[Bindable]
	public class UserPreference
	{
		public var startAtLogin:Boolean=true;		

		public var applicationX:int;
		public var applicationY:int;
		
		public var chatWindowX:int;
		public var chatWindowY:int;
		public var chatWindowHeight:int;
		public var chatWindowWidth:int;		
		
	}
}