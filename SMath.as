package  AS3
{
	/**
	 * ...
	 * @author samana
	 * Дополнительный класс с полезными математическими методами.
	 * 
	 * Любая статическая функция выполняется медленнее, поэтому для отптимизации лучше прописывать расчёты в теле функции, где они нужны.
	 */
	public class SMath 
	{
		
		public function SMath() 
		{
			
		}
		
		/**
		 * Получить случайный цвет, без альфа канала.
		 * @param	color По умолчанию захватывается весь диапазон цветов
		 * @return Возвращает случайный цвет
		 */
		public static function randColor(color:uint=0xFFFFFF):uint 
		{
			return Math.random() * color
		}
		
		
		/**
		 * Получить случайное чилос в заданном диапазоне
		 * @param	min минимальное число
		 * @param	max максимальное  число
		 * @param	toInt округлить результать до целых. При округлении, минимальное и максимальное число входят в результат.
		 * @return
		 */
		public static function rand(min:Number=0,max:Number=0,toInt:Boolean=false):Number 
		{
			if (toInt) return Math.round(min + Math.random() * (max - min));
			
			return min + Math.random() * (max - min);
		}
		
		/**
		 * Получить расстояние между объектами
		 * @param	x1 икс первой точки
		 * @param	y1 игрек первой точки
		 * @param	x2 икс второй точки
		 * @param	y2 игрек второй точки
		 * @return Расстояние в пикселях
		 */
		public static function dist(fromX:Number,fromY:Number,toX:Number,toY:Number):Number 
		{
			var dx:Number = fromX - toX;
			var dy:Number = fromY - toY;
			return Math.sqrt(dx * dx + dy * dy);
		}
		
		
		/**
		 * Находит угол между двумя точками в радианах или градусах
		 * @param	fromX
		 * @param	fromY
		 * @param	toX
		 * @param	toY
		 * @param	inRadians переводит угол в радианы или градусы
		 * @return
		 */
		static public function angTo(fromX:Number, fromY:Number, toX:Number, toY:Number, inRadians:Boolean=true):Number 
		{
			if (inRadians) return Math.atan2(toY - fromY, toX - fromX);
			
			return Math.atan2(toY - fromY, toX - fromX) * 180 / Math.PI;
		}
		
		
	}

}