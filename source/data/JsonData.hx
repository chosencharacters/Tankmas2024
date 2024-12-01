package data;

import data.types.TankmasDefs.CostumeDef;
import data.types.TankmasDefs.PresentDef;
import data.types.TankmasDefs.StickerDef;

/**
 * Mostly a wrapper for a JSON loaded costumes Map
 */
class JsonData
{
	static var costumes:Map<String, CostumeDef>;
	static var presents:Map<String, PresentDef>;
	static var stickers:Map<String, StickerDef>;

	public static var all_costume_defs(get, default):Array<CostumeDef>;
	public static var all_costume_names(get, default):Array<String>;

	public static var all_present_defs(get, default):Array<PresentDef>;
	public static var all_present_names(get, default):Array<String>;

	public static var all_sticker_defs(get, default):Array<StickerDef>;
	public static var all_sticker_names(get, default):Array<String>;

	public static function init()
	{
		load_costumes();
		load_presents();
		load_stickers();
	}

	static function load_costumes()
	{
		costumes = [];
		var json:{costumes:Array<CostumeDef>} = haxe.Json.parse(Utils.load_file_string("costumes.json"));

		for (costume_def in json.costumes)
			costumes.set(costume_def.name, costume_def);
	}

	static function load_presents()
	{
		presents = [];
		var json:{presents:Array<PresentDef>} = haxe.Json.parse(Utils.load_file_string("presentarts.json"));

		for (present_def in json.presents)
			presents.set(present_def.file, present_def);
	}

	static function load_stickers()
	{
		stickers = [];
		var json:{stickers:Array<StickerDef>} = haxe.Json.parse(Utils.load_file_string("stickers.json"));

		for (sticker_def in json.stickers)
			stickers.set(sticker_def.name, sticker_def);
	}

	public static function get_costume(costume_name:String):CostumeDef
		return costumes.get(costume_name);

	public static function get_present(present_name:String):PresentDef
		return presents.get(present_name);

	public static function get_sticker(sticker_name:String):StickerDef
		return stickers.get(sticker_name);

	public static function check_for_unlock_costume(costume:CostumeDef):Bool
	{
		if (costume.unlock == null)
			return true;
		return data.types.TankmasEnums.UnlockCondition.get_unlocked(costume.unlock, costume.data);
	}

	public static function check_for_unlock_sticker(sticker:StickerDef):Bool
	{
		return SaveManager.saved_sticker_collection.contains(sticker.name);
		/*
			if (sticker.unlock == null)
				return true;
			return data.types.TankmasEnums.UnlockCondition.get_unlocked(sticker.unlock, sticker.data);
		 */
	}

	static function get_all_costume_defs():Array<CostumeDef>
	{
		var arr:Array<CostumeDef> = [];
		for (val in costumes)
			arr.push(val);
		return arr;
	}

	static function get_all_costume_names():Array<String>
	{
		var arr:Array<String> = [];
		for (val in costumes.keys())
			arr.push(val);
		return arr;
	}

	static function get_all_present_defs():Array<PresentDef>
	{
		var arr:Array<PresentDef> = [];
		for (val in presents)
			arr.push(val);
		return arr;
	}

	static function get_all_present_names():Array<String>
	{
		var arr:Array<String> = [];
		for (val in presents.keys())
			arr.push(val);
		return arr;
	}

	static function get_all_sticker_defs():Array<StickerDef>
	{
		var arr:Array<StickerDef> = [];
		for (val in stickers)
			arr.push(val);
		return arr;
	}

	static function get_all_sticker_names():Array<String>
	{
		var arr:Array<String> = [];
		for (val in stickers.keys())
			arr.push(val);
		return arr;
	}

	public static function random_draw_stickers(amount:Int, ?limit_list:Array<String>)
	{
		var drawn_stickers:Array<String> = [];
		for (n in 0...amount)
		{
			var random_sticker:String = null;
			while (random_sticker == null || SaveManager.saved_sticker_collection.contains(random_sticker))
				random_sticker = Main.ran.getObject(limit_list == null ? all_sticker_names : limit_list);
			drawn_stickers.push(random_sticker);
		}
		return drawn_stickers;
	}
}
