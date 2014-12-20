package LightEffect 
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.GradientType;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.filters.BlurFilter;
	import flash.filters.ColorMatrixFilter;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	/**
	 * ...
	 * @author Samana
	 */
	public class Light extends Sprite 
	{
		//PUBLIC
		/**
		 * Прозрачность каждой тени. Если меньше единицы, то возникает эффект наложения теней, 
		 * что более реалистично, но больше идёт просчёт.
		 */
		public var shadowAlpha:Number = 1;
		
		//   PRIVATE
		
		//массив для ТеневыхОбъктов
		private var shadowObjects:Vector.<ShadowObject> = new Vector.<ShadowObject>();
		//шейп в котором будут рисоваться векторные тени
		private var holder:Shape = new Shape();
		//прямоугольная область вокруг света. 
		//Все рёбра ТеневыхОбъектов, попавшие в этот прямоугольник, будут "отбрасывать тень"
		private var lightRect:Rectangle;
		//длина тени
		private var shadowDistance:Number;
		//растровый свет
		private var bmd:BitmapData;
		private var bm:Bitmap;
		//растровый, круговой градиент с прозрачными краями
		private var bmdSpot:BitmapData;
		//текущая изображение света
		private var currentLightImage:Bitmap;
		//матрица для BitmapData.draw
		private var matrix:Matrix = new Matrix();
		//нулевая точка, помещается в методы, где она нужна, чтобы не создавать каждый раз новую
		private var emptyPoint:Point=new Point();
		//фильтры
		private var cmfAplhaInvert:ColorMatrixFilter = new ColorMatrixFilter([1, 0, 0, 0, 0,  0, 1, 0, 0, 0, 0, 0, 1, 0, 0,	 0, 0, 0, -1, 255]);
		private var blurFilter:BlurFilter=new BlurFilter(0,0,1);
		//радиус света
		private var radius:uint;
		private var halfRadius:uint;
		//качество/размер изображения света, чем меньше, тем хуже, но быстрее просчёт
		private var quality:Number;
		//временные переменные из метода drawVectorShadows
		private var shObj:ShadowObject; // текущий проверяемый ТеневойОбъект
		private var diaplayObject:DisplayObject; // текущий дисплейОбъект, которому принадлежит текущий ТеневойОбъект.
		private var edges:Vector.<Object>; // текущий массив рёбер ТеневогоОбъекта
		private var aLocal:Point; // а точка ребра
		private var bLocal:Point; // b точка ребра
		private var aAngle:Number; // угол от точки а к свету
		private var bAngle:Number; // угол от точки b к свету
		private var aShadow:Point=new Point(); // точка, отбрасываемой тени от точки а
		private var bShadow:Point = new Point(); // точка, отбрасываемой тени от точки b
		private var shadowObjectsLength:int; // длина массива shadowObjects
		private var edgesLength:int; // длина массива рёбер из ТеневогоОбъекта
		private var allDOLength:int; //длина массива дисплейОбъектов ТеневогоОбъекта
		private var i:int; // переменная цикла for
		private var j:int; // переменная цикла for
		private var k:int; // переменная цикла for
		
		
		/**
		 * Создаёт круглый источник света с радиальным градиентом.
		 * @param	radius Радиус света.
		 * @param	colorA Цвет в середине света.
		 * @param	colorB Цвет по краям света.
		 * @param 	shadowAlpha Альфа каждой отдельной тени. При значениях меньше единицы, создаёт красивый эффект наложения теней друг на друга.
		 * Но требует больше времени на просчёт.
		 * @param	quality Качество визуализации света. Можно менять от 0.1 до 1. Чем меньше качество, тем больше видны кубики
		 * растрового изображения света, но намного быстрее просчёт. Компенсировать кубики можно размытием света, методом lightBlur.
		 * @param	shadowDistance Длина теней от объектов.
		 */
		public function Light(radius:uint=200, colorA:uint = 0xFFFFFF, colorB:uint = 0xFFFFFF, shadowAlpha:Number=1, quality:Number=1, shadowDistance:int = 3000)
		{
			if (quality < 0.1) quality = 0.1;
			if (quality > 1) quality = 1;
			this.quality = quality;
			
			if (radius < 10) radius = 10;
			this.radius = radius*quality;
			halfRadius = this.radius / 2;
			
			this.shadowAlpha = shadowAlpha;
			
			
			this.shadowDistance = shadowDistance;
			
			matrix.scale(quality, quality);
			
			lightRect = new Rectangle(0, 0, radius, radius);
			
			//рисую круговой градиент для альфы и цвета света и делаю её растровую копию
			var matrixBox:Matrix = new Matrix();
			matrixBox.createGradientBox(this.radius, this.radius);
			
			var tempShape:Shape = new Shape();
			tempShape.graphics.beginGradientFill(GradientType.RADIAL, [colorA, colorB], [1, 0], [0, 255], matrixBox);
			tempShape.graphics.drawRect(0, 0, this.radius, this.radius);
			tempShape.graphics.endFill();
			
			bmdSpot = new BitmapData(this.radius, this.radius, true, 0x00000000);
			bmdSpot.draw(tempShape);
			
			//изображение радиального градиента
			currentLightImage = new Bitmap();
			//назначаю текущее изображение света, изображение с радиальным градиентом
			currentLightImage.bitmapData = bmdSpot;
			currentLightImage.smoothing = true;
			currentLightImage.scaleX = 1 / quality;
			currentLightImage.scaleY = 1 / quality;
			//чем больше альфа, тем сильнее эффект дымки
			currentLightImage.alpha = 0;
			
			//создаю растровые данные для визуализации света
			bmd = new BitmapData(this.radius,this.radius, true, 0x00000000);
			// в эту битмап будут рисоваться тени
			// так же она служит маской для изображения света (currentLightImage)
			bm = new Bitmap(bmd);
			bm.smoothing = true;
			bm.scaleX = 1 / quality;
			bm.scaleY = 1 / quality;
			
			//addChild(holder);
			//эффект дымки, тени с цветом света
			addChild(currentLightImage);
			//добавляю растрировый свет на сцену
			addChild(bm);
		}
		
		/**
		 * Просчитать все тени и нарисовать свет.
		 */
		public function renderLight():void 
		{
			//если свет не находится на сцене, то прерываю дальнейшие расчёты
			if (parent == null) return;
			
			drawVectorShadows();
			drawRasterLight();
		}
		
		
		/**
		 * Растеризация векторных теней и рисование самого света.
		 */
		private function drawRasterLight():void 
		{
			matrix.tx = -bm.x*quality;
			matrix.ty = -bm.y*quality;
			
			
			bmd.lock();
			
			bmd.fillRect(bmd.rect, 0x00000000);
			bmd.draw(holder, matrix);
			
			bmd.applyFilter(bmd, bmd.rect, emptyPoint, cmfAplhaInvert);
			if (blurFilter.blurX != 0)
			{
				bmd.applyFilter(bmd, bmd.rect, emptyPoint, blurFilter);
			}
			bmd.copyPixels(currentLightImage.bitmapData, currentLightImage.bitmapData.rect, emptyPoint, bmd, emptyPoint);
			
			bmd.unlock();
		}
		
		
		/**
		 * Перебераем все рёбра всех ShadowObject-ов и рисуем от них тени.
		 */
		private function drawVectorShadows():void 
		{
			//отчищаю holder от графики
			holder.graphics.clear();
			
			//запоминаю длину массива с ТеневымиОбъектами
			shadowObjectsLength = shadowObjects.length
			
			//пробегаюсь по всем ТеневымОбъектам
			for (i = 0; i < shadowObjectsLength; i++) 
			{
				//текущий ТеневойОбъект
				shObj = shadowObjects[i];
				
				//пробегаюсь по всем дисплей объектам, которым принадлежит текущий ТеневойОбъект
				allDOLength = shObj.allDO.length;
				for (k = 0; k < allDOLength; k++) 
				{
					//текущий дисплей объект
					diaplayObject = shObj.allDO[k];
					
					//если дисплейОбъект, которому принадлежит ТеневойОбъект не находится на экране,
					//то нет смысла просчитывать тени
					if (diaplayObject.stage == null) continue;
					
					//текущий массив с рёбрами
					edges = shObj.edges;
					
					//запонимаю длину массива рёбер
					edgesLength = edges.length;
					
					//пробегаюсь по всем рёбрам данного ТеневогоОбъекта
					for (j = 0; j < edgesLength; j++) 
					{
						//текущие точки ребра
						aLocal = edges[j].a;
						bLocal = edges[j].b;
						
						//если свет и ТеневойОбъект не в одной системе координат, то
						//перевожу точки ребра в локальые кооринаты Света
						if (parent != diaplayObject)
						{
							aLocal = globalToLocal(diaplayObject.localToGlobal(aLocal));
							bLocal = globalToLocal(diaplayObject.localToGlobal(bLocal));
						}
						
						//если хоть одна из точек ребра, находится в пределах прямоуголькой области света,
						//то рисуем тень от этого ребра. Если точки за пределами света, то переходим к
						//следующему ребру
						if (lightRect.containsPoint(aLocal) || lightRect.containsPoint(bLocal))
						{
							//нахожу углы от точек "a" и "b" к свету
							aAngle = Math.atan2(y - aLocal.y, x - aLocal.x);
							bAngle = Math.atan2(y - bLocal.y, x - bLocal.x);
							
							//нахожу точки, куда отброситься тень
							aShadow.setTo (aLocal.x - Math.cos(aAngle) * shadowDistance, aLocal.y - Math.sin(aAngle) * shadowDistance);
							bShadow.setTo (bLocal.x - Math.cos(bAngle) * shadowDistance, bLocal.y - Math.sin(bAngle) * shadowDistance);
							
							//рисую по этим черытём точкам тень
							with (holder.graphics) 
							{
								beginFill(0,shadowAlpha);
								moveTo(aLocal.x, aLocal.y);
								lineTo(aShadow.x, aShadow.y);
								lineTo(bShadow.x, bShadow.y);
								lineTo(bLocal.x, bLocal.y);
							}
							
						}
						else
						{
							continue;
						}
					}
				}
				
			}
			
		}
		
		
		//добавить ТеневойОбъект в массив
		/**
		 * Добавить ShadowObject в список.
		 * @param	shadowObj Объект ShadowObject, который нужно добавить.
		 */
		public function addShadowObject(shadowObj:ShadowObject):void 
		{
			if (shadowObjects.indexOf(shadowObj) == -1) shadowObjects.push(shadowObj);
		}
		
		
		/**
		 * Удалить ShadowObject из списка.
		 * @param	shadowObj Объект ShadowObject, который нужно удалить.
		 */
		public function removeShadowObject(shadowObj:ShadowObject):void 
		{
			var ind:int = shadowObjects.indexOf(shadowObj);
			if (ind != -1) shadowObjects.splice(ind, 1);
		}
		
		
		/**
		 * Удалить все ShadowObject's, которые были переданы данному источнику света.
		 */
		public function removeAllShadowObjects():void 
		{
			shadowObjects.length = 0;
		}
		
		
		/**
		 * Назначить изображение для света. Если вызвать без параметра,
		 * то изображение смениться на дефолтное (радиальных градиент).
		 * На качество этого изображения влияет свойство quality.
		 * @param	imageBMD БитмапДата изображения. 
		 */
		public function setLightImage(imageBMD:BitmapData=null):void 
		{
			
			if (imageBMD == null)
			{
				currentLightImage.bitmapData = bmdSpot;
			}
			else
			{
				//подгоняю изображение под размер радиуса
				//и создаю новую битмапДату для него
				var sprite:Sprite = new Sprite();
				var bm:Bitmap = new Bitmap(imageBMD);
				bm.smoothing = true;
				bm.width = radius;
				bm.height = radius;
				sprite.addChild(bm);
				
				var bmd:BitmapData = new BitmapData(radius, radius, true, 0x00000000);
				bmd.draw(sprite);
				
				currentLightImage.bitmapData = bmd;
				currentLightImage.smoothing = true;
			}
		}
		
		
		/**
		 * Эффект размытия для света (нативный BlurFilter)
		 * @param	blur Степень размытия
		 * @param	quality Качество размытия. Чем больше, тем дольше просчёт.
		 */
		public function lightBlur(blur:int=2,quality:int=1):void 
		{
			blurFilter.blurX = blur;
			blurFilter.blurY = blur;
			blurFilter.quality = quality;
		}
		
		/**
		 * Освещённость теней.
		 * @param	fog 0 - тени прозрачны, 1 - тени полностью освещены.
		 */
		public function lightFog(fog:Number=0):void 
		{
			currentLightImage.alpha = fog;
		}
		
		//-------------------------------------------------------------
		//						OVERRIDE X, Y, SCALE, ROTATION,
		//-------------------------------------------------------------
		//при изменении x или y, двигаю изображения света (bm), так, чтобы центр изображения
		//был в указаных координатах
		override public function set x(value:Number):void 
		{
			bm.x = value-(halfRadius * (1 / quality));
			currentLightImage.x = bm.x;
			
			lightRect.x = bm.x;
		}
		
		override public function set y(value:Number):void 
		{
			bm.y = value-(halfRadius * (1 / quality));
			currentLightImage.y = bm.y;
			
			lightRect.y = bm.y;
		}
		
		override public function get x():Number 
		{
			return bm.x + halfRadius*(1/quality);  
		}
		
		
		override public function get y():Number 
		{
			return bm.y + halfRadius*(1/quality); 
		}
		
		override public function get scaleX():Number 
		{
			return super.scaleX;
		}
		
		override public function get scaleY():Number 
		{
			return super.scaleY;
		}
		
		override public function get rotation():Number 
		{
			return super.rotation;
		}
		
		override public function set scaleX(value:Number):void 
		{
			// nothing
		}
		
		override public function set scaleY(value:Number):void 
		{
			// nothing
		}
		
		override public function set rotation(value:Number):void 
		{
			// nothing
		}
		
		
	}

}