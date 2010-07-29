package com.treegger.websocket
{
	import com.treegger.protobuf.WebSocketMessage;
	
	import flash.errors.EOFError;
	import flash.errors.IOError;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.net.SecureSocket;
	import flash.net.Socket;
	import flash.utils.ByteArray;

	public class WSConnector
	{
		private var handshaked:Boolean = false;
		private var socket:Socket;

		public function WSConnector()
		{
		}
		
		public var onMessage:Function;
		public var onHandshake:Function;
						
						
						
		private function decodeBinaryFrame():ByteArray
		{
			var frameSize:uint = 0;
			var lengthFieldSize:uint = 0;
			var b:uint;
			do {
				b = socket.readByte() & 0xff;
				frameSize <<= 7;
				frameSize |= b & 0x7f;
				lengthFieldSize ++;
				if (lengthFieldSize > 8) {
					throw new IOError( "Unexpected lengthFieldSize");
				}
			}
			while( (b & 0x80) == 0x80 );
			
			const buffer:ByteArray = new ByteArray();
			socket.readBytes( buffer, 0, frameSize );
			return buffer;
		}
						
		public function send( message:ByteArray ):void
		{
			if( handshaked )
			{
				socket.writeByte( 0x80 );
				const dataLen:uint = message.length;
				socket.writeByte( (dataLen >>> 28 & 0x7F | 0x80));
				socket.writeByte( (dataLen >>> 14 & 0x7F | 0x80));
				socket.writeByte( (dataLen >>> 7 & 0x7F | 0x80));
				socket.writeByte( (dataLen & 0x7F));
				socket.writeBytes( message );
				socket.flush();
			}
			else
			{
				enqueue( message );
			}
		}

		
		private const messageQueue:Array = [];
		private function enqueue( message:ByteArray ):void
		{
			messageQueue.push( message );
		}
		
		public function close():void
		{
			socket.close();
		}
			
		public function connect( scheme:String, host:String, port:int, path:String ):void
		{
			if( scheme == "wss" )
			{
				socket = new SecureSocket();
				if( port == -1 ) port = 443;
			}
			else
			{
				socket = new Socket();
				if( port == -1 ) port = 80;
			}

			
			
			socket.addEventListener( Event.CONNECT, function ( event:Event ):void
			{
				trace("Connected.");
				const handshake:String = "GET " + path + " HTTP/1.1\r\n" +
				"Upgrade: WebSocket\r\n" +
				"Connection: Upgrade\r\n" +
				"Host: " + host + "\r\n" +
				"Origin: http://" + host     
				+ "\r\n"
				+ "\r\n";
				socket.writeUTFBytes( handshake );
			} );
			
			socket.addEventListener( IOErrorEvent.IO_ERROR, function ( event:Event ):void
			{
				trace("IO Error on socket.");
			} );
			
			socket.addEventListener( ProgressEvent.SOCKET_DATA, function ( event:ProgressEvent ):void
			{
				if( !handshaked )
				{
					const data:String = socket.readUTFBytes( event.bytesLoaded );
					if( data.indexOf("HTTP/1.1 101 Web Socket Protocol Handshake") == 0 )
					{
						trace( "Handshaked." );
						
						handshaked = true;
						
						if( onHandshake != null ) onHandshake();
						
						while( messageQueue.length > 0 )
						{
							send( messageQueue.pop() )
						}
						
					}
				}
				else
				{
					try
					{
						const b:uint = socket.readByte() & 0xff;
						if(b == 0x00) 
						{
							//eventHandler.onMessage(  decodeTextFrame() );
						}
						else if( b == 0x80 )
						{
							const byteArray:ByteArray = decodeBinaryFrame();
							const wsMessage:WebSocketMessage = new WebSocketMessage();
							wsMessage.readExternal( byteArray );
							if( onMessage != null  ) onMessage( wsMessage )
						}
						else
						{
							trace( "Unexpected byte: " + b.toString(16) );
							throw new IOError( "Unexpected byte: " + b.toString(16) );
						}
						
					}
					catch( eofError:EOFError )
					{
						
					}
					catch( ioError:IOError )
					{
						
					}
				}	
			});
			
			
			try
			{
				socket.connect( host, port );				
			}
			catch ( error:Error )
			{
				trace ( error.toString() );
			}
		}
		
	
		
	}
}