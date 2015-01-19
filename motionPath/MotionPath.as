package AS3.motionPath {
	import AS3.SMath;
	import flash.display.Graphics;
	import flash.display.Shape;
	import flash.geom.Point;
	
	/**
	 * ...
	 * @author samana
	 * Своего рода motionPath.
	 * Как использовать:
		 * Передать массив точек для составление пути через метод initPath.
		 * Чтобы визуализировать путь, нужно добавить в дисплейЛист displayShape и вызвать метод showPathData, но в этом нет необходимости.
		 * Получать положение и поворот точки на пути с помощью getValue, где 0 - начало, 1-конец пути.
		 * Так же удобно использовать в связке с Locator-ом, который привязывается к пути и имеет удобные методы для управления.
	 */
	public class MotionPath
	{
		/**
		 * Визуальное представление пути
		 */
		public var displayShape:Shape;
		
		private var _x:Number;					//координата икс
		private var _y:Number;					//координата игрек
		
		private var _vertexes:Vector.<Vertex>;	//массив с вершинами
		private var _length:Number;				//длина пути в пикселях
		private var _numVertexes:int;			//кол-во вершин, составляющих путь
		
		
		// проба оптимизации поиска вершин. Оправдывает себя, когда путь очень гладкий и содержит очень много вершин.
		// При getValue идёт поиск близжайщей вершины к искомому value и чтобы не перебирать все вершины,
		// общий массив с вершинами разбивается на указанное кол-во массивов, в каждом из которых будут
		// занесены те вершины, ребро которой (ребро: value - nextVertex.value) попадает в заданный диапазон value (напр. от 0.3 до 0.4)
		// В конечном счёте поиск вершины в миниМассиве происходит быстрее, чем в общем, цельном массиве.
		
		private var _numMiniArrays:int;			//на сколько частей разбить общий массив с вершинами (например 10)
		private var _valueMiniArray:Number;		//какой диапазон value для каждого миниМассива (=  1 / _numMiniArrays = 0.1)
		private var _allMiniVectors:Array;		//массив во всеми миниМассивами
		
		
		public function MotionPath() 
		{
			displayShape = new Shape();
			
			_x = 0;
			_y = 0;
			_vertexes = new Vector.<Vertex>();
			_length = 0;
			_numVertexes = 0;
			
			
			//проба отпимизации поиска вершин
			_numMiniArrays = 10;
			_valueMiniArray = 1 / _numMiniArrays;
			_allMiniVectors = [];
			
		}
		
		/**
		 * Данные о точке на пути. Возвращает вершину со всеми парраметрами.
		 * @param	value 0 - начало пути, 1 - конец пути
		 * @param 	cycle если value выходит из диапазона 0-1, то создаётся цикличность: из-конца в начало и наоборот.
		 * @param	rotateInterpolation усерединять angNext(поворот) вершины, если она находится между базовых вершин.
		 * Например если путь плавный, то лучше установить true, а если путь прямой и угловой, то - false.
		 * @return
		 */
		public function getValue(value:Number, cycle:Boolean=false, rotateInterpolation:Boolean=false):Vertex 
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
			
			var v:Vertex = new Vertex();
			
			if (value==0) 
			{
				v.copyFrom(_vertexes[0]);
				v.x += _x;
				v.y += _y;
				return v;
			}
			if (value==1) 
			{
				v.copyFrom(_vertexes[_vertexes.length - 1]);
				v.x += _x;
				v.y += _y;
				return v;
			}
			
			//-------------------------
			//нахожу тот мини вектор, который содержит вершины у которых рёбро входят в данныи диапозон вектора
			var miniVector:Vector.<Vertex> = _allMiniVectors[int(value / _valueMiniArray)];
			var len:int=miniVector.length-1
			
			
			var baseV:Vertex;
			//пробегаюсь по вершинам до первой и нахожу ту, у которой value меньше искомого value.
			//другими словами нахожу между какими вершинами находится искомое value
			for (var i:int = len; i >= 0; i--) 
			{
				baseV = miniVector[i];
				if (baseV.value == value)
				{
					v.copyFrom(baseV);
					v.x += _x;
					v.y += _y;
					return v;
				}
				
				if (baseV.value < value) 
				{
					v.copyFrom(baseV);
					break;
				}
			}
			
			var nextV:Vertex = _vertexes[baseV.id + 1];
			
			var valueOffset:Number = (value - v.value) / (nextV.value-v.value);
			
			v.x += (nextV.x - v.x) * valueOffset;
			v.y += (nextV.y - v.y) * valueOffset;
			v.x += _x;
			v.y += _y;
			
			if(rotateInterpolation) v.angNext += SMath.diffAngles(v.angNext, nextV.angNext, false) * valueOffset;
			
			v.uv += (nextV.uv - v.uv) * valueOffset;
			v.value = value;
			
			baseV = null;
			nextV = null;
			miniVector = null;
			
			return v;
		}
		
		
		/**
		 * Данные о точке на пути, через длину пути.
		 * Например получить точку, на 25-ом пикселе вдоль пути getValueUV(25)
		 * @param	valueUV величина в пикселях
		 * @param 	cycle если valueUV меньше 0 и больше длинны пути, то создаётся цикличность: из-конца в начало и наоборот.
		 * @param	rotateInterpolation усерединять angNext(поворот) вершины, если она находится между базовых вершин.
		 * Например если путь плавный, то лучше установить true, а если путь прямой и угловой, то - false.
		 * @return
		 */
		public function getValueUV(valueUV:Number,cycle:Boolean=false, rotateInterpolation:Boolean=false ):Vertex 
		{
			return getValue(valueUV/_length, cycle, rotateInterpolation)
		}
		
		/**
		 * Создать путь из точек.
		 * @param	points Вектор  с точками
		 * @param	smoothPass 	Количество смягчений для пути
		 * @param	closePath 	Если путь является замкнутым по задумке, то для правильного смягчения если (smoothPass > 0),
		 * 	нужно установить closePath=true 
		 */
		public function initPath(points:Vector.<Point>, smoothPass:int=0, closePath:Boolean=false):void 
		{
			if (points.length == 1)
			{
				trace("[Path][initPath] путь не может состоять из одной точки");
				return;
			}
			
			//если нужно смягчить путь
			if (smoothPass) 
			{
				for (var j:int = 0; j < smoothPass; j++) 
				{
					points = PolyLineEditor.smoothingLine(points, closePath);
				}
			}
			
			//обнулить данные
			_length = 0;
			
			_vertexes.fixed = false;
			_vertexes.length = 0;
			_allMiniVectors.length = 0;
			_numVertexes = 0;
			
			displayShape.graphics.clear();
			
			//создать по каждой точке vertex и найти какое она занимает положение к пикселях на пути,
			//чтобы потом можно было найти value
			for (var i:int = 0; i < points.length; i++) 
			{
				var currentP:Point = points[i];
				var v:Vertex = new Vertex();
				v.x = currentP.x;
				v.y = currentP.y;
				
				//угол к следующей точке и нормаль
				if (i < points.length-1) // до предпоследней точки
				{
					v.angNext = SMath.angTo(v.x, v.y, points[i + 1].x, points[i + 1].y, false);
					v.normal = v.angNext - 90;
				}
				
				//угол к предыдущей точке и позциция на пути (uv)
				if (i>0) // начинаем со второй точки 
				{
					v.angPrev = SMath.angTo(v.x, v.y, points[i - 1].x, points[i - 1].y, false);
					
					_length += SMath.dist(v.x, v.y, points[i - 1].x, points[i - 1].y);
					v.uv = _length;
				}
				
				_vertexes[i] = v;
			}
			
			
			
			var currentV:Vertex;
			var otherV:Vertex;
			
			//-------------------------
			// вершины созданы, но для первой вершины надо определить prevAng,
			// он будет такой же как у второй вершины, но если путь цельный,
			// то он будет такой же, как у последней вершины
			currentV = _vertexes[0];
			otherV = _vertexes[_vertexes.length - 1];
			
			if (closePath) currentV.angPrev = otherV.angPrev;
			else currentV.angPrev = _vertexes[1].angPrev;
			
			
			//-------------------------
			// и для последней вершины надо определить nextAng и normal
			// он будет такой же как у предпоследней вершины,
			// но если путь цельный, тогда nextAng будет как у первой вершины
			currentV = _vertexes[_vertexes.length - 1];
			otherV = _vertexes[0];
			
			if (closePath) 	currentV.angNext = otherV.angNext;
			else currentV.angNext = _vertexes[_vertexes.length - 2].angNext;
			
			currentV.normal = currentV.angNext - 90;
			
			
			//-------------------------
			// теперь надо вичислить value для вершин, так как общая длина пути известна,
			// и назначить id для вершины.
			for (var k:int = 0; k < _vertexes.length; k++) 
			{
				_vertexes[k].value = _vertexes[k].uv / _length;
				_vertexes[k].id = k;
			}
			
			//фикисрую длину пути и кол-во вершин
			_length = Number(_length.toFixed(2));
			_numVertexes = _vertexes.length;
			_vertexes.fixed = true;
			
			redrawPathData(1);
			
			//-------------------------------------------  
			//проба оттимизации поиска вершин
			
			//создать нужное кол-во мини-массивов
			var minValue:Number = 0;
			var maxValue:Number = _valueMiniArray;
			
			for (var l:int = 0; l < _numMiniArrays; l++) 
			{
				var miniVector:Vector.<Vertex>=new Vector.<Vertex>();
				
				//пробежать по всем вершинам и занести все в только что созданный массив,
				//если ребро вершины попадает в диапазон minValue maxValue
				for (var m:int = 0; m < _vertexes.length; m++) 
				{
					v = _vertexes[m];
					//нахожу value у следующей вершины, но если она последняя, то = 1
					var nextValue:Number = (m != _vertexes.length - 1) ? _vertexes[m + 1].value : 1;
					//если ребро вершины входт в диапазон для текущего минимального и максимального значения,
					//то заношу вершину в мими-массив.
					if (SMath.rangeNumbers(v.value, nextValue, minValue, maxValue))
					{
						miniVector.push(v);
					}
				}
				
				miniVector.fixed = true;
				
				_allMiniVectors[l] = miniVector;
				
				minValue = maxValue;
				maxValue+= _valueMiniArray;
			}
			
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
		public function redrawPathData(pathLine:int=1, vertexes:int=0, normals:int=0, nextAng:int=0, prevAng:int=0):void 
		{
			var normalLen:int = 10;
			var vertexSize:int = 2;
			
			displayShape.x = _x;
			displayShape.y = _y;
			
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
		
		/**
		 * Позиция по икс
		 */
		public function get x():Number 
		{
			return _x;
		}
		
		/**
		 * Позиция по икс
		 */
		public function set x(value:Number):void 
		{
			_x = value;
			displayShape.x = _x;
		}
		
		/**
		 * Позиция по игрек
		 */
		public function get y():Number 
		{
			return _y;
		}
		
		/**
		 * Позиция по игрек
		 */
		public function set y(value:Number):void 
		{
			_y = value;
			displayShape.y = _y;
		}
		
	}

}
