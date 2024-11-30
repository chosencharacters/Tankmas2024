package ui.sheets;

import squid.ext.FlxTypedGroupExt;
import states.substates.SheetSubstate;

enum SheetTab
{
	COSTUMES;
	STICKERS;
}

class SheetMenu extends FlxTypedGroupExt<BaseSelectSheet>
{
	var costumes:CostumeSelectSheet;
	var stickers:StickerSelectSheet;

	var current(get, never):BaseSelectSheet;

	var tabs:Array<SheetTab> = [COSTUMES, STICKERS];
	var tab(get, never):SheetTab;

	public function new(open_on_tab:SheetTab = COSTUMES)
	{
		super();

		FlxG.state.openSubState(new SheetSubstate(this));

		costumes = new CostumeSelectSheet(this);
		stickers = new StickerSelectSheet(this);

		add(stickers);
		add(costumes);

		cycle_tabs_until(open_on_tab);

		update_tab_states();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
	}

	public function open()
	{
		visible = true;
	}

	override function set_visible(visible:Bool):Bool
		return this.visible = visible;

	function get_current():BaseSelectSheet
		return tab == COSTUMES ? costumes : stickers;

	public function start_closing(?on_complete:Void->Void)
		current.start_closing(on_complete);

	function cycle_tabs_until(new_tab:SheetTab)
		while (tab != new_tab)
			next_tab();

	public function next_tab()
	{
		tabs.push(tabs.shift());
		members.push(members.shift());
		update_tab_states();
	}

	public function update_tab_states()
	{
		for (sheet in members)
			sheet.visible = sheet == current;
		for (sheet in members)
			sheet.set_sheet_active(sheet == current);
	}

	function get_tab():SheetTab
		return tabs[0];
}
