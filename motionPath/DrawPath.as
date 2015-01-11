package AS3.motionPath {
	import adobe.utils.CustomActions;
	import AS3.SMath;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.display.Stage;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	
	/**
	 * ...
	 * @author samana
	 * Вспомогательный класс для рисование пути.
	 * Рисует путь из точек, плавность рисования пути можно регулировать свойством lazyDist.
	 * Каждое новое рисование, отчищает все предыдущие данные (массив точек).
	 * 
	 * Как использовать:
		 * Добавить экземпляр данного класса в дисплейЛист.
		 * Подписать его на событие PATH_END_DRAW, которое всплывёт после завершения рисования.
		 * Вызвать метод startDraw (передав stage в параметре). Теперь при нажатии и движении мыши будет рисоваться путь.
		 * После события PATH_END_DRAW можно получить массив точек через геттер points и удалить экземпляр, если он больше не нужен.
		 * Либо получить строку для инициалицации массива с точками методом traceVectorPoints, чтобы сохранить результат.
	 */
	public class DrawPath extends Sprite
	{
		static public const PATH_END_DRAW:String = "pathEndDraw";	//событие при завершении рисования, когда mouseUp
		
		private var _points:Vector.<Point>;			//массив с точками
		private var _flowPoint:Point;				//плавающая точка при рисовании
		private var _lazyDist:int = 90;				//расстояние между плавающей точкой и курсором
		private var _distBetweenPoints:int = 20;	//расстояние между точками
		private var _stageRef:Stage;				//ссылка на сцену, нужна при рисовании
		
		private var _lazyLine:Shape;				//шейп в котором рисуется lazyLine
		
		public function DrawPath()
		{
			super();
			_points = new <Point>[];
			_flowPoint = new Point();
			_lazyLine = new Shape();
			
			addChild(_lazyLine);
			
			addEventListener(Event.REMOVED_FROM_STAGE, removedFromStage);
		}
		
		private function removedFromStage(e:Event):void 
		{
			removeEventListener(Event.REMOVED_FROM_STAGE, removedFromStage);
			removeEventListener(Event.ENTER_FRAME, stageRef_enterFrame);
			_stageRef.removeEventListener(MouseEvent.MOUSE_UP, _stageRef_mouseUp);
		}
		
		
		/**
		 * Начать рисование. Должна быть доступна stage.
		 */
		public function startDraw(stage:Stage):void
		{
			_stageRef = stage;
			if (_stageRef)
			{
				_points.length = 0;
				
				addEventListener(Event.ENTER_FRAME, stageRef_enterFrame);
				_stageRef.addEventListener(MouseEvent.MOUSE_UP, _stageRef_mouseUp);
				
				_flowPoint.x = mouseX;
				_flowPoint.y = mouseY;
				_flowPoint.x = Number(_flowPoint.x.toFixed(1));
				_flowPoint.y = Number(_flowPoint.y.toFixed(1));
				
				graphics.clear();
				drawCircle(_flowPoint.x, _flowPoint.y);
				
				_points[0] = new Point(_flowPoint.x, _flowPoint.y);
			}
		}
		
		
		/**
		 * Завершение рисование
		 * @param	e
		 */
		private function _stageRef_mouseUp(e:MouseEvent):void
		{
			removeEventListener(Event.ENTER_FRAME, stageRef_enterFrame);
			_stageRef.removeEventListener(MouseEvent.MOUSE_UP, _stageRef_mouseUp);
			
			_lazyLine.graphics.clear();
			
			dispatchEvent(new Event(PATH_END_DRAW));
		}
		
		/**
		 * Процесс рисования
		 * @param	e
		 */
		private function stageRef_enterFrame(e:Event):void
		{
			
			if (SMath.dist(_flowPoint.x,_flowPoint.y,mouseX,mouseY) > _lazyDist) 
			{
				var ang:Number = SMath.angTo(_flowPoint.x, _flowPoint.y, mouseX, mouseY);
				_flowPoint.x += Math.cos(ang) * _distBetweenPoints;
				_flowPoint.y += Math.sin(ang) * _distBetweenPoints;
				
				_flowPoint.x = Number(_flowPoint.x.toFixed(1));
				_flowPoint.y = Number(_flowPoint.y.toFixed(1));
				
				drawCircle(_flowPoint.x, _flowPoint.y);
				
				_points.push(new Point(_flowPoint.x, _flowPoint.y));
			}
			
			drawLazyLine(_flowPoint.x, _flowPoint.y, mouseX, mouseY);
		}
		
		
		/**
		 * Рисует контрастный круг
		 * @param	x
		 * @param	y
		 */
		private function drawCircle(x:Number,y:Number):void 
		{
			graphics.lineStyle(0, 0xD8FD02);
			graphics.beginFill(0x3276A3)
			graphics.drawCircle(x, y, 2);
			graphics.endFill();
			graphics.lineStyle();
		}
		
		
		/**
		 * Рисует линию
		 * @param	fromX
		 * @param	fromY
		 * @param	toX
		 * @param	toY
		 */
		private function drawLazyLine(fromX:Number,fromY:Number,toX:Number,toY:Number):void 
		{
			with (_lazyLine) 
			{
				graphics.clear();
				graphics.lineStyle(1, 0xFF80FF);
				graphics.moveTo(fromX, fromY);
				graphics.lineTo(toX, toY);
				graphics.lineStyle();
			}
		}
		
		
		//==============================================
		//				PUBLIC
		//==============================================
		/**
		 * Формирует и возвращает строку для создания вектора с созданными точками.
		 * В виде new <Point>[new Pont(1,5),new Point(8,3)...]
		 * @return
		 */
		public function traceVectorPoints():String 
		{
			if (_points.length<2) 
			{
				trace("[DrawPath][traceVectorPoints] Ошибка! Точек меньше двух");
				return "";
			}
			
			var pointsInString:String = "new <Point>[";
			for (var i:int = 0; i < _points.length; i++) 
			{
				pointsInString+="new Point(" + points[i].x + "," +_points[i].y + "),"
			}
			pointsInString=pointsInString.substr(0, -1); //убираю последнюю запятую
			pointsInString += "];"
			
			return pointsInString
		}
		
		//==============================================
		//				GETTERS
		//==============================================
		/**
		 * Массив с точками пути
		 */
		public function get points():Vector.<Point>
		{
			return _points;
		}
		
		/**
		 * расстояние между курсором и плавающей точкой
		 */
		public function get lazyDist():int 
		{
			return _lazyDist;
		}
		
		public function set lazyDist(value:int):void 
		{
			_lazyDist = value;
		}
		
		/**
		 * расстояние между точками, плотность пути
		 */
		public function get distBetweenPoints():int 
		{
			return _distBetweenPoints;
		}
		
		public function set distBetweenPoints(value:int):void 
		{
			_distBetweenPoints = value;
		}
	
	}

}