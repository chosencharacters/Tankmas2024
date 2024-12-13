package video;

import haxe.io.Float32Array;
import net.tankmas.TankmasClient;

typedef PremiereData =
{
	var name:String;
	var timestamp:Float;
	var url:String;
	var released:Bool;
}

typedef PremiereList =
{
	var premieres:Array<PremiereData>;
}

class PremiereHandler
{
	/**
	 * Called when the data has been retrieved and the next premiere has been selected.
	 */
	public var on_loaded:() -> Void = null;

	/**
	 * Called when a new premiere starts or if it has started today.
	 */
	public var on_premiere_release:(d:PremiereData) -> Void = null;

	var current_premiere:PremiereData = null;

	var enable_recheck:Bool = false;
	var recheck_timestamp:Float = 0;

	public function new() {}

	public function get_active_premiere()
	{
		return current_premiere;
	}

	public function get_time_until_next_premiere()
	{
		if (current_premiere == null)
			return -1.0;

		return Math.max(0, current_premiere.timestamp - (Main.time.utc / 1000.0));
	}

	public function update(elapsed:Float)
	{
		if (enable_recheck)
		{
			var now = Date.now().getTime();
			if (now >= recheck_timestamp)
			{
				refresh();
			}
		}
	}

	public function refresh()
	{
		enable_recheck = false;
		TankmasClient.get_premieres(on_get_premieres);
	}

	function on_get_premieres(p:PremiereList)
	{
		var premieres:Array<PremiereData> = p != null ? p.premieres : null;

		if (premieres == null)
		{
			trace('[ERROR] Failed to retrieve premiere list!');
			return;
		}

		// Guarantee premieres are sorted by timestamp.
		premieres.sort(function(a, b)
		{
			return Std.int(a.timestamp) - Std.int(b.timestamp);
		});

		for (premiere in premieres)
		{
			var current_timestamp = Date.now().getTime();
			var premiere_timestamp:Float = (premiere.timestamp * 1000.0); // Floats are 64bit, ints don't work good here
			var current_date = Date.fromTime(current_timestamp);
			var premiere_date = Date.fromTime(premiere_timestamp);

			trace('$premiere_date, $premiere_timestamp');

			if (current_date.getMonth() != premiere_date.getMonth())
			{
				continue;
			}

			if (current_date.getDate() == premiere_date.getDate())
			{
				// This premiere happens today!
				trace('Premiere is today...');
				current_premiere = premiere;

				var delta = premiere_timestamp - current_timestamp;

				if (delta <= 0)
				{
					trace('TRIGGERING Premiere: ${premiere.name}');
					enable_recheck = false;
					if (recheck_timestamp == 0)
						recheck_timestamp = premiere_timestamp;

					try_premiere_release(premiere);
				}
				else
				{
					trace('QUEUING Premiere: ${premiere.name} (${premiere_timestamp})');
					enable_recheck = true;
					recheck_timestamp = premiere_timestamp;
				}

				break;
			}
			else if (premiere_date.getDate() < current_date.getDate())
			{
				// This premiere has already happened!
				trace('Premiere is yesterday (${current_date.getDate()} == ${premiere_date.getDate()})...');
				current_premiere = premiere;
			}
			else
			{
				// This premiere happens in the far future (>1 day)!
				// No need to check anymore.
				trace('Premiere is tomorrow (${current_date} == ${premiere_date} : ${premiere_timestamp})...');
				break;
			}
		}

		if (on_loaded != null)
			on_loaded();
	}

	function try_premiere_release(p:PremiereData)
	{
		if (on_premiere_release != null)
		{
			on_premiere_release(p);
		}
		/*
			else
			{
				var now = Date.now().getTime();
				var new_timestamp = now + (10 * 1000);
				trace('POSTPONING Premiere: ${p.name} (${new_timestamp})');
				enable_recheck = true;
				recheck_timestamp = new_timestamp;
			}
		 */
	}
}
