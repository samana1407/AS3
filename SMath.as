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
		 * Получить случайное число в заданном диапазоне
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
			
			return Math.atan2(toY - fromY, toX - fromX) * 180 / 3.141592653589793;// Math.PI
		}
		
		/**
		 * Вернуть разницу между углами в радианах или грудусах. Приоритет в меньшую сторону круга. 
		 * Сколько нужно добавить или отнять у угла ang1 чтобы он стал равен ang2
		 * @param	ang1 первый угол
		 * @param	ang2 второй угол
		 * @param 	inRadian переданные углы и возвращаемое значение в радианах, иначе в градусах
		 * @return
		 */
		static public function diffAngles(ang1:Number, ang2:Number,inRadian:Boolean=true):Number 
		{
			var diff:Number;
			
			if (inRadian) 
			{
				//convert to  0 - Math.PI*2
				// 3.141592653589793 = Math.PI;
				// 6.283185307179586 = Math.PI*2;
				if (ang1 < 0) ang1 = 6.283185307179586 - (ang1 * -1);//to abs
				if (ang2 < 0) ang2 = 6.283185307179586 - (ang2 * -1);//to abs
				 
				diff = ang2 - ang1;
				 
				if (diff > 3.141592653589793) diff -= 6.283185307179586;
				else if (diff < -3.141592653589793) diff += 6.283185307179586;
			}
			else
			{
				//convert to  0-360
				if (ang1 < 0) ang1 = 360 - (ang1 * -1);//to abs
				if (ang2 < 0) ang2 = 360 - (ang2 * -1);//to abs
				 
				diff = ang2 - ang1;
				 
				if (diff > 180) diff -= 360;
				else if (diff < -180) diff += 360;
			}
			
			return diff;
		}
		
		
		/**
		 * Находится ли число в заданном диапозоне, включая минимальное и максимальное значение.
		 * @param	min Минимальное число
		 * @param	max Максимальное число
		 * @param	rangeNum Число которое нужно проверить
		 * @return
		 */
		static public function rangeNum(min:Number,max:Number,rangeNum:Number):Boolean 
		{
			return (rangeNum>=min && rangeNum<=max)
		}
		
		
	}

}