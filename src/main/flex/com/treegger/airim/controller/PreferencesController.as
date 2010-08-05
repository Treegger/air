package com.treegger.airim.controller
{
	import com.treegger.util.FileSerializer;
	import com.treegger.airim.model.UserAccount;

	public class PreferencesController
	{
		private var _userAccount:UserAccount;

		public function PreferencesController()
		{
			_userAccount = FileSerializer.readObjectFromFile("airim.preferences") as UserAccount;
		}
		
		public function get userAccount():UserAccount
		{
			return _userAccount;
		}
		
		public function set userAccount( userAccount:UserAccount ):void
		{
			_userAccount = userAccount;
			FileSerializer.writeObjectToFile( _userAccount, "airim.preferences");
		}

		
	}
}