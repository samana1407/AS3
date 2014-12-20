package  myClasses
{
	import flash.errors.IllegalOperationError;
	import flash.utils.getDefinitionByName;
	/**
	 * ...
	 * @author Samana
	 */
	public class ArrayUtils 
	{
		/**
		 * Создаёт и возвращает новый перемешанный массив из заданного. Переданный массив остаётся не изменённым
		 * @param	arr Массив который нужно перемешать
		 * @return Перемешанный массив
		 */
		public static function MixArray(arr:Array):Array 
		{
			var t:Array = arr.concat();
			var newArr:Array = [];
			
			//while (t.length) newArr.push(t[int(Math.random() * t.length)]);
			while (t.length) newArr.push(t.splice(int(Math.random() * t.length), 1)[0]);
			
			return newArr;
		}
		
		/**
		 * Выбирает случайные элементы в массиве и возвращает новый массив с этими элементами
		 * @param	arr Массив в котором нужно выбрать элементы
		 * @param	num Число выбранных элементов (не больше длины массива arr)
		 * @return Массив со случайными элементами
		 */
		public static function findRandElements(arr:Array,num:int):Array
		{
			if (num > arr.length || num == 0) throw new IllegalOperationError("[ArrayUtils][findRandElements] неверные параметры");
			
			var tempArr:Array = arr.concat();
			var newArr:Array = [];
			for (var i:int = 0; i < num; i++) 
			{
				var ind:int = Math.random() * tempArr.length;
				newArr[i] = tempArr[ind];
				tempArr.splice(ind, 1);
			}
			return newArr;
		}
		
		
		
	}

}