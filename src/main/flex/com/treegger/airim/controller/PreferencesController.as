package com.treegger.airim.controller
{
	import com.treegger.airim.model.UserAccount;
	import com.treegger.airim.model.UserPreference;
	import com.treegger.util.FileSerializer;

	public class PreferencesController
	{
		private var _userAccount:UserAccount;

		private var _userPreference:UserPreference;
		
		private static const USER_PREF_FILE:String = "airim.userPreferences";
		private static const USER_ACCOUNT_FILE:String = "airim.userAccount";
		
		public function PreferencesController()
		{
			_userPreference = FileSerializer.readObjectFromFile(USER_PREF_FILE) as UserPreference;
			
			_userAccount = FileSerializer.readObjectFromFile(USER_ACCOUNT_FILE) as UserAccount;
		}
		
		public function get userAccount():UserAccount
		{
			return _userAccount;
		}
		
		public function set userAccount( userAccount:UserAccount ):void
		{
			_userAccount = userAccount;
			FileSerializer.writeObjectToFile( _userAccount, USER_ACCOUNT_FILE);
		}

		public function hasUserPreference():Boolean 
		{
			return _userPreference != null;
		}
		public function get userPreference():UserPreference 
		{
			if( _userPreference == null ) _userPreference = new UserPreference();
			return _userPreference;
		}
		public function set userPreference( userPreference:UserPreference ):void
		{
			_userPreference = userPreference;
			FileSerializer.writeObjectToFile( _userPreference, USER_PREF_FILE);
		}
		
	}
}