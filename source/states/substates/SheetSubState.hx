package states.substates;

import data.JsonData;
import data.SaveManager;
import data.types.TankmasDefs.CostumeDef;
import flixel.FlxBasic;
import flixel.FlxSubState;
import flixel.util.FlxTimer;
import squid.ext.FlxSubstateExt;
import ui.sheets.SheetMenu;

class SheetSubstate extends FlxSubstateExt
{
	var sheet_menu:SheetMenu;

	public static var self:SheetSubstate;

	override public function new(sheet_menu:SheetMenu)
	{
		super();

		self = this;

		this.sheet_menu = sheet_menu;

		add(sheet_menu);

		sstate(ACTIVE);
	}

	override function update(elapsed:Float)
	{
		sheet_menu.update(elapsed);

		Ctrl.update();

		super.update(elapsed);

		fsm();
	}

	function fsm()
		switch (cast(state, State))
		{
			default:
			case ACTIVE:
				if (Ctrl.jmenu[1])
					sheet_menu.back_button_activated();
			case CLOSING:
				return;
		}

	override function close()
	{
		Ctrl.mode = ControlModes.OVERWORLD;
		sheet_menu.kill();
		self = null;
		PlayState.self.ui_overlay.reveal_top_ui();
		super.close();
	}
}

private enum abstract State(String) from String to String
{
	var ACTIVE;
	var CLOSING;
}
