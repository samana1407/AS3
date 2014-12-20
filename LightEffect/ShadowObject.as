package LightEffect 
{
	import flash.display.DisplayObject;
	import flash.geom.Point;
	/**
	 * ...
	 * @author Samana
	 */
	public class ShadowObject 
	{
		//массив со всеми рёбрами (ребро -> {a:Point, b:Point} )
		internal var edges:Vector.<Object> = new Vector.<Object>();
		
		// дисплейОбъекты которым принадлежит этот ТеневойОбъект
		// и относительно которых будут рассчитываться построение теней
		internal var allDO:Vector.<DisplayObject> = new Vector.<DisplayObject>();
		
		public function ShadowObject() 
		{
			
		}
		
		
		//-------------------------------------------------------------
		//						DISPLAY OBJECTS MANIPULATION
		//-------------------------------------------------------------
		
		/**
		 * Добавить в список дисплейОбъект, которому будет принадлежать текущий ТеневойОбъект
		 * @param	displayObject
		 */
		public function addToDisplayObject(displayObject:DisplayObject):void 
		{
			if (allDO.indexOf(displayObject) == -1) allDO.push(displayObject);
		}
		
		
		/**
		 * Удалить дисплейОбъект из списка. Теперь текущий ТеневойОбъект не будет ему принадлежать.
		 * @param	displayObject
		 */
		public function removeFromDisplayObject(displayObject:DisplayObject):void 
		{
			var ind:int = allDO.indexOf(displayObject);
			if (ind != -1) allDO.splice(ind, 1);
		}
		
		/**
		 * Удалить все дисплейОбъекты из списка.
		 * Теперь текущий ТеневойОбъект не будет принадлежать ни одному дисплейОбъекту.
		 */
		public function removeFromAllDisplayObjects():void 
		{
			allDO.length = 0;
		}
		
		//-------------------------------------------------------------
		//						ADD EDGES UTILS
		//-------------------------------------------------------------
		/**
		 * Добавить одно ребро.
		 * @param	startPoint Начальная точка ребра.
		 * @param	endPoint Конечная точка ребра.
		 */
		public function addEdge(startPoint:Point,endPoint:Point):void 
		{
			for (var i:int = 0; i < edges.length; i++) 
			{
				//если переданная точка совпадает с любой уже имеющейся точкой,
				//то не создаём новых точек, а передаём ссылку на существующую точку
				if (edges[i].a.equals(startPoint)) startPoint = edges[i].a;
				if (edges[i].b.equals(endPoint)) endPoint = edges[i].b;
			}
			edges.push({a:startPoint, b:endPoint});
			
		}
		
		
		/**
		 * Добавляет "цепочку" рёбер, путём перебора всех точек подряд.
		 * При необходимости, можно замкнуть последнюю точку и первую точку дополнительным ребром.
		 * @param	pointsPath Вектор точек, из которых создадутся рёбра.
		 * @param	closedPath Замкнуть первую и последнюю точку ребром.
		 */
		public function addEdgePath(pointsPath:Vector.<Point>, closedPath:Boolean=false):void 
		{
			
			if (pointsPath.length < 2 ) return;
			
			for (var i:int = 0; i < pointsPath.length-1; i++) 
			{
				addEdge(pointsPath[i], pointsPath[i+1]);
			}
			
			//если нужно - соединить последню и первую точку ребром
			if (closedPath && pointsPath.length > 2)
			{
				
				addEdge(pointsPath[0], pointsPath[i]);
			}
			
		}
		
		
		/**
		 * Добавить прямоугольник из рёбер.
		 * @param	x Координата x прямоугольника.
		 * @param   y Координата y прямоугольника.
		 * @param	width Ширина прямоугольника.
		 * @param	height Высота прямоугольника.
		 */
		public function addEdgeRect(x:Number,y:Number,width:Number,height:Number):void 
		{
			addEdgePath(new <Point>[new Point(x,y),new Point(x+width,y),new Point(x+width,y+height),new Point(x,y+height)],true);
		}
		
		
		/**
		 * Добавить круг из рёбер. Подходит больше для маленьких кругов, т.к. для большого круга,
		 * нужно большое количесво сегментов, для видимой гладкости. 
		 * @param	x Центр по x круга.
		 * @param	y Центр по y круга.
		 * @param	radius Радиус круга.
		 * @param	segments Коричество рёбер, из которых составится круг. 
		 * Минимальное кол-во рёбер - 3.
		 */
		public function addEdgeCircle(x:Number,y:Number,radius:Number,segments:uint=8):void 
		{
			if (segments < 3) return;
			var points:Vector.<Point> = new Vector.<Point>();
			var ang:Number = 2 * Math.PI / segments;
			
			for (var i:int = 0; i < segments; i++) 
			{
				points[i] = new Point(x + Math.cos(ang * i) * radius, y + Math.sin(ang * i) * radius);
			}
			addEdgePath(points, true);
		}
		
		
		/**
		 * Удалить все рёбра.
		 */
		public function removeAllEdges():void 
		{
			edges.length = 0;
		}
		
		
	}

}