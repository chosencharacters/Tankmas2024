package data;

import data.types.TankmasDefs.CostumeDef;
import data.types.TankmasDefs.EmoteDef;
import data.types.TankmasDefs.PresentDef;
import ui.sheets.defs.SheetDefs.SheetDef;
import ui.sheets.defs.SheetDefs.SheetMenuDef;

/**
 * Mostly a wrapper for a JSON loaded costumes Map
 */
class JsonData
{
	static var costumes:Map<String, CostumeDef>;
	static var presents:Map<String, PresentDef>;
	static var emotes:Map<String, EmoteDef>;

	public static var costume_defs(get, default):Array<CostumeDef>;
	public static var costume_names(get, never):Array<String>;

	public static var present_defs(get, default):Array<PresentDef>;
	public static var present_names(get, never):Array<String>;

	public static var emote_defs(get, default):Array<EmoteDef>;
	public static var emote_names(get, never):Array<String>;

	public static var costume_sheets:Map<String, SheetDef>;
	public static var emote_sheets:Map<String, SheetDef>;

	public static function init()
	{
		load_sheets();
		load_costumes();
		load_presents();
		load_emotes();
	}

	static function load_sheets()
	{
		costume_sheets = [];
		var json:{sheets:Array<SheetDef>} = haxe.Json.parse(Utils.load_file_string("costume-sheets.json"));

		for (costume_def in json.sheets)
			costumes.set(costume_def.name, costume_def);

		emote_sheets = [];
		var json:{sheets:Array<SheetDef>} = haxe.Json.parse(Utils.load_file_string("emote-sheets.json"));

		for (emote_def in json.sheets)
			emotes.set(emote_def.name, emote_def);
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
	}

	public static function get_costume(costume_name:String):CostumeDef
		return costumes.get(costume_name);

	public static function get_emote(emote_name:String):EmoteDef
		return emotes.get(emote_name);

	public static function get_present(present_name:String):PresentDef
		return presents.get(present_name);

	public static function get_emote_sheet_def(sheet_name:String):SheetDef
		return emote_sheets.get(sheet_name);

	public static function get_costume_sheet_def(sheet_name:String):SheetDef
		return costume_sheets.get(sheet_name);

	public static function get_costume_names():Array<String>
		return costume_defs.map((def:CostumeDef) -> return def.name);

	public static function get_costume_defs():Array<CostumeDef>
		return map_to_array(costumes);

	public static function get_emote_names():Array<String>
		return emote_defs.map((def:EmoteDef) -> return def.name);

	public static function get_emote_defs():Array<EmoteDef>
		return map_to_array(emotes);

	public static function get_present_names():Array<String>
		return present_defs.map((def:PresentDef) -> return def.name);

	public static function get_present_defs():Array<PresentDef>
		return map_to_array(presents);

	public static inline function map_to_array<T:Dynamic>(map:Map<String, T>):Array<T>
	{
		var vals:Array<T> = [];
		for (val in map)
			vals.push(val);
		return vals;
	}

	public static function check_for_unlock_costume(costume:CostumeDef):Bool
	{
		if (costume.unlock == null)
			return true;
		return data.types.TankmasEnums.UnlockCondition.get_unlocked(costume.unlock, costume.data);
	}

	public static function check_for_unlock_emote(emote:EmoteDef):Bool
		return SaveManager.saved_emote_collection.contains(emote.name);

	public static function random_draw_emotes(amount:Int, ?limit_list:Array<String>)
	{
		var drawn_emotes:Array<String> = [];
		for (n in 0...amount)
		{
			var random_emote:String = null;
			while (random_emote == null
				|| SaveManager.saved_emote_collection.contains(random_emote)
				|| drawn_emotes.contains(random_emote))
				random_emote = Main.ran.getObject(limit_list == null ? emote_names : limit_list);
			drawn_emotes.push(random_emote);
		}
		return drawn_emotes;
	}
}
