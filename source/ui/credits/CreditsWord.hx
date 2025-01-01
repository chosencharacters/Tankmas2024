package ui.credits;

import data.types.TankmasFontTypes.TextFormatPresets;

class CreditsWord extends FlxText
{
	var state:String = "";
	var tick:Int = 0;

	var trace_new_state:Bool = false;
	var state_history:Array<String> = [];

	public function new(?X:Float, ?Y:Float, fieldWidth:Int, input:String)
	{
		super(X, Y);

		setFormat(Paths.get('CharlieType-Heavy.otf'), 48, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);

		if (input.contains("*"))
			setFormat(Paths.get('CharlieType-Heavy.otf'), 64, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);

		if (input.contains("**"))
			setFormat(Paths.get('CharlieType-Heavy.otf'), 96, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);

		text = input.replace("*", "").trim();

		this.fieldWidth = fieldWidth;
		autoSize = false;
		wordWrap = true;

		sstate(IDLE);
	}

	override function update(elapsed:Float)
	{
		fsm();
		super.update(elapsed);
	}

	function fsm()
		switch (cast(state, State))
		{
			default:
		}

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

private enum abstract State(String) from String to String
{
	final IDLE;
}
