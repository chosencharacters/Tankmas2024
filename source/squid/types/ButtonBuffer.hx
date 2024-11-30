package squid.types;

import haxe.ds.ObjectMap;

/**
 * Map that handles Button Buffers
 */
class ButtonBuffer
{
	final DEFAULT_BUFFER_TIME:Int = 10;

	/**Buffer CD for input locking */
	public var cd:Int = 2;

	var charge_opposites:Map<String, String>;

	var buffer_time:Int = 0;

	public var team:Int;

	var buffer:Map<String, Int> = [];

	public function new(team:Int, ?buffer_time:Int)
	{
		this.team = team;
		this.buffer_time = buffer_time == null ? DEFAULT_BUFFER_TIME : buffer_time;
	}

	/**
	 * Manages action buffers
	 */
	public function buffer_update()
	{
		cd--;
		if (cd > 0)
			return;

		if (charge_opposites == null)
		{
			charge_opposites = new Map<String, String>();
			for (key in ["jump", "action", "special", "use"])
				charge_opposites.set(key + "_hold", key + "_release");
		}

		for (key in buffer.keys())
		{
			set(key, get(key) - 1);
			if (get_int(key) <= 0)
				remove(key);
			if (key.indexOf("_hold") > -1 && exists(charge_opposites.get(key)))
				switch (key)
				{
					case "interact_hold":
						!Ctrl.interact[team] ? set(key, 2) : "pass";
					case "menu_hold":
						!Ctrl.menu[team] ? set(key, 2) : "pass";
					case "emote_hold":
						!Ctrl.emote[team] ? set(key, 2) : "pass";
				}
		}

		buffer_input(Ctrl.jinteract[team], "interact");
		buffer_input(Ctrl.jmenu[team], "menu");
		buffer_input(Ctrl.jemote[team], "emote");

		buffer_input(Ctrl.rinteract[team], "interact_release");
		buffer_input(Ctrl.rmenu[team], "menu_release");
		buffer_input(Ctrl.remote[team], "emote_release");

		buffer_input(Ctrl.interact[team], "interact_hold");
		buffer_input(Ctrl.menu[team], "menu_hold");
		buffer_input(Ctrl.emote[team], "emote_hold");
	}

	/**
	 * Buffers an input, handles hold/release inputs
	 */
	public function buffer_input(input:Bool, key:String):Bool
	{
		if (cd > 0)
			return false;
		if (input)
		{
			if (key.indexOf("_hold") <= -1)
				set(key, buffer_time);
			else
				set(key, !exists(key) ? 2 : get_int(key) + 2);
			return true;
		}
		return false;
	}

	public function get_int(key:String):Int
	{
		// for (key_2 in keys())
		// if (key == "action")
		// trace(key == key_2, key, key_2, exists(key), get(key), this, exists(key) ? get(key) : -1);
		return exists(key) ? get(key) : -1;
	}

	public function exists(key:String):Bool
		return buffer.exists(key);

	public function get(key:String):Int
		return buffer.get(key);

	public function set(key:String, val:Int)
		buffer.set(key, val);

	public function clear()
		buffer.clear();

	public function remove(key:String)
		buffer.remove(key);
}
