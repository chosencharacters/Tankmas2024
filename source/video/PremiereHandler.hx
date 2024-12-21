package video;

import haxe.io.Float32Array;
import net.tankmas.TankmasClient;

typedef PremiereData =
{
	var name:String;
	var timestamp:Float;
	var ?url:String;
	var released:Bool;
	var length:Int;

	var ?resume_time:Float;
}

typedef PremiereList =
{
	var premieres:Array<PremiereData>;
}

class PremiereHandler
{
	final PREMIERE_EXCLUSIVE_LOOP_DURATION = 60 * 60 * 24 * 1000;

	/**
	 * Called when the data has been retrieved and the next premiere has been selected.
	 */
	public var on_loaded:() -> Void = null;

	/**
	 * Called when a new premiere starts or if it has started today.
	 */
	public var on_premiere_release:(d:PremiereData) -> Void = null;

	var next_premiere:PremiereData = null;

	var enable_recheck:Bool = false;
	var recheck_timestamp:Float = 0;

	// Total playlist length in milliseconds
	public var total_playlist_length:Int = 0;

	var available_premieres:Array<PremiereData> = [];

	public function new() {}

	public function get_next_premiere()
	{
		return next_premiere;
	}

	public function get_time_until_next_premiere():Null<Float>
	{
		if (next_premiere == null)
			return null;

		return Math.max(0, next_premiere.timestamp - (Main.time.utc / 1000.0));
	}

	public function update(elapsed:Float)
	{
		if (enable_recheck)
		{
			var now = Date.now().getTime();
			if (now >= recheck_timestamp)
				refresh();
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
		premieres.sort((a, b) -> Std.int(a.timestamp) - Std.int(b.timestamp));

		var previous_premieres:Array<PremiereData> = [];

		var current_timestamp = Date.now().getTime();

		next_premiere = null;
		for (premiere in premieres)
		{
			var premiere_timestamp:Float = (premiere.timestamp * 1000.0); // Floats are 64bit, ints don't work good here

			if (premiere_timestamp + premiere.length <= current_timestamp)
			{
				previous_premieres.push(premiere);
				continue;
			}

			// Premiere is upcoming...
			next_premiere = premiere;
			if (next_premiere.url != null)
			{
				if (on_premiere_release != null)
					on_premiere_release(next_premiere);
				available_premieres.push(next_premiere);
				break;
			}

			recheck_timestamp = premiere_timestamp;
			enable_recheck = true;
			break;
		}

		available_premieres = previous_premieres;

		total_playlist_length = 0;
		for (p in previous_premieres)
			total_playlist_length += p.length;

		if (on_loaded != null)
			on_loaded();
	}

	public function get_currently_playing_premiere()
	{
		var current_timestamp = Date.now().getTime();

		if (next_premiere != null && next_premiere.url != null)
		{
			var premiere_timestamp:Float = (next_premiere.timestamp * 1000.0);
			next_premiere.resume_time = (current_timestamp - premiere_timestamp) / 1000.0;
			return next_premiere;
		}

		// Check if latest premiere has been playing for the exclusive duration
		var latest_premiere = available_premieres[available_premieres.length - 1];
		if (latest_premiere != null)
		{
			trace(latest_premiere.name);
			var premiere_timestamp:Float = (latest_premiere.timestamp * 1000.0); // Floats are 64bit, ints don't work good here
			if (current_timestamp - premiere_timestamp < PREMIERE_EXCLUSIVE_LOOP_DURATION)
			{
				var p = latest_premiere;
				var timestamp:Float = (1.0 * p.timestamp);
				return {
					url: p.url,
					name: p.name,
					timestamp: timestamp,
					released: p.released,
					length: p.length,
					resume_time: (current_timestamp - premiere_timestamp) / 1000.0,
				}
			}
		}

		var playlist_time = current_timestamp % total_playlist_length;
		var playlist_loop_start_time = current_timestamp - (total_playlist_length - (current_timestamp % total_playlist_length));
		var active_premiere:PremiereData = null;
		for (premiere in available_premieres)
		{
			if (playlist_time < premiere.length)
			{
				active_premiere = premiere;
				break;
			}

			playlist_loop_start_time += premiere.length;
			playlist_time -= premiere.length;
		}

		if (active_premiere != null)
		{
			var p = active_premiere;
			return {
				url: p.url,
				name: p.name,
				timestamp: playlist_loop_start_time / 1000.0,
				released: p.released,
				length: p.length,
				resume_time: playlist_time / 1000.0,
			}
		}

		return null;
	}
}
