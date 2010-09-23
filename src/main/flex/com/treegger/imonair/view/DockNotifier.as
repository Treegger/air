package com.treegger.imonair.view
{
	import com.treegger.imonair.controller.PreferencesController;
	
	import flash.desktop.DockIcon;
	import flash.desktop.InteractiveIcon;
	import flash.desktop.NativeApplication;
	import flash.desktop.NotificationType;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.events.ErrorEvent;
	import flash.filters.BevelFilter;
	import flash.filters.DropShadowFilter;
	import flash.media.SoundTransform;
	import flash.text.engine.ElementFormat;
	import flash.text.engine.FontDescription;
	import flash.text.engine.TextBlock;
	import flash.text.engine.TextElement;
	import flash.text.engine.TextLine;
	
	import mx.core.SoundAsset;

	public class DockNotifier
	{
		
		
		[Embed(source="icons/logo-128x128.png")]
		private var ApplicationLogo128:Class;     

		[Embed(source="icons/logo-16x16.png")]
		private var ApplicationLogo16:Class;     
		
		[Embed(source="audio/beep.mp3")]
		private var beepClass:Class;

		private var previousCount:uint = 0;
		
		[Inject]
		public var preferenceController:PreferencesController;
		
		public function DockNotifier()
		{
		}
		
		public function notify( unseenCount:uint, notificationType:String = null ):void
		{
			if( NativeApplication.supportsDockIcon )
			{
				setDockIcon( unseenCount, notificationType );
			}
			else if( NativeApplication.supportsSystemTrayIcon )
			{
				setSystemTrayIcon( unseenCount );
			}
		}
		
		private function playBeep():void
		{
			var beepSound:SoundAsset = SoundAsset( new beepClass() );
			var trans:SoundTransform = new SoundTransform( (preferenceController.userPreference.soundEffectsLevel)/100.0 );
			beepSound.play(0,0,trans);
		}
		
		private function setSystemTrayIcon( unseenCount:uint ):void
		{
			if( previousCount != unseenCount )
			{
				
				previousCount = unseenCount;
				var bitmap:BitmapData = new BitmapData(16, 16, true, 0x00000000);  
				bitmap.draw( (new ApplicationLogo16).bitmapData );
				
				if( unseenCount >  0 )
				{
					playBeep();

					var sprite:Sprite = new Sprite(); 
					sprite.width = 16; 
					sprite.height = 16; 
					sprite.x = 0; 
					sprite.y = 0; 
					
					sprite.graphics.beginFill(0xE92200); 
					sprite.graphics.drawEllipse( 3, 3, 10, 10 ); 
					sprite.graphics.endFill(); 
					
					var bevel:BevelFilter = new BevelFilter(1); 
					sprite.filters = [bevel.clone()];
					
					bitmap.draw( sprite );
				}				
				InteractiveIcon(NativeApplication.nativeApplication.icon).bitmaps = [new Bitmap(bitmap)];
			}				

		}
		private function setDockIcon(unseenCount:uint, notificationType:String = null):void
		{
			if( previousCount != unseenCount )
			{
				previousCount = unseenCount;
				var bitmap:BitmapData = new BitmapData(128, 128, true, 0x00000000);  
				bitmap.draw( (new ApplicationLogo128).bitmapData );
				
				
				if( unseenCount >  0 )
				{
					playBeep();
					
					var sprite:Sprite = new Sprite(); 
					sprite.width = 128; 
					sprite.height = 128; 
					sprite.x = 0; 
					sprite.y = 0; 
					var padding:uint = 16; 
					
					var fontDesc:FontDescription = new FontDescription("Arial", "bold"); 
					var elementFormat:ElementFormat = new ElementFormat(fontDesc, 26, 0xFFFFFF); 
					var textElement:TextElement = new TextElement(String(unseenCount), elementFormat); 
					var textBlock:TextBlock = new TextBlock(textElement); 
					var textLine:TextLine = textBlock.createTextLine(); 
					
					var diameter:uint = padding;
					if( textLine.textWidth < textLine.textHeight ) diameter += textLine.textHeight;  
					else diameter += textLine.textWidth;
					
					textLine.x = 128 - diameter/2 - textLine.textWidth/2 - 4; 
					textLine.y = diameter/2 + textLine.textHeight/2 - 3;
					
					
					sprite.graphics.beginFill(0xE92200); 
					sprite.graphics.drawEllipse( 128 - diameter - 4, 0, diameter, diameter); 
					sprite.graphics.endFill(); 
					sprite.addChild(textLine); 
					var shadow:DropShadowFilter = new DropShadowFilter(3, 45, 0, .75); 
					var bevel:BevelFilter = new BevelFilter(1); 
					sprite.filters = [shadow.clone(),bevel.clone()];
					
					bitmap.draw( sprite );
					
					if( notificationType ) bounce( notificationType );
				}
				
				InteractiveIcon(NativeApplication.nativeApplication.icon).bitmaps = [new Bitmap(bitmap)];
			}
			
		}
		
		public function bounce( notificationType:String = null ):void
		{
			if( NativeApplication.supportsDockIcon )
			{
				var dock:DockIcon = NativeApplication.nativeApplication.icon as DockIcon;
				if( notificationType ) dock.bounce( notificationType );
			}
		}
		
	}
}