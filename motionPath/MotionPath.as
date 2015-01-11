package AS3.motionPath {
	import AS3.SMath;
	import flash.display.Graphics;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.geom.Point;
	
	/**
	 * ...
	 * @author samana
	 * Своего рода motionPath.
	 * Как использовать:
		 * Передать массив точек для составление пути через метод initPath.
		 * ВАЖНО!!!! Точки должы быть на одинаковом расстоянии друг от друга
		 * Чтобы визуализировать путь, нужно добавить в дисплейЛист displayShape и вызвать метод showPathData, но в этом нет необходимости.
		 * Получать положение и поворот точки на пути с помощью getValue, где 0 - начало, 1-конец пути.
	 */
	public class MotionPath
	{
		/**
		 * Визуальное представление пути
		 */
		public var displayShape:Shape;		
		
		private var _vertexes:Vector.<Vertex>;	//массив с вершинами
		private var _length:Number;				//длина пути в пикселях
		private var _numVertexes:int;			//кло-во вершин, составляющих путь
		
		
		public function MotionPath() 
		{
			_vertexes = new Vector.<Vertex>();
			_length = 0;
			_numVertexes = 0;
			
			displayShape = new Shape();
			
		}
		
		/**
		 * Данные о точке на пути. Возвращает вершину со всеми парраметрами.
		 * @param	value 0 - начало пути, 1 - конец пути
		 * @param 	cycle если value выходит из диапазона 0-1, то создаётся цикличность: из-конца в начало и наоборот.
		 * @return
		 */
		public function getValue(value:Number, cycle:Boolean=false):Vertex 
		{
			if (!cycle) 
			{
				if (value > 1) value = 1;
				if (value < 0) value = 0;
			}
			else
			{
				if (value>0) value = value % 1;
				if (value<0) value = 1-Math.abs(value % 1);
			}
			
			var baseValue:Number = value * (_numVertexes-1);	//какая вершина соответствует данному value
			var offsetBaseV:Number = baseValue % 1;				//смещение от базовой вершины, когда value между вершинами
			var baseV:Vertex = _vertexes[int(baseValue)];		//ссылка на эту вершину
			
			var v:Vertex = new Vertex();
			v.copyFrom(baseV);
			
			//если есть смещение, а оно практически всегда есть, то добавляем к вершине это смещение
			if (offsetBaseV != 0) 
			{
				var nextV:Vertex = _vertexes[int(baseValue) + 1];
				v.x += (nextV.x - v.x) * offsetBaseV;
				v.y += (nextV.y - v.y) * offsetBaseV;
				v.angNext += SMath.diffAngles(v.angNext, nextV.angNext, false) * offsetBaseV;
				v.value = value;
				v.uv = _length * value;
			}
			
			return v;
		}
		
		/**
		 * Данные о точке на пути, через длину пути.
		 * Например получить точку, на 25-ом пикселе вдоль пути getValueUV(25)
		 * @param	valueUV величина в пикселях
		 * @param 	cycle если valueUV меньше 0 и больше длинны пути, то создаётся цикличность: из-конца в начало и наоборот.
		 * @return
		 */
		public function getValueUV(valueUV:Number,cycle:Boolean=false):Vertex 
		{
			return getValue(valueUV/_length, cycle)
		}
		
		/**
		 * Создать путь из точек.
		 * Точки должны быть на одинаковом расстоянии друг от друга, иначе всё пропало!
		 * @param	points Вектор  с точками
		 */
		public function initPath(points:Vector.<Point>):void 
		{
			if (points.length == 1)
			{
				trace("[Path][initPath] путь не может состоять из одной точки");
				return;
			}
			
			//обнулить данные
			_length = 0;
			
			_vertexes.fixed = false;
			_vertexes.length = 0;
			_numVertexes = 0;
			
			displayShape.graphics.clear();
			
			//пробежаться по точкам и постоить путь
			for (var i:int = 0; i < points.length; i++) 
			{
				var currentP:Point = points[i];
				var prevP:Point;
				var nextP:Point;
				
				var prevV:Vertex;
				
				var v:Vertex = new Vertex();
				v.x = currentP.x;
				v.y = currentP.y;
				v.value = i / (points.length - 1);
				v.uv = Number(_length.toFixed(1));
				
				_vertexes[i] = v;
				
				//угол к следующей точке и нормаль для текущей.
				//если эта последняя точка на пути, то её нормаль и angNext такие же как у предыдущей точки.
				//так же расстояние до следующей точки, для определения длинны всего пути в пикселях.
				if (i < points.length-1) 
				{
					nextP = points[i + 1];
					v.angNext = SMath.angTo(currentP.x, currentP.y, nextP.x, nextP.y, false);
					v.normal = v.angNext - 90;
					
					_length += SMath.dist(currentP.x, currentP.y, nextP.x, nextP.y);
				}
				else if (i==points.length-1) 
				{
					prevV = _vertexes[i - 1];
					v.angNext = prevV.angNext;
					v.normal = prevV.normal;
				}
				
				
				//угол к предыдущей точке и
				//если это первая точка на пути, то её prevAng такой же как у второй точки.
				if (i>0) 
				{
					prevP = points[i - 1];
					v.angPrev = SMath.angTo(currentP.x, currentP.y, prevP.x, prevP.y, false);
					if (i==1) 
					{
						prevV = _vertexes[i - 1];
						prevV.angPrev = v.angPrev;
					}
				}
			}
			
			_length = Number(_length.toFixed(2));
			_numVertexes = _vertexes.length;
			_vertexes.fixed = true;
		}
		
		/**
		 * Для отладки. Визуализировать данные о пути.
		 * 1- показать, 0 - скрыть
		 * @param	pathLine линия пути - серая
		 * @param	vertexes вершины - синие
		 * @param	normals нормали - жёлтые
		 * @param	nextAng угол к след.вершине - зелёная
		 * @param	prevAng угол к пред.вершине - красная
		 */
		public function showPathData(pathLine:int=1, vertexes:int=0, normals:int=0, nextAng:int=0, prevAng:int=0):void 
		{
			var normalLen:int = 10;
			var vertexSize:int = 2;
			
			var g:Graphics = displayShape.graphics;
			g.clear();
			
			//нарисовать путь
			if (pathLine) 
			{
				g.lineStyle(1, 0xB6B6B6);
				g.moveTo(_vertexes[0].x, _vertexes[0].y);
				for (var i:int = 1; i < _vertexes.length; i++) 
				{
					g.lineTo(_vertexes[i].x, _vertexes[i].y);
				}
				g.lineStyle();
			}
			
			//нарисовать всё остальное
			for (var j:int = 0; j < _vertexes.length; j++) 
			{
				var v:Vertex = _vertexes[j];
				
				if (vertexes) 
				{
					g.beginFill(0xC41515);
					g.drawRect(v.x - vertexSize/2, v.y - vertexSize/2, vertexSize, vertexSize);
					g.endFill();
				}
				
				if (normals) 
				{
					g.lineStyle(1, 0xDFC402);
					g.moveTo(v.x, v.y);
					g.lineTo(v.x + Math.cos(v.normal * Math.PI / 180) * normalLen, v.y + Math.sin(v.normal * Math.PI / 180) * normalLen);
					g.lineStyle();
				}
				
				if (nextAng) 
				{
					g.lineStyle(1, 0x6BD700);
					g.moveTo(v.x, v.y);
					g.lineTo(v.x + Math.cos(v.angNext * Math.PI / 180) * normalLen, v.y + Math.sin(v.angNext * Math.PI / 180) * normalLen);
					g.lineStyle();
				}
				
				if (prevAng) 
				{
					g.lineStyle(1, 0xD72000);
					g.moveTo(v.x, v.y);
					g.lineTo(v.x + Math.cos(v.angPrev * Math.PI / 180) * normalLen, v.y + Math.sin(v.angPrev * Math.PI / 180) * normalLen);
					g.lineStyle();
				}
			}
		}
		
		//==============================================
		//				GETTERS
		//==============================================
		/**
		 * Длина пути в пикселях
		 */
		public function get length():Number 
		{
			return _length;
		}
		
		/**
		 * Кол-во точек составляющих путь
		 */
		public function get numVertexes():int 
		{
			return _numVertexes;
		}
		
	}

}