package  AS3
{
	/**
	 * ...
	 * @author samana
	 * Дополнительный класс с полезными математическими методами
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
			return Math.random() * color;
		}
		
		/**
		 * Получить расстояние между объектами
		 * @param	x1 икс первой точки
		 * @param	y1 игрек первой точки
		 * @param	x2 икс второй точки
		 * @param	y2 игрек второй точки
		 * @return Расстояние в пикселях
		 */
		public static function dist(x1:Number,y1:Number,x2:Number,y2:Number):Number 
		{
			var dx:Number = x1 - x2;
			var dy:Number = y1 - y2;
			return Math.sqrt(dx * dx + dy * dy);
		}
	}

}