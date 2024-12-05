package ui.sheets;

import data.SaveManager;
import entities.Player;
import ui.sheets.BaseSelectSheet;
import ui.sheets.defs.SheetDefs.SheetFileDef;
import ui.sheets.defs.SheetDefs.SheetMenuDef;

class CostumeSelectSheet extends BaseSelectSheet
{
	public static var saved_sheet:Int = 0;
	public static var saved_selection:Int = 0;
	public static var seenCostumes:Array<String> = [];

	public function new(menu:SheetMenu, ?forceState:Bool = true)
	{
		super(menu, saved_sheet, saved_selection, COSTUME);
		seen = seenCostumes.copy();
	}

	override function load_def():SheetMenuDef
	{
		var file_def:SheetFileDef = haxe.Json.parse(Utils.load_file_string('costume-sheets.json'));
		return {name: file_def.sheets, src: file_def}
	}

	override function save_selection()
	{
		SaveManager.current_costume = characterNames[locked_sheet][locked_selection];

		saved_sheet = locked_sheet;
		saved_selection = locked_selection;
		seenCostumes = seen.copy();

		SaveManager.save_costumes(true);

		PlayState.self.player.new_costume(data.JsonData.get_costume(SaveManager.current_costume));
	}
}
