package video;

import net.tankmas.TankmasClient;

typedef PremiereData =
{
	var name:String;
	var date:String;
	var release_timestamp:Int;
	var ?url:String;
}

class PremiereHandler
{
	public var on_premiere_release:(d:{name:String, url:String}) -> Void = null;
	public var on_loaded:() -> Void = null;

	var premieres:Map<String, PremiereData> = new Map();

	var enable_recheck:Bool = false;
	var recheck_timestamp:Int = 0;
	var name_of_premiere:String;

	public function new()
	{
		refresh();
	}

	public function get_premiere_info(name:String)
	{
		var p = premieres[name];
		if (p == null)
		{
			return null;
		}

		var now = get_timestamp();
		var delta = p.release_timestamp - now;
		var released = delta <= 0;
		var url:String = p.url;

		return {
			until_release: Math.max(0, delta),
			url: url,
			released: released,
		}
	}

	function refresh()
	{
		enable_recheck = false;
		TankmasClient.get_premieres(on_get_premieres);
	}

	function get_timestamp()
	{
		#if sys
		return Sys.time();
		#end
		return Date.now().getTime();
	}

	function on_get_premieres(p:Dynamic)
	{
		var d:Array<PremiereData> = p.data;
		var now = Std.int(get_timestamp());
		for (p in d)
		{
			var timestamp = Std.int(p.release_timestamp);
			var delta = timestamp - now;

			if (name_of_premiere == p.name && p.url != null)
			{
				if (on_premiere_release != null)
				{
					on_premiere_release({name: p.name, url: p.url});
				}
			}

			if (delta > 0 && (recheck_timestamp > timestamp || !enable_recheck))
			{
				recheck_timestamp = timestamp;
				enable_recheck = true;
				name_of_premiere = p.name;
			}

			premieres[p.name] = p;
		}

		if (on_loaded != null)
			on_loaded();
	}

	public function update(elapsed:Float)
	{
		if (enable_recheck)
		{
			var now = Std.int(get_timestamp());
			if (now >= recheck_timestamp)
			{
				refresh();
			}
		}
	}
}
