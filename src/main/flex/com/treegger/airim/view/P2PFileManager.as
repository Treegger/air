package com.treegger.airim.view
{
	import com.treegger.airim.controller.ChatController;
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
	import flash.utils.ByteArray;
	
	import mx.controls.Alert;
	import mx.events.CloseEvent;
	

	public class P2PFileManager
	{
		
		public var chatController:ChatController;
		public var contact:Contact;
		
		
		private var file:FileReference;

		
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
			startStratus();
		}
		
		
		private function completeHandler(event:Event):void
		{
			trace("completeHandler: " + event);
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
			var fileData:Object = {};
			fileData.file = file.data;
			fileData.name = file.name;
			trace( "Send File "  + file.name );
			ioStream.output.send( "receiveRemoteFile", { name: file.name, data: file.data } );
			trace( "Send Error" );
			file.removeEventListener(Event.COMPLETE, completeHandler);
		}
		public function receiveRemoteFile( remoteObject:Object ):void
		{
			trace( "Recieve: " + remoteObject );
			var savefile:FileReference = new FileReference();
			savefile.save( remoteObject.data, remoteObject.name );
		}
		
		
		private function close():void
		{
			
		}
		
		
		private var netConnection:NetConnection;
		private var ioStream:IOStream;
		private var acceptIncomingRequest:Boolean = false;
	
		private var handshakeCallBack:Function;
		
		private function stratusConnect():void
		{
			trace( "Status Connect" );
			var stratusConnector:StratusConnector = new StratusConnector();
			stratusConnector.addEventListener( StratusConnector.CONNECTION_SUCCESS, function(event:Event):void
			{
				trace( "Status Connected" );
				netConnection = stratusConnector.netConnection;
				chatController.sendTextMessage( contact.jidWithoutRessource, null, ChatController.MESSAGE_TYPE_STRATUS_FILE_REQUEST, netConnection.nearID );
				if( contact.stratusId ) handshake( contact.stratusId );
			});
			stratusConnector.addEventListener( StratusConnector.CONNECTION_CLOSE, function(event:Event):void
			{
				netConnection = null;
				acceptIncomingRequest = false;
				close();
			});				
			stratusConnector.connect();
		}
		
		public function startStratus():void
		{
			trace( "Start Status" );
			handshakeCallBack = sendFile;
			acceptIncomingRequest = true;
			stratusConnect();
		}
		public function requestStratus( alertParentSprite:Sprite ):void
		{
			trace( "Request Status" );
			if( acceptIncomingRequest )
			{
				handshake( contact.stratusId );
			}
			else
			{
				Alert.show( "File Transfer request from "+contact.name, "Accept remote file?", Alert.YES|Alert.NO, alertParentSprite, acceptRemoteClickHandler );
			}
		}
		
		private function acceptRemoteClickHandler( event:CloseEvent ):void
		{
			if( event.detail == Alert.YES )
			{
				acceptIncomingRequest = true;
				stratusConnect();
			}
			else 
			{
				close();
			}
		}
		
		private function handshake( stratusId:String ):void
		{
			trace( "Handshake remoteId " + stratusId + " net " + netConnection  +  " callback: " + handshakeCallBack );
			if( netConnection && stratusId )
			{
				ioStream = new IOStream();
				ioStream.duplexConnect( netConnection, stratusId, IOStream.FILE_STREAM, true );
				
				ioStream.input.client = this;
				
				if( handshakeCallBack != null ) handshakeCallBack();
			}
		}

		
	}
}