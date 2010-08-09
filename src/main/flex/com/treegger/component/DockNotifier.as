package com.treegger.component
{
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
	import flash.text.engine.ElementFormat;
	import flash.text.engine.FontDescription;
	import flash.text.engine.TextBlock;
	import flash.text.engine.TextElement;
	import flash.text.engine.TextLine;

	public class DockNotifier
	{
		
		
		[Embed(source="icons/logo-128x128.png")]
		[Bindable]
		private var ApplicationLogo128:Class;     
		
		private var previousCount:uint = 0;
		
		public function DockNotifier()
		{
		}
		
		public function notify( unseenCount:uint, notificationType:String = null ):void
		{
			if( NativeApplication.supportsDockIcon )
			{
				if( previousCount != unseenCount )
				{
					previousCount = unseenCount;
					var bitmap:BitmapData = new BitmapData(128, 128, true, 0x00000000);  
					bitmap.draw( (new ApplicationLogo128).bitmapData );
					
	
					if( unseenCount >  0 )
					{
						var unreadCountSprite:Sprite = new Sprite(); 
						unreadCountSprite.width = 128; 
						unreadCountSprite.height = 128; 
						unreadCountSprite.x = 0; 
						unreadCountSprite.y = 0; 
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
						
						
						unreadCountSprite.graphics.beginFill(0xE92200); 
						unreadCountSprite.graphics.drawEllipse( 128 - diameter - 4, 0, diameter, diameter); 
						unreadCountSprite.graphics.endFill(); 
						unreadCountSprite.addChild(textLine); 
						var shadow:DropShadowFilter = new DropShadowFilter(3, 45, 0, .75); 
						var bevel:BevelFilter = new BevelFilter(1); 
						unreadCountSprite.filters = [shadow.clone(),bevel.clone()];
						
						bitmap.draw( unreadCountSprite );
						
						bounce( notificationType );
					}
					
					var appIcon:Bitmap = new Bitmap(bitmap); 
					// If you do want to change the system tray icon on Windows, as well, add a 16x16 icon to the array below. 
					InteractiveIcon(NativeApplication.nativeApplication.icon).bitmaps = [appIcon];
				}				
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