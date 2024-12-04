package states.debug;

import ui.sheets.SheetMenu;

class DebugMenuState extends BaseState
{
	override function create()
	{
		super.create();
		add(new SheetMenu());
	}
}
