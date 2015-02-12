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
		 * Получить случайный элемент из массива
		 * @param	array массив со значениями
		 * @param	autoRemove удалить выбранный элемент из массива
		 * @return
		 */
		public static function randInArray(array:Array, autoRemove:Boolean=false):* 
		{
			var ind:int = (Math.random() * array.length);
			if (autoRemove) return array.splice(ind, 1)[0];
			return array[ind];
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
		 * @param 	inAbsCircle результат в положительном числе от 0-360 в градусах, либо от 0 - Math.Pi*2 в радианах
		 * @return
		 */
		static public function angTo(fromX:Number, fromY:Number, toX:Number, toY:Number, inRadians:Boolean=true, inAbsCircle:Boolean=true):Number 
		{
			var ang:Number;
			
			if (inRadians)
			{
				ang= Math.atan2(toY - fromY, toX - fromX);
				if (inAbsCircle && ang < 0) ang = 6.283185307179586 - (ang * -1);//to abs
			}
			else
			{
				ang = Math.atan2(toY - fromY, toX - fromX) * 180 / 3.141592653589793;// Math.PI
				if(inAbsCircle && ang < 0) ang = 360 - (ang * -1);//to abs
			}
			
			return ang
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
				if (diff < -180) diff += 360;
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
		
		
		/**
		 * Пересекаются ли отрезки min-max и minRange-maxRange.
		 * Например отрезок (0.2,0.5) пересекается с отрезками (0.45,0.7), (-60, 20), (0.5 0.51),
		 * но не пересекается с (0.1,0.199), (0.51, 3.5).
		 * @param	min Минимальное число первого отрезка
		 * @param	max Максимальное число первого отрезка
		 * @param	minRange Минимальное число второго отрезка
		 * @param	maxRange Максимально число второго отрезка
		 * @return
		 */
		static public function rangeNumbers(min:Number, max:Number, minRange:Number, maxRange:Number):Boolean 
		{
			return (min<=maxRange && max>=minRange);
		}
		
		
	}

}