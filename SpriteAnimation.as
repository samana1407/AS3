package AS3
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.getTimer;
	import flash.utils.Timer;
	
	/**
	 * Проигрывает анимацию из спрайтЛиста.
	 * Необходим xml вида
	 * 		<?xml version="1.0" encoding="UTF-8"?>
			<data imagePath="name Atlas image.png">
			<SubTexture name="nameAnim_000.png"	x="0"	y="0"	width="0"	height="0" frameX="0" frameY="0" frameWidth="0" frameHeight=""/>
	 *		</data>
	 * @author samana
	 * 
	 */
	
	
	
	/**
	 * События при наступлении первого и последнего кадра
	 */
	 [Event(name = "lastFrame", type = "RastrMovieClip")]
	 [Event(name = "firstFrame", type = "RastrMovieClip")]
	 
	public class SpriteAnimation extends Sprite
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
		 * Объект в котором хранятся массивы c набором BitmapData,
		 * для каждой анимации.
		 */
		private static var _animationsBMDs:Object = {};
		
		/**
		 * Объект в котором хранятся массивы с Point, для каждого
		 * отдельного кадра анимации.
		 * Так как кадр может быть разного размера (в зависимости от содержащейся в нём графики),
		 * положение bitmap надо постоянно менять.
		 */
		private static var _animationsPositions:Object = {};
		
		//==============================================
		//			PRIVATE VARS
		//==============================================
		/**
		 * Таймер
		 */
		private var _timer:Timer;
		
		/**
		 * Имя текущей анимации = имя изображения + имя анимации
		 */
		private var _currentAnimation:String;
		
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
		 * Bitmap, которая будет показывать текущий кадр. Добавляется в _holder.
		 * Она двигается по переданным в текстурном алтасе данным
		 */
		private var _bitmap:Bitmap;
		
		/**
		 * Контейнер для _bitmap. 
		 * Необходим для того, чтобы задавать offset текущей анимации.
		 * Ведь _bitmap постоянно меняет своё положение и бывает трудно изначально поместить
		 * анимацию в заданную позицию
		 */
		private var _holder:Sprite;
		
		/**
		 * Объект в который записываются данные о вставки кода в кадр.
		 */
		private var _framesScript:Object;
		
		//==============================================
		//			PUBLIC VARS
		//==============================================
		/**
		 * Включение сглаживания для растра, влияет на производительность.
		 */
		public var smoothing:Boolean = false;
		
		
		/**
		 * @construstor
		 * Создаёт анимацию из спрайт листа.
		 * Для назначения анимации используйте метод setAnimation
		 */
		public function SpriteAnimation()
		{
			_framesScript = { };
			
			_holder = new Sprite();
			_bitmap = new Bitmap();
			
			_holder.addChild(_bitmap);
			addChild(_holder);
			
			_timer = new Timer(1000/30);
			this.fps = 1000/30;
			
			
			
			addEventListener(Event.ADDED_TO_STAGE, addedToStage);
		}
		
		
		//==============================================
		//			PUBLIC METHODS
		//==============================================
		/**
		 * Назначает новую анимацию и переводит её в первый кадр.
		 * ВАЖНО: анимация начнётся с первого кадра! Все предыдущие script на кадрах удаляются.
		 * @param	xmlSpriteSheet - xml (Starling format).
		 * @param 	bitmapAtlas - текстурный атлас.
		 * @param 	nameAnimation - имя анимации из xml.
		 * @param 	autoPlay - начать воспроизведение, по умолчанию отключено.
		 * @param 	fps - скорость кадров в секунду. Если установлен 0, то fps не изменяется.
		 */
		public function setAnimation(xmlSpriteSheet:XML,bitmapAtlas:Bitmap,nameAnimation:String,autoPlay:Boolean=false,fps:int= 0):void
		{
			stop();
			
			// достаю анимацию из атласа, если его кеша ещё нет
			if (_animationsBMDs[xmlSpriteSheet.@imagePath+"_"+nameAnimation] == undefined)
			{
				createRastrMovie(xmlSpriteSheet,bitmapAtlas,nameAnimation);
			}
			//повторная проверка, на случай если анимация не создалась, например передано не верное имя
			if (_animationsBMDs[xmlSpriteSheet.@imagePath+"_"+nameAnimation] == undefined) 
			{
				return;
			}
			
			if (fps > 0) this.fps = fps;
			
			//назначаю имя текущей анимации
			_currentAnimation = xmlSpriteSheet.@imagePath+"_"+nameAnimation;
			
			//передаю приватным переменным ссылки на массивы картинок и их позиций из статических объектов,
			//в которых хранится весь кеш. Так как доступ к приватной переменной быстрее, чем к статической.
			_bitmapDates = _animationsBMDs[xmlSpriteSheet.@imagePath+"_"+nameAnimation];
			_bitmapsPos = _animationsPositions[xmlSpriteSheet.@imagePath+"_"+nameAnimation];
			
			_totalFrames = _bitmapDates.length;
			_currentFrame = 1;
			_framesScript = { };
			
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
		
		/**
		 * Назначить метод на определённый кадр
		 * @param	frame номер кадра на котором сработает метод
		 * @param	method метод
		 * @param	params параметры для метода если нужно
		 * @param	autoRemove автоматическое удаление метода из кадра, после его срабатывания
		 */
		public function addFrameScript(frame:int,method:Function,params:Array=null,autoRemove:Boolean=true):void 
		{
			if (frame > 0 && frame <= totalFrames)
			{
				_framesScript[frame] = { func:method, args:params, removeScript:autoRemove };
			}
			else
			{
				trace(this, "[addFrameScript] неверный номер кадра:",frame );
			}
		}
		
		/**
		 * Удалить метод из кадра
		 * @param	frame номер кадра. Если кадр равен -1, то удалятся все методы на всех кадрах
		 */
		public function removeFrameScript(frame:int=-1):void 
		{
			if (_framesScript[frame] != undefined)
			{
				delete _framesScript[frame];
			}
			
			if (frame == -1) 
			{
				_framesScript = { };
			}
		}
		
		
		//==============================================
		//			STATIC PUBLIC METHODS
		//==============================================
		/**
		 * Удаляет кеш анимации и освобождает память.
		 * @param	movieClipClass - класс мувиклипа, кеш которого надо удалить.
		 */
		public static function clearAmination(xmlSpriteSheet:XML,nameAnimation:String):void
		{
			if (_animationsBMDs[xmlSpriteSheet.@imagePath+"_"+nameAnimation] != undefined)
			{
				var bmdArr:Vector.<BitmapData> = _animationsBMDs[xmlSpriteSheet.@imagePath+"_"+nameAnimation];
				
				while (bmdArr.length)
				{
					bmdArr[0].dispose();
					bmdArr[0] = null;
					bmdArr.shift();
				}
				
				delete _animationsBMDs[xmlSpriteSheet.@imagePath+"_"+nameAnimation];
				delete _animationsPositions[xmlSpriteSheet.@imagePath+"_"+nameAnimation];
			}
			
			trace("Кеш анимации", xmlSpriteSheet.@imagePath, nameAnimation, "был удалён");
		}
		
		
		/**
		 * Удаляет ссылки на все анимации
		 * Но отчистка памяти произойдёт после GC
		 */
		public static function clearAll():void
		{
			_animationsBMDs = { };
			_animationsPositions = { };
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
			if (_animationsBMDs[_currentAnimation] == undefined)
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
			
			//выполняю метод повешаный на кадр если он есть
			var obj:Object = _framesScript[currentFrame];
			
			if (obj) 
			{
				obj.func.apply(this, obj.args);
				//trace("какой-то код в кадре", currentFrame);
				
				if (obj.removeScript)
				{
					delete _framesScript[currentFrame];
					//trace("код в кадре",currentFrame,"был удалён")
				}
			}
			
			
			//events
			if (_currentFrame == _totalFrames) 
			{
				dispatchEvent(new Event(LAST_FRAME));
			}
			
			if (_currentFrame == 1)
			{
				dispatchEvent(new Event(FIRST_FRAME));
			}
		
		}
		
		
		/**
		 * Перевод мувиклипа в растр.
		 * @param	movieClipClass - класс мувиклипа, который нужно перевести в растр.
		 */
		private function createRastrMovie(xmlSpriteSheet:XML,bitmapAtlas:Bitmap,nameAnimation:String):void
		{
			var time:Number = getTimer();
			trace(this,"создание растра для", nameAnimation, "...");
			
			
			//временное хранилищце для битмапДат и позиций
			var bmdVec:Vector.<BitmapData> = new Vector.<BitmapData>();
			var bmPos:Vector.<Point> = new Vector.<Point>();
			
			var findName:String = nameAnimation;
			
			//счётчик копий битмапДат, напрмер кадры 1,3 и 5,6 одинаковы - две копии не создадутся
			var equalsBMD:int = 0;
			
			//номер ноды в xml с которой начинается данная анимация.
			//Нужно для правильного вывода trace - какие кадры совпадают по графике 
			var startNumberInXml:int=-1;
			
			for (var i:int = 0; i < xmlSpriteSheet.*.length(); i++) 
			{
				//узнаю текущее имя
				var currentName:String = xmlSpriteSheet.SubTexture[i].@name;
				//нахожу ноду в которой совпадет искаемое имя
				if (currentName.slice(0, currentName.lastIndexOf("_")) == findName)
				{
					if (startNumberInXml == -1)
					{
						startNumberInXml = i;
					}
					
					var x:int = xmlSpriteSheet.SubTexture[i].@x;
					var y:int = xmlSpriteSheet.SubTexture[i].@y;
					var w:int = xmlSpriteSheet.SubTexture[i].@width;
					var h:int = xmlSpriteSheet.SubTexture[i].@height;
					
					var bmd:BitmapData = new BitmapData(w, h, true, 0x00000000);
					bmd.copyPixels(bitmapAtlas.bitmapData, new Rectangle(x, y, w, h), new Point());
					
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
							//trace(nameAnimation,"кадр:", i+1-startNumberInXml, "такой же как кадр:", j + 1)
							bmd = bmdVec[j];
							equalsBMD++;
							break;
						}
					}
					
					bmdVec.push(bmd);
					//-------------------------
					var offsetX:int = xmlSpriteSheet.SubTexture[i].@frameX;
					var offsetY:int = xmlSpriteSheet.SubTexture[i].@frameY;
					
					bmPos.push(new Point(offsetX, offsetY));
					
					
				}
			}
			
			if (equalsBMD>0) 
			{
				trace(this,nameAnimation, "не создавалось одинаковых bitmapData:", equalsBMD);
			}
			
			if (bmdVec.length==0) 
			{
				trace(this, "анимации с именем:", nameAnimation, "не существует в xml для", currentName);
				return;
			}
			
			
			// КОГДА все кадры отрендерены, сохраняю кеш в статических словарях.
			
			//помещаю набор битмапДат отрендеренного мувика - в статический словарь для картинок
			//и так же помещаю набор координат для каждого кадра мувика - в статичечкий словарь для позиций
			_animationsBMDs[xmlSpriteSheet.@imagePath+"_"+nameAnimation] = bmdVec;
			_animationsPositions[xmlSpriteSheet.@imagePath+"_"+nameAnimation] = bmPos;
			
			trace(this,"создан новый растр для", nameAnimation, "(время создания", (getTimer()-time)/1000, "секунд(ы))" );
		}
		
		/**
		 * Смещение для анимации. Каждый кадр имеет разную позицию, поэтому иногда трудно
		 * установить правильные координаты на общей сцене для этого объекта SpriteAnimation. Например всю анимацию надо сместить так, чтобы первый кадр попадал левым верхним углом в нулевые координаты этого объекта SpriteAnimation.
		 * 
		 * @param	frame  Номер кадра, по которому будет происходить выравнивание
		 * @param	ancoreType  Тип смещения. Варианты "TL","TC","TR","CL","CC","CR","BL","BC","BR".
		 * Что означает: T-top, C-center, B-bottom, L- left, R-right. Например "TL": верхний левый угол.
		 * @param	offsetX Дополнительное смещение по x
		 * @param	offsetY Дополнительное смещение по y
		 */
		
		public function offset(frame:int=1, ancoreType:String="TL",offsetX:Number=0, offsetY:Number=0):void 
		{
			if (frame > 0 && frame <= totalFrames)
			{
				var frameW:int = _bitmapDates[frame-1].width;
				var frameH:int = _bitmapDates[frame-1].height;
				
				var frameX:Number = _bitmapsPos[frame-1].x;
				var frameY:Number = _bitmapsPos[frame-1].y;
				
				switch (ancoreType) 
				{
							// TOP
					case "TL":
						_holder.x = -frameX;
						_holder.y = -frameY;
					break;
					
					case "TC":
						_holder.x = -frameX - (frameW / 2);
						_holder.y = -frameY;
					break;
					
					case "TR":
						_holder.x = -frameX - frameW;
						_holder.y = -frameY;
					break;
							// CENTER
					case "CL":
						_holder.x = -frameX;
						_holder.y = -frameY-(frameH/2);
					break;
					
					case "CC":
						_holder.x = -frameX-(frameW/2);
						_holder.y = -frameY-(frameH/2);
					break;
					
					case "CR":
						_holder.x = -frameX - frameW;
						_holder.y = -frameY - (frameH/2);
					break;
							//BOTTOM
					case "BL":
						_holder.x = -frameX;
						_holder.y = -frameY - frameH;
					break;
					
					case "BC":
						_holder.x = -frameX-(frameW/2);
						_holder.y = -frameY - frameH;
					break;
					
					case "BR":
						_holder.x = -frameX-frameW;
						_holder.y = -frameY - frameH;
					break;
					
					default: trace(this,"[offset] неверное значение для ancoreType")
				}
				
				_holder.x += offsetX;
				_holder.y += offsetY;
				_holder.x = int(_holder.x);
				_holder.y = int(_holder.y);
			}
		}
		
		/**
		 * Сбросить сдвиг по X и Y для анимации, который мог быть задан методом offset
		 */
		public function resetOffset():void 
		{
			_holder.x = 0;
			_holder.y = 0;
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
			//trace(this, _currentAnimation, "был удалён со сцены и остановлен");
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
		public function get currentAnimation():String
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


