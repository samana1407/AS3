package AS3.motionPath
{
	import AS3.SMath;
	import flash.display.Shape;
	
	/**
	 * ...
	 * @author samana
	 * С помощью локатора, можно лекго перемещаться вдоль пути.
	 * Перемещение с помощью:
	 * uv - в пикселях, (locator.uv+=5 переместить локатор на 5 пикселей вперёд вдоль пути)
	 * value - относительно, (locator.value=0.5 переместить локатор на половину пути)
	 * Чтобы увидеть локатор, нужно добавить в дисплейЛист displayShape
	 */
	public class Locator
	{
		/**
		 * Поворот локатора относительно пути
		 */
		public var orientToPath:Boolean;
		
		/**
		 * Цикличность передвиженя вдоль пути.
		 * Если выходит за пределы, то появлятся с обратной строны.
		 */
		public var cycleValue:Boolean;
		
		/**
		 * Шейп, для визуального представления локатора.
		 */
		public var displayShape:Shape;
		
		
		private var _x:Number; //позиция по x
		private var _y:Number; //позиция по y
		private var _rotation:Number; //поворот в градусах
		private var _uv:Number; //положение в пикселях вдоль пути
		private var _value:Number; //положение на пути 0-начало, 1-конец
		private var _path:MotionPath; //ссылка на путь
		
		
		/**
		 * Создать локатор на пути.
		 * @param	path путь для локатора
		 * @param	cycle цикличность передвижения
		 */
		public function Locator(path:MotionPath, cycle:Boolean = false)
		{
			_x = 0;
			_y = 0;
			_rotation = 0;
			_path = path;
			_uv = 0;
			_value = 0;
			
			cycleValue = cycle;
			orientToPath = true;
			displayShape = new Shape();
			
			updateTransform(_value);
			drawLocator();
		}
		
		
		/**
		 * Имитация перетаскивание локатора по кривой.
		 * На острых углах может наблюдаться тряска поворота.
		 *
		 * @param	targetX
		 * @param	targetY
		 */
		public function dragTo(targetX:Number, targetY:Number):void
		{
			//при перетаскивании блокируем цикличное передвиженое по пути, если оно включено.
			var cycleBeenTrue:Boolean = cycleValue;
			cycleValue = false;
			
			var v:Vertex = _path.getValue(_value); //текущие данные на пути
			var angToTarget:Number = SMath.angTo(v.x, v.y, targetX, targetY, false); //угол к цели
			var offsetAng:Number = SMath.diffAngles(v.angNext, angToTarget, false); //разница угла к цели и угла к след.вершине на  пути
			offsetAng = offsetAng < 0 ? offsetAng * -1 : offsetAng; //to abs
			
			//направление куда тянем, вперёд или назад по пути.
			//это для того, чтобы цикл while не зависал на острых углах
			var forvard:Boolean = offsetAng < 90 ? true : false;
			
			//расстояние между целью и текущим положением на пути
			var dist:Number;
			
			//двигаем локатор на 1 px в нужную сторону, пока есть куда двигаться
			while (true)
			{
				v = _path.getValue(_value);
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
			
			if (cycleBeenTrue)
				cycleValue = true;
		}
		
		
		/**
		 * Обновить трансформацию локатора и визуального шейпа
		 */
		private function updateTransform(val:Number):void
		{
			var v:Vertex = _path.getValue(val, cycleValue);
			_x = v.x;
			_y = v.y;
			_uv = v.uv;
			_value = v.value;
			if (orientToPath)
				_rotation = v.angNext;
			
			//обновить визуальный шейп
			displayShape.x = _x;
			displayShape.y = _y;
			displayShape.rotation = _rotation;
			
			v = null;
		}
		
		
		/**
		 * Нарисовать локатор в виде креста
		 */
		private function drawLocator():void
		{
			var w:Number = 1;
			var len:int = 20;
			with (displayShape.graphics)
			{
				//верх синий
				lineStyle(w, 0x48A4FF);
				moveTo(0, 0);
				lineTo(0, -len);
				//низ коричневый
				lineStyle(w, 0x800000);
				moveTo(0, 0);
				lineTo(0, len);
				//левая сторона серая
				lineStyle(w, 0x909090);
				moveTo(0, 0);
				lineTo(-len, 0);
				//правая сторона зелёная
				lineStyle(w, 0x47FC03);
				moveTo(0, 0);
				lineTo(len, 0);
			}
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
		//					GETTERS x,y,rotation
		//==============================================
		public function get x():Number
		{
			return _x
		}
		
		public function get y():Number
		{
			return _y;
		}
		
		public function get rotation():Number
		{
			return _rotation;
		}
	
	}

}