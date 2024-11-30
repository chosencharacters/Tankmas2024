package squid.ext;

import flixel.FlxBasic;

class FlxGroupExt<T:FlxBasic> extends FlxTypedGroup<T>
{
	var state:String = "";
	var tick:Int = 0;

	var trace_new_state:Bool = false;

	var state_history:Array<String> = [];

	/**
	 * Switch state
	 * @param new_state new state to switch to 
	 * @param reset_tick resets ticking int (if the state changes)
	 * @param on_state_change function to perform (if the state changes)
	 * @return if the state changed
	 */
	public function sstate(new_state:String, ?reset_tick:Bool = true, ?on_state_change:Void->Void):Bool
	{
		var state_changing:Bool = new_state_check(new_state);

		#if dev_trace
		if (trace_new_state && state_changing)
			trace('[${type}] New State: ${state} -> ${new_state}');
		#end
		if (!state_changing)
			return false;

		tick = reset_tick ? 0 : tick;
		state = new_state;
		state_history.push(new_state);
		on_state_change != null ? on_state_change() : null;
		return true;
	}

	/**
	 * Adds amount to tick
	 * @return tick = tick + amount
	 */
	function ttick(amount:Int = 1):Int
		return tick = tick + amount;

	/**Would this be a new state?**/
	public function new_state_check(new_state:String)
		return new_state != state;
}
