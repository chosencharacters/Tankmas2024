package ui.sheets;

import data.JsonData;
import flixel.FlxBasic;
import flixel.tweens.FlxEase;
import squid.ext.FlxTypedGroupExt;
import states.substates.SheetSubstate;
import ui.Button.BackButton;
import ui.button.HoverButton;
import ui.sheets.BaseSelectSheet.SheetType;

typedef SheetPosition =
{
	var sheet_name:String;
	var selection:Int;
}

class SheetMenu extends FlxTypedGroupExt<FlxBasic>
{
	var tab_order:Array<SheetType> = [COSTUMES, EMOTES];

	var costume_sheets:FlxTypedGroupExt<CostumeSelectSheet> = new FlxTypedGroupExt<CostumeSelectSheet>();
	var emote_sheets:FlxTypedGroupExt<EmoteSelectSheet> = new FlxTypedGroupExt<EmoteSelectSheet>();

	function get_current_group():FlxTypedGroupExt<Dynamic>
	{
		switch (tab)
		{
			case COSTUMES:
				return costume_sheets;
			case EMOTES:
				return emote_sheets;
		}
		return null;
	}

	var tabs:Array<SheetType> = [COSTUMES, EMOTES];
	var tab(get, never):SheetType;

	var back_button:HoverButton;

	var substate:SheetSubstate;

	public static var local_saves:Map<SheetType, SheetPosition>;

	public function new(open_on_tab:SheetType = COSTUMES)
	{
		super();

		FlxG.state.openSubState(substate = new SheetSubstate(this));

		for (name in JsonData.costume_sheet_names)
			costume_sheets.add(new CostumeSelectSheet(name, this));
		for (name in JsonData.emote_sheet_names)
			emote_sheets.add(new EmoteSelectSheet(name, this));

		if (local_saves == null)
		{
			local_saves = [];
			local_saves.set(COSTUMES, {sheet_name: "costumes-series-1", selection: 0});
			local_saves.set(EMOTES, {sheet_name: "emotes-back-red", selection: 0});
		}

		select_sheet(tab, local_saves.get(COSTUMES));

		add(costume_sheets);
		add(emote_sheets);

		cycle_tabs_until(open_on_tab);
		substate.add(back_button = new HoverButton((b) -> back_button_activated()));
		back_button.scrollFactor.set(0, 0);
		back_button.loadAllFromAnimationSet("back-arrow");
		back_button.setPosition(FlxG.width - back_button.width - 16, FlxG.height - back_button.height - 16);
		back_button.offset.y = -back_button.height;
		back_button.tween = FlxTween.tween(back_button.offset, {y: 0}, 0.25, {ease: FlxEase.cubeInOut});
		update_tab_states();
	}

	public function select_sheet(tab:SheetType, sheet_position:SheetPosition)
	{
		trace(tab, sheet_position);
		switch (tab)
		{
			case COSTUMES:
				for (sheet in costume_sheets)
				{
					sheet.visible = sheet_position.sheet_name == sheet.def.name;
					if (sheet.visible)
						sheet.selection = sheet_position.selection;
					sheet.set_sheet_active(sheet.visible);
				}
				while (!costume_sheets.members[0].visible)
					costume_sheets.members.push(costume_sheets.members.shift());
			case EMOTES:
				for (sheet in emote_sheets)
				{
					sheet.visible = sheet_position.sheet_name == sheet.def.name;
					if (sheet.visible)
						sheet.selection = sheet_position.selection;
					sheet.set_sheet_active(sheet.visible);
				}
				while (!emote_sheets.members[0].visible)
					emote_sheets.members.push(emote_sheets.members.shift());
		}
	}

	public function prev_page()
	{
		get_current_group().members.unshift(get_current_group().members.pop());
		local_saves.get(tab).sheet_name = cast(get_current_group().members[0], BaseSelectSheet).def.name;
		local_saves.get(tab).selection = 0;

		select_sheet(tab, local_saves.get(tab));

		get_current_group().members[0].update_unlocks();
	}

	public function next_page()
	{
		get_current_group().members.push(get_current_group().members.shift());
		local_saves.get(tab).sheet_name = cast(get_current_group().members[0], BaseSelectSheet).def.name;
		local_saves.get(tab).selection = 0;

		select_sheet(tab, local_saves.get(tab));

		get_current_group().members[0].update_unlocks();
	}

	function current_group_order():Array<String>
		return get_current_group().members.map((member) -> cast(member, BaseSelectSheet).def.name.split("-").last());

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

	function cycle_tabs_until(new_tab:SheetType)
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
			sheet.visible = sheet == members[0];
		for (sheet in members)
			sheet.active = sheet == members[0];
	}

	function get_tab():SheetType
		return tabs[0];

	public function start_closing(?on_complete:Void->Void)
	{
		// current.start_closing(on_complete);
	}
}
