package video;

import net.tankmas.TankmasClient;

typedef PremiereData =
{
	var name:String;
	var timestamp:Int;
	var url:String;
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
	public var on_premiere_release:(d:{name:String, url:String}) -> Void = null;

	var current_premiere:PremiereData = null;

	var enable_recheck:Bool = false;
	var recheck_timestamp:Float = 0;

	public function new()
	{
		refresh();
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

	function refresh()
	{
		enable_recheck = false;
		TankmasClient.get_premieres(on_get_premieres);
	}

	function on_get_premieres(p:Dynamic)
	{
		var premieres:Array<PremiereData> = p.data.premieres;

		if (premieres == null) {
			trace('[ERROR] Failed to retrieve premiere list!');
			return;
		}

		// Guarantee premieres are sorted by timestamp.
		premieres.sort(function(a, b) {
			return Std.int(a.timestamp) - Std.int(b.timestamp);
		});

		for (premiere in premieres) {
			var current_timestamp = Date.now().getTime();
			var premiere_timestamp = Std.int(premiere.timestamp) * 1000;
			var current_date = Date.fromTime(current_timestamp);
			var premiere_date = Date.fromTime(premiere_timestamp);

			if (current_date.getDate() == premiere_date.getDate()) {
				// This premiere happens today!
				trace('Premiere is today...');
				current_premiere = premiere;

				var delta = premiere_timestamp - current_timestamp;

				if (delta <= 0) {
					trace('TRIGGERING Premiere: ${premiere.name}');
					enable_recheck = false;
					if (recheck_timestamp == 0) recheck_timestamp = premiere_timestamp;
					
					try_premiere_release({name: premiere.name, url: premiere.url});
				} else if (delta > 0) {
					trace('QUEUING Premiere: ${premiere.name} (${premiere_timestamp})');
					enable_recheck = true;
					recheck_timestamp = premiere_timestamp;
				}

				break;
			} else if (premiere_date.getDate() < current_date.getDate()) {
				// This premiere has already happened!
				trace('Premiere is yesterday (${current_date.getDate()} == ${premiere_date.getDate()})...');
				current_premiere = premiere;
			} else {
				// This premiere happens in the far future (>1 day)!
				// No need to check anymore.
				trace('Premiere is tomorrow (${current_date} == ${premiere_date} : ${premiere_timestamp})...');
				break;
			}
		}

		if (on_loaded != null)
			on_loaded();
	}

	function try_premiere_release(p:{name:String, url:String}) {
		if (on_premiere_release != null) {
			on_premiere_release({name: p.name, url: p.url});
		} else {
			var now = Date.now().getTime();
			var new_timestamp = now + (10 * 1000);
			trace('POSTPONING Premiere: ${p.name} (${new_timestamp})');
			enable_recheck = true;
			recheck_timestamp = new_timestamp;
		}
	}
}
