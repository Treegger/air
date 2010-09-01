package com.treegger.imonair.view
{
	import com.treegger.component.IOStream;
	import com.treegger.component.StratusConnector;
	import com.treegger.imonair.controller.ChatController;
	import com.treegger.imonair.controller.ChatEvent;
	import com.treegger.imonair.model.Contact;
	
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.TimerEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileStream;
	import flash.net.FileReference;
	import flash.net.NetConnection;
	import flash.net.NetStream;
	import flash.utils.ByteArray;
	import flash.utils.setTimeout;
	
	import mx.controls.Alert;
	import mx.core.UIComponent;
	import mx.events.CloseEvent;
	import mx.events.DynamicEvent;
	
	import org.flexunit.internals.namespaces.classInternal;
	
	import spark.components.Group;
	
	[ResourceBundle("imonair")]
	
	public class P2PFileManager extends UIComponent
	{

		private var _stratusConnector:StratusConnector;
		[Inject]
		public function set stratusConnector(value:StratusConnector):void
		{
			_stratusConnector = value;
			_stratusConnector.addEventListener( "receiveRemoteFile_"+contact.screenname, function( event:DynamicEvent ):void
			{
				receiveRemoteFile( event.data );
			});
			_stratusConnector.addEventListener( "askPermissionRemoteFile_"+contact.screenname, function( event:DynamicEvent ):void
			{
				askPermissionRemoteFile( event.data );
			});
			_stratusConnector.addEventListener( "givePermissionRemoteFile_"+contact.screenname, function( event:DynamicEvent ):void
			{
				givePermissionRemoteFile( event.data );
			});
		}

		
		public var contact:Contact;
		public var currentContact:Contact;
		
		private var file:FileReference;
		
		private var ioStream:IOStream;
		
		
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
			file = FileReference( event.target );
			var that:P2PFileManager = this;
			_stratusConnector.connect( contact, function( contact:Contact, ioStream:IOStream ):void
			{
				that.ioStream = ioStream;
				sendFile();
			});
		}
		
		
		private function completeHandler(event:Event):void
		{
			trace("File load complete: " + file.name );
			
			ioStream.output.send( "remoteCall", { remoteEvent: "receiveRemoteFile_"+currentContact.screenname, remoteObject: { name: file.name, data: file.data } } );
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
			ioStream.output.send( "remoteCall",  { remoteEvent: ChatEvent.STRATUSFILE } );
			setTimeout( remoteCallAskPermission, 500 );
		}
		private function remoteCallAskPermission():void
		{
			ioStream.output.send( "remoteCall", { remoteEvent: "askPermissionRemoteFile_"+currentContact.screenname, remoteObject: { name: file.name } } );
		}
		
		public function askPermissionRemoteFile( remoteObject:Object ):void
		{
			Alert.show( resourceManager.getString('imonair', 'fileTranserAcceptFile', [remoteObject.name]), 
						resourceManager.getString('imonair', 'fileTransferRequest', [contact.name]), 
						Alert.YES|Alert.NO, parent as Sprite, acceptRemoteClickHandler );
			
		}
		
		private function acceptRemoteClickHandler( event:CloseEvent ):void
		{
			if( event.detail == Alert.YES )
			{
				var that:P2PFileManager = this;
				_stratusConnector.connect( contact, function( contact:Contact, ioStream:IOStream ):void
				{
					that.ioStream = ioStream;
					that.ioStream.output.send( "remoteCall", { remoteEvent: "givePermissionRemoteFile_"+currentContact.screenname, remoteObject: {} } );
				});

			}
			else 
			{
				close();
			}
		}

		public function givePermissionRemoteFile( remoteObject:Object ):void
		{
			trace( "Loading file " + file.name );
			file.load();
		}
		
		
		
		public function receiveRemoteFile( remoteObject:Object ):void
		{
			trace( "Receive: " + remoteObject );

			if( remoteObject.name && remoteObject.data ) 
			{
				
				var savefile:File = File.documentsDirectory.resolvePath(remoteObject.name);
				savefile.addEventListener(Event.SELECT, function( event:Event ):void {
					var fs:FileStream = new FileStream();
					fs.open( (event.target as File), "write" );
					fs.writeBytes(remoteObject.data);
					fs.close();
				});
				savefile.browseForSave("Save file");
				
				/*
				var savefile:FileReference = new FileReference();
				savefile.save( remoteObject.data, remoteObject.name );
				*/
			}
			else
			{
				Alert.show( resourceManager.getString('imonair', 'fileTranserFailureDetail'),
							resourceManager.getString('imonair', 'fileTransferFailure', [contact.name]),
							Alert.OK, parent as Sprite );

			}
		}
		
		
		private function close():void
		{
			
		}
		
		
	
		
	}
}