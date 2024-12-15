package states.debug;

import data.JsonData;
import ui.sheets.SheetMenu;

class DebugSheetMenuState extends BaseState
{
	override function create()
	{
		super.create();
		JsonData.init();
		Lists.init();
		add(new SheetMenu());
	}
}
