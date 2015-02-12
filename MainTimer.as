package AS3
{
	import flash.display.Shape;
	import flash.events.Event;
	
	/**
	 * ...
	 * @author samana
	 * enterFrame для группы объектов.
	 * Поэтому можно ставить на паузу всё сразу.
	 * Обычно создаётся static public экземпляр данного класса в Main классе
	 * и все объекты вместо нативного enterFrame подписываются сюда с помощью Main.mainTimer.add(obj.function)
	 */
	public class MainTimer
	{
		private var _timerShape:Shape;
		private var _functions:Vector.<Function>;			//основной, меняющийся список функций
		private var _len:int = 0;
		private var _isOn:Boolean = false;
		
		private var _functionsFreeze:Vector.<Function>;		//списом методов на данный кадр
		private var _changed:Boolean = false;				//происходили подписки или отписки в основмном массиве
		
		public function MainTimer()
		{
			_timerShape = new Shape();
				
			_functions = new Vector.<Function>();
			_functionsFreeze = new Vector.<Function>();
		}
		
		
		//==============================================
		//				PUBLIC
		//==============================================
		
		/**
		 * Добавить функцию для выполнение в enterFrame
		 * @param	f функция
		 */
		public function add(f:Function):void
		{
			if (_functions.indexOf(f) == -1)
			{
				_functions.push(f);
				_len = _functions.length;
				_changed = true;
			}
		}
		
		
		/**
		 * Удалить функцию из выполнения в enterFrame
		 * @param	f функция
		 */
		public function remove(f:Function):void
		{
			var ind:int = _functions.indexOf(f);
			if (ind != -1)
			{
				_functions.splice(ind, 1);
				_len = _functions.length;
				_changed = true;
			}
		}
		
		
		/**
		 * Проверить, добавленна данная функция в enterFrame
		 * @param	f функция
		 * @return возвращает true/false
		 */
		public function has(f:Function):Boolean
		{
			if (_functions.indexOf(f) != -1) return true;
				
			return false;
		}
		
		
		/**
		 * Запусить общий enterFrame
		 */
		public function start():void
		{
			_timerShape.addEventListener(Event.ENTER_FRAME, timerShape_enterFrame);
			_isOn = true;
		}
		
		
		/**
		 * Остановить общий enterFrame
		 */
		public function stop():void
		{
			_timerShape.removeEventListener(Event.ENTER_FRAME, timerShape_enterFrame);
			_isOn = false;
		}
		
		
		/**
		 * Удаляет все слушатели, которые были занесены методом add
		 */
		public function removeAll():void
		{
			for (var i:int = 0; i < _functions.length; i++) 
			{
				_functions[i] = null;
			}
			
			_functions.length = 0;
			_len = 0;
		}
		
		
		/**
		 * Уничтожить все данные. Применять перед удалением данного экземпляра.
		 * Останавливает enterFrame и удаляет все ссылки на методы.
		 */
		public function destroy():void 
		{
			stop();
			removeAll();
			_timerShape = null;
		}
		
		
		//==============================================
		//				PRIVATE
		//==============================================
		/**
		 * Вызывает все переданные методы
		 * @param	e
		 */
		private function timerShape_enterFrame(e:Event):void
		{
			if (_changed) 
			{
				_functionsFreeze = _functions.concat();
				_changed = false;
			}
			
			var len:int = _len;
			while (--len > -1)
			{
				_functionsFreeze[len]();
			}
			
		}
		
		
		//==============================================
		//				GETTERS
		//==============================================
		
		public function get isOn():Boolean
		{
			return _isOn;
		}
		
		
		public function get length():int
		{
			return _functions.length;
		}
	}

}