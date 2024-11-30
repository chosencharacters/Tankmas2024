package states.substates;

import flixel.FlxBasic;
import flixel.util.FlxTimer;
import ui.sheets.BaseSelectSheet;
import ui.sheets.CostumeSelectSheet;
import ui.sheets.StickerSelectSheet;

class SheetSubstate extends flixel.FlxSubState
{
	var sheet_ui:BaseSelectSheet;

	public static var instance:SheetSubstate;

	override public function new(sheet_ui:BaseSelectSheet)
	{
		super();

		this.sheet_ui = sheet_ui;

		instance = this;

		add(sheet_ui);

		trace("substate exists");
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		if (Ctrl.jinteract[1] && sheet_ui.canSelect)
		{
			sheet_ui.transOut();
			new FlxTimer().start(1.2, function(tmr:FlxTimer)
			{
				close();
			});
		}
	}

	public function reload(type:String)
	{
		remove(sheet_ui);
		sheet_ui = type == "COSTUME" ? new CostumeSelectSheet(false) : new StickerSelectSheet(false);
		add(sheet_ui);
	}

	override function close()
	{
		sheet_ui.kill();
		super.close();
	}
}
