package ui.sheets;

import data.JsonData;
import data.SaveManager;
import entities.Player;
import ui.sheets.BaseSelectSheet;
import ui.sheets.defs.SheetDefs.SheetDef;
import ui.sheets.defs.SheetDefs.SheetMenuDef;

class EmoteSelectSheet extends BaseSelectSheet
{
	public function new(sheet_name:String, menu:SheetMenu, ?forceState:Bool = true)
	{
		super(sheet_name, menu, EMOTES);
	}

	override function load_new_def(name:String):SheetMenuDef
	{
		var def:SheetDef = JsonData.get_emote_sheet(name);
		return {
			name: def.name,
			src: def,
			grid_1D: [],
			grid_2D: []
		}
	}

	override function save_selection()
	{
		super.save_selection();

		// SheetMenu.local_saves[EMOTES].selection = selection;
		// SheetMenu.local_saves[EMOTES].sheet_name = def.name;

		// SaveManager.current_emote = characterNames[locked_sheet][locked_selection];

		SaveManager.save_emotes(true);
	}
}
