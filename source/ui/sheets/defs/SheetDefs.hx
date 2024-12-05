package ui.sheets.defs;

import ui.sheets.buttons.SheetButton;

typedef SheetFileDef =
{
	var sheets:Array<SheetDef>;
}

typedef SheetDef =
{
	var ?graphic:String;
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
	var grid:Array<Array<SheetButton>>;
}
