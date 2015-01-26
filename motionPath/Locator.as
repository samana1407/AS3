package AS3.motionPath
{
	import AS3.SMath;
	import flash.display.Sprite;
	
	/**
	 * ...
	 * @author samana
	 * С помощью локатора, можно лекго перемещаться вдоль пути.
	 * Перемещение с помощью:
	 * uv - в пикселях, (locator.uv+=5 переместить локатор на 5 пикселей вперёд вдоль пути)
	 * value - относительно, (locator.value=0.5 переместить локатор на половину пути)
	 * 
	 */
	public class Locator extends Sprite
	{
		/**
		 * Поворот локатора относительно пути
		 */
		private var _orientToPath:Boolean;
		
		/**
		 * Цикличность передвиженя вдоль пути, при изменении свойств value или uv.
		 * Если выходит за пределы пути, то появлятся с обратной строны.
		 */
		public var cycleValue:Boolean;
		
		/**
		 * Усерединение поворота между предыдущей и следующей вершиной, если локатор находится между ними.
		 */
		public var rotateInterpolation:Boolean;
		
		
		private var _uv:Number; //положение в пикселях вдоль пути
		private var _value:Number; //положение на пути 0-начало, 1-конец
		private var _path:MotionPath; //ссылка на путь
		
		
		/**
		 * Создать локатор на пути.
		 * @param	path путь для локатора
		 * @param	cycle цикличность передвижения
		 * @param 	rotateInterpolation усерединять поворот между предыдущей и следующей вершиной, если локатор находится между ними
		 */
		public function Locator(path:MotionPath=null, cycle:Boolean = false, rotateInterpolation:Boolean = false )
		{
			_uv = 0;
			_value = 0;
			
			cycleValue = cycle;
			_orientToPath = false;
			this.rotateInterpolation = rotateInterpolation;
			
			if (path != null)
			{
				this.path = path;
			}
			
		}
		
		
		/**
		 * Имитация перетаскивание локатора по кривой. Возвращает uv скорость перетаскивания. 
		 * На острых углах может наблюдаться тряска, причина которой 
		 * мне известна, но пока не нашел ей решение.
		 * @param	targetX
		 * @param	targetY
		 * @param 	slow Плавность перетаскивания 1 - мгновенное 0 - нет перетаскивания.
		 * @return	Скорость перетаскивания.
		 */
		public function dragTo(targetX:Number, targetY:Number, slow:Number=0.4):Number
		{
			//корректируем значение плавности
			slow = slow > 1 ? 1 : slow;
			if (slow <= 0) return 0;
			
			
			//запоминаем текущее значение цикличности локатора
			//и заменяем на время перетаскивания. Если путь не замкнутый, то цикличность отсутствует.
			var cycleBeen:Boolean = cycleValue;
			cycleValue = _path.isClosed;
			
			//запоминаем позицию до перетаскивания, которая понадобится если задана плавность.
			var oldUV:Number = uv;
			
			//скорость перетаскивания
			var offsetUV:Number = 0;
			
			
			var angToTarget:Number = SMath.angTo(x, y, targetX, targetY, false); //угол к цели
			
			var nextV:Vertex = _path.getValueUV(uv + 1, cycleValue);
			var prevV:Vertex = _path.getValueUV(uv - 1, cycleValue);
			
			var nextAng:Number = SMath.angTo(x, y, nextV.x, nextV.y, false);
			var prevAng:Number = SMath.angTo(x, y, prevV.x, prevV.y, false);
			
			var nextAngDiff:Number = Math.abs(SMath.diffAngles(angToTarget, nextAng, false));
			var prevAngDiff:Number = Math.abs(SMath.diffAngles(angToTarget, prevAng, false));
			
			
			//тянем назад, но тупик
			if (value == 0 && prevV.value == 0 && nextAngDiff > 80)
			{
				//trace("назад но тупик")
				return 0;
			}
			
			//тянем вперёд, но тупик
			if (value == 1 && nextV.value == 1 && prevAngDiff > 80)
			{
				//trace("вперёд но тупик")
				return 0;
			}
			
			var forvard:Boolean = false;
			//все условия, которые определяют, что тянуть можно только вперёд по пути:
			//	1) 	если шаг назад, такой же как и текущее положение, то есть стоим в начале у незамкнутого пути
			//		а угол к слешующему шагу близко к углу, куда тянем мышь
			//
			//  2)	или шагнуть назад можно, но
			//	3)	угол к слешующему шагу меньше, чем угол к угол к шагу назад
			//	4)	и угол к слещующему шагу близко к направлению мыши
			//	5) 	и шагать вперёд вообще возможно
			//
			//  (                 1                  )    (       2       )    (			3			)	  (			4	   )	(		5	)
			if (((prevV.uv == uv) && nextAngDiff < 80) || ((prevV.uv != uv) && (nextAngDiff < prevAngDiff) && (nextAngDiff < 80) && (nextV.uv!=uv)))
			{
				//trace("forvard true");
				forvard = true;
			}
			
			
			//двигаем локатор на 1 px в нужную сторону, пока есть куда двигаться
			var prevUV:Number;
			
			while (true)
			{
				prevUV = uv;
				angToTarget = SMath.angTo(x, y, targetX, targetY, false); //угол к цели
				
				if (forvard) 
				{
					nextV = _path.getValueUV(uv + 1, cycleValue);
					nextAng = SMath.angTo(x, y, nextV.x, nextV.y, false);
					nextAngDiff = SMath.diffAngles(angToTarget, nextAng, false);
					if(nextAngDiff < 0) nextAngDiff *=  -1;
					
					if (nextAngDiff < 80) uv++;
					
					
				}
				else
				{
					prevV = _path.getValueUV(uv - 1, cycleValue);
					prevAng = SMath.angTo(x, y, prevV.x, prevV.y, false);
					prevAngDiff = SMath.diffAngles(angToTarget, prevAng, false);
					if(prevAngDiff < 0) prevAngDiff *= -1;
					
					if (prevAngDiff < 80) uv--;
					
				}
				
				//если смещения не произошло, например конец или начало пути, либо направление
				//перетаскивания перпендикулярно пути, то останавливаем перетаскивание
				if (prevUV==uv) break;
				
			}
			
			
			//вычисляем относительное смещение
			offsetUV = (uv - oldUV);
			
			//ищем кратчайшее направление если путь замкнут, чтобы не обходить весь путь, когда двигаемся например от 5 до конца пути.
			if (_path.isClosed) 
			{
				if (offsetUV > _path.length * 0.5) offsetUV -= _path.length;
				if (offsetUV < -_path.length * 0.5) offsetUV += _path.length;
			}
			
			offsetUV *= slow;
			uv = oldUV+offsetUV;
			
			
			//установить цикличное движение, которое было до перетаскивания
			cycleValue = cycleBeen;
			
			return offsetUV;
		}
		
		
		/**
		 * Обновить трансформацию локатора
		 */
		private function updateTransform(val:Number):void
		{
			var v:Vertex = _path._getValue(val, cycleValue, rotateInterpolation);
			x = v.x;
			y = v.y;
			if (_orientToPath) rotation = v.angNext;
			_uv = v.uv;
			_value = v.value;
			
			v = null;
		}
		
		
		//==============================================
		//				GETTERS SETTERS value & uv
		//==============================================
		
		/**
		 * Текущее положение на пути в пикселях
		 */
		public function get uv():Number
		{
			return _uv;
		}
		
		
		/**
		 * Установить положение на пути в пикселях.
		 * Как если бы путь можно было измерять в пикселях.
		 * 0 - начало, n - длина пути
		 */
		public function set uv(valueUV:Number):void
		{
			updateTransform(valueUV / _path.length);
		
		}
		
		
		/**
		 * Текущая позиция на пути в процентром соотношении.
		 * 0 - начало, 1 - конец
		 */
		public function get value():Number
		{
			return _value;
		}
		
		
		/**
		 * Установить позицию на пути
		 * 0-начало, 1-конец
		 */
		public function set value(value:Number):void
		{
			updateTransform(value);
		}
		
		
		//==============================================
		//					GETTERS SETTERS other
		//==============================================
		
		public function get path():MotionPath 
		{
			return _path;
		}
		
		public function set path(value:MotionPath):void 
		{
			_path = value;
			updateTransform(_value);
		}
		
		public function get orientToPath():Boolean 
		{
			return _orientToPath;
		}
		
		public function set orientToPath(value:Boolean):void 
		{
			_orientToPath = value;
			updateTransform(_value);
		}
	
	}

}