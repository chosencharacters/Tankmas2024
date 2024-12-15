package ui.sheets.buttons;

import data.JsonData;
import data.types.TankmasDefs.CostumeDef;
import data.types.TankmasDefs.EmoteDef;
import ui.button.HoverButton;
import ui.sheets.BaseSelectSheet.SheetType;
import ui.sheets.defs.SheetDefs.SheetItemDef;

class SheetButton extends HoverButton
{
	var sheet_type:SheetType;

	public var empty:Bool;
	public var unlocked:Bool;

	public var def:SheetItemDef;

	public function new(X:Float, Y:Float, def:SheetItemDef, sheet_type:SheetType, ?on_release:HoverButton->Void)
	{
		super(X, Y, on_release);
		this.sheet_type = sheet_type;

		this.def = def;

		empty = def.name == null || def.name == "";
		loadAllFromAnimationSet(!empty ? def.name : "thomas");

		update_unlocked();
	}

	public function update_unlocked()
	{
		unlocked = eval_unlocked();

		color = unlocked ? FlxColor.WHITE : FlxColor.BLACK;
		if (empty)
			visible = false;
	}

	public function eval_unlocked():Bool
	{
		if (empty)
			return false;
		switch (sheet_type)
		{
			case SheetType.COSTUMES:
				var costume:CostumeDef = JsonData.get_costume(def.name);
				if (costume.unlock != null)
					return data.types.TankmasEnums.UnlockCondition.get_unlocked(costume.unlock, costume.data);
			case SheetType.EMOTES:
				var emote:EmoteDef = JsonData.get_emote(def.name);
				if (emote.unlock != null)
					return data.types.TankmasEnums.UnlockCondition.get_unlocked(emote.unlock, emote.data);
		}
		return true;
	}
}
