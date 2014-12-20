package
{
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.text.TextField;
	import flash.utils.Timer;
	
	public class FPS extends Sprite
	{
		
		private var _fps:Number = 0;
		
		private var _tf:TextField = new TextField();
		private var _timer:Timer = new Timer(1000);
		private var _frame:Number = 0;
		private var _offsetX:int;
		private var _offsetY:int;
		
		
		public function FPS(color:uint = 0xFFFFFF)
		{
			_tf.textColor = color;
			_tf.background = true;
			_tf.backgroundColor = 0x000000;
			_tf.autoSize = "left";
			_tf.mouseEnabled = false;
			_tf.text = "INIT...";
			
			buttonMode = true;
			
			addEventListener(Event.ADDED_TO_STAGE, addStage);
		}
		
		
		private function addStage(e:Event):void
		{
			addEventListener(Event.REMOVED_FROM_STAGE, removedFromStage);
			
			addEventListener(Event.ENTER_FRAME, nPlus);
			
			addEventListener(MouseEvent.MOUSE_DOWN, mouseDown);
			
			_timer.addEventListener(TimerEvent.TIMER, onTimer);
			_timer.start();
			
			addChild(_tf);
		}
		
		
		private function removedFromStage(e:Event):void
		{
			_timer.stop();
			_timer.removeEventListener(TimerEvent.TIMER, onTimer);
			removeEventListener(Event.ENTER_FRAME, nPlus);
			removeEventListener(Event.REMOVED_FROM_STAGE, removedFromStage);
			mouseUp();
		}
		
		
		//==============================================
		//			DRAG AND DROP +
		//==============================================
		private function mouseDown(e:MouseEvent):void
		{
			addEventListener(MouseEvent.MOUSE_UP, mouseUp);
			stage.addEventListener(MouseEvent.MOUSE_MOVE, stage_mouseMove);
			
			_offsetX = mouseX;
			_offsetY = mouseY;
		}
		
		
		private function stage_mouseMove(e:MouseEvent):void
		{
			x = e.stageX - _offsetX;
			y = e.stageY - _offsetY;
		}
		
		
		private function mouseUp(e:MouseEvent=null):void
		{
			stage.removeEventListener(MouseEvent.MOUSE_MOVE, stage_mouseMove);
			removeEventListener(MouseEvent.MOUSE_UP, mouseUp);
		}
		
		
		//==============================================
		//			DRAG AND DROP -
		//==============================================
		
		private function onTimer(e:TimerEvent):void
		{
			_tf.text = "fps:  " + _frame;
			_fps = _frame;
			_frame = 0;
		}
		
		
		private function nPlus(e:Event):void
		{
			_frame++;
		}
		
		
		public function get fps():Number
		{
			return _fps;
		}
	
	}

}