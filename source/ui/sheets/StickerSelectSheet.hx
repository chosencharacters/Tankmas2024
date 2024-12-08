package ui.sheets;

import data.SaveManager;
import entities.Player;
import ui.sheets.BaseSelectSheet;
import ui.sheets.defs.SheetDefs.SheetFileDef;

class StickerSelectSheet extends BaseSelectSheet
{
	public static var saved_sheet:Int = 0;
	public static var saved_selection:Int = 0;
	public static var seenStickers:Array<String>;

	public function new(menu:SheetMenu, ?forceState:Bool = true)
	{
		super(menu, saved_sheet, saved_selection, STICKER);
		seen = seenStickers.copy();
	}

	override function make_sheet_collection():SheetFileDef
		return haxe.Json.parse(Utils.load_file_string('sticker-sheets.json'));

	override function save_selection()
	{
		SaveManager.current_emote = characterNames[locked_sheet][locked_selection];

		saved_sheet = locked_sheet;
		saved_selection = locked_selection;
		seenStickers = seen.copy();

		SaveManager.save_emotes(true);
	}
}
