package data;

import data.types.TankmasDefs.CostumeDef;
import data.types.TankmasDefs.PetDef;
import data.types.TankmasDefs.PresentDef;
import data.types.TankmasDefs.StickerDef;
import entities.Pet;

/**
 * Mostly a wrapper for a JSON loaded costumes Map
 */
class JsonData
{
	static var costumes:Map<String, CostumeDef>;
	static var presents:Map<String, PresentDef>;
	static var stickers:Map<String, StickerDef>;
	static var pets:Map<String, PetDef>;

	public static var all_costume_defs(get, default):Array<CostumeDef>;
	public static var all_costume_names(get, default):Array<String>;

	public static var all_present_defs(get, default):Array<PresentDef>;
	public static var all_present_names(get, default):Array<String>;

	public static var all_sticker_defs(get, default):Array<StickerDef>;
	public static var all_sticker_names(get, default):Array<String>;

	public static var all_pet_defs(get, default):Array<PetDef>;
	public static var all_pet_names(get, default):Array<String>;

	public static function init()
	{
		load_costumes();
		load_presents();
		load_stickers();
		load_pets();
	}

	static function load_costumes()
	{
		costumes = [];
		var json:{costumes:Array<CostumeDef>} = haxe.Json.parse(Utils.load_file_string("costumes.json"));

		for (costume_def in json.costumes)
			costumes.set(costume_def.name, costume_def);
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

	static function load_presents()
	{
		presents = [];
		var json:{presents:Array<PresentDef>} = haxe.Json.parse(Utils.load_file_string("presents.json"));

		for (present_def in json.presents)
			presents.set(present_def.artist.toLowerCase(), present_def);
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

	public static function get_pet(pet_name:String):PetDef
		return pets.get(pet_name);

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

	public static function get_all_costume_defs():Array<CostumeDef>
	{
		var arr:Array<CostumeDef> = [];
		for (val in costumes)
			arr.push(val);
		return arr;
	}

	public static function get_all_costume_names():Array<String>
	{
		var arr:Array<String> = [];
		for (val in costumes.keys())
			arr.push(val);
		return arr;
	}

	public static function get_all_pet_defs():Array<PetDef>
	{
		var arr:Array<PetDef> = [];
		for (val in pets)
			arr.push(val);
		return arr;
	}

	public static function get_all_pet_names():Array<String>
	{
		var arr:Array<String> = [];
		for (val in pets.keys())
			arr.push(val);
		return arr;
	}

	public static function get_all_present_defs():Array<PresentDef>
	{
		var arr:Array<PresentDef> = [];
		for (val in presents)
			arr.push(val);
		return arr;
	}

	public static function get_all_present_names():Array<String>
	{
		var arr:Array<String> = [];
		for (val in presents.keys())
			arr.push(val);
		return arr;
	}

	public static function get_all_sticker_defs():Array<StickerDef>
	{
		var arr:Array<StickerDef> = [];
		for (val in stickers)
			arr.push(val);
		return arr;
	}

	public static function get_all_sticker_names():Array<String>
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
			while (random_sticker == null
				|| SaveManager.saved_sticker_collection.contains(random_sticker)
				|| drawn_stickers.contains(random_sticker))
				random_sticker = Main.ran.getObject(limit_list == null ? all_sticker_names : limit_list);
			drawn_stickers.push(random_sticker);
		}
		return drawn_stickers;
	}
}
