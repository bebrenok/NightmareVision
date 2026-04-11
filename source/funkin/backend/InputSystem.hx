package funkin.backend;

import flixel.input.FlxInput.FlxInputState;
import flixel.input.actions.FlxActionInput;
import flixel.input.actions.FlxAction.FlxActionDigital;

import openfl.events.EventType;
import openfl.events.EventDispatcher;

import funkin.backend.Controls;
import funkin.backend.Controls.Action;

import flixel.input.keyboard.FlxKey;

import openfl.events.KeyboardEvent;

import lime.system.System;

/**
 * An `InputSystem` object tracks note inputs with events
 * You can add listeners to check for when an input is pressed and released
 * ```haxe
 * input = new InputSystem();
 * input.addEventListener(InputEvent.INPUT_PRESSED, onInputPressed);
 * input.addEventListener(InputEvent.INPUT_RELEASED, onInputReleased);
 * ```
 * Input events can also be cancelled
 * ```haxe
 * function onInputPressed(event:InputEvent)
 * {
 *  if (badInput)
 *      event.cancel();
 * }
 * ```
 */
@:nullSafety
class InputSystem implements flixel.util.IFlxDestroyable extends EventDispatcher
{
    /**
     * The list of actions checked for, in order of their note direction
     */
    public static final ACTION_LIST:Array<Action> = [NOTE_LEFT, NOTE_DOWN, NOTE_UP, NOTE_RIGHT];

	/**
	 * The current controls instance used for this input system
	 */
	public var controls:funkin.backend.Controls;
	
	// the actions themselves
	public var pressedActions:Array<FlxActionDigital> = [];
	public var justPressedActions:Array<FlxActionDigital> = [];
	public var justReleasedActions:Array<FlxActionDigital> = [];
	
	// the index of these arrays correlates to the input ID of the input (ex: justPressedKeyInputs[FlxKey.DOWN] would exist if that key was bound)
	// specific device action inputs
	var justPressedKeyInputs:Array<Array<FlxActionInput>> = [];
	var justReleasedKeyInputs:Array<Array<FlxActionInput>> = [];
	
	// note incase if matters to anyone: this counts all non-keyboard inputs under `FlxActionInput.device`
	var justPressedGamepadInputs:Array<Array<FlxActionInput>> = [];
	var justReleasedGamepadInputs:Array<Array<FlxActionInput>> = [];
	
	// cleared out every frame
	var awaitingEvents:Array<InputEvent> = [];
	
	/**
	 * Creates a new input system
	 * @param controls 
	 */
	public function new(?controls:Controls)
	{
		super();
		
		this.controls = controls ?? Controls.instance;
		
		for (noteData => action in ACTION_LIST)
		{
            final pressed:Action = action;
			final justPressed:Action = '$action-press';
			final justReleased:Action = '$action-release';
			
            pressedActions[noteData] = this.controls.actions.get(pressed) ?? throw "Missing Control Bind";
			justPressedActions[noteData] = this.controls.actions.get(justPressed) ?? throw "Missing Control Bind";
			justReleasedActions[noteData] = this.controls.actions.get(justReleased) ?? throw "Missing Control Bind";
			
			justPressedKeyInputs[noteData] = [];
			justReleasedKeyInputs[noteData] = [];
			
			justPressedGamepadInputs[noteData] = [];
			justReleasedGamepadInputs[noteData] = [];
			
            // assign each input to its direction and inputID
			inline function findInputs(action:FlxActionDigital, keys:Array<Array<FlxActionInput>>, gamepad:Array<Array<FlxActionInput>>)
			{
				for (input in action.inputs)
				{
					switch input.device
					{
						case KEYBOARD:
							keys[noteData][input.inputID] = input;
						case _:
							gamepad[noteData][input.inputID] = input;
					}
				}
			}
			
			findInputs(justPressedActions[noteData], justPressedKeyInputs, justPressedGamepadInputs);
			findInputs(justReleasedActions[noteData], justReleasedKeyInputs, justReleasedGamepadInputs);
		}

		FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyboardEvent);
		FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyboardEvent);
	}

    /**
     * Checks if a note direction is pressed
     * @param noteData 
     */
    public function inputPressed(noteData:Int)
    {
        return pressedActions[noteData].check();
    }

    /**
     * Checks if a note direction has just been pressed
     * @param noteData 
     */
    public function inputJustPressed(noteData:Int)
    {
        return justPressedActions[noteData].check();
    }

    /**
     * Checks if a note direction has just been released
     * @param noteData 
     */
    public function inputJustReleased(noteData:Int)
    {
        return justReleasedActions[noteData].check();
    }
	
	/**
	 * Dispatches all awaiting input events
	 */
    @:nullSafety(Off)
	public function update():Void
	{
		while (awaitingEvents.length > 0)
			dispatchEvent(awaitingEvents.shift());
	}
	
	public function destroy():Void
	{
		FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyboardEvent);
		FlxG.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyboardEvent);
	}
	
	@:access(flixel.input.FlxKeyManager.resolveKeyCode)
	function onKeyboardEvent(event:KeyboardEvent)
	{
		if (event.keyCode > -1) onInputEvent(event.type == KeyboardEvent.KEY_DOWN ? InputEvent.INPUT_PRESSED : InputEvent.INPUT_RELEASED, Keys, FlxG.keys.resolveKeyCode(event));
	}
	
	function onInputEvent(event:EventType<InputEvent>, device:Device, inputID:Int)
	{
		final timer = System.getTimer();
		
		final inputState:FlxInputState = switch event
		{
			case InputEvent.INPUT_PRESSED: JUST_PRESSED;
			case InputEvent.INPUT_RELEASED: JUST_RELEASED;
			default: throw "Invalid Event";
		}
		
		switch device
		{
			case Keys:
				// with lime, it counts repeated key inputs when you hold down the key.
				if (!FlxG.keys.checkStatus(inputID, inputState)) return;
			case _:
		}
		
		final inputList:Array<Array<FlxActionInput>> = switch event
		{
			case InputEvent.INPUT_PRESSED:
				switch device
				{
					case Keys: justPressedKeyInputs;
					case Gamepad(_): justPressedGamepadInputs;
				}
			case InputEvent.INPUT_RELEASED:
				switch device
				{
					case Keys: justReleasedKeyInputs;
					case Gamepad(_): justReleasedGamepadInputs;
				}
			default:
				throw "Invalid Event";
		}
		
		for (noteData => inputs in inputList)
        {
            @:nullSafety(Off)
            if (inputs[inputID] != null)
            {
                awaitingEvents.push(new InputEvent(event, false, true, noteData, device, inputID, timer));
                // if we don't break here, then people would be able to bind multiple controls to the same key
                // i don't know if we would want that and it's kinda cheaty so i'll just break
                break;
            }
		}
	}
}
