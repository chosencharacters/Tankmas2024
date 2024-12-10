package minigames;

import entities.Minigame;
import flixel.FlxState;
import json2object.JsonParser;
import squid.util.Utils;
import utils.URL;

class MinigameHandler
{
	public static var instance(get, never):MinigameHandler;
	static var _instance:Null<MinigameHandler>;

	static function get_instance():MinigameHandler
	{
		if (_instance == null)
			_instance = new MinigameHandler();
		return _instance;
	}

	private function new() {}

	public var active_minigame_id(default, null):Null<String>;

	var data:Null<MinigameEntries> = null;
	var constructors = new Map<String, MinigameConstructor>();
	var destructors = new Map<String, MinigameDestructor>();

	public function initialize():Void
	{
		loadData();

		#if !exclude_bunnymark
		constructors["bunnymark"] = () -> new bunnymark.PlayState();
		destructors["bunnymark"] = null;
		#end

		handleDefines();
	}

	function loadData():Void
	{
		var contents = Utils.load_file_string("assets/data/entries/minigames.json");

		var parser = new JsonParser<MinigameEntries>();

		parser.fromJson(contents, "errors.txt");

		var data:Null<MinigameEntries> = parser.value;
		var errors:Array<json2object.Error> = parser.errors;

		if (errors.length > 0 || data == null)
		{
			throw "Failed to load minigame data!";
		}
		else
		{
			this.data = data;
		}
	}

	function fetchData(minigame_id:String):MinigameEntry
	{
		if (data == null)
		{
			throw "Minigame data not initialized!";
		}
		else
		{
			var result = data.minigames[minigame_id];
			if (result == null)
			{
				throw "Minigame not found in data: " + minigame_id;
			}
			else
			{
				return result;
			}
		}
	}

	function handleDefines():Void
	{
		#if skip_to_bunnymark
		#if (skip_to_chimney)
		trace("[ERROR] Cannot skip to multiple minigames!");
		#elseif exclude_bunnymark
		trace("[ERROR] Cannot skip to excluded minigame: bunnymark");
		#else
		playMinigame("bunnymark");
		#end
		#end

		#if skip_to_chimney
		#if (skip_to_bunnymark)
		trace("[ERROR] Cannot skip to multiple minigames!");
		#elseif exclude_chimney
		trace("[ERROR] Cannot skip to excluded minigame: chimney");
		#else
		playMinigame("chimney");
		#end
		#end
	}

	/**
	 * Call this function to play the minigame of the given ID!
	 * @param minigame_id The ID of the minigame to play.
	 * @throws error If the minigame is already active.
	 */
	public function playMinigame(minigame_id:String):Void
	{
		if (active_minigame_id != null)
		{
			throw 'Cannot play minigame (${minigame_id}) while another minigame is active (${active_minigame_id})';
		}

		var data = fetchData(minigame_id);

		// Initialization common to all minigames.
		playMinigame_common(minigame_id, data);

		// Initialization specific to the minigame type.
		switch (data.type)
		{
			case MinigameType.STATE:
				playMinigame_state(minigame_id, data);
			case MinigameType.OVERLAY:
				playMinigame_overlay(minigame_id, data);
			case MinigameType.EXTERNAL:
				playMinigame_external(minigame_id, data);
			default:
				throw "Unknown minigame type: " + data.type;
		}
	}

	function playMinigame_common(minigame_id:String, data:MinigameEntry):Void
	{
		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		FlxG.sound.music = null;

		active_minigame_id = minigame_id;
	}

	function playMinigame_state(minigame_id:String, data:MinigameEntry):Void
	{
		if (constructors[minigame_id] == null)
			throw "Minigame constructor not found for minigame: " + minigame_id;

		throw "Not implemented";
	}

	function playMinigame_overlay(minigame_id:String, data:MinigameEntry):Void
	{
		var constructor = constructors[minigame_id];
		if (constructor == null)
			throw "Minigame constructor not found for minigame: " + minigame_id;

		var overlay = new OverlaySubState(minigame_id, data, constructor);

		overlay.closeCallback = () ->
		{
			var destructor = destructors[minigame_id];

			if (destructor != null)
				destructor();

			closeMinigame();
		}

		FlxG.state.openSubState(overlay);
	}

	function playMinigame_external(minigame_id:String, data:MinigameEntry):Void
	{
		if (data.external == null)
		{
			throw "Minigame external reference not found for minigame: " + minigame_id;
		}

		var onClose = () ->
		{
			closeMinigame();
		}

		data.external.url.open(data.external.prompt, onClose, onClose);
	}

	function closeMinigame():Void
	{
		active_minigame_id = null;

		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		// TODO: Restart the radio.
	}

	public function is_minigame_active():Bool
	{
		return active_minigame_id != null;
	}
}

typedef MinigameConstructor = () -> FlxState;
typedef MinigameDestructor = Null<() -> Void>;

typedef MinigameEntries =
{
	// Key is the ID, value is the info about the minigame.
	var minigames:Map<String, MinigameEntry>;
}

typedef MinigameEntry =
{
	var name:String;
	var description:String;
	var type:MinigameType;

	/**
	 * @default `false`
	 */
	@:optional
	@:default(false)
	var crtShader:Bool;

	/**
	 * @default {width: FlxG.width, height: FlxG.height, zoom: 1}
	 */
	@:optional
	var ?camera:MinigameEntryCamera;

	/**
	 * Should only be specified if type is `external`.
	 */
	var ?external:MinigameEntryExternal;
}

typedef MinigameEntryCamera =
{
	var width:Int;
	var height:Int;
	var zoom:Float;
}

typedef MinigameEntryExternal =
{
	/**
	 * The URL to open.
	 */
	var url:URL;

	/**
	 * Optionally specify a prompt to show before opening the URL.
	 */
	@:optional
	var ?prompt:String;
}

enum abstract MinigameType(String) from String
{
	// Move to another FlxState
	var STATE = "state";
	// Display as an overlay on the current FlxState
	var OVERLAY = "overlay";
	// This is just a link to another web page.
	var EXTERNAL = "external";
}
