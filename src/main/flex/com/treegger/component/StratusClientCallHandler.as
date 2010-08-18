package com.treegger.component
{

	import com.treegger.component.StratusConnector;
	import com.treegger.imonair.model.Contact;
	
	import mx.events.DynamicEvent;
	
	public class StratusClientCallHandler
	{
		private var contact:Contact;
		private var stratusConnector:StratusConnector;
	
		public function StratusClientCallHandler( stratusConnector:StratusConnector, contact:Contact )
		{
			this.stratusConnector = stratusConnector;
			this.contact = contact;
		}
		
		public function remoteCall( data:Object ):void
		{
			trace( "Remote called " + data.remoteEvent +" / " + data.remoteObject );
			const e:DynamicEvent = new DynamicEvent( data.remoteEvent );
			e.data = data.remoteObject;
			e.contact = contact;
			
			stratusConnector.dispatchEvent( e );
		}
	}
}