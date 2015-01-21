package  AS3.motionPath
{
	import AS3.SMath;
	import flash.display.Loader;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.display.Stage;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.net.FileFilter;
	import flash.net.FileReference;
	import flash.system.System;
	import flash.text.TextField;
	import flash.text.TextFormat;
	
	/**
	 * ...
	 * @author samana
	 * Простой редактор для создания полигональной кривой.
	 * Как использовать:
		 * создать экземпляр данного класса и добавить на сцену.
		 * инструкция по использованию будет находится в левом верхнем углу.
		 * при копировании точек, копируются текущие, смягчённые точки.
	 */
	public class PolyLineEditor extends Sprite 
	{
		private var _baseVertexes:Vector.<BaseVertex>;
		private var _smoothLinePoints:Vector.<Point>;
		
		private var _edgeSprite:Sprite;
		private var _baseVertexSprite:Sprite;
		private var _smoothLineShape:Shape;
		
		private var _tfCursor:TextField;
		
		private var _currentBaseVertexSelected:BaseVertex;
		
		private var _keyUpCommands:Object;
		
		private var _smoothPass:int = 0;
		private var _closePath:Boolean = false;
		
		private var _info:Info;
		
		private var _fileRef:FileReference;
		private var _imageHolder:Loader;
		
		public function PolyLineEditor() 
		{
			_baseVertexes = new Vector.<BaseVertex>();
			_smoothLinePoints = new Vector.<Point>();
			
			_keyUpCommands = new Object();
			_keyUpCommands[8] = deleteLastBaseVertex; 	//backspace
			
			_keyUpCommands[37] = moveLeftCanvas;		//arrow left
			_keyUpCommands[38] = moveUpCanvas;			//arrow up
			_keyUpCommands[39] = moveRightCanvas;		//arrow right
			_keyUpCommands[40] = moveDownCanvas;		//arrow down
			
			_keyUpCommands[107] = smoothLine;			//key + (numPad)
			_keyUpCommands[187] = smoothLine;			//key +
			_keyUpCommands[109] = unSmoothLine;			//key - (numPad)
			_keyUpCommands[189] = unSmoothLine;			//key -
			
			_keyUpCommands[32] = changeClosePath;		//space
			
			_keyUpCommands[13] = copyPontsToClipboard;	//enter
			_keyUpCommands[67] = copyPontsToClipboard;	//C
			
			_keyUpCommands[76] = loadImage;				//L
			_keyUpCommands[72] = toggleHelpWindow;		//H
			_keyUpCommands[46] = deletePath;		//delete
			
			_edgeSprite = new Sprite();
			_baseVertexSprite = new Sprite();
			_smoothLineShape = new Shape();
			
			_tfCursor = new TextField();
			_tfCursor.selectable = false;
			_tfCursor.mouseEnabled = false;
			_tfCursor.defaultTextFormat = new TextFormat("Consolas", 11);
			
			_info = new Info();
			
			_fileRef = new FileReference();
			_imageHolder = new Loader();
			_imageHolder.mouseEnabled = false;
			_imageHolder.mouseChildren = false;
			_imageHolder.alpha = 0.2;
			_imageHolder.visible = false;
			
			addChild(_imageHolder);
			addChild(_edgeSprite);
			addChild(_baseVertexSprite);
			addChild(_smoothLineShape);
			addChild(_info);
			addChild(_tfCursor);
			
			
			addEventListener(Event.ADDED_TO_STAGE, addedToStage);
		}
		
		
		
		
		private function addedToStage(e:Event):void 
		{
			removeEventListener(Event.ADDED_TO_STAGE, addedToStage);
			//-------------------------
			stage.addEventListener(KeyboardEvent.KEY_UP, stage_keyUp);
			stage.addEventListener(MouseEvent.MOUSE_DOWN, stage_mouseDown);
			
			addEventListener(MouseEvent.MOUSE_OVER, mouseOver);
			addEventListener(MouseEvent.ROLL_OUT, mouseOut);
			addEventListener(MouseEvent.MOUSE_MOVE, mouseOver);
		}
		
		//==============================================
		//				CURSOR MOUSE
		//==============================================
		private function mouseOver(e:MouseEvent):void 
		{
			// make cursor
			_tfCursor.text = "";
			_tfCursor.x = mouseX+15;
			_tfCursor.y = mouseY+10;
			
			if (e.target is Edge) 
			{
				_tfCursor.text = "+";
			}
			
			if (e.target is BaseVertex) 
			{
				_tfCursor.text = "move";
			}
		}
		
		private function mouseOut(e:MouseEvent):void 
		{
			_tfCursor.text = "";
		}
		
		//==============================================
		//				KEY UP
		//==============================================
		private function stage_keyUp(e:KeyboardEvent):void 
		{
			var key:uint = e.keyCode;
			if (_keyUpCommands[key]) _keyUpCommands[key]();
			//trace(key);
		}
		
		//==============================================
		//				MOUSE DOWN
		//==============================================
		private function stage_mouseDown(e:MouseEvent):void 
		{
			//  create new base vertex
			if (e.target is Stage || e.target is PolyLineEditor || e.target is Edge) 
			{
				var baseV:BaseVertex = new BaseVertex(mouseX, mouseY, baseVertexMoved);
				
				//если мышь нажата на ребре, то добавляю вершину  в массив между вершин, образующих ребро.
				//иначе просто добавляю вершину в конец массива
				if (e.target is Edge) 
				{
					var edge:Edge = e.target as Edge;
					_baseVertexes.splice(_baseVertexes.indexOf(edge.b), 0, baseV);
				}
				else
				{
					_baseVertexes.push(baseV);
				}
				
				_baseVertexSprite.addChild(baseV);
				
				if (_currentBaseVertexSelected) _currentBaseVertexSelected.selectOff();
				_currentBaseVertexSelected = baseV;
				_currentBaseVertexSelected.selectOn();
				
				drawBaseLine();
				
				updateSmoothLine();
				drawSmoothLine();
				
				baseV.fakeMouseDown();
			}
			
			//select vertex
			if (e.target is BaseVertex) 
			{
				if (_currentBaseVertexSelected) _currentBaseVertexSelected.selectOff();
				_currentBaseVertexSelected = e.target as BaseVertex;
				_currentBaseVertexSelected.selectOn();
			}
			
		}
		
		//==============================================
		//				DRAW BASE LINE
		//==============================================
		private function drawBaseLine():void 
		{
			
			while (_edgeSprite.numChildren) _edgeSprite.removeChildAt(0);
			
			for (var i:int = 0; i < _baseVertexes.length-1; i++) 
			{
				var edge:Edge = new Edge(_baseVertexes[i], _baseVertexes[i + 1]);
				_edgeSprite.addChild(edge);
			}
			
		}
		
		private function baseVertexMoved():void 
		{
			//trace("base vertex moved");
			drawBaseLine();
			
			updateSmoothLine();
			drawSmoothLine();
		}
		
		//==============================================
		//				SMOOTHING CHANGE
		//==============================================
		
		
		private function updateSmoothLine():void 
		{
			_smoothLinePoints = convertBaseVertexToPoints();
			
			if (_smoothPass>0 && _smoothLinePoints.length>1) 
			{
				for (var i:int = 0; i < _smoothPass; i++) 
				{
					_smoothLinePoints = smoothingLine(_smoothLinePoints, _closePath);
				}
			}
			
			//update path length in pixel
			var lenInPix:Number = 0;
			for (var j:int = 0; j < _smoothLinePoints.length-1; j++) 
			{
				var p1:Point = _smoothLinePoints[j];
				var p2:Point = _smoothLinePoints[j+1];
				lenInPix += SMath.dist(p1.x, p1.y, p2.x, p2.y);
			}
			
			_info.pathLength = Number(lenInPix.toFixed(2));
			_info.numPoints = _smoothLinePoints.length;
		}
		
		
		
		private function convertBaseVertexToPoints():Vector.<Point> 
		{
			_smoothLinePoints.length = 0;
			for (var i:int = 0; i < _baseVertexes.length; i++) 
			{
				_smoothLinePoints[i] = new Point(_baseVertexes[i].x, _baseVertexes[i].y);
			}
			
			//если путь нужно замкнуть, то создать в конце ещё одну точку, такую же, как и первую
			if (_closePath && _smoothLinePoints.length>1) 
			{
				_smoothLinePoints.push(new Point(_smoothLinePoints[0].x, _smoothLinePoints[0].y));
			}
			
			return _smoothLinePoints;
		}
		
		
		
		private function drawSmoothLine():void 
		{
			_smoothLineShape.graphics.clear();
			if (_smoothLinePoints.length < 2) return;
			
			//draw line
			_smoothLineShape.graphics.lineStyle(1, 0x4FA7FF);
			_smoothLineShape.graphics.moveTo(_smoothLinePoints[0].x, _smoothLinePoints[0].y);
			for (var i:int = 1; i < _smoothLinePoints.length; i++) 
			{
				_smoothLineShape.graphics.lineTo(_smoothLinePoints[i].x, _smoothLinePoints[i].y);
			}
			_smoothLineShape.graphics.lineStyle();
			
			
			//draw vertexes
			for (i = 0; i < _smoothLinePoints.length; i++) 
			{
				_smoothLineShape.graphics.beginFill(0x370CCB)
				_smoothLineShape.graphics.drawRect(_smoothLinePoints[i].x-1, _smoothLinePoints[i].y-1,2,2);
			}
			_smoothLineShape.graphics.endFill();
			
		}
		
		internal static function smoothingLine(points:Vector.<Point>, closePath:Boolean=false):Vector.<Point> 
		{
			//создаю базовый массив точек
			var originClone:Vector.<Point> = new Vector.<Point>();
			for (var k:int = 0; k < points.length; k++) 
			{
				originClone[k] = points[k].clone();
			}
			
			
			// нахожу промежуточные точки
			var middlePoints:Vector.<Point> = new Vector.<Point>();
			for (var i:int = 0; i < originClone.length; i++) 
			{
				if (i != originClone.length-1) 
				{
					var p1:Point = originClone[i];
					var p2:Point = originClone[i + 1];
					var middleP:Point = new Point(p1.x + ((p2.x - p1.x) / 2), p1.y + ((p2.y - p1.y) / 2));
					middlePoints[i] = middleP;
				}
			}
			
			//двигаю базовые  точки для смягчения
			for (var j:int = 0; j < middlePoints.length-1; j++) 
			{
				var m1:Point = middlePoints[j];
				var m2:Point = middlePoints[j + 1];
				var mHalf:Point = new Point(m1.x + ((m2.x - m1.x) * 0.5), m1.y + ((m2.y - m1.y) * 0.5));
				
				var orinigP:Point = originClone[j + 1];
				
				var offsetOriginP:Point = new Point(orinigP.x + ((mHalf.x - orinigP.x) * 0.5), orinigP.y + ((mHalf.y - orinigP.y) * 0.5));
				
				orinigP.x = offsetOriginP.x;
				orinigP.y = offsetOriginP.y;
			}
			if (closePath) //смягчить первую базовую точку, а последнюю базовую точку сделать такую же как первую
			{
				m1 = middlePoints[middlePoints.length-1];
				m2 = middlePoints[0];
				mHalf = new Point(m1.x + ((m2.x - m1.x) * 0.5), m1.y + ((m2.y - m1.y) * 0.5));
				
				orinigP = originClone[0];
				
				offsetOriginP = new Point(orinigP.x + ((mHalf.x - orinigP.x) * 0.5), orinigP.y + ((mHalf.y - orinigP.y) * 0.5));
				
				orinigP.x = offsetOriginP.x;
				orinigP.y = offsetOriginP.y;
				
				originClone[originClone.length - 1] = originClone[0].clone();
			}
			
			//объединяю базовые (уже смягчённые) точки и промежуточные
			for (var l:int = 0; l < originClone.length-1; l++) 
			{
				originClone.splice(l+1, 0, middlePoints.shift());
				l++;
			}
			
			return originClone;
			
		}
			
		//==============================================
		//				KEY COMMANDS
		//==============================================
		private function deleteLastBaseVertex():void 
		{
			if (_currentBaseVertexSelected)
			{
				//remove from array
				var id:int = _baseVertexes.indexOf(_currentBaseVertexSelected)
				_baseVertexes.splice(id, 1);
				
				//remove from displayList
				_baseVertexSprite.removeChild(_currentBaseVertexSelected);
				
				//select on last baseVertex in array
				if (_baseVertexes.length) 
				{
					_currentBaseVertexSelected = _baseVertexes[_baseVertexes.length - 1];
					_currentBaseVertexSelected.selectOn();
				}
				else _currentBaseVertexSelected = null;
				
				drawBaseLine();
				
				updateSmoothLine();
				drawSmoothLine();
			}
		}
		
		private function smoothLine():void 
		{
			_smoothPass++;
			
			updateSmoothLine();
			drawSmoothLine();
			
			_info.smoothPass = _smoothPass;
		}
		
		private function unSmoothLine():void 
		{
			_smoothPass = _smoothPass > 0 ? --_smoothPass : 0;
			
			updateSmoothLine();
			drawSmoothLine();
			
			_info.smoothPass = _smoothPass;
		}
		
		private function changeClosePath():void 
		{
			_closePath = !_closePath;
			
			drawBaseLine();
			updateSmoothLine();
			drawSmoothLine();
			
			_info.closePath = _closePath;
		}
		
		private function copyPontsToClipboard():void 
		{
			var fixedX:Number;
			var fixedY:Number;
			var s:String = "new <Point>[";
			
			for (var i:int = 0; i < _smoothLinePoints.length; i++) 
			{
				fixedX = Number(_smoothLinePoints[i].x.toFixed(3));
				fixedY = Number(_smoothLinePoints[i].y.toFixed(3));
				s += "new Point(" + fixedX + "," + fixedY + "),";
			}
			
			if(_smoothLinePoints.length) s = s.substr(0, -1); // remove last coma
			s+="];"
			
			System.setClipboard(s);
		}
		
		//==============================================
		//				LOAD BACK IMAGE
		//==============================================
		private function loadImage():void 
		{
			//trace("load image");
			if (_imageHolder.visible)
			{
				_imageHolder.visible = false;
				return;
			}
			
			var fileFilter:FileFilter = new FileFilter("Images (.jpg, .png)", "*.jpg; *.png");
			
			_fileRef.addEventListener(Event.SELECT, fileRef_select);
			_fileRef.addEventListener(Event.COMPLETE, fileRef_complete);
			_fileRef.browse([fileFilter]);
		}
		
		private function fileRef_complete(e:Event):void 
		{
			_imageHolder.loadBytes(_fileRef.data);
			_imageHolder.visible = true;
		}
		
		private function fileRef_select(e:Event):void 
		{
			_fileRef.load();
		}
		
		
		//==============================================
		//				TOGGLE HELP WINDOW
		//==============================================
		private function toggleHelpWindow():void 
		{
			_info.changeVisible();
		}
		
		//==============================================
		//				DELETE PATH
		//==============================================
		private function deletePath():void 
		{
			_baseVertexes.length = 0;
			_smoothLinePoints.length = 0;
			
			_currentBaseVertexSelected = null;
			
			_smoothLineShape.graphics.clear();
			
			while (_baseVertexSprite.numChildren) _baseVertexSprite.removeChildAt(0);
			while (_edgeSprite.numChildren) _edgeSprite.removeChildAt(0);
			
			_info.numPoints = 0;
			_info.pathLength = 0;
		}
		
		//==============================================
		//				MOVE CANVAS
		//==============================================
		private function moveDownCanvas():void 
		{
			y -= 50;
			_info.y = -y;
		}
		
		private function moveUpCanvas():void 
		{
			y += 50;
			_info.y = -y;
		}
		
		private function moveRightCanvas():void 
		{
			x -= 50;
			_info.x = -x;
		}
		
		private function moveLeftCanvas():void 
		{
			x += 50;
			_info.x = -x;
		}
	}

}


//==============================================
//			private	class BASE VERTEX
//==============================================
import flash.display.Shape;
import flash.display.Sprite;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.text.TextField;
import flash.text.TextFieldAutoSize;
import flash.text.TextFormat;

class BaseVertex extends Sprite 
{
	public var movedCB:Function;
	
	private var _movedHitArea:Shape;
	
	public function BaseVertex(posX:Number,posY:Number,movedCallback:Function) 
	{
		x = posX;
		y = posY;
		movedCB = movedCallback;
		
		tabEnabled = false;
		
		
		_movedHitArea = new Shape();
		_movedHitArea.graphics.beginFill(0, 0);
		_movedHitArea.graphics.drawRect( -50, -50, 100, 100);
		_movedHitArea.graphics.endFill();
		//draw vertex
		selectOff();
		
		addEventListener(Event.ADDED_TO_STAGE, addedToStage);
		addEventListener(Event.REMOVED_FROM_STAGE, removedFromStage);
	}
	
	
	
	public function selectOn():void 
	{
		graphics.clear();
		graphics.beginFill(0xEFD125);
		graphics.drawRect( -3, -3, 6, 6);
		graphics.endFill();
	}
	
	public function selectOff():void 
	{
		graphics.clear();
		graphics.beginFill(0x9A9A9A);
		graphics.drawRect( -3, -3, 6, 6);
		graphics.endFill();
	}
	
	public function fakeMouseDown():void 
	{
		mouseDown();
	}
	
	private function addedToStage(e:Event):void 
	{
		removeEventListener(Event.ADDED_TO_STAGE, addedToStage);
		addEventListener(MouseEvent.MOUSE_DOWN, mouseDown);
	}
	
	private function removedFromStage(e:Event):void 
	{
		removeEventListener(Event.REMOVED_FROM_STAGE, removedFromStage);
		stage.removeEventListener(MouseEvent.MOUSE_MOVE, stage_mouseMove);
		stage.removeEventListener(MouseEvent.MOUSE_UP, stage_mouseUp);
	}
	
	private function mouseDown(e:MouseEvent=null):void 
	{
		stage.addEventListener(MouseEvent.MOUSE_MOVE, stage_mouseMove);
		stage.addEventListener(MouseEvent.MOUSE_UP, stage_mouseUp);
		
		addChild(_movedHitArea);
	}
	
	private function stage_mouseUp(e:MouseEvent):void 
	{
		stage.removeEventListener(MouseEvent.MOUSE_MOVE, stage_mouseMove);
		stage.removeEventListener(MouseEvent.MOUSE_UP, stage_mouseUp);
		
		removeChild(_movedHitArea);
	}
	
	private function stage_mouseMove(e:MouseEvent):void 
	{
		x = parent.mouseX;
		y = parent.mouseY;
		movedCB();
	}
}


//==============================================
//				private class EDGE
//==============================================

class Edge extends Sprite 
{
	public var a:BaseVertex;
	public var b:BaseVertex;
	
	public function Edge(vertA:BaseVertex, vertB:BaseVertex) 
	{
		tabEnabled = false;
		
		a = vertA;
		b = vertB;
		
		graphics.lineStyle(5, 0xD7D7D7,0);
		graphics.moveTo(vertA.x, vertA.y);
		graphics.lineTo(vertB.x, vertB.y);
		
		graphics.lineStyle(1, 0xB5B5B5);
		graphics.moveTo(vertA.x, vertA.y);
		graphics.lineTo(vertB.x, vertB.y);
	}
}

//==============================================
//				private class INFO
//==============================================
class Info extends Sprite
{
	private var _numPoints:int;
	private var _closePath:Boolean;
	private var _smoothPass:int;
	private var _pathLength:Number = 0;
	private var _infoVisible:Boolean = true;
	
	private var _tf:TextField;
	private var _tFormat:TextFormat;
	
	public function Info() 
	{
		mouseEnabled = false;
		mouseChildren = false;
		tabEnabled = false;
		
		_tFormat = new TextFormat("Tahoma", 11, 0xFFFFFF);
		
		_tf = new TextField();
		_tf.defaultTextFormat = _tFormat;
		_tf.background = true;
		_tf.backgroundColor = 0x000000;
		_tf.wordWrap = false;
		_tf.multiline = true;
		_tf.selectable = false;
		_tf.autoSize = TextFieldAutoSize.LEFT;
		updateText();
		
		addChild(_tf);
	}
	
	public function changeVisible():void 
	{
		_infoVisible = !_infoVisible;
		updateText();
	}
	
	
	private function updateText():void 
	{
		if (_infoVisible==false) 
		{
			_tf.htmlText = "press <b>H</b> for help";
			return;
		}
		
		var s:String = "  *** <b><u>keyboard</u></b> ***\n";
		s += "<b>CLICK</b>: add/move point\n";
		s += "<b>BACKSPACE</b>: delete last/select vertex \n";
		s += "<b>PLUS</b> : smooth \n";
		s += "<b>MINUS</b> : unsmooth\n";
		s += "<b>DELETE</b>: delete path \n";
		s += "<b>SPACE</b> : close/open path\n";
		s += "<b>ARROWS</b>: move canvas\n";
		s += "<b>ENTER or C</b> : copy points to clipboard\n";
		s += "<b>L</b> : load/unload image\n";
		s += "<b>H</b> : show/hide help\n\n";
		
		//info
		s += "      *** <b><u>info</u></b> ***";
		s += "\n<b>smooth pass</b>: " + _smoothPass;
		s += "\n<b>num points</b>: " + _numPoints;
		s += "\n<b>path length pix</b>: " + _pathLength;
		s += "\n<b>close path</b>: " + _closePath;
		
		_tf.htmlText = s;
	}
	
	public function set numPoints(value:int):void 
	{
		_numPoints = value;
		updateText();
	}
	
	public function set closePath(value:Boolean):void 
	{
		_closePath = value;
		updateText();
	}
	
	public function set smoothPass(value:int):void 
	{
		_smoothPass = value;
		updateText();
	}
	
	public function set pathLength(value:Number):void 
	{
		_pathLength = value;
		updateText();
	}
}
