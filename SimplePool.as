package  AS3
{
	/**
	 * ...
	 * @author samana
	 * Простой пул для объектов
	 */
	public class SimplePool 
	{
		private var _pool:Vector.<Object>;
		private var _className:Class;
		
		/**
		 * Создать пул объектов
		 * @param	className имя класса объектов
		 * @param	numInstances начальное кол-во экземпляров
		 */
		public function SimplePool(className:Class, numInstances:int = 0 ) 
		{
			_pool = new Vector.<Object>();
			_className = className;
			
			if (numInstances > 0)
			{
				for (var i:int = 0; i < numInstances; i++) 
				{
					_pool[i] = new _className();
				}
			}
		}
		
		/**
		 * Получить объект из пула
		 * @return Возвращает последний объект в пул-е
		 */
		public function getInstance():Object 
		{
			if (_pool.length) return _pool.pop();
			else return new _className();
		}
		
		/**
		 * Поместить объект в пул
		 * @param	instance Обьект помещается в конец пул-а
		 */
		public function  setInstance(instance:Object):void 
		{
			if (_pool.indexOf(instance) == -1)
			{
				_pool[_pool.length] = instance;
			}
		}
		
		/**
		 * Отчистить пул. Длина массива пул-а принимает значение ноль.
		 */
		public function clear():void 
		{
			_pool.length = 0;
		}
		
		/**
		 * Получить кол-во объектов в пул-е.
		 */
		public function get length():int 
		{
			return _pool.length;
		}
		
		
		
	}

}