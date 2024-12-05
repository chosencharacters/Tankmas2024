package ui.sheets.buttons;

import ui.button.HoverButton;
import ui.sheets.BaseSelectSheet.SheetType;

class SheetButton extends HoverButton
{
	var sheet_type:SheetType;

	public function new(X:Float, Y:Float, image:String, sheet_type:SheetType)
	{
		super(X, Y);
		this.sheet_type = sheet_type;
		loadAllFromAnimationSet(image);
	}
}
