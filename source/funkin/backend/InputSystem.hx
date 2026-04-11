package funkin.backend;

import funkin.backend.Controls;

import flixel.input.keyboard.FlxKey;

import openfl.events.KeyboardEvent;

@:nullSafety
class InputSystem implements flixel.util.IFlxDestroyable
{
	public var _pressCallback:KeyboardEvent->Void;
	public var _releaseCallback:KeyboardEvent->Void;
	public var keys:Array<Dynamic> = [];
	
	private var controls:funkin.backend.Controls;
	
	public function new(press:KeyboardEvent->Void, release:KeyboardEvent->Void, keys:Array<Dynamic>)
	{
		_pressCallback = press;
		_releaseCallback = release;
		FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, press);
		FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, release);
		controls = Controls.instance;
		
		this.keys = keys;
	}
	
	public function destroy():Void
	{
		FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, _pressCallback);
		FlxG.stage.removeEventListener(KeyboardEvent.KEY_UP, _releaseCallback);
	}
	
	public function update(elapsed:Float = 0.0):Void
	{
		if (_pressCallback == null || _releaseCallback == null) return;
		
		// controlEventStuff('keyDown', [controls.NOTE_LEFT, controls.NOTE_DOWN, controls.NOTE_UP, controls.NOTE_RIGHT]);
		controlEventStuff('keyDown', [controls.NOTE_LEFT_P, controls.NOTE_DOWN_P, controls.NOTE_UP_P, controls.NOTE_RIGHT_P]);
		controlEventStuff('keyUp', [controls.NOTE_LEFT_R, controls.NOTE_DOWN_R, controls.NOTE_UP_R, controls.NOTE_RIGHT_R]);
	}
	
	public function controlEventStuff(direction:String = 'up', controls:Array<Bool> = null)
	{
		if (controls == null) controls = [false, false, false, false];
		var callback:KeyboardEvent->Void = direction == 'up' ? _releaseCallback : _pressCallback;
		
		if (controls.contains(true))
		{
			for (i in 0...controls.length)
			{
				if (controls[i]) callback(new KeyboardEvent(direction, true, true, -1, keys[i][0]));
			}
		}
	}
	
	public function getKeyFromEvent(key:FlxKey):Int
	{
		if (key != NONE)
		{
			for (i in 0...keys.length)
			{
				for (j in 0...keys[i].length)
					if (key == keys[i][j]) return i;
			}
		}
		return -1;
	}
}
