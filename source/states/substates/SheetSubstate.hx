package states.substates;

import data.JsonData;
import data.SaveManager;
import data.types.TankmasDefs.CostumeDef;
import flixel.FlxBasic;
import flixel.FlxSubState;
import flixel.util.FlxTimer;
import squid.ext.FlxSubstateExt;
import ui.sheets.SheetMenu;

class SheetSubstate extends FlxSubStateExt
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

		super.update(elapsed);

		fsm();
	}

	function fsm()
		switch (cast(state, State))
		{
			default:
			case ACTIVE:
				if (Ctrl.jmenu[1])
					start_closing();
			case CLOSING:
				return;
		}

	public function start_closing()
	{
		sheet_menu.start_closing(() -> close_and_close_substate());
		sstate(CLOSING);
	}

	public function close_and_close_substate()
	{
		/*
			var new_costume:CostumeDef = JsonData.get_costume(SaveManager.current_costume);
			if (new_costume != null && new_costume.name != PlayState.self.player.costume.name)
			{
				PlayState.self.player.new_costume(JsonData.get_costume(SaveManager.current_costume));
				FlxG.camera.flash(FlxColor.BLACK, 0.5);
			}
		 */
		close();
		FlxG.state.closeSubState();
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
