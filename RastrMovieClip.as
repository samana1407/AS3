package AS3
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.GraphicsBitmapFill;
	import flash.display.IGraphicsData;
	import flash.display.MovieClip;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	import flash.utils.getTimer;
	import flash.utils.Timer;
	
	/**
	 * Растеризует мувиклип в набор картинок.
	 *
	 * @author samana
	 * 
	 * @update 13.06.14
	 * 			-> Теперь в конструктор по умолчанию не обязательно передавать параметр.
	 * 			-> Переопределены методы с манипуляциями потомков. Чтобы _bitmap оставался неизменным.
	 * 			-> Созданы метатеги для событий.
	 * 			-> Оптимизация поиска одинаковых кадров. (515)
	 * 			-> Блокировка запуска анимации, если кадров меньше чем 2.
	 *			-> Добавлен параметр autoPlay:Boolean в метод setAnimation(), позволяющий начать воспроизведение сразу, после смены анимации.
	 * 			
	 * @update 22.11.14
	 * 			-> Добавлена возможность менять fps в том числе и на ходу. 
	 * 			-> Вместо enterFrame используется Timer.
	 * 			-> Если во Flash IDE создан мувиклип в котором сиквенция из картинок (в каждом кадре одна картинка),
	 * 			   	то нет смысла дополнительно делать снимок draw при растеризации этого мувика. 
	 * 				Поэтому можно установить параметр cloneRastr в true (у методов setAnimation или в конструкторе).
	 * 				В таком случае из каждого кадра вытаскивается битмапДата (для того, чтобы bitmap в кадре не превратился в Shape, ему нужно назначить имя класса в библиотеке) 
	 * 				и заносится в массив с растеризованными классами-мувиками.
	 * 					p.s. Такая ситуация возникает, когда анимацию сложно или невозможно сделать во Flash IDE
	 * 					и она делается в другой программе. После чего экспортируется в набор картинок.
	 * 					Затем этот набор картинок импортируется во Flash в Movieclip и экспортируется уже как SWC файл.
	 */
	
	
	
	/**
	 * События при наступлении первого и последнего кадра
	 */
	 [Event(name = "lastFrame", type = "RastrMovieClip")]
	 [Event(name = "firstFrame", type = "RastrMovieClip")]
	 
	public class RastrMovieClip extends Sprite
	{
		/**
		 * Константы для событий первого и последнего кадров.
		 */
		static public const LAST_FRAME:String = "lastFrame";
		static public const FIRST_FRAME:String = "firstFrame";
		
		//==============================================
		//			STATIC PRIVATE
		//==============================================
		/**
		 * Словарь в котором хранятся массивы c набором BitmapData,
		 * для  каждого класса мувиклипа, который был переведён в растр.
		 */
		private static var _movieClipClasses:Dictionary = new Dictionary();
		
		/**
		 * Словарь в котором хранятся массивы с Point, для каждого
		 * отдельного кадра мувиклипа, который был переведён в растр.
		 * Так как кадр может быть разного размера (в зависимости от содержащейся в нём графики),
		 * положение bitmap надо постоянно менять.
		 */
		private static var _movieClipPositions:Dictionary = new Dictionary();
		
		//==============================================
		//			PRIVATE VARS
		//==============================================
		/**
		 * Таймер
		 */
		private var _timer:Timer;
		
		/**
		 * Имя класса текущего, кешированного мувиклипа.
		 */
		private var _currentAnimation:Class;
		
		//-------------------------
		//-------------------------
		/**
		 * Массив с BitmapData для каждого кадра
		 */
		private var _bitmapDates:Vector.<BitmapData>;
		
		/**
		 * Массив позиций для каждого кадра
		 */
		private var _bitmapsPos:Vector.<Point>;
		
		//-------------------------
		//-------------------------
		
		/**
		 * Кол-во кадров анимации.
		 */
		private var _totalFrames:int;
		
		/**
		 * Текущий кадр.
		 */
		private var _currentFrame:int = 1;
		
		/**
		 * Проигрывается ли анимация в данный момент.
		 */
		private var _isPlay:Boolean = false;
		
		/**
		 * Зацикленность анимации, по умолчанию - зациклена.
		 */
		private var _isLoop:Boolean = true;
		
		//-------------------------
		//-------------------------
		
		/**
		 * Bitmap, которая будет показывать текущий кадр. Добавляется в отображение.
		 */
		private var _bitmap:Bitmap;
		
		//==============================================
		//			PUBLIC VARS
		//==============================================
		/**
		 * Включение сглаживания для растра, влияет на производительность.
		 */
		public var smoothing:Boolean = false;
		
		
		/**
		 * @construstor
		 *
		 * @param	movieClipClass - класс мувиклипа, который нужно перевести в растр.
		 * @param 	fps - кол-во кадров в секунду.
		 * @param	cloneRastr - просто вытащить растр из каждого кадра.
		 */
		public function RastrMovieClip(movieClipClass:Class=null, fps:uint=30, cloneRastr:Boolean=false)
		{
			_bitmap = new Bitmap();
			addChild(_bitmap);
			
			_timer = new Timer(1000/fps);
			this.fps = fps;
			
			if (movieClipClass) setAnimation(movieClipClass,false,fps,cloneRastr);
			
			addEventListener(Event.ADDED_TO_STAGE, addedToStage);
		}
		
		
		//==============================================
		//			PUBLIC METHODS
		//==============================================
		/**
		 * Назначает новую анимацию и переводит её в первый кадр.
		 * ВАЖНО: анимация начнётся с первого кадра!
		 * @param	movieClipClass - имя класса мувиклипа.
		 * @param 	autoPlay - начать воспроизведение, по умолчанию отключено.
		 * @param 	fps - скорость кадров в секунду. Если установлен 0, то fps не изменяется.
		 * @param 	cloneRastr - просто вытащить растр из каждого кадра.
		 */
		public function setAnimation(movieClipClass:Class,autoPlay:Boolean=false,fps:int= 0, cloneRastr:Boolean=false):void
		{
			stop();
			
			if (fps > 0) this.fps = fps;
			
			// растеризую мувик, если его кеша ещё нет
			if (_movieClipClasses[movieClipClass] == undefined)
			{
				if (cloneRastr==false) createRastrMovie(movieClipClass);
				else cloneRastrFromMovie(movieClipClass);
			}
			
			//назначаю имя текущей анимации
			_currentAnimation = movieClipClass;
			
			//передаю приватным переменным ссылки на массивы картинок и их позиций из статических словарей
			//в которых хранится весь кеш. Так как доступ к приватной переменной быстрее, чем к статической.
			_bitmapDates = _movieClipClasses[movieClipClass];
			_bitmapsPos = _movieClipPositions[movieClipClass];
			
			_totalFrames = _bitmapDates.length;
			_currentFrame = 1;
			
			//показать картинку кадра
			_bitmap.bitmapData = _bitmapDates[_currentFrame - 1];
			_bitmap.x = _bitmapsPos[_currentFrame - 1].x;
			_bitmap.y = _bitmapsPos[_currentFrame - 1].y;
			
			//если надо, то запуситить анимацию.
			if (autoPlay) play();
		}
		
		/**
		 * Возвращает битмапДату текущего кадра
		 * @return БитмапДата не клонированная
		 */
		public function currentFrameBMD():BitmapData 
		{
			return _bitmap.bitmapData;
		}
		
		
		/**
		 * Проигрывание анимации
		 * @param	loop - зацикленность анимации
		 */
		public function play(loop:Boolean = true):void
		{
			stop();
			
			//если кадр всего один, или кеш был удалён _totalFrames=0,
			//то анимацию не запусткаю.
			if (_totalFrames < 2) return;
			
			_isPlay = true;
			_isLoop = loop;
			//addEventListener(Event.ENTER_FRAME, enterFramePlay);
			_timer.addEventListener(TimerEvent.TIMER, enterFramePlay);
			_timer.start();
		}
		
		
		/**
		 * Обратное проигрывание анимации.
		 * @param	loop - зацикленность анимации.
		 */
		public function playRevers(loop:Boolean = true):void
		{
			stop();
			
			//если кадр всего один, или кеш был удалён _totalFrames=0,
			//то анимацию не запусткаю.
			if (_totalFrames < 2) return;
			
			_isPlay = true;
			_isLoop = loop;
			//addEventListener(Event.ENTER_FRAME, enterFrameRevers);
			_timer.addEventListener(TimerEvent.TIMER, enterFrameRevers);
			_timer.start();
		}
		
		
		/**
		 * Остановка анимации.
		 */
		public function stop():void
		{
			_isPlay = false;
			
			if (hasEventListener(Event.ENTER_FRAME))
			{
				removeEventListener(Event.ENTER_FRAME, enterFramePlay);
				removeEventListener(Event.ENTER_FRAME, enterFrameRevers);
			}
			
			_timer.stop();
			_timer.removeEventListener(TimerEvent.TIMER, enterFramePlay);
			_timer.removeEventListener(TimerEvent.TIMER, enterFrameRevers);
		}
		
		
		//==============================================
		//			GO TO AND PLAY or STOP
		//==============================================
		/**
		 * Проигрывание анимации с определённого кадра.
		 *
		 * @param	frame - номер кадра с которого нужно начать воспроизведение.
		 * @param	loop - зацикленность для воспроизведения.
		 */
		public function gotoAndPlay(frame:int, loop:Boolean = true):void
		{
			_currentFrame = frame;
			play(loop);
		}
		
		
		/**
		 * Проигрывание анимации в обратном порядке с определённого кадра.
		 *
		 * @param	frame - номер кадра с которого нужно начать обратное воспроизведение.
		 * @param	loop - зацикленность для воспроизведения.
		 */
		public function gotoAndPlayRevers(frame:int, loop:Boolean = true):void
		{
			_currentFrame = frame;
			playRevers(loop);
		}
		
		
		/**
		 * Переход на выбранный кадр и остановка анимации.
		 * @param	frame - номер кадра.
		 */
		public function gotoAndStop(frame:int):void
		{
			_currentFrame = frame;
			stop();
			showFrame();
		}
		
		
		/**
		 * Переход на следующий кадр.
		 */
		public function nextFrame():void
		{
			_currentFrame++;
			showFrame();
			//trace("next");
		}
		
		
		/**
		 * Переход на предыдущий кадр.
		 */
		public function prevFrame():void
		{
			_currentFrame--;
			showFrame();
			//trace("prev");
		}
		
		
		//==============================================
		//			STATIC PUBLIC METHODS
		//==============================================
		/**
		 * Удаляет кеш мувиклипа и освобождает память.
		 * @param	movieClipClass - класс мувиклипа, кеш которого надо удалить.
		 */
		public static function clearAmination(movieClipClass:Class):void
		{
			if (_movieClipClasses[movieClipClass] != undefined)
			{
				var bmdArr:Vector.<BitmapData> = _movieClipClasses[movieClipClass];
				
				while (bmdArr.length)
				{
					bmdArr[0].dispose();
					bmdArr[0] = null;
					bmdArr.shift();
				}
				
				delete _movieClipClasses[movieClipClass];
				delete _movieClipPositions[movieClipClass];
			}
			
			trace("Кеш мувиклипа", movieClipClass, "был удалён");
		}
		
		
		/**
		 * Удаляет кеш всех мувиклипов
		 */
		public static function clearAll():void
		{
			for (var name:Object in _movieClipClasses)
			{
				clearAmination(name as Class);
			}
		}
		
		
		//==============================================
		//			PRIVATE METHODS
		//==============================================
		/**
		 * Проигрывание анимации вперёд.
		 * @param	e - Event
		 */
		private function enterFramePlay(e:TimerEvent):void
		{
			//trace("plays");
			_currentFrame++;
			showFrame();
		}
		
		
		/**
		 * Проигрывание анимации назад.
		 * @param	e - Event
		 */
		private function enterFrameRevers(e:TimerEvent):void
		{
			//trace("playsRevers");
			_currentFrame--;
			showFrame();
		}
		
		
		/**
		 * Корректирует номер кадра, если его число вышло за пределы в обе стороны.
		 * Назначает нужную BitmapData для текущего кадра.
		 * Рассылает события в первом и последнем кадре.
		 */
		private function showFrame():void
		{
			// если кадр больше общего кол-ва кадров
			if (_currentFrame > _totalFrames)
			{
				// если loop то начинаем сначала
				if (_isLoop)
				{
					_currentFrame = 1;
				}
				else
				{
					// иначе останавливаемя в конце
					_currentFrame = _totalFrames;
					stop();
				}
			}
			
			// если кадр меньше чем 1, то
			if (_currentFrame < 1)
			{
				// если цикл включён - переходим на последний кадр
				if (_isLoop)
				{
					_currentFrame = _totalFrames;
				}
				// иначе переходим на первый кадр и останавливаемся.
				else
				{
					_currentFrame = 1;
					stop();
				}
				
			}
			
			//если вдруг кеш был удалён, то обнуляем все приватные массивы и 
			//останавливаем анимацию.
			if (_movieClipClasses[_currentAnimation] == undefined)
			{
				trace(this, "остановлен. Кеш для", currentAnimation, "не существует.");
				stop();
				_totalFrames = 0;
				_currentFrame = 0;
				_currentAnimation = null;
				_bitmap.bitmapData = null;
				_bitmapDates = null;
				_bitmapsPos = null;
				return;
			}
			
			//назначаю битмапДату текущего кадра
			_bitmap.bitmapData = _bitmapDates[_currentFrame - 1];
			_bitmap.x = _bitmapsPos[_currentFrame - 1].x;
			_bitmap.y = _bitmapsPos[_currentFrame - 1].y;
			
			_bitmap.smoothing = smoothing;
			
			//events
			if (_currentFrame == _totalFrames) 
			{
				dispatchEvent(new Event(LAST_FRAME));
			}
			
			if (_currentFrame == 1)
			{
				dispatchEvent(new Event(FIRST_FRAME));
			}
		
			//посмотреть границы клипа
			//graphics.clear();
			//var r:Rectangle = getBounds(this);
			//graphics.lineStyle(1, 0x0000FF);
			//graphics.drawRect(r.x, r.y, r.width, r.height);
		}
		
		/**
		 * Для чего этот метод, можно посмотреть в описании @update 22.11.14 данного класса.
		 * 
		 * В каждом кадре берёт первый объект и вытаскивает из него bitmapData,
		 * после чего сохраняет эту её в массив, а так же сохраняет 
		 * позицию данного объекта.
		 * @param	movieClipClass - класс мувиклипа
		 */
		private function cloneRastrFromMovie(movieClipClass:Class):void 
		{
			var time:Number = getTimer();
			trace("создание клона растра для", movieClipClass, "...");
			
			var mc:MovieClip = new movieClipClass() as MovieClip;
			mc.stop();
			
			//временное хранилищце для битмапДат и позиций
			var bmdVec:Vector.<BitmapData> = new Vector.<BitmapData>();
			var bmPos:Vector.<Point> = new Vector.<Point>();
			
			for (var i:int = 0; i < mc.totalFrames; i++) 
			{
				//var data:Vector.<IGraphicsData> = (mc.getChildAt(0) as Shape).graphics.readGraphicsData(true);
				//var bmdFill:GraphicsBitmapFill = data[0] as GraphicsBitmapFill;
				//trace(bmdFill.bitmapData.width)
				
				//bmdVec[i] = bmdFill.bitmapData;
				bmdVec[i] = (mc.getChildAt(0) as Bitmap).bitmapData;
				bmPos[i] = new Point((mc.getChildAt(0) as Bitmap).x, (mc.getChildAt(0) as Bitmap).y);
				
				
				mc.nextFrame();
			}
			
			_movieClipClasses[movieClipClass] = bmdVec;
			_movieClipPositions[movieClipClass] = bmPos;
			
			trace("создан новый клон растр для", movieClipClass, "(время создания", (getTimer() - time) / 1000, "секунд(ы))" );
			
		}
		
		
		/**
		 * Перевод мувиклипа в растр.
		 * @param	movieClipClass - класс мувиклипа, который нужно перевести в растр.
		 */
		private function createRastrMovie(movieClipClass:Class):void
		{
			var time:Number = getTimer();
			trace("создание растра для", movieClipClass, "...");
			
			
			//прозрачная битмапДата 1х1 для пустых кадров.
			var _emptyBMD:BitmapData = new BitmapData(1, 1, true, 0x00000000);
			
			//мувик который будем рендерить
			var mc:MovieClip = new movieClipClass() as MovieClip;
			mc.stop();
			
			//временное хранилищце для битмапДат и позиций
			var bmdVec:Vector.<BitmapData> = new Vector.<BitmapData>();
			var bmPos:Vector.<Point> = new Vector.<Point>();
			
			// ЦИКЛ равен кол-ву кадров 
			for (var i:int = 0; i < mc.totalFrames; i++)
			{
				//переходим по кадрам мувиклипа
				mc.gotoAndStop(i + 1);
				
				// РЕНДЕР КАДРА
				//значение на которое увеличится прямоугольник если вдруг там фильтр
				var offset:int = 100;
				
				//определяю прямоугольную область в которой расположен мувик в данном его кадре. 
				var rect:Rectangle = mc.getBounds(mc);
				
				//битмапДата для кадра
				var bmd:BitmapData;
				
				//если графики меньше чем пиксель или кадр пустой, то
				//передаём битмапДате - однопиксельную, заранее созданную битмапДату
				if (rect.width < 1 || rect.height < 1)
					bmd = _emptyBMD;
				//но если графика в кадре есть, то начинаем сдедующее.. 
				else
				{
					// увеличиваю прямоугольник (вдруг там фильтры)
					rect.x -= offset;
					rect.y -= offset;
					rect.width += offset * 2;
					rect.height += offset * 2;
					
					rect.x = int(rect.x);
					rect.y = int(rect.y);
					rect.width = int(rect.width);
					rect.height = int(rect.height);
					
					//рисую содержимое кадра
					bmd = new BitmapData(rect.width, rect.height, true, 0x00000000);
					bmd.draw(mc, new Matrix(1, 0, 0, 1, -rect.x, -rect.y));
					
					//нахожу область, где есть цвета (так как до этого была отрендерена область больше нужной)
					var rectColor:Rectangle = bmd.getColorBoundsRect(0xFFFFFFFF, 0x00000000, false);
					rectColor.x = int(rectColor.x);
					rectColor.y = int(rectColor.y);
					rectColor.width = int(rectColor.width);
					rectColor.height = int(rectColor.height);
					
					//если там были фильры, то возможно всё размыто в ноль,
					//либо все объекты в кадре полностью прозрачны.
					//Поэтому прямоугольная область снова может стать нулевой,
					//и если это так, то передаю пустую битмапДату
					if (rectColor.width < 1 || rectColor.height < 1)
					{
						bmd = _emptyBMD;
					}
					//а если содержимое всё же осталось, то
					else
					{
						
						//создаю новую битмапДату уже нужного размера
						var bmdFix:BitmapData = new BitmapData(rectColor.width, rectColor.height, true, 0x00000000);
						// копирую в неё графику кадра
						bmdFix.copyPixels(bmd, rectColor, new Point());
						
						bmd.dispose();
						bmd = null;
						bmd = bmdFix.clone();
						
						bmdFix.dispose();
						bmdFix = null;
						
						//корректирую положение прямоугольной области (положение для битмапы на сцене)
						rect.x += rectColor.x;
						rect.y += rectColor.y;
					}
					
				} // РЕНДЕР КАДРА конец
				
				//создаю временную позицию для положение битмапы текущего кадра на сцене
				var positionPoint:Point = new Point(rect.x, rect.y);
				
				//------------------------------------------------------------------------------------------
				//найти такую же битмапдату (если кадры не оличаются)
				//и передать на неё ссылку (чтобы не создавать одинаковых данных)
				var bmdV:BitmapData;
				var bmdVec_length:int = bmdVec.length
				
				for (var j:int = 0; j < bmdVec_length; j++)
				{
					bmdV = bmdVec[j];
					//если битмапДаты не отличаются
					if (bmd.width == bmdV.width && bmd.height == bmdV.height && bmd.compare(bmdV) == 0)
					{
						//trace("кадр:", i + 1, "такой же как кадр:", j + 1)
						bmd = bmdVec[j];
						positionPoint = bmPos[j];
						break;
					}
				}
				//------------------------------------------------------------------------------------------
				
				//заношу в массив отрендеренный кадр
				bmdVec[i] = bmd;
				//и в другой массив заношу координаты для битмапы этого кадра
				bmPos[i] = positionPoint;
				
				//------------------------------------------------------------------------------------------
				//перебрать все вложенные мувики и передвинуть их анимацию вперёд,
				//Делается это уже после рендера кадра, чтобы не пропустить первый кадр любого вложенного ребёнка.
				//А если этот ребёнок встретится и на следующем кадре, то его анимация уже перейдёт на кадр вперёд, то что и надо.
				nextFrameChildren(mc);
				
				//локалный метод. Поиск всех детей в текущем кадре мувиклипа.
				//Если среди них есть мувиклип, то переводим его анимацию на кадр вперёд (loop)
				function nextFrameChildren(obj:DisplayObject):void
				{
					if (obj is MovieClip)
					{
						var mclip:MovieClip = obj as MovieClip;
						
						for (var k:int = 0; k < mclip.numChildren; k++)
						{
							if (mclip.getChildAt(k) is MovieClip)
							{
								var mcChild:MovieClip = mclip.getChildAt(k) as MovieClip;
								
								if (mcChild.currentFrame == mcChild.totalFrames)
									mcChild.gotoAndStop(1);
								else
									mcChild.nextFrame();
								
								nextFrameChildren(mcChild);
							}
						}
					}
				}
				//------------------------------------------------------------------------------------------
				
			}
			
			// КОГДА все кадры отрендерены, сохраняю кеш в статических словарях.
			
			//помещаю набор битмапДат отрендеренного мувика - в статический словарь для картинок
			//и так же помещаю набор координат для каждого кадра мувика - в статичечкий словарь для позиций
			_movieClipClasses[movieClipClass] = bmdVec;
			_movieClipPositions[movieClipClass] = bmPos;
			
			trace("создан новый растр для", movieClipClass, "(время создания", (getTimer()-time)/1000, "секунд(ы))" );
		}
		
		
		/**
		 * Добавление и удаление со сцены.
		 */
		private function addedToStage(e:Event):void
		{
			addEventListener(Event.REMOVED_FROM_STAGE, removedFromStage);
		}
		
		
		/**
		 * При удалении со сцены, останавливаем проигрывание анимации.
		 */
		private function removedFromStage(e:Event):void
		{
			removeEventListener(Event.REMOVED_FROM_STAGE, removedFromStage);
			stop();
		}
		
		
		//==============================================
		//			GETTERS SETTERS
		//==============================================
		/**
		 * Узнать текущий кадр.
		 */
		public function get currentFrame():int
		{
			return _currentFrame;
		}
		
		
		/**
		 * Узнать кол-во кадров.
		 */
		public function get totalFrames():int
		{
			return _totalFrames;
		}
		
		
		/**
		 * Узнать проигрывается ли в данный момент анимация.
		 */
		public function get isPlay():Boolean
		{
			return _isPlay;
		}
		
		
		/**
		 * Узнать имя класса текущей анимации.
		 */
		public function get currentAnimation():Class
		{
			return _currentAnimation;
		}
		
		/**
		 * Текущий fps узнать/установить
		 */
		public function get fps():int 
		{
			return 1000/_timer.delay;
		}
		
		/**
		 * Текущий fps узнать/установить
		 */
		public function set fps(framePerSecond:int):void 
		{
			if (framePerSecond < 1) return;
			_timer.delay = 1000 / framePerSecond;
		}
		
		
		//==============================================
		//			OVERRIDE CHILDREN METHODS
		//==============================================
		/**
		 * Переопределят все манимипуляции с потомками, чтобы не удлалить
		 * _bitmap, который является главной анимацией
		 */
		
		override public function removeChild(child:DisplayObject):DisplayObject 
		{
			if (child == _bitmap) return null;
			return super.removeChild(child);
		}
		
		override public function removeChildAt(index:int):DisplayObject 
		{
			if (super.getChildAt(index) == _bitmap) return null;
			return super.removeChildAt(index);
		}
		
		//override public function removeChildren(beginIndex:int = 0, endIndex:int = 2147483647):void 
		//{
			//beginIndex = beginIndex == 0?1:1;
			//super.removeChildren(beginIndex, endIndex);
		//}
		
		override public function swapChildren(child1:DisplayObject, child2:DisplayObject):void 
		{
			if (child1 == _bitmap || child2 == _bitmap) return;
			super.swapChildren(child1, child2);
		}
		
		override public function swapChildrenAt(index1:int, index2:int):void 
		{
			if (super.getChildAt(index1) == _bitmap || super.getChildAt(index2) == _bitmap) return;
			super.swapChildrenAt(index1, index2);
		}
		
		override public function addChildAt(child:DisplayObject, index:int):DisplayObject 
		{
			if (index == 0) index=1;
			return super.addChildAt(child, index);
		}
		
		override public function getChildAt(index:int):DisplayObject 
		{
			if (index == 0) return null;
			return super.getChildAt(index);
		}
		
		override public function getChildByName(name:String):DisplayObject 
		{
			if (super.getChildByName(name) == _bitmap) return null;
			return super.getChildByName(name);
		}
		
	}

}


