package squid.ext;

import flixel.FlxSubState;

class FlxSubStateExt extends FlxSubState
{
	var tick:Float = 0;
	var state:String = "";

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
	public function sstate(s:String, reset_tick:Bool = true)
	{
		if (reset_tick)
			tick = 0;
		state = s;
	}
}
