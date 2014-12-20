package  
{
	/**
	 * ...
	 * @author samana
	 * Простой класс-коллбек. 
	 * Чтобы можно было назначить на коллбек несколько методов.
	 * Использую в триггерах.
	 */
	public class CallbackList 
	{
		private var _password:Object;
		private var _methods:Array = [];
		private var _params:Array = [];
		private var _len:int = 0;
		
		/**
		 * Создать колбекЛист.
		 * @param	password объект, содержащий экземпляр данного класса.
		 * Используется для блокировки случайного вызова метода applyAll, из других классов.
		 */
		public function CallbackList(password:Object) 
		{
			super();
			_password=password
		}
		
		
		/**
		 * Добавить метод и параметры
		 * @param	method метод
		 * @param	params параметры
		 */
		public function add(method:Function,params:Array=null):void 
		{
			_methods.push(method);
			_params.push(params);
			_len++;
		}
		
		
		/**
		 * Удалить все методы с параметрами
		 */
		public function removeAll():void 
		{
			_methods.length = 0;
			_params.length = 0;
			_len = 0;
		}
		
		/**
		 * Выполнить все методы, если они были переданы.
		 * Запускать в том классе, который содержит экземляр этого callbackList
		 * @param password объект, содержащий экземпляр данного класса.
		 */
		public function applyAll(password:Object=null):void 
		{
			if (password != _password) return;
			
			for (var i:int = 0; i < _len; i++) 
			{
				(_methods[i] as Function).apply(this, _params[i]);
			}
		}
		
		
		
	}

}