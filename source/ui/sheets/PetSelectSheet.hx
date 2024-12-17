package ui.sheets;

import data.JsonData;
import ui.sheets.BaseSelectSheet;
import ui.sheets.defs.SheetDefs.SheetDef;
import ui.sheets.defs.SheetDefs.SheetMenuDef;

class PetSelectSheet extends BaseSelectSheet
{
	public function new(sheet_name:String, menu:SheetMenu, ?forceState:Bool = true)
	{
		super(sheet_name, menu, PETS);
	}

	override function load_new_def(name:String):SheetMenuDef
	{
		var def:SheetDef = JsonData.get_pet_sheet(name);
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

		// SheetMenu.local_saves[COSTUMES].selection = selection;
		// SheetMenu.local_saves[COSTUMES].sheet_name = def.name;

		// SaveManager.current_costume = characterNames[locked_sheet][locked_selection];

		// seenCostumes = seen.copy();

		// SaveManager.save_costumes(true);

		// PlayState.self.player.new_costume(data.JsonData.get_costume(SaveManager.current_costume));
	}
}
