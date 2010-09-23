package com.treegger.component
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.NativeWindow;
	import flash.display.NativeWindowInitOptions;
	import flash.display.NativeWindowSystemChrome;
	import flash.display.NativeWindowType;
	import flash.display.Screen;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	import flash.text.TextFormatAlign;
	import flash.text.engine.ElementFormat;
	import flash.text.engine.FontDescription;
	import flash.text.engine.TextBlock;
	import flash.text.engine.TextElement;
	import flash.text.engine.TextLine;
	import flash.utils.Timer;
	
	import spark.filters.DropShadowFilter;

	public class Notification extends NativeWindow
	{
		private var sprite:Sprite;
		private var closeTimer:Timer;
		private var alphaTimer:Timer;
		
		private var duration:uint;
		
		[Embed(source="icons/logo-48x48.png")]
		private var ApplicationLogo48:Class;     
		
		public function Notification( message:String, subMessage:String = null, duration:uint=3 )
		{
			this.duration = duration;

			var result: NativeWindowInitOptions = new NativeWindowInitOptions();
			result.maximizable = false;
			result.minimizable = false;
			result.resizable = false;
			result.transparent = true;
			result.systemChrome = NativeWindowSystemChrome.NONE;
			result.type = NativeWindowType.LIGHTWEIGHT;
			super(result);
			
			
			
			stage.align = StageAlign.TOP_LEFT;
			stage.scaleMode = StageScaleMode.NO_SCALE;
			
			var padding:int = 10;
			const textLine:TextLine = getTextLine( message, 14, padding );
			textLine.x = padding*2 + 48; 
			textLine.y = textLine.height + padding + padding/2;

			if( subMessage )
			{
				const subTextLine:TextLine = getTextLine( subMessage, 11, padding );
				
				subTextLine.x = padding*2 + 48; 
				subTextLine.y = textLine.height + subTextLine.height + padding*2 + padding/2;

				width = Math.max( textLine.textWidth + padding*3 + 48 , subTextLine.textWidth + padding*3 + 48 );
				height = Math.max( textLine.textHeight + subTextLine.textHeight + padding*3.5, 48+padding*2 );
				getSprite().addChild(subTextLine);
					
			}
			else
			{
				width = textLine.textWidth + padding*3 + 48;
				height = Math.max( textLine.textHeight + padding*2.5, 48+padding*2 );
			}
			getSprite().addChild(textLine);
			
			
			var bitmap:BitmapData = new BitmapData( 48, 48, true, 0x00000000);  
			bitmap.draw( (new ApplicationLogo48).bitmapData );
			const bmp:Bitmap = new Bitmap( bitmap );
			bmp.y = padding;
			bmp.x = padding;
			getSprite().addChild(bmp);

			var screen:Screen = Screen.mainScreen;
			bounds = new Rectangle(screen.visibleBounds.width - width - 2, screen.visibleBounds.y + 2, width, height );
			alwaysInFront = true;
			visible = true;
			
		}

		private function getTextLine( str:String, fontSize:int, padding:int ):TextLine
		{
			var fontDesc:FontDescription = new FontDescription("Arial", "normal"); 
			var elementFormat:ElementFormat = new ElementFormat(fontDesc, fontSize, 0xFFFFFF); 
			var textElement:TextElement = new TextElement( str, elementFormat ); 
			var textBlock:TextBlock = new TextBlock(textElement); 
			var textLine:TextLine = textBlock.createTextLine(); 
			
			var shadow:DropShadowFilter = new DropShadowFilter(3, 45, 0, .75); 
			textLine.filters = [shadow.clone()];
			
			return textLine;
		}
		
		protected function getSprite(): Sprite
		{
			if (sprite == null)
			{
				sprite = new Sprite();
				sprite.alpha = 0;
				sprite.graphics.beginFill(0x333333);
				sprite.graphics.drawRoundRect(0, 0, this.width, this.height, 20, 20);
				sprite.graphics.endFill();
				sprite.addEventListener(MouseEvent.CLICK, this.notificationClick);
				stage.addChild(sprite);
			}
			return sprite;
		}
		
		
		override public function set visible( value:Boolean ):void
		{
			super.visible = value;
			if (value == true)
			{
				this.alphaTimer = new Timer(3);
				var listener:Function = function (e:TimerEvent):void
				{
					alphaTimer.stop();
					var nAlpha:Number = getSprite().alpha;
					nAlpha = nAlpha + .01;
					getSprite().alpha = nAlpha;
					if (getSprite().alpha < .8)
					{
						alphaTimer.start();
					}
					else
					{
						alphaTimer.removeEventListener(TimerEvent.TIMER, listener);
						startClose();
					}
				};
				this.alphaTimer.addEventListener(TimerEvent.TIMER, listener);
				this.alphaTimer.start();
			}
		}
		private function startClose():void
		{
			this.closeTimer = new Timer(duration * 1000);
			var listener:Function = function(e:TimerEvent):void
			{
				closeTimer.removeEventListener(TimerEvent.TIMER, listener);
				close();
			};
			this.closeTimer.addEventListener(TimerEvent.TIMER, listener); 
			this.closeTimer.start();
		}
		
		private function closeWindow():void
		{
			super.close();
		}
		override public function close(): void
		{
			if (this.closeTimer != null)
			{
				this.closeTimer.stop();
				this.closeTimer = null;
			}
			
			if (this.alphaTimer != null)
			{
				this.alphaTimer.stop();
				this.alphaTimer = null;
			}
			
			const that:Notification = this;
			this.alphaTimer = new Timer(25);
			var listener:Function = function (e:TimerEvent):void
			{
				alphaTimer.stop();
				var nAlpha:Number = getSprite().alpha;
				nAlpha = nAlpha - .01;
				getSprite().alpha = nAlpha;
				if (getSprite().alpha <= 0)
				{
					alphaTimer.removeEventListener(TimerEvent.TIMER, listener);
					closeWindow();
				}
				else 
				{
					alphaTimer.start();
				}
			};
			this.alphaTimer.addEventListener(TimerEvent.TIMER, listener);
			this.alphaTimer.start();
		}

		
		private function notificationClick(event:MouseEvent):void
		{
			var sprite:Sprite = event.currentTarget as Sprite;
			sprite.removeEventListener(MouseEvent.CLICK, this.notificationClick);
			//this.dispatchEvent( new NotificationClickedEvent() );
			this.close();
		}
	}
}