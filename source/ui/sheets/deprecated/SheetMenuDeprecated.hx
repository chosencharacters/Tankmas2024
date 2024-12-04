#if deprecated
package ui.sheets;

import flixel.tweens.FlxEase;
import squid.ext.FlxTypedGroupExt;
import states.substates.SheetSubstate;
import ui.Button.BackButton;
import ui.button.HoverButton;

enum SheetTab
{
	COSTUMES;
	STICKERS;
}

class SheetMenuDeprecated extends FlxTypedGroupExt<BaseSelectSheet>
{
	var costumes:CostumeSelectSheet;
	var stickers:StickerSelectSheet;

	var current(get, never):BaseSelectSheet;

	var tabs:Array<SheetTab> = [COSTUMES, STICKERS];
	var tab(get, never):SheetTab;

	var back_button:HoverButton;

	var substate:SheetSubstate;

	public function new(open_on_tab:SheetTab = COSTUMES)
	{
		super();

		FlxG.state.openSubState(substate = new SheetSubstate(this));

		costumes = new CostumeSelectSheet(this);
		stickers = new StickerSelectSheet(this);

		add(stickers);
		add(costumes);

		cycle_tabs_until(open_on_tab);

		substate.add(back_button = new HoverButton((b) -> back_button_activated()));

		back_button.scrollFactor.set(0, 0);

		back_button.loadAllFromAnimationSet("back-arrow");
		back_button.setPosition(FlxG.width - back_button.width - 16, FlxG.height - back_button.height - 16);
		back_button.offset.y = -back_button.height;
		back_button.tween = FlxTween.tween(back_button.offset, {y: 0}, 0.25, {ease: FlxEase.cubeInOut});

		update_tab_states();
	}

	function back_button_activated()
	{
		back_button.tween = FlxTween.tween(back_button, {y: FlxG.height + back_button.height}, 0.25, {ease: FlxEase.cubeInOut});
		back_button.disable();
		substate.start_closing();
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
#end
