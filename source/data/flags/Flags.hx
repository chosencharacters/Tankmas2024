package data.flags;

class Flags
{
	static var flags:Map<String, Dynamic>;

	static var update_callbacks:Map<String, Void->Void> = new Map<String, Void->Void>();

	#if (debugFlag)
	public static var debug_flag:String = '${haxe.macro.Compiler.getDefine("debugFlag")}';
	#else
	public static var debug_flag:String = null;
	#end

	public static var USE_COMPILER_DEBUG_FLAGS:Bool = #if dev true #else false #end;

	public static function generate()
	{
		if (flags == null)
			flags = new Map<String, Dynamic>();

		set_compiler_flags();
	}

	static function set_compiler_flags()
	{
		if (USE_COMPILER_DEBUG_FLAGS)
		{
			if (debug_flag != null)
				for (flag in debug_flag.split(","))
					set_bool(flag);
		}

		if (USE_COMPILER_DEBUG_FLAGS)
		{
			set_bool("DEV_MODE", true);
		}
		else
		{
			set_bool("DEV_MODE", false);
		}
	}

	public static function clear()
	{
		flags = null;
		generate();
		set_compiler_flags();

		#if dev
		var str:String = 'FLAGS CLEARED: ${flags}';
		if (debug_flag != null)
			trace(str);
		#end

		update_callbacks = new Map<String, Void->Void>();
	}

	public static function load(data)
		flags = data;

	public static function get_all():Map<String, Dynamic>
		return flags;

	public static function get_all_as_string():String
		return get_all().toString();

	public static function get(key:String):Dynamic
		return flags.get(key);

	public static function get_int(key:String):Int
		return flags.get(key) != null ? cast(get(key), Int) : 0;

	public static function get_keys():Array<String>
	{
		var array:Array<String> = [];
		for (key in flags.keys())
			array.push(key);
		return array;
	}

	/**Use ! to indicate not*/
	public static function get_bool(key:String, verbose:Bool = false):Bool
	{
		if (key == null)
			return false;

		key = key.replace("_and_", "&&").replace("+", "&&").replace("_or_", "||");

		var OR:Bool = key.indexOf("||") > -1;
		var AND:Bool = key.indexOf("&&") > -1;

		if (OR && AND)
			throw 'CAN\'T DO BOTH OR & AND IN ONE FLAG STRING: ${key}';

		// or support
		if (OR)
		{
			for (k in key.split("||"))
				if (get_bool_singular(k))
					return true;
			return false;
		}
		// and support
		if (AND)
		{
			var result:Bool = false;
			for (k in key.split("&&"))
			{
				result = get_bool_singular(k);
				if (!result)
					return false;
			}
			return result;
		}

		return get_bool_singular(key, verbose);
	}

	static function get_bool_singular(key:String, verbose:Bool = false):Bool
	{
		var clean_key:String = key.replace_multiple(["!", "GT_", "LT_", "LTE_", "GTE_"], "");

		var not:Bool = key.charAt(0) == '!';

		if (verbose)
			trace(key);

		if (not)
			key = key.substring(1);
		if (!bool_key_exists(key))
			return not;
		if (not && !get_bool_singular_value(key) || !not && get_bool_singular_value(key))
			return true;

		return false;
	}

	static function bool_key_exists(key:String):Bool
	{
		for (special_prefix in ["COSTUME_", "PET_"])
			if (key.indexOf(special_prefix) == 0)
				return true;

		return flags.get(key) != null;
	}

	/**
	 * To add support for special Flag names
	 */
	static function get_bool_singular_value(key:String):Bool
	{
		// key item flag support
		for (special_prefix in ["COSTUME_", "PET_"])
			if (key.indexOf(special_prefix) == 0)
			{
				var search_flag:String = key.split(special_prefix)[1];
				var search_flag_upper:String = search_flag.toUpperCase().replace("-", "_"); // this line may be a redundancy
				var search_flag_kebab:String = search_flag.toLowerCase().replace("_", "-");

				switch (special_prefix)
				{
					case "COSTUME_":
						return SaveManager.current_costume == search_flag_kebab;
					case "PET_":
						return SaveManager.current_pet == search_flag_kebab;
				}
			}

		return cast(flags.get(key), Bool);
	}

	public static function get_string(key:String):String
		return flags.get(key) != null ? cast(get(key), String) : "";

	public static function get_array(key:String):Array<Dynamic>
		return flags.get(key) != null ? cast(get(key), Array<Dynamic>) : [];

	public static function set(key:String, value:Dynamic, ?iid:String = "", ?source_type:String = ""):Dynamic
	{
		if (key == null || key.length == 0)
			return null;
		#if dev_trace
		if (value != null)
			trace('FLAG SET: \'${key}\': ${flags.get(key)} -> \'${value}\' from \'${iid}\' (${source_type})');
		#end
		flags.set(key, value);

		for (callback in update_callbacks.keys())
		{
			update_callbacks.get(callback)();
			trace(callback, key);
		}

		return get(key);
	}

	public static function add_int(key:String, value:Int):Int
	{
		if (flags.get(key) == null)
			return set_int(key, value);
		flags.set(key, get_int(key) + value);
		return get_int(key);
	}

	public static function set_int(key:String, value:Int):Int
	{
		set(key, value);
		return get_int(key);
	}

	public static function set_bool_handler(key:String, ?iid:String = "", source_type:String = "")
		Flags.set_bool(key, true, iid, source_type);

	public static function set_bool(keys:String, value:Bool = true, ?destroy:Bool = false, ?iid:String = "", ?source_type:String = ""):Bool
	{
		var return_me:Bool = false;
		for (key in keys.split(","))
		{
			set(key, value, iid, source_type);
			if (destroy)
				flags.remove(key);
			return_me = get_bool(key) && return_me;
		}
		return return_me;
	}

	public static function destroy_bool(keys:String, ?iid:String, ?source_type:String)
	{
		for (key in keys.split(","))
			set_bool(key, false, true, iid, source_type);
	}

	public static function set_string(key:String, value:String):String
	{
		set(key, value);
		return get_string(key);
	}

	public static function set_array(key:String, value:Array<Dynamic>):Array<Dynamic>
	{
		set(key, value);
		return get_array(key);
	}

	/**
	 * add to a flag array
	 */
	public static function add_array(key:String, value:Array<Dynamic>):Array<Dynamic>
	{
		var array:Array<Dynamic> = get_array(key).concat(value);
		set_array(key, array);
		return get_array(key);
	}

	/**
	 * Converts level name to flag name notation i.e. forest-b1-bees to FOREST_B1_BEES
	 * @param curLevel level to convert
	 */
	public static function get_level_flag_name(curLevel:String)
	{
		var array:Array<String> = curLevel.split("/");
		var raw:String = array[array.length - 1];
		raw = StringTools.replace(raw.toUpperCase(), "-", "_");
		return raw;
	}

	public static function set_level_flag(curLevel:String, value:Int, dead:Bool = false):Int
	{
		var flag_name:String = dead ? get_level_flag_name(curLevel) + "_DEAD" : get_level_flag_name(curLevel);
		// trace(flag_name, value);
		return set_int(flag_name, value);
	}

	public static function get_level_flag(curLevel:String, dead:Bool = false):Int
	{
		var flag_name:String = dead ? get_level_flag_name(curLevel) + "_DEAD" : get_level_flag_name(curLevel);
		return get_int(flag_name);
	}

	/***end flag methods***/
	/**
	 * Registers a flag callback
	 * @param name 
	 * @param callback_function 
	 * @param callback_type 
	 */
	public static function register_callback(name:String, callback_function:Void->Void, callback_type:FlagCallBackType)
	{
		switch (callback_type)
		{
			case UPDATE:
				update_callbacks.set(name, callback_function);
		}
	}
}

enum abstract FlagCallBackType(Int) to Int
{
	/** Whenever flags update*/
	var UPDATE = 0;
}
