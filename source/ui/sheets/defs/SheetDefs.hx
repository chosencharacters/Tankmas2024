package ui.sheets.defs;

import ui.sheets.buttons.SheetButton;

typedef SheetFileDef =
{
	var sheets:Array<SheetDef>;
}

typedef SheetDef =
{
	var name:String;
	var items:Array<SheetItemDef>;
}

typedef SheetItemDef =
{
	var name:String;
	var ?angle:Int;
	var ?xOffset:Float;
	var ?yOffset:Float;
}

typedef SheetMenuDef =
{
	var name:String;
	var src:SheetDef;
	var grid_1D:Array<SheetButton>;
	var grid_2D:Array<Array<SheetButton>>;
}
