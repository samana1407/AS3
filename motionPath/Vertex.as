package AS3.motionPath {
	
	/**
	 * ...
	 * @author samana
	 * Класс вершины из которых состоит путь.
	 */
	public class Vertex
	{
		public var x:Number;			//позиция по x
		public var y:Number;			//позиция по y
		public var angNext:Number;		//угол к следующей вернише (в градусах)
		public var angPrev:Number;		//угол к предыдущей вершине (в градусах)
		public var normal:Number;		//угол нормали (в градусах)
		public var value:Number;		//позиция на пути 0-1 конец пути
		public var uv:Number;			//позиция на пути в пикселях 0 - n n=длина пути
		
		public function Vertex() 
		{
			x = 0;
			y = 0;
			angNext = 0;
			angPrev = 0;
			normal = 0;
			value = 0;
			uv = 0;
		}
		
		public function copyFrom(v:Vertex):Vertex 
		{
			x = v.x;
			y = v.y;
			angNext = v.angNext;
			angPrev = v.angPrev;
			normal = v.normal;
			value = v.value;
			uv = v.uv;
			return this
		}
		
	}

}