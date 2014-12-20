package AS3
{
	import flash.display.DisplayObject;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.getTimer;
	
	/**
	 * Простой триггер.
	 * Задаётся прямоугольная область для триггера, которую можно проверить на пересечение с
	 * точкой либо прямоугольником.
	 * При успешном касании триггера - выполняется переданный метод.
	 * Можно включать и отключать триггер, так же выключать его автоматически после срабатывания.
	 *
	 * @update 23.11.2014 13:42
	 * Добавлена возможность узнать с какой стороны произошла активация/декктивация, слева либо справа.
	 * И назначить методы на эти моменты.
	 * Это удобно, если в игре требуется разное повередие объекта в зависимости от того, с какой стороны к нему прикоснулись.
	 *
	 * @update 01.12.14
	 * Триггер переводится в глобальные координаты, поэтому вне зависимости от вложенности триггеров по разным объектам,
	 * пересечение с точкой всегда будет корректным.
	 *
	 * При создании триггера нужно "привязать" его к объекту, чтобы установить в каком пространстве находится триггер.
	 * И если объекты будут двигаться, то триггер автоматически будет следовать. Повороты объекта не учитываются.
	 *
	 * При проверке триггера с точкой так же нужно указать объект, относительно которого взяты эти точки.
	 * 
	 * @update 19.12.2014 15:48
	 * Все коллбеки заменены с простой Function на CallbackList.
	 *
	 * @author samana
	 */
	public class SimpleTrigger
	{
		//статический массив со всеми триррегами
		private static var allTriggers:Vector.<SimpleTrigger> = new Vector.<SimpleTrigger>();
		private static var _debugGlobalPoint:Point = new Point();
	
		private var _isAction:Boolean; // тригг активирован, находятся в его пределах
		
		// координаты предыдущей проверки, для вычисления направления касания
		private var _tempX:int = 0;
		private var _tempY:int = 0;
		private var _dir:int = 0; // <0 = right,  >0 = left
		
		private var _on:Boolean = true; // вкл/выкл триггер
		
		
		//----------------------       PUBLIC PROPS
		
		//          CALLBACKs
		// метод срабатывает при любой активации
		public var onCallback:CallbackList = new CallbackList(this);
		
		// метод срабатывает при любой деактивации
		public var offCallback:CallbackList = new CallbackList(this);
		
		// методы срабатывают при активации/деактивации слева/справа
		public var onRightCallback:CallbackList = new CallbackList(this);
		public var onLeftCallback:CallbackList = new CallbackList(this);
		
		public var offRightCallback:CallbackList = new CallbackList(this);
		public var offLeftCallback:CallbackList = new CallbackList(this);
		
		public var autoOff:Boolean = false;
		
		public var x:Number = 0;
		public var y:Number = 0;
		public var width:Number = 0;
		public var height:Number = 0;
		
		public var parent:DisplayObject;
		
		
		public function SimpleTrigger()
		{
			//добавить триггер в статический массив, если его там ещё нет
			if (allTriggers.indexOf(this) == -1)
				allTriggers.push(this);
			
			_isAction = false;
		
		}
		
		
		//==============================================
		//			PUBLIC METHODS
		//==============================================
		
		/**
		 * назначить прямоугольную область для тригга
		 * @param	rect - прямоугольная область
		 */
		public function setTriggRect(rect:Rectangle, parent:DisplayObject, autoOff:Boolean = false):void
		{
			x = rect.x;
			y = rect.y;
			width = rect.width;
			height = rect.height;
			
			this.parent = parent;
			
			this.autoOff = autoOff;
		
		}
		
		
		/**
		 * Показать триггеры. Для отладки. Работает медленно.
		 * @param	sprite Спрайт который будет служить контейнером для графики.
		 */
		public static function updateDebug(sprite:Sprite):void
		{
			
			sprite.removeChildren();
			for (var i:int = 0; i < allTriggers.length; i++)
			{
				var trigg:SimpleTrigger = allTriggers[i];
				var color:uint;
				switch (trigg.getState())
				{
					case "isAction": // красный
						color = 0xFF0080
						break;
					
					case "on": //голубой
						color = 0x92C2E2
						break;
					
					case "off": //серый
						color = 0xC0C0C0
						break;
					default: 
				}
				
				var s:Shape = new Shape();
				var projPoint:Point = sprite.globalToLocal(trigg.parent.localToGlobal(new Point(trigg.x, trigg.y)));
				s.x = projPoint.x;
				s.y = projPoint.y;
				
				s.graphics.lineStyle(1, color);
				s.graphics.drawRect(0, 0, trigg.width, trigg.height);
				
				sprite.addChild(s);
			}
			
			var p:Shape = new Shape();
			p.graphics.beginFill(0x00FF00);
			p.graphics.drawCircle(0, 0, 3);
			
			var debugLocalPoint:Point = sprite.globalToLocal(_debugGlobalPoint)
			p.x = debugLocalPoint.x;
			p.y = debugLocalPoint.y;
			
			sprite.addChild(p);
		}
		
		
		/**
		 * Проверить все триггеры на столкновение с заданной точкой.
		 * @param	px Координата по икс
		 * @param	py Координата по игрек
		 */
		public static function updateAllTriggs(px:Number, py:Number, objSpace:DisplayObject):void
		{
			var trigg:SimpleTrigger;
			var globalObjectPoint:Point = objSpace.localToGlobal(new Point(px, py));
			var projRect:Rectangle = new Rectangle();
			
			_debugGlobalPoint.setTo(globalObjectPoint.x, globalObjectPoint.y);
			
			for (var i:int = 0; i < allTriggers.length; i++)
			{
				trigg = allTriggers[i];
				if (trigg._on)
				{
					//если триггер и искомая точка находятся в разный пространствах (разные родители)
					//то координаты триггера надо перевести в глобальные
					if (trigg.parent != objSpace || trigg.parent.rotation != 0)
					{
						//перевожу координаты триггера в глобальные
						var triggGlobalPoint:Point = trigg.parent.localToGlobal(new Point(trigg.x, trigg.y));
						projRect.x = triggGlobalPoint.x;
						projRect.y = triggGlobalPoint.y;
					}
					else
					{
						//иначе просто сумирую координаты триггера и его родителя
						projRect.x = trigg.x + trigg.parent.x;
						projRect.y = trigg.y + trigg.parent.y;
					}
					
					projRect.width = trigg.width;
					projRect.height = trigg.height;
					
					//узнаю с какой стороны было касание
					//trigg._dir = globalObjectPoint.x - trigg._tempX;
					//trigg._tempX = globalObjectPoint.x;
					
					trigg._dir = px - trigg._tempX;
					trigg._tempX = px;
					
					//если было касание
					if (projRect.contains(globalObjectPoint.x, globalObjectPoint.y))
					{
						//выполнить колбеки 
						trigg.checkCallbacks(true);
						if (trigg.autoOff)
						{
							trigg._on = false;
						}
						
					}
					else
					{
						//если касания небыло/не стало, выполнить колбеки
						trigg.checkCallbacks(false);
					}
				}
				
			}
		
		}
		
		
		/**
		 * Удаляет все триггеры
		 */
		public static function destroyAll():void
		{
			allTriggers = new Vector.<SimpleTrigger>();
		}
		
		
		/**
		 * Проверить конкретный тригг с точкой
		 * @param	px - позиция точки по икс
		 * @param	py - позиция точки по игрек
		 * @param 	objSpace из какого локального пространства взять указанную точку
		 * @param	autoOff - автовыключение тригга после его срабатывания, по-умолчанию отключено
		 */
		public function checkTriggPoint(px:int, py:int, objSpace:DisplayObject, autoOff:Boolean = false):void
		{
			if (_on)
			{
				//перевожу координаты точки в глобальные 
				var globalObjectPoint:Point = objSpace.localToGlobal(new Point(px, py));
				
				_debugGlobalPoint.setTo(globalObjectPoint.x, globalObjectPoint.y);
				
				var projRect:Rectangle = new Rectangle();
				if (parent != objSpace || parent.rotation != 0)
				{
					//перевожу координаты триггера в глобальные
					var triggGlobalPoint:Point = parent.localToGlobal(new Point(x, y));
					projRect.x = triggGlobalPoint.x;
					projRect.y = triggGlobalPoint.y;
				}
				else
				{
					projRect.x = x + parent.x;
					projRect.y = y + parent.y;
				}
				
				projRect.width = width;
				projRect.height = height;
				
				//узнаю с какой стороны было касание
				//_dir = globalObjectPoint.x - _tempX;
				//_tempX = globalObjectPoint.x;
				_dir = px - _tempX;
				_tempX = px;
				
				//если было касание
				if (projRect.contains(globalObjectPoint.x, globalObjectPoint.y))
				{
					//выполнить колбеки 
					checkCallbacks(true);
					if (autoOff)
					{
						_on = false;
					}
					
				}
				else
				{
					//если касания небыло/не стало, выполнить колбеки
					checkCallbacks(false);
				}
				
			}
		
		}
		
		
		/**
		 * Проверить тригг с прямоугольной областью
		 * @param	rect - прямоугольник который нужно проверить
		 * @param	autoOff - автовыключение тригга после его срабатывания, по-умолчанию отключено
		 */
		//public function checkTriggRect(rect:Rectangle, autoOff:Boolean = false):void
		//{
			//if (on)
			//{
				////узнаю с какой стороны было касание
				//_dir = rect.x - _tempX;
				//_tempX = rect.x;
				//
				//if (checkTrigg(_rectTrigg.intersects(rect)) == true)
				//{
					//if (autoOff)
						//on = false;
				//}
			//}
		//}
		
		
		/**
		 * Удаляет триггер из общего массива
		 */
		public function destroy():void
		{
			var ind:int = allTriggers.indexOf(this)
			if (ind != -1)
			{
				allTriggers.splice(ind, 1);
				off();
			}
		}
		
		
		//==============================================
		//			PRIVATE METHODS
		//==============================================
		private function getState():String
		{
			if (_isAction == true && _on == true)
				return "isAction";
			
			if (_isAction == false && _on == true)
				return "on";
			
			return "off";
		}
		
		
		/**
		 * Выполнить действие назначенное триггу, если было касание извне,
		 * либо если касание прекратилось.
		 * @param	hit - результат касания прямоугольной области тригга
		 * @return 	true/false - результат срабатывания тригга
		 */
		private function checkCallbacks(hit:Boolean):Boolean
		{
			// произошло касание
			if (hit && _isAction == false)
			{
				_isAction = true;
				
				// on call
				onCallback.applyAll(this);
				
				//right on
				if (_dir < 0)
					onRightCallback.applyAll(this)
				
				//left on
				if (_dir > 0)
					onLeftCallback.applyAll(this);
				
				return true;
			}
			
			// отсутствие касания (перестали находиться в области триггера)
			if (!hit && _isAction)
			{
				_isAction = false;
				
				// off call
				offCallback.applyAll(this);
				
				//off right
				if (_dir > 0)
					offRightCallback.applyAll(this);
				
				//off left
				if (_dir < 0)
					offLeftCallback.applyAll(this);
				
			}
			
			return false;
		}
		
		
		//==============================================
		//			PUBLIC
		//==============================================
		public function on():void
		{
			_on = true;
		}
		
		
		public function off():void
		{
			_on = false;
			_isAction = false;
		}
		
		
		//==============================================
		//			GETTERS
		//==============================================
		/**
		 * Узнать находится ли триггер в активном состоянии.
		 * Находится ли точка в его пределах когда он включен.
		 */
		public function get isAction():Boolean
		{
			return _isAction;
		}
	
	}

}