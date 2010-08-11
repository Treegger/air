package com.treegger.airim.view
{
	import com.treegger.airim.controller.ChatController;
	import com.treegger.airim.controller.ChatEvent;
	import com.treegger.airim.model.Contact;
	import com.treegger.component.IOStream;
	import com.treegger.component.StratusConnector;
	
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.TimerEvent;
	import flash.net.FileReference;
	import flash.net.NetConnection;
	import flash.net.NetStream;
	import flash.utils.ByteArray;
	
	import mx.controls.Alert;
	import mx.core.UIComponent;
	import mx.events.CloseEvent;
	import mx.events.DynamicEvent;
	
	import org.flexunit.internals.namespaces.classInternal;
	
	import spark.components.Group;
	

	public class P2PFileManager extends UIComponent
	{

		private var _stratusConnector:StratusConnector;
		[Inject]
		public function set stratusConnector(value:StratusConnector):void
		{
			_stratusConnector = value;
			_stratusConnector.addEventListener( "receiveRemoteFile", function( event:DynamicEvent ):void
			{
				receiveRemoteFile( event.data );
			});
			
		}

		
		public var contact:Contact;
		
		private var file:FileReference;
		
		private var ioStream:IOStream = ioStream = new IOStream();
		
		
		public function selectFile():void
		{
			// Creating a new FileReference to start choosing your file
			file = new FileReference;
			
			// Adding eventListeners
			file.addEventListener(Event.SELECT, selectHandler);
			file.addEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
			file.addEventListener(ProgressEvent.PROGRESS, progressHandler);
			file.addEventListener( Event.COMPLETE, completeHandler);
			file.browse();
		}
		
		private function selectHandler( event:Event ):void
		{
			var that:P2PFileManager = this;
			file = FileReference( event.target );
			_stratusConnector.connect( contact, function( contact:Contact, ioStream:IOStream ):void
			{
				that.ioStream = ioStream;
				sendFile();
			});
		}
		
		
		private function completeHandler(event:Event):void
		{
			trace("completeHandler: " + event);
			
			ioStream.output.send( "remoteCall", { remoteEvent: ChatEvent.STRATUSFILE } );
			
			ioStream.output.send( "remoteCall", { remoteEvent: "receiveRemoteFile", remoteObject: { name: file.name, data: file.data } } );
		}
		private function ioErrorHandler(event:IOErrorEvent):void
		{
			trace("ioErrorHandler: " + event);
		}
		
		private function progressHandler(event:ProgressEvent):void
		{
		}
		
		private function sendFile():void
		{
			file.load();
		}
		public function receiveRemoteFile( remoteObject:Object ):void
		{
			trace( "Recieve: " + remoteObject );
			if( remoteObject.name && remoteObject.data ) 
			{
				var savefile:FileReference = new FileReference();
				savefile.save( remoteObject.data, remoteObject.name );
			}
			else
			{
				Alert.show( "File Transfer failure from "+contact.name, "Error", Alert.OK, parent.parent as Sprite );

			}
		}
		
		
		private function close():void
		{
			
		}
		
	
		
		/*
		public function requestStratus():void
		{
			Alert.show( "File Transfer request from "+contact.name, "Accept remote file?", Alert.YES|Alert.NO, parent.parent as Sprite, acceptRemoteClickHandler );
		}
		
		private function acceptRemoteClickHandler( event:CloseEvent ):void
		{
			if( event.detail == Alert.YES )
			{
				stratusConnect();
			}
			else 
			{
				close();
			}
		}
		*/

		
	}
}