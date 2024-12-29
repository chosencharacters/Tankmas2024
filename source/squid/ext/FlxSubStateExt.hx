package squid.ext;

import flixel.FlxSubState;
import ui.Cursor;

class FlxSubstateExt extends FlxSubState
{
	var tick:Float = 0;
	var state:String = "";

	var cursor:Cursor;

	public var cursor_always_visible = true;

	var state_history:Array<String> = [];
	var trace_new_state:Bool = false;

	override function create()
	{
		super.create();

		cursor = new Cursor(this, cursor_always_visible);
	}

	/**
		Increment tick by i * timescale
		@param	add int to increment by
	**/
	public function ttick(add:Int = 1):Float
	{
		tick += add * FlxG.timeScale;
		return tick;
	}

	/**
	 * Switch state
	 * @param s new state
	 * @param reset_tick resets ticking int
	 */
	public function sstate(new_state:String, ?reset_tick:Bool = true, ?on_state_change:Void->Void):Bool
	{
		var state_changing:Bool = new_state_check(new_state);

		#if dev_trace
		if (trace_new_state && state_changing)
			trace('New State: ${state} -> ${new_state}');
		#end
		if (!state_changing)
			return false;

		tick = reset_tick ? tick : 0;
		state = new_state;
		state_history.push(new_state);
		on_state_change != null ? on_state_change() : null;
		return true;
	}

	/*Would this be a new state?*/
	public function new_state_check(new_state:String)
		return new_state != state;
}
