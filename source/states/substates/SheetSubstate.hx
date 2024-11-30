package states.substates;

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

		add(this.sheet_menu = sheet_menu);

		sstate(ACTIVE);

		trace("substate exists");
	}

	override function update(elapsed:Float)
	{
		fsm();

		super.update(elapsed);
	}

	function fsm()
		switch (cast(state, State))
		{
			default:
			case ACTIVE:
				Ctrl.update();
				if (Ctrl.jinteract[1])
				{
					sheet_menu.start_closing();
					sstate(CLOSING);
				}
			case CLOSING:
				return;
		}

	override function close()
	{
		sheet_menu.kill();
		self = null;
		super.close();
	}
}

private enum abstract State(String) from String to String
{
	var ACTIVE;
	var CLOSING;
}
