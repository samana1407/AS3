package soundManager
{
	import com.greensock.TweenMax;
	import flash.automation.KeyboardAutomationAction;
	import flash.display.DisplayObject;
	import flash.events.EventDispatcher;
	import flash.geom.Point;
	import flash.utils.Dictionary;
	import soundManager.SoundObject;
	
	/**
	 * ...
	 * @author samana
	 * Просто менеджер звуков, работает в связке с SoundObject и TweenMax(для плавного управления звука)
	 * 
	 */
	public class SoundManager
	{
		private var _sounds:Dictionary = new Dictionary();
		private var _instances:Array = [];
		
		private var _volume:Number = 1;
		
		
		public function SoundManager()
		{
			
		}
		
		/**
		 * Получить экземпляр звука, для индивидуального контроля
		 * @param	name имя звука, ранее внесённое в менеджер
		 * @return 	объект звука
		 */
		public function getSoundInstance(name:String,snapObject:DisplayObject=null,snapObjectPoint:Point= null):SoundObject
		{
			if (_sounds[name] != undefined)
			{
				var sObject:SoundObject = new SoundObject(_sounds[name],snapObject,snapObjectPoint)
				sObject._instance = true;
				sObject._sManager = this;
				
				_instances.push(sObject)
				return sObject;
			}
			return null;
		}
		
		/**
		 * Добавить звук в список классов
		 * @param	soundClass класс звука
		 * @param	name имя для звука, затем это имя используется для доступа к этому звуку
		 */
		public function add(soundClass:Class, name:String = "untitled"):void
		{
			if (_sounds[name] == undefined)
			{
				_sounds[name] = new soundClass();
			}
			
		}
		
		/**
		 * Включить звук
		 * @param	name имя звука
		 * @param	loop количество повторов
		 * @param	volume громкость
		 * @param 	offset смещение звука в миллисекундах
		 */
		public function play(name:String,loop:int=0,volume:Number=1,offset:Number=0, snapObject:DisplayObject=null,snapObjectPoint:Point= null):void
		{
			if (_sounds[name] != undefined)
			{
				var sObject:SoundObject = new SoundObject(_sounds[name],snapObject,snapObjectPoint);
				_instances.push(sObject);
				
				sObject._sManager = this;
				sObject.play(loop, volume,offset);
				
			}
		}
		
		/**
		 * Поставить все звуки данного менеждера на паузу
		 */
		public function pauseAll():void 
		{
			for (var i:int = 0; i < _instances.length; i++) 
			{
				var sObject:SoundObject = _instances[i];
				sObject.pause();
			}
		}
		
		/**
		 * Включить все звуки, которые были на паузе
		 */
		public function resumeAll():void 
		{
			for (var i:int = 0; i < _instances.length; i++) 
			{
				var sObject:SoundObject = _instances[i];
				sObject.resume();
			}
		}
		
		/**
		 * Остановить все звуки
		 */
		public function stopAll():void 
		{
			for (var i:int = 0; i < _instances.length; i++) 
			{
				var sObject:SoundObject = _instances[i];
				sObject.stop();
			}
		}
		
		
		/**
		 * Плавно изменить громкость
		 * @param	value значение громкости
		 * @param	fadeTime время в секундах
		 * @param	autoStopAll остановить все звуки после манипуляции с громностью
		 */
		public function volumeFade(value:Number=1, fadeTime:Number=1, autoStopAll:Boolean=false):void 
		{
			if(autoStopAll) TweenMax.to(this, fadeTime, { volume:value, onComplete:stopAll } )
			else TweenMax.to(this, fadeTime, { volume:value } );
		}
		
		
		/**
		 * Когда звук заканчивает играть, он вызывает этот метод.
		 * И если этот звук не является контролируемым (не получен методом getInstance), то звук удаляется из списка
		 * @param	sObject
		 */
		internal function mySoundComplete(sObject:SoundObject):void 
		{
			//trace("sManager soundComplete")
			if (sObject._instance==false) 
			{
				var ind:int = _instances.indexOf(sObject);
				_instances.splice(ind, 1);
				//trace("removeInstance")
			}
			//trace("instances", _instances.length)
		}
		
		/**
		 * При срабатывании метода destroy у SoundObject, вызывается этот метод, чтобы удалить звук из списка
		 * @param	sObject
		 */
		internal function removeInstance(sObject:SoundObject):void 
		{
			var ind:int = _instances.indexOf(sObject);
			if (ind!=-1) 
			{
				_instances.splice(ind, 1);
			}
			//trace(_instances.length)
		}
		
		/**
		 * Удалить все инстансы звуков.
		 */
		public function clearAll():void 
		{
			stopAll();
			while (_instances.length) 
			{
				(_instances[0] as SoundObject).destroy();
			}
			
			//trace(_instances.length )
		}
		
		//==============================================
		//			GETTERS SETTERS
		//==============================================
		public function set volume(value:Number):void 
		{
			_volume = value;
			for (var i:int = 0; i < _instances.length; i++) 
			{
				var sObject:SoundObject = _instances[i] as SoundObject;
				sObject.volume = sObject.volume;
			}
		}
		
		public function get volume():Number 
		{
			return _volume;
		}
	
	}

}