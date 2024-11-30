package ui.sheets;

import squid.ext.FlxGroupExt;

enum SheetTab
{
	COSTUMES;
	STICKERS;
}

class SheetMenu extends FlxGroupExt<BaseSelectSheet>
{
	var costumes:CostumeSelectSheet;
	var stickers:StickerSelectSheet;

	public function new(current_sheet:SheetTab = COSTUMES)
	{
		super();

		costumes = new CostumeSelectSheet();
		stickers = new StickerSelectSheet();

		add(stickers);
		add(costumes);
	}

	override function set_visible(visible:Bool):Bool
		return this.visible = visible;
}
