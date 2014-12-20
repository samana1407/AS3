package  AS3
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.filters.DropShadowFilter;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	/**
	 * ...
	 * @author samana
	 * Разбивает DisplayObject на тайлы и показыает только те части, которые попадают
	 * в заданную прямоугольную область.
	 * Очень полезно, когда в игре большая карта.
	 */
	public class TileSprite extends Sprite 
	{
		private var _screenRect:Rectangle;
		private var _tiles:Array = [];
		private var _tileW:int;
		private var _tileH:int;
		private var _numTilesX:int;
		private var _numTilesY:int;
		
		private var _firstTile:Point = new Point();
		private var _lastTile:Point = new Point();
		
		private var _oldFirstTile:Point = new Point();
		private var _oldLastTile:Point = new Point();
		
		
		public function TileSprite() 
		{
			mouseEnabled = false;
			mouseChildren = false;
		}
		
		/**
		 * Разбить объект на тайлы
		 * @param	obj Объект, который надо разбить на тайлы
		 * @param	tileW Ширина тайла
		 * @param	tileH Высота тайла
		 * @param	screenRect прямоугольная область в которой тайлы будут показываться
		 */
		public function createTiles(obj:DisplayObject, tileW:int, tileH:int, screenRect:Rectangle):void 
		{
			_screenRect = screenRect;
			_tileW = tileW;
			_tileH = tileH;
			_numTilesX = obj.width / tileW;
			_numTilesY = obj.height / tileH;
			
			
			var objRect:Rectangle = obj.getBounds(obj);
			
			var tempBMD:BitmapData = new BitmapData(tileW, tileH, true, 0x00000000);
			var emptyBMD:BitmapData = new BitmapData(1, 1, true, 0x00000000);
			var bm:Bitmap;
			
			_tiles = [];
			// разбиваю объект на тайлы
			for (var i:int = 0; i < objRect.height/tileH; i++) 
			{
				_tiles[i] = [];
				
				for (var j:int = 0; j < objRect.width/tileW; j++) 
				{
					//нахожу положение текущего тайла и отрисовываю его
					var currectDrawRect:Rectangle = new Rectangle(tileW * j, tileH * i, tileW, tileH);
					var matrix:Matrix = new Matrix();
					matrix.tx = -currectDrawRect.x;
					matrix.ty = -currectDrawRect.y;
					
					tempBMD.fillRect(tempBMD.rect, 0x00000000);
					tempBMD.draw(obj, matrix);
					
					//если тайл без графики, то устанавливаю вместо тайла прозрачную картинку 1х1
					var colorRect:Rectangle = tempBMD.getColorBoundsRect(0xFFFFFFFF, 0x00000000, false);
					
					if (colorRect.isEmpty()) 
					{
						bm = new Bitmap(emptyBMD);
						bm.x = tileW * j;
						bm.y = tileH * i;
						//bm.filters=[new DropShadowFilter(2,45,0,1,4,4,1,1,true)]
						//addChild(bm);
					}
					else
					{
						//обрезаю тайл до размеров где содержится графика
						colorRect.x = int(colorRect.x);
						colorRect.y = int(colorRect.y);
						colorRect.width = int(colorRect.width);
						colorRect.height = int(colorRect.height);
						
						var bmd:BitmapData = new BitmapData(colorRect.width, colorRect.height, true, 0x00000000);
						bmd.copyPixels(tempBMD,colorRect,new Point())
						
						bm = new Bitmap(bmd);
						bm.x = tileW * j + colorRect.x;
						bm.y = tileH * i + colorRect.y;
						//bm.filters=[new DropShadowFilter(0,45,0xFF0000,1,4,4,5,1,true)]
						//addChild(bm);
					}
					
					//помещаю тайл в массив
					_tiles[i][j] = bm;
				}
				
			}
		}
		
		
		/**
		 * Обновить видимость тайлов
		 * @param	px позиция экрана по икс
		 * @param	py позиция экрана по игрек
		 */
		public function update(px:int, py:int):void 
		{
			_firstTile.x = int(px / _tileW);
			_firstTile.y = int(py / _tileH);
			
			_lastTile.x= int((px + _screenRect.width) / _tileW);
			_lastTile.y= int((py + _screenRect.height) / _tileH);
			
			if (_firstTile.equals(_oldFirstTile) && _lastTile.equals(_oldLastTile)) return; 
			
			//trace(_firstTile);
			//trace(_lastTile);
			
			removeChildren()
			
			for (var i:int = _firstTile.y; i <= _lastTile.y; i++) 
			{
				for (var j:int = _firstTile.x; j <= _lastTile.x; j++) 
				{
					if (i>=0 && i <_numTilesY && j>=0 && j<_numTilesX) 
					{
						addChild(_tiles[i][j] as DisplayObject);
					}
				}
			}
			
			_oldFirstTile.x = _firstTile.x;
			_oldFirstTile.y = _firstTile.y;
			
			_oldLastTile.x = _lastTile.x;
			_oldLastTile.y = _lastTile.y;
		}
		
	}

}