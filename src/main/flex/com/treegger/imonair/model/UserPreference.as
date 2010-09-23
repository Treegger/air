package com.treegger.imonair.model
{
	[RemoteClass]
	[Bindable]
	public class UserPreference
	{
		public var startAtLogin:Boolean=true;
		public var soundEffectsLevel:Number=50;

		public var applicationX:int;
		public var applicationY:int;
		
		public var chatWindowX:int;
		public var chatWindowY:int;
		public var chatWindowHeight:int;
		public var chatWindowWidth:int;		
		
	}
}