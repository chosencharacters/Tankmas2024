package ui.sheets;

import data.SaveManager;
import entities.Player;
import ui.sheets.BaseSelectSheet;
import ui.sheets.defs.SheetDefs.SheetFileDef;

class CostumeSelectSheet extends BaseSelectSheet
{
	public static var saved_sheet:Int = 0;
	public static var saved_selection:Int = 0;
	public static var seenCostumes:Array<String> = [];

	public function new(menu:SheetMenu, ?forceState:Bool = true)
	{
		super(menu, saved_sheet, saved_selection, COSTUME);
		seen = seenCostumes;
	}

	override function make_sheet_collection():SheetFileDef
		return haxe.Json.parse(Utils.load_file_string('costume-sheets.json'));

	override function save_selection()
	{
		SaveManager.current_costume = characterNames[locked_sheet][locked_selection];

		saved_sheet = locked_sheet;
		saved_selection = locked_selection;
		seenCostumes = seen;

		SaveManager.save_costumes(true);

		PlayState.self.player.new_costume(data.JsonData.get_costume(SaveManager.current_costume));
	}
}
