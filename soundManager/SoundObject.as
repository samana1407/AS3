package AS3.soundManager
{
	import com.greensock.TweenMax;
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.geom.Point;
	import flash.media.Sound;
	import flash.media.SoundChannel;
	import flash.media.SoundTransform;
	
	/**
	 * ...
	 * @author samana
	 * Не создавайте экземпляр этого класса, создавайте звуки через SoundManager методами getInstance или play
	 * 
	 * Класс для управления конкретным звуком.
	 * 
	 * Звук можно привязать к объекту, тогда громкость и параномирование  будет зависить от положения объекта относительно сцены.
	 * Звук будет слышан в радиусе 400 пиксл от центра сцены.
	 * Центр сцены определяется через root.loaderInfo объекта к которому привязан звук. Так как обычные stageWidth не корректно 
	 * работают в барузере.
	 */
	public class SoundObject
	{
		private var _sound:Sound;
		private var _channel:SoundChannel;
		private var _transform:SoundTransform;
		
		private var _volume:Number = 1;
		private var _loops:int = 0;
		private var _position:Number = 0;
		private var _offset:Number = 0;
		
		private var _isPlaying:Boolean = false;
		private var _isPaused:Boolean = false;
		
		private var _snapObject:DisplayObject;
		private var _snapObjectPoint:Point;
		private var _snapObjectVolume:Number; // значение влияющее на громкость, исходя от дистанции объекта от центра флешки.
		
		private var _swfCenterX:int = 0; // центр флешки
		private var _swfCenterY:int = 0;
		
		internal var _instance:Boolean = false;
		internal var _sManager:SoundManager;
		
		
		
		/**
		 * 
		 * @param	soundClass Класс звука.
		 * @param	snapObject Привязать ли звук к объекту. От этого меняется громкость и стерио.
		 * @param	snapObjectPoint Смещение точки на обьекте, по-умолчанию это будут нулевые координаты.
		 */
		public function SoundObject(soundClass:Sound, snapObject:DisplayObject=null, snapObjectPoint:Point= null)
		{
			_sound = soundClass;
			_transform = new SoundTransform()
			_channel = new SoundChannel();
			_snapObject = snapObject;
			_snapObjectPoint = snapObjectPoint == null? new Point():snapObjectPoint;
			
		}
		
		
		/**
		 * Начать воспроизведение звука. Если был на паузе, то начнёт с того же места. 
		 * @param	loops Кол-во циклов
		 * @param	volumeSound Громкость
		 * @param	offset Смещение звука в миллисекундах
		 */
		public function play(loops:int = 0, volumeSound:Number=1, offset:Number=0):void
		{
			
			if (!_isPlaying && !_isPaused) 
			{
				
				_loops = loops;
				_offset = offset;
				volume = volumeSound;
				
				if (_snapObject!=null) 
				{
					_transform.volume = 0;
					_channel.soundTransform = _transform;
					volumeFromObjectOn();
				}
				
				_channel = _sound.play(_offset, 0, _transform);
				_channel.addEventListener(Event.SOUND_COMPLETE, channel_soundComplete);
				
				_isPlaying = true;
				//trace("play")
			}
			
			if (_isPaused) 
			{
				resume();
				//trace("resume from Play")
			}
			
		}
		
		/**
		 * Поставить звук на паузу
		 */
		public function pause():void
		{
			if (_isPlaying) 
			{
				_position = _channel.position;
				_channel.stop();
				_isPlaying = false;
				_isPaused = true;
				volumeFromObjectOff();
				//trace("pause")
			}
		}
		
		
		/**
		 * Остановить звук
		 */
		public function stop():void
		{
			_isPaused = false;
			_isPlaying = false;
			_loops = 0;
			_channel.stop();
			_position = 0;
			
			volumeFromObjectOff();
			//trace("stop")
		}
		
		/**
		 * Изменить плавно громкость.
		 * @param	value значение нужной громкости
		 * @param	fadeTime время изменения громности 
		 * @param	autoStop автовыключение звука после достижения заданной громности. Используется чаще при затухании.
		 */
		public function volumeFade(value:Number=1, fadeTime:Number=1, autoStop:Boolean=false):void 
		{
			if (autoStop) TweenMax.to(this, fadeTime, { volume:value, onComplete:stop } );
			else TweenMax.to(this, fadeTime, { volume:value} );
		}
		
		/**
		 * Уничтожить звук. Данный звук полностью останавливается удаляется из менеджераЗвуков.
		 * Если на этот звук была внешняя ссылка, то её желательно удалить.
		 */
		public function destroy():void 
		{
			TweenMax.killTweensOf(this);
			
			stop();
			volumeFromObjectOff();
			_snapObject = null;
			_sManager.removeInstance(this);
		}
		
		
		//==============================================
		//			PRIVATE
		//==============================================
		/**
		 * Восстановить проигрывание, если оно было на паузе
		 */
		internal function resume():void
		{
			if (_isPaused) 
			{
				_isPaused = false;
				_isPlaying = true;
				
				_channel = _sound.play(_position, 0, _transform);
				_channel.addEventListener(Event.SOUND_COMPLETE, channel_soundComplete);
				volumeFromObjectOn();
				//trace("resume")
			}
		}
		
		/**
		 * Когда звук полностью проиграл, то в зависимости от кол-ва заданной цикличности,
		 * запустить звук заново, либо остановить его.
		 * @param	e 
		 */
		private function channel_soundComplete(e:Event):void
		{
			if (--_loops>0) 
			{
				volumeFromObjectOn();
				_channel = _sound.play(_offset, 0, _transform);
				_channel.addEventListener(Event.SOUND_COMPLETE, channel_soundComplete);
				//trace("next loop")
			}
			else
			{
				_loops = 0;
				_isPlaying = false;
				_isPaused = false;
				
				_sManager.mySoundComplete(this);
				volumeFromObjectOff();
				//trace("complete")
			}
		}
		
		//==============================================
		//			VOLUME FROM OBJECT
		//==============================================
		/**
		 * Подписаться на ентерФрейм, чтобы менять громкость и параномирование
		 * если звук привязан к объекту
		 */
		private function volumeFromObjectOn():void 
		{
			if (_snapObject!=null) 
			{
				_snapObject.addEventListener(Event.ENTER_FRAME, snapObject_enterFrame);
				_swfCenterX = _snapObject.root.loaderInfo.width * 0.5;
				_swfCenterY = _snapObject.root.loaderInfo.height * 0.5;
			}
		}
		
		/**
		 * Остановить ентерФрейм, если звук привязан к объекту
		 */
		private function volumeFromObjectOff():void 
		{
			if (_snapObject!=null) 
			{
				_snapObject.removeEventListener(Event.ENTER_FRAME, snapObject_enterFrame);
			}
		}
		
		/**
		 * Меняет громкость и параномирование звука каждый кадр, если звук привязан к объекту.
		 * И останавливает звук, если объект не находится на сцене.
		 * @param	e
		 */
		private function snapObject_enterFrame(e:Event=null):void 
		{
			if (_snapObject.stage != null) 
			{
				var globalPoint:Point = _snapObject.localToGlobal(_snapObjectPoint);
				
				var dx:Number =_swfCenterX - globalPoint.x;
				var dy:Number = _swfCenterY - globalPoint.y;
				var dist:Number = Math.sqrt(dx * dx + dy * dy);
				
				if (dist<400) 
				{
					_snapObjectVolume=(1 - (dist * (1 / 400)))
					//trace(_snapObjectVolume);
					//trace((dx * (1 / 300)));
					_transform.volume = (_volume * _snapObjectVolume) * _sManager.volume;
					_transform.pan = (dx * (1 / 400));
					_channel.soundTransform = _transform;
				}
				else
				{
					_transform.volume = 0;
					_channel.soundTransform = _transform;
				}
			}
			else
			{
				volumeFromObjectOff();
			}
			
			//trace("ee")
			
		}
		//==============================================
		//			GETTERS SETTERS
		//==============================================
		/**
		 * Личная громность, зависит от громности менеджера и
		 * от объекта, если звук к нему привязан.
		 */
		public function get volume():Number 
		{
			return _volume;
		}
		
		public function set volume(value:Number):void 
		{
			_volume = value;
			_transform.volume = _volume * _sManager.volume;
			_channel.soundTransform = _transform;
			
		}
	
	}

}