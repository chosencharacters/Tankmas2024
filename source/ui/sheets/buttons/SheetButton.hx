package ui.sheets.buttons;

import ui.button.HoverButton;
import ui.sheets.BaseSelectSheet.SheetType;
import ui.sheets.defs.SheetDefs.SheetItemDef;

class SheetButton extends HoverButton
{
	var sheet_type:SheetType;

	public var empty:Bool;

	var def:SheetItemDef;

	public function new(X:Float, Y:Float, def:SheetItemDef, sheet_type:SheetType, ?on_release:HoverButton->Void)
	{
		super(X, Y);
		this.sheet_type = sheet_type;

		this.def = def;

		empty = def.name == null || def.name == "";
		loadAllFromAnimationSet(!empty ? def.name : "thomas");
	}
}
