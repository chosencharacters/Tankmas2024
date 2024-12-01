package data;

import entities.Player;
import ui.sheets.CostumeSelectSheet;
import ui.sheets.StickerSelectSheet;

class SaveManager
{
	public static var savedPresents:Array<String> = [];
	public static var savedCostumes:Array<String> = [];
	public static var savedEmotes:Array<String> = [];
	public static var savedRoom:String;
	public static var saved_sticker_collection:Array<String>;
	public static var saved_costume_collection:Array<String>;

	public static function init()
	{
		savedRoom = Main.default_room;

		saved_sticker_collection = Main.default_sticker_collection;
		saved_costume_collection = Main.default_costume_collection;

		// opened presents
		load_presents();

		// unlocked costumes, as well as what the player is currently wearing
		load_costumes();

		// unlocked emotes, as well as what emote the player is currently using
		load_emotes();

		// loads current room
		load_room();
	}

	public static function save()
	{
		save_presents();
		save_costumes();
		save_emotes();
		save_room();
		save_collections();
		FlxG.save.flush();
	}

	public static function save_collections(force:Bool = false):Void
	{
		save_costume_collection(force);
		save_sticker_collection(force);
	}

	public static function save_costume_collection(force:Bool = false):Void
	{
		FlxG.save.data.costume_collection = saved_costume_collection;
		if (force)
			FlxG.save.flush();
	}

	public static function save_sticker_collection(force:Bool = false):Void
	{
		FlxG.save.data.savedPresents = saved_sticker_collection;
		if (force)
			FlxG.save.flush();
	}

	public static function load_costume_collection(force:Bool = false):Void
	{
		if (FlxG.save.data.saved_costume_collection == null)
		{
			trace("Error loading saved costumes");
			save_costume_collection(true);
		}
		savedPresents = FlxG.save.data.savedPresents;
	}

	public static function load_sticker_collection(force:Bool = false):Void
	{
		if (FlxG.save.data.saved_sticker_collection == null)
		{
			trace("Error loading saved stickers");
			save_sticker_collection(true);
		}
		savedPresents = FlxG.save.data.savedPresents;
	}

	public static function load_presents(force:Bool = false):Void
	{
		if (FlxG.save.data.savedPresents == null)
		{
			trace("Error loading saved presents");
			save_presents(true);
		}
		savedPresents = FlxG.save.data.savedPresents;
	}

	public static function load_costumes():Void
	{
		if (FlxG.save.data.savedCostumes == null)
		{
			trace("Error loading saved costumes");
			save_costumes(true);
		}
		savedCostumes = FlxG.save.data.savedCostumes;
		if (FlxG.save.data.currentCostume != null && PlayState.self != null)
			PlayState.self.player.new_costume(JsonData.get_costume(FlxG.save.data.currentCostume));
		CostumeSelectSheet.saved_sheet = FlxG.save.data.savedCostumeSheet != null ? FlxG.save.data.savedCostumeSheet : 0;
		CostumeSelectSheet.saved_selection = FlxG.save.data.savedCostumeSelect != null ? FlxG.save.data.savedCostumeSelect : 0;
		CostumeSelectSheet.seenCostumes = FlxG.save.data.seenCostumes != null ? FlxG.save.data.seenCostumes : [];
	}

	public static function load_emotes():Void
	{
		if (FlxG.save.data.savedEmotes == null)
		{
			trace("Error loading saved emotes");
			save_emotes(true);
		}
		savedEmotes = FlxG.save.data.savedEmotes;
		if (FlxG.save.data.currentEmote != null && PlayState.self != null)
			PlayState.self.player.sticker = FlxG.save.data.currentEmote;
		StickerSelectSheet.saved_sheet = FlxG.save.data.savedEmoteSheet != null ? FlxG.save.data.savedEmoteSheet : 0;
		StickerSelectSheet.saved_selection = FlxG.save.data.savedEmoteSelect != null ? FlxG.save.data.savedEmoteSelect : 0;
		StickerSelectSheet.seenStickers = FlxG.save.data.seenEmotes != null ? FlxG.save.data.seenEmotes : [];
	}

	public static function load_room():Void
	{
		if (FlxG.save.data.savedRoom == null)
		{
			trace("Error loading saved room");
			save_room(true);
		}
		savedRoom = FlxG.save.data.savedRoom;
	}

	public static function open_present(content:String, day:Int)
	{
		if (savedPresents.contains(content))
			return;
		trace("saving present" + content);
		savedPresents.push(content);
		// TODO: find medal accompanying present
		save_presents(true);
	}

	public static function save_presents(force:Bool = false)
	{
		FlxG.save.data.savedPresents = savedPresents;
		if (force)
			FlxG.save.flush();
	}

	public static function save_costumes(force:Bool = false)
	{
		FlxG.save.data.savedCostumes = savedCostumes;
		FlxG.save.data.currentCostume = PlayState.self == null ? 'tankman' : PlayState.self.player.costume.name;
		FlxG.save.data.savedCostumeSheet = CostumeSelectSheet.saved_sheet;
		FlxG.save.data.savedCostumeSelect = CostumeSelectSheet.saved_selection;
		FlxG.save.data.seenCostumes = CostumeSelectSheet.seenCostumes;
		if (force)
			FlxG.save.flush();
	}

	public static function save_emotes(force:Bool = false)
	{
		FlxG.save.data.savedEmotes = savedEmotes;
		FlxG.save.data.currentEmote = PlayState.self == null ? 'edd-sticker' : PlayState.self.player.sticker;
		FlxG.save.data.savedEmoteSheet = StickerSelectSheet.saved_sheet;
		FlxG.save.data.savedEmoteSelect = StickerSelectSheet.saved_selection;
		FlxG.save.data.seenEmotes = StickerSelectSheet.seenStickers;
		if (force)
			FlxG.save.flush();
	}

	public static function save_room(force:Bool = false)
	{
		FlxG.save.data.savedRoom = savedRoom;
		if (force)
			FlxG.save.flush();
	}
}
