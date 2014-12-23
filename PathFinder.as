package  AS3
{
	import flash.geom.Point;
	/**
	 * ...
	 * @author samana
	 * Простой поиск пути в двухметром массиве.
	 */
	public class PathFinder 
	{
		
		/**
		 * Найти путь, если он существует. 
		 * @param	map двухмерный массив поля
		 * @param	emptyCell число определяющее пустую клетку на поле
		 * @param	startP клетка старта
		 * @param	endP клетка финиша
		 * @return Возвращает массив точек найденного пути от точки старта до финишной включительно, либо пустой массив.
		 */
		public function findPath(map:Array,emptyCell:int, startP:Point, endP:Point):Array 
		{
			// если началная или конечная клетки заняты, то прерываем поиск
			if (map[startP.y][startP.x] != emptyCell || map[endP.y][endP.x] != emptyCell)
			{
				trace("start or end point is bussy")
				return [];
			}
			
			//копия карты, куда будут записываться результаты
			var mapClone:Array = [];
			
			for (var i:int = 0; i < map.length; i++) 
			{
				mapClone[i] = [];
				for (var j:int = 0; j < map[i].length; j++) 
				{
					mapClone[i][j] = map[i][j];
				}
			}
			
			// заносим на карту точку старта
			mapClone[startP.y][startP.x] = startP;
			
			//ширина и высота карты
			var mapW:int = mapClone[0].length;
			var mapH:int = mapClone.length;
			
			//клетки, из которых ищем путь
			var checkCells:Array = [startP];
			
			//вспомогательные переменные для обозначения близжайщих клеток
			var tempX:int;
			var tempY:int;
			
			//изначально путь не найден
			var pathExist:Boolean = false;
			
			//проверить свободна ли указанная клетка
			function cellIsEmpty(cellX:int, cellY:int):Boolean 
			{
				//если клетка входит в пространство поля и если она пустая, возвращем true
				//иначе - false
				if (cellX >= 0 && cellX < mapW && cellY >= 0 && cellY < mapH)
				{
					if (mapClone[cellY][cellX] == emptyCell) return true;
				}
				return false
			}
			
			//выполнять поиск до тех пор, пока есть куда двигаться на поле
			while(checkCells.length)
			{
				//берём первую клетку и проверяем её соседние клетки на пустоту,
				//если соседняя клетка свободна, значит заносим ту клетку в очередь на поиск уже относительно её.
				var x:int = checkCells[0].x;
				var y:int = checkCells[0].y;
				var pointForCheck:Point;
				
				//up
				tempX = x;
				tempY = y - 1;
				if (cellIsEmpty(tempX,tempY))
				{
					
					mapClone[tempY][tempX] = new Point(x, y);//from
					pointForCheck = new Point(tempX, tempY);
					checkCells.push(pointForCheck);
					if (endP.equals(pointForCheck))
					{
						pathExist = true;
						break;
					}
					
				}
				
				//down
				tempX = x;
				tempY = y + 1;
				if (cellIsEmpty(tempX,tempY))
				{
					
					mapClone[tempY][tempX] = new Point(x, y);//from
					pointForCheck = new Point(tempX, tempY);
					checkCells.push(pointForCheck);
					if (endP.equals(pointForCheck))
					{
						pathExist = true;
						break;
					}
				}
				
				//right
				tempX = x+1;
				tempY = y;
				if (cellIsEmpty(tempX,tempY))
				{
					
					mapClone[tempY][tempX] = new Point(x, y);//from
					pointForCheck = new Point(tempX, tempY);
					checkCells.push(pointForCheck);
					if (endP.equals(pointForCheck))
					{
						pathExist = true;
						break;
					}
				}
				
				//left
				tempX = x-1;
				tempY = y;
				if (cellIsEmpty(tempX,tempY))
				{
					
					mapClone[tempY][tempX] = new Point(x, y);//from
					pointForCheck = new Point(tempX, tempY);
					checkCells.push(pointForCheck);
					if (endP.equals(pointForCheck))
					{
						pathExist = true;
						break;
					}
				}
				
				//-------------------------
				checkCells.splice(0, 1);
				//trace(checkCells.length)
			}
			
			//если путь найдет, но вернуть этот путь.
			if (pathExist) 
			{
				var path:Array = [mapClone[endP.y][endP.x]];
				var p:Point;
				while (true)
				{
					p = path[path.length-1];//from
					if (p.equals(startP))
					{
						path.unshift(endP);
						path.reverse();
						break;
					}else {
						path.push(mapClone[p.y][p.x]);
					}
				}
				//trace("path",path);
				return path;
			}
				
			trace("path no exist")
			return [];
			
		}
		
		
	}

}