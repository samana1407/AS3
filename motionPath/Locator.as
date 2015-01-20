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
	 * Чтобы увидеть локатор, нужно добавить в дисплейЛист displayShape
	 */
	public class Locator extends Sprite
	{
		/**
		 * Поворот локатора относительно пути
		 */
		public var orientToPath:Boolean;
		
		/**
		 * Цикличность передвиженя вдоль пути, при изменении свойств value или uv.
		 * Если выходит за пределы, то появлятся с обратной строны.
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
			orientToPath = true;
			this.rotateInterpolation = rotateInterpolation;
			
			if (path != null)
			{
				this.path = path;
			}
			
		}
		
		
		/**
		 * Имитация перетаскивание локатора по кривой.
		 * На острых углах может наблюдаться тряска поворота, причина которой 
		 * мне известна, но пока не нашел ей решение.
		 *
		 * @param	targetX
		 * @param	targetY
		 * @param	cycleWhenDrag заменяет свойство cycleValue на время перетаскивания.
		 * 
		 */
		public function dragTo(targetX:Number, targetY:Number, cycleWhenDrag:Boolean=false):void
		{
			//запоминаем текущее значение цикличности локатора
			//и заменяем на время перетаскивания
			var cycleBeen:Boolean = cycleValue;
			cycleValue = cycleWhenDrag;
			
			
			var v:Vertex = _path._getValue(_value); //текущие данные на пути
			var angToTarget:Number = SMath.angTo(v.x, v.y, targetX, targetY, false); //угол к цели
			var offsetAng:Number = SMath.diffAngles(v.angNext, angToTarget, false); //разница угла к цели и угла к след.вершине на  пути
			offsetAng = offsetAng < 0 ? offsetAng * -1 : offsetAng; //to abs
			
			//направление куда тянем, вперёд или назад по пути.
			//это для того, чтобы цикл while не зависал на острых углах,
			//не понимая в какую сторону двигаться.
			var forvard:Boolean = offsetAng < 90 ? true : false;
			
			//расстояние между целью и текущим положением на пути
			var dist:Number;
			
			//двигаем локатор на 1 px в нужную сторону, пока есть куда двигаться
			while (true)
			{
				v = _path._getValue(_value);
				dist = SMath.dist(v.x, v.y, targetX, targetY);
				
				if (dist > 5)
				{
					angToTarget = SMath.angTo(v.x, v.y, targetX, targetY, false);
					
					if (forvard)
					{
						offsetAng = SMath.diffAngles(v.angNext, angToTarget, false);
						offsetAng = offsetAng < 0 ? offsetAng * -1 : offsetAng; //to abs
						
						// вперёд
						if (offsetAng < 80 && v.value < 1)
						{
							uv += 1;
							continue;
						}
						
					}
					else
					{
						//назад
						offsetAng = SMath.diffAngles(v.angNext - 180, angToTarget, false);
						offsetAng = offsetAng < 0 ? offsetAng * -1 : offsetAng; //to abs
						
						if (offsetAng < 80 && v.value > 0)
						{
							uv -= 1;
							continue;
						}
					}
					
				}
				//когда угол от target к текущей точке на кривой станет перпендикулярным (+- 20 градусов),
				//то цикл while завершается. 
				
				break;
			}
			
			//установить цикличное движение, которое было до перетаскивания
			cycleValue = cycleBeen;
		}
		
		
		/**
		 * Обновить трансформацию локатора и визуального шейпа
		 */
		private function updateTransform(val:Number):void
		{
			var v:Vertex = _path._getValue(val, cycleValue, rotateInterpolation);
			x = v.x;
			y = v.y;
			if (orientToPath) rotation = v.angNext;
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
	
	}

}