package ui.sheets;

import cdb.Sheet;
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

	var tab_buttons:FlxTypedGroup<HoverButton> = new FlxTypedGroup<HoverButton>();

	var sheet_groups:FlxTypedGroup<FlxTypedGroup<Dynamic>> = new FlxTypedGroup<FlxTypedGroup<Dynamic>>();

	var tabs:Array<SheetType> = [COSTUMES, EMOTES];
	var current_tab(get, never):SheetType;

	var back_button:HoverButton;

	var substate:SheetSubstate;

	var front_tabs:FlxTypedGroup<HoverButton> = new FlxTypedGroup<HoverButton>();
	var back_tabs:FlxTypedGroup<HoverButton> = new FlxTypedGroup<HoverButton>();

	public static var local_saves:Map<SheetType, SheetPosition>;
	public static var locked_selection:Map<SheetType, SheetPosition>;

	public function new(open_on_tab:SheetType = COSTUMES)
	{
		super();

		FlxG.state.openSubState(substate = new SheetSubstate(this));

		if (local_saves == null)
		{
			local_saves = [];
			local_saves.set(COSTUMES, {sheet_name: "costumes-series-1", selection: 0});
			local_saves.set(EMOTES, {sheet_name: "emotes-back-red", selection: 0});
		}

		if (locked_selection == null)
		{
			locked_selection = [];
			for (tab in tab_order)
				locked_selection.set(tab, local_saves.get(tab));
		}

		for (name in JsonData.costume_sheet_names)
			costume_sheets.add(new CostumeSelectSheet(name, this));
		for (name in JsonData.emote_sheet_names)
			emote_sheets.add(new EmoteSelectSheet(name, this));

		add_tab_buttons();

		sheet_groups.add(costume_sheets);
		sheet_groups.add(emote_sheets);

		add(back_tabs);
		add(sheet_groups);
		add(front_tabs);

		select_sheet(current_tab, local_saves.get(COSTUMES));

		cycle_tabs_until(open_on_tab);
		substate.add(back_button = new HoverButton((b) -> back_button_activated()));
		back_button.scrollFactor.set(0, 0);
		back_button.loadAllFromAnimationSet("back-arrow");
		back_button.setPosition(FlxG.width - back_button.width - 16, FlxG.height - back_button.height - 16);
		back_button.offset.y = -back_button.height;
		back_button.tween = FlxTween.tween(back_button.offset, {y: 0}, 0.25, {ease: FlxEase.cubeInOut});

		update_tab_states();

		update_locked_selection_overlays();
	}

	public function add_tab_buttons()
	{
		for (tab in tabs)
		{
			var tab_x:Float = tab_buttons.length > 0 ? tab_buttons.members.last().x + tab_buttons.members.last().width - 64 : 48;
			var tab_button:HoverButton = new HoverButton(tab_x, 130);

			tab_button.loadAllFromAnimationSet('${tab}-tab');
			tab_button.on_release = (b) -> select_sheet(tab, local_saves.get(tab));

			tab_buttons.add(tab_button);
		}
	}

	public function select_sheet(new_tab:SheetType, sheet_position:SheetPosition)
	{
		cycle_tabs_until(new_tab);
		switch (current_tab)
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

	public function save_locked_selection(tab:SheetType, position:SheetPosition):SheetPosition
	{
		locked_selection.set(current_tab, position);
		return locked_selection.get(current_tab);
	}

	public function update_locked_selection_overlays()
	{
		for (sheet in get_current_sheets())
			cast(sheet, BaseSelectSheet).update_locked_selection_overlay(locked_selection.get(current_tab));
	}

	public function prev_page()
	{
		get_current_sheets().members.unshift(get_current_sheets().members.pop());
		local_saves.get(current_tab).sheet_name = cast(get_current_sheets().members[0], BaseSelectSheet).def.name;
		local_saves.get(current_tab).selection = 0;

		select_sheet(current_tab, local_saves.get(current_tab));

		get_current_sheets().members[0].update_unlocks();

		if (get_current_sheets().members[0].empty)
			prev_page();
	}

	public function next_page()
	{
		get_current_sheets().members.push(get_current_sheets().members.shift());
		local_saves.get(current_tab).sheet_name = cast(get_current_sheets().members[0], BaseSelectSheet).def.name;
		local_saves.get(current_tab).selection = 0;

		select_sheet(current_tab, local_saves.get(current_tab));

		get_current_sheets().members[0].update_unlocks();

		if (get_current_sheets().members[0].empty)
			next_page();
	}

	function current_group_order():Array<String>
		return get_current_sheets().members.map((member) -> cast(member, BaseSelectSheet).def.name.split("-").last());

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

	function cycle_tabs_until(new_tab:SheetType)
		while (current_tab != new_tab)
			next_tab();

	public function next_tab()
	{
		tabs.push(tabs.shift());

		sheet_groups.members.push(sheet_groups.members.shift());
		tab_buttons.members.push(tab_buttons.members.shift());

		update_tab_states();
	}

	public function update_tab_states()
	{
		for (n in 0...sheet_groups.length)
			sheet_groups.members[n].active = sheet_groups.members[n].visible = n == 0;

		back_tabs.clear();
		front_tabs.clear();

		for (n in 0...tab_buttons.length)
			n > 0 ? back_tabs.add(tab_buttons.members[n]) : front_tabs.add(tab_buttons.members[n]);
	}

	function get_current_tab():SheetType
		return tabs[0];

	function get_current_sheets():FlxTypedGroupExt<Dynamic>
		return cast(sheet_groups.members[0], FlxTypedGroupExt<Dynamic>);

	public function start_closing(?on_complete:Void->Void)
	{
		// current.start_closing(on_complete);
	}
}
