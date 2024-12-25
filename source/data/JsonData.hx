package data;

import data.types.TankmasDefs;
import entities.Pet;
import ui.sheets.defs.SheetDefs.SheetDef;
import ui.sheets.defs.SheetDefs.SheetMenuDef;

/**
 * Mostly a wrapper for a JSON loaded costumes Map
 */
class JsonData
{
	static var emote_sheets:Map<String, SheetDef>;
	static var costume_sheets:Map<String, SheetDef>;
	static var pet_sheets:Map<String, SheetDef>;

	static var costumes:Map<String, CostumeDef>;
	static var emotes:Map<String, EmoteDef>;
	static var presents:Map<String, PresentDef>;
	static var tracks:Map<String, TrackDef>;
	static var pets:Map<String, PetDef>;

	public static var costume_sheet_defs(get, default):Array<SheetDef>;
	public static var costume_sheet_names(get, default):Array<String>;

	public static var emote_sheet_defs(get, default):Array<SheetDef>;
	public static var emote_sheet_names(get, default):Array<String>;

	public static var pet_sheet_defs(get, default):Array<SheetDef>;
	public static var pet_sheet_names(get, default):Array<String>;

	public static var costume_defs(get, default):Array<CostumeDef>;
	public static var costume_names(get, never):Array<String>;

	public static var emote_defs(get, default):Array<EmoteDef>;
	public static var emote_names(get, never):Array<String>;

	public static var present_defs(get, default):Array<PresentDef>;
	public static var present_names(get, never):Array<String>;

	public static var track_defs(get, default):Array<TrackDef>;
	public static var track_ids(get, default):Array<String>;

	public static var pet_defs(get, default):Array<PetDef>;
	public static var pet_names(get, default):Array<String>;

	public static function init()
	{
		load_costumes();
		load_presents();
		load_emotes();
		load_tracks();
		load_sheets();
		load_pets();
	}

	static function load_sheets()
	{
		costume_sheets = [];
		var json:{sheets:Array<SheetDef>} = haxe.Json.parse(Utils.load_file_string("costume-sheets.json"));

		for (costume_def in json.sheets)
		{
			try
			{
				costume_sheets.set(costume_def.name, costume_def);
			}
			catch (e)
			{
				trace('costume sheet load error @ $costume_def, error is: $e');
			}
		}

		emote_sheets = [];
		var json:{sheets:Array<SheetDef>} = haxe.Json.parse(Utils.load_file_string("emote-sheets.json"));

		for (emote_def in json.sheets)
			try
			{
				emote_sheets.set(emote_def.name, emote_def);
			}
			catch (e)
			{
				trace('emote sheet load error @ $emote_def, error is: $e');
			}

		pet_sheets = [];
		var json:{sheets:Array<SheetDef>} = haxe.Json.parse(Utils.load_file_string("pet-sheets.json"));

		for (pet_def in json.sheets)
			try
			{
				pet_sheets.set(pet_def.name, pet_def);
			}
			catch (e)
			{
				trace('emote sheet load error @ $pet_def, error is: $e');
			}
	}

	static function load_costumes()
	{
		costumes = [];
		var json:{costumes:Array<CostumeDef>} = haxe.Json.parse(Utils.load_file_string("costumes.json"));

		for (costume_def in json.costumes)
			costumes.set(costume_def.name, costume_def);
	}

	static function load_emotes()
	{
		emotes = [];
		var json:{emotes:Array<EmoteDef>} = haxe.Json.parse(Utils.load_file_string("emotes.json"));

		for (emote_def in json.emotes)
			emotes.set(emote_def.name, emote_def);
	}

	static function load_presents()
	{
		presents = [];
		var json:{presents:Array<PresentDef>} = haxe.Json.parse(Utils.load_file_string("presents.json"));

		for (present_def in json.presents)
			presents.set(present_def.artist.toLowerCase(), present_def);

		var json:{presents:Array<PresentDef>} = haxe.Json.parse(Utils.load_file_string("presents-25.json"));

		for (present_def in json.presents)
			presents.set(present_def.artist.toLowerCase(), present_def);
	}

	static function load_tracks()
	{
		tracks = [];
		var json:{tracks:Array<TrackDef>} = haxe.Json.parse(Utils.load_file_string("tracks.json"));

		for (track_def in json.tracks)
			tracks.set(track_def.id, track_def);
	}

	static function load_pets()
	{
		pets = [];
		var json:{pets:Array<PetDef>} = haxe.Json.parse(Utils.load_file_string("pets.json"));

		// yes I know this could be one for loop but for readability it's two

		for (pet_def in json.pets)
			if (pet_def.stats == null)
				pet_def.stats = Reflect.copy(Pet.default_stats);
			else
			{
				pet_def.stats.follow_speed = pet_def.stats.follow_speed == null ? Pet.default_stats.follow_speed : pet_def.stats.follow_speed;
				pet_def.stats.follow_acl = pet_def.stats.follow_acl == null ? Pet.default_stats.follow_acl : pet_def.stats.follow_acl;
				pet_def.stats.follow_accuracy = pet_def.stats.follow_accuracy == null ? Pet.default_stats.follow_accuracy : pet_def.stats.follow_accuracy;

				pet_def.stats.deadzone = pet_def.stats.deadzone == null ? Pet.default_stats.deadzone : pet_def.stats.deadzone;

				pet_def.stats.follow_offset_x = pet_def.stats.follow_offset_x == null ? Pet.default_stats.follow_offset_x : pet_def.stats.follow_offset_x;
				pet_def.stats.follow_offset_y = pet_def.stats.follow_offset_y == null ? Pet.default_stats.follow_offset_y : pet_def.stats.follow_offset_y;
			}

		for (pet_def in json.pets)
			pets.set(pet_def.name, pet_def);
	}

	///<defs singular>///
	public static function get_costume_sheet(name:String):SheetDef
		return costume_sheets.get(name);

	public static function get_emote_sheet(name:String):SheetDef
		return emote_sheets.get(name);

	public static function get_pet_sheet(name:String):SheetDef
		return pet_sheets.get(name);

	public static function get_costume(name:String):CostumeDef
		return costumes.get(name);

	public static function get_emote(name:String):EmoteDef
		return emotes.get(name);

	public static function get_present(name:String):PresentDef
		return presents.get(name);

	public static function get_pet(name:String):PetDef
		return pets.get(name);

	public static function get_track(track_id:String):TrackDef
		return tracks.get(track_id);

	///<defs (multiple)>///
	public static function get_costume_sheet_defs():Array<SheetDef>
		return map_to_array(costume_sheets);

	public static function get_emote_sheet_defs():Array<SheetDef>
		return map_to_array(emote_sheets);

	public static function get_pet_sheet_defs():Array<SheetDef>
		return map_to_array(pet_sheets);

	public static function get_emote_defs():Array<EmoteDef>
		return map_to_array(emotes);

	public static function get_present_defs():Array<PresentDef>
		return map_to_array(presents);

	public static function get_costume_defs():Array<CostumeDef>
		return map_to_array(costumes);

	public static function get_pet_defs():Array<PetDef>
		return map_to_array(pets);

	public static function get_track_defs():Array<TrackDef>
		return map_to_array(tracks);

	/// <names/ids>
	public static function get_costume_sheet_names():Array<String>
		return costume_sheet_defs.map((def:SheetDef) -> return def.name);

	public static function get_emote_sheet_names():Array<String>
		return emote_sheet_defs.map((def:SheetDef) -> return def.name);

	public static function get_pet_sheet_names():Array<String>
		return pet_sheet_defs.map((def:SheetDef) -> return def.name);

	public static function get_costume_names():Array<String>
		return costume_defs.map((def:CostumeDef) -> return def.name);

	public static function get_present_names():Array<String>
		return present_defs.map((def:PresentDef) -> return def.artist);

	public static function get_emote_names():Array<String>
		return emote_defs.map((def:EmoteDef) -> return def.name);

	public static function get_pet_names():Array<String>
		return pet_defs.map((def:PetDef) -> return def.name);

	public static function get_track_ids():Array<String>
		return track_defs.map((def:TrackDef) -> return def.id);

	public static inline function map_to_array<T:Dynamic>(map:Map<String, T>):Array<T>
	{
		var vals:Array<T> = [];
		for (val in map)
			vals.push(val);
		return vals;
	}

	public static function random_draw_emotes(amount:Int, ?limit_list:Array<String>)
	{
		var drawn_emotes:Array<String> = [];
		for (n in 0...amount)
		{
			var random_emote:String = null;
			while (random_emote == null
				|| SaveManager.saved_emote_collection.contains(random_emote)
				|| drawn_emotes.contains(random_emote)
				|| ["rare-tamago-sticker"].contains(random_emote))
				random_emote = Main.ran.getObject(limit_list == null ? emote_names : limit_list);
			drawn_emotes.push(random_emote);
		}
		return drawn_emotes;
	}

	public static function check_for_unlock_costume(costume:CostumeDef):Bool
	{
		if (costume.unlock == null)
			return true;
		return data.types.TankmasEnums.UnlockCondition.get_unlocked(costume.unlock, costume.data);
	}

	public static function check_for_unlock_emote(emote:EmoteDef):Bool
	{
		return SaveManager.saved_emote_collection.contains(emote.name);
		/*
			if (emote.unlock == null)
				return true;
			return data.types.TankmasEnums.UnlockCondition.get_unlocked(emote.unlock, emote.data);
		 */
	}
}
