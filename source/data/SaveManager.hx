package data;

import http.HttpError;
import net.tankmas.TankmasClient;
import ui.sheets.CostumeSelectSheet;
import ui.sheets.EmoteSelectSheet;
import ui.sheets.SheetMenu;

class SaveManager
{
	public static var savedPresents:Array<String> = [];
	public static var savedCostumes:Array<String> = [];
	public static var savedEmotes:Array<String> = [];
	public static var savedRoom:String;

	public static var saved_emote_collection:Array<String>;
	public static var saved_costume_collection:Array<String>;

	public static var current_costume(default, default):String;
	public static var current_emote(default, default):String;

	public static var on_save_stored:() -> Void = null;

	// will sort this out tomorrow
	public static var has_emote_pack:Bool = false;
	public static var has_rare_emote_pack(get, default):Bool;

	static function get_has_rare_emote_pack():Bool
		return saved_emote_collection.length < (Main.default_emote_collection.length * 2);

	public static var data = {
		saved_room: Main.default_room,
	}

	public static function init()
	{
		savedRoom = Main.default_room;
		saved_emote_collection = Main.default_emote_collection;
		saved_costume_collection = Main.default_costume_collection;
		current_emote = Main.default_emote;
		current_costume = Main.default_costume;

		Flags.generate();

		trace(saved_emote_collection);
	}

	static function finalize_load()
	{
		load_flags();

		load_collections();

		// if it's December 1st, reset it...?
		// if(Date.now().getMonth() == 11 && Date.now().getDate() == 1) return;

		// opened presents
		load_presents();

		// loads current room
		load_room();
	}

	public static function upload()
	{
		// Serialize data
		var encodedData = haxe.Serializer.run(FlxG.save.data);

		// Upload data
		TankmasClient.post_save(encodedData, (data:Dynamic) ->
		{
			trace("Successfully uploaded save data.");
			if (on_save_stored != null)
				on_save_stored();
		});
	}

	public static function load(on_complete:() -> Void = null, ?on_fail:() -> Void)
	{
		#if offline
		finalize_load();
		if (on_complete != null)
			on_complete();
		#else
		// Download data
		TankmasClient.get_save((data:Dynamic) ->
		{
			trace("Successfully downloaded save data.");

			var encodedData = data?.data;

			if (encodedData != null)
			{
				// Deserialize data
				var data = haxe.Unserializer.run(encodedData);
				trace('Successfully deserialized save data.');
				trace(data);
				FlxG.save.mergeData(data, true);
			}

			finalize_load();

			if (on_complete != null)
				on_complete();
		}, (error:HttpError) ->
			{
				if (on_fail != null)
					on_fail();
				trace('Failed to download save');
			});
		#end
	}

	public static function save()
	{
		save_flags();
		save_presents();
		save_costumes();
		save_emotes();
		save_room();
		save_collections();
		flush();

		upload();
	}

	public static function flush()
	{
		try
		{
			FlxG.save.flush();
		}
		catch (e)
		{
			trace("SAVE ERROR: " + e);
		}
	}

	public static function save_flags(force:Bool = false)
	{
		FlxG.save.data.flags = Flags.get_all();
	}

	public static function load_flags()
	{
		if (FlxG.save.data.flags != null)
			Flags.load(FlxG.save.data.flags);
	}

	public static function save_collections(force:Bool = false):Void
	{
		FlxG.save.data.locked_selections = SheetMenu.locked_selections;
		FlxG.save.data.emote_collection = saved_emote_collection;

		if (SheetMenu.locked_selections != null)
		{
			SaveManager.current_costume = SheetMenu.locked_selections.get(COSTUMES).selection_name;
			SaveManager.current_emote = SheetMenu.locked_selections.get(EMOTES).selection_name;
		}

		if (force)
			flush();
	}

	public static function load_collections(force:Bool = false):Void
	{
		if (FlxG.save.data.locked_selections != null)
		{
			// null cases are handled by SheetMenu
			SheetMenu.locked_selections = FlxG.save.data.locked_selections;
			SaveManager.current_costume = SheetMenu.locked_selections.get(COSTUMES).selection_name;
			SaveManager.current_emote = SheetMenu.locked_selections.get(EMOTES).selection_name;
		}

		saved_emote_collection = FlxG.save.data.emote_collection ?? Main.default_emote_collection;

		#if newgrounds
		/*
			for (emote_def in JsonData.emote_defs)
				if (!saved_emote_collection.contains(emote_def.name))
					if (emote_def.artist.toLowerCase() == Main.ng_api.NG_USERNAME.toLowerCase())
						saved_emote_collection.push(emote_def.name);
		 */
		#end
	}

	public static function load_presents(force:Bool = false):Void
	{
		if (FlxG.save.data.savedPresents == null)
		{
			trace("Error loading saved presents (might be empty)");
			save_presents(true);
		}
		savedPresents = FlxG.save.data.savedPresents;
	}

	public static function load_emotes():Void
	{
		if (FlxG.save.data.savedEmotes == null)
		{
			trace("Error loading saved emotes (might be empty)");
			save_emotes(true);
		}
		savedEmotes = FlxG.save.data.savedEmotes;
	}

	public static function load_room():Void
	{
		if (FlxG.save.data.savedRoom == null)
		{
			trace("Error loading saved room (might be empty)");
			save_room(true);
		}
		savedRoom = FlxG.save.data.savedRoom;
	}

	public static function open_present(username:String, present_day:Int, got_medal:Bool)
	{
		if (!savedPresents.contains(username))
		{
			savedPresents.push(username);
			save_presents(true);
		}
	}

	public static function save_presents(force:Bool = false)
	{
		FlxG.save.data.savedPresents = savedPresents;
		if (force)
			flush();
	}

	public static function save_costumes(force:Bool = false)
	{
		FlxG.save.data.savedCostumes = savedCostumes;
		FlxG.save.data.currentCostume = current_costume;
		// FlxG.save.data.savedCostumeSheet = CostumeSelectSheet.saved_sheet;
		// FlxG.save.data.savedCostumeSelect = CostumeSelectSheet.saved_selection;
		FlxG.save.data.seenCostumes = CostumeSelectSheet.seenCostumes;
		/*trace(FlxG.save.data.savedCostumes, FlxG.save.data.currentCostume, FlxG.save.data.savedCostumeSheet, FlxG.save.data.savedCostumeSelect,
			FlxG.save.data.seenCostumes); */

		if (force)
			flush();
	}

	public static function save_emotes(force:Bool = false)
	{
		FlxG.save.data.savedEmotes = savedEmotes;
		FlxG.save.data.currentEmote = current_emote;
		// FlxG.save.data.savedEmoteSheet = EmoteSelectSheet.saved_sheet;
		// FlxG.save.data.savedEmoteSelect = EmoteSelectSheet.saved_selection;
		if (force)
			flush();
	}

	public static function save_room(force:Bool = false)
	{
		FlxG.save.data.savedRoom = savedRoom;
		if (force)
			flush();
	}
}
