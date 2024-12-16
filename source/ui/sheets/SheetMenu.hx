package ui.sheets;

import data.JsonData;
import data.SaveManager;
import entities.Player;
import flixel.FlxBasic;
import flixel.tweens.FlxEase;
import squid.ext.FlxTypedGroupExt;
import states.substates.SheetSubstate;
import ui.button.HoverButton;
import ui.sheets.BaseSelectSheet.SheetType;

typedef SheetPosition =
{
	var sheet_name:String;
	var selection:Int;
	var selection_name:String;
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
	var next_sheet_button:HoverButton;

	var substate:SheetSubstate;

	var front_tabs:FlxTypedGroup<HoverButton> = new FlxTypedGroup<HoverButton>();
	var back_tabs:FlxTypedGroup<HoverButton> = new FlxTypedGroup<HoverButton>();

	var saved_positions:Map<SheetType, SheetPosition>;

	public static var locked_selections:Map<SheetType, SheetPosition>;

	public var closing:Bool = false;

	public function new(open_on_tab:SheetType = COSTUMES)
	{
		super();

		FlxG.state.openSubState(substate = new SheetSubstate(this));

		if (saved_positions == null)
		{
			saved_positions = [];
			saved_positions.set(COSTUMES, {sheet_name: "costumes-series-1", selection: 0, selection_name: Main.default_costume});
			saved_positions.set(EMOTES, {sheet_name: "emotes-1-back-red", selection: 0, selection_name: Main.default_emote});
		}

		if (locked_selections == null)
		{
			locked_selections = [];
			for (tab in tab_order)
				locked_selections.set(tab, saved_positions.get(tab));
		}

		for (tab in tab_order)
		{
			saved_positions.set(tab, locked_selections.get(tab));
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

		add(next_sheet_button = new HoverButton());

		select_sheet(current_tab, locked_selections.get(COSTUMES));

		cycle_tabs_until(open_on_tab);
		substate.add(back_button = new HoverButton((b) -> back_button_activated()));
		back_button.scrollFactor.set(0, 0);
		back_button.loadAllFromAnimationSet("back-arrow");
		back_button.setPosition(FlxG.width - back_button.width - 16, FlxG.height - back_button.height - 16);
		back_button.offset.y = -back_button.height;
		back_button.tween = FlxTween.tween(back_button.offset, {y: 0}, 0.25, {ease: FlxEase.cubeInOut});

		update_tab_states();

		update_locked_selections_overlays();

		next_sheet_button.one_line("next-sticker-page");
		next_sheet_button.setPosition(costume_sheets.members[0].bg.x + costume_sheets.members[0].bg.width - next_sheet_button.width,
			costume_sheets.members[0].bg.y - next_sheet_button.height / 2);
		next_sheet_button.scrollFactor.set(0, 0);
		next_sheet_button.on_pressed = (b) -> next_page();

		intro();
	}

	function add_tab_buttons()
		for (tab in tabs)
		{
			var tab_x:Float = tab_buttons.length > 0 ? tab_buttons.members.last().x + tab_buttons.members.last().width - 64 : 48;
			var tab_button:HoverButton = new HoverButton(tab_x, 130);
			tab_button.loadAllFromAnimationSet('${tab}-tab');
			tab_button.on_pressed = (b) -> select_sheet(tab, saved_positions.get(tab));
			tab_buttons.add(tab_button);
			tab_button.scrollFactor.set(0, 0);
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

	public function save_locked_selections(tab:SheetType, position:SheetPosition):SheetPosition
	{
		locked_selections.set(current_tab, position);
		return locked_selections.get(current_tab);
	}

	public function update_locked_selections_overlays()
	{
		for (sheet in get_current_sheets())
			cast(sheet, BaseSelectSheet).update_locked_selections_overlay(locked_selections.get(current_tab));
	}

	public function prev_page()
	{
		get_current_sheets().members.unshift(get_current_sheets().members.pop());

		var row:Int = (saved_positions.get(current_tab).selection / BaseSelectSheet.rows).floor();

		saved_positions.get(current_tab).sheet_name = cast(get_current_sheets().members[0], BaseSelectSheet).def.name;
		saved_positions.get(current_tab).selection = BaseSelectSheet.cols - 1;

		select_sheet(current_tab, saved_positions.get(current_tab));

		get_current_sheets().members[0].update_unlocks();

		if (get_current_sheets().members[0].empty)
			prev_page();
	}

	public function next_page()
	{
		get_current_sheets().members.push(get_current_sheets().members.shift());

		var row:Int = (saved_positions.get(current_tab).selection / BaseSelectSheet.rows).floor();

		saved_positions.get(current_tab).sheet_name = cast(get_current_sheets().members[0], BaseSelectSheet).def.name;
		saved_positions.get(current_tab).selection = 0;

		select_sheet(current_tab, saved_positions.get(current_tab));

		get_current_sheets().members[0].update_unlocks();

		if (get_current_sheets().members[0].empty)
			next_page();
	}

	function current_group_order():Array<String>
		return get_current_sheets().members.map((member) -> cast(member, BaseSelectSheet).def.name.split("-").last());

	public function back_button_activated()
	{
		for (sheet_group in sheet_groups)
			for (sheet in cast(sheet_group, FlxTypedGroup<Dynamic>))
				for (member in cast(sheet, BaseSelectSheet))
					FlxTween.tween(member, {y: FlxG.height + 128}, 0.25, {ease: FlxEase.cubeInOut});

		for (tab in tab_buttons)
			tab.tween = FlxTween.tween(tab, {y: FlxG.height + 128}, 0.25, {ease: FlxEase.cubeInOut});

		back_button.tween = FlxTween.tween(back_button, {y: FlxG.height + 128}, 0.25, {
			ease: FlxEase.cubeInOut,
			onComplete: function(t)
			{
				Ctrl.mode = ControlModes.OVERWORLD;
				FlxG.state.closeSubState();
			}
		});

		closing = true;

		back_button.disable();

		substate.sstate("CLOSING");

		trace("yo");

		SaveManager.save_collections();

		PlayState.self.player.new_costume(JsonData.get_costume(SaveManager.current_costume));
	}

	public function intro()
	{
		for (sheet_group in sheet_groups)
			for (sheet in cast(sheet_group, FlxTypedGroup<Dynamic>))
				for (member in cast(sheet, BaseSelectSheet))
				{
					member.offset.y = -FlxG.height;
					FlxTween.tween(member.offset, {y: 0}, 0.25, {ease: FlxEase.cubeInOut});
				}

		for (tab in tab_buttons)
		{
			tab.offset.y = -FlxG.height;
			tab.tween = FlxTween.tween(tab.offset, {y: 0}, 0.25, {ease: FlxEase.cubeInOut});
		}

		/*
			back_button.y = back_button.y + (FlxG.height + 128);
			back_button.tween = FlxTween.tween(back_button, {y: back_button.y - (FlxG.height + 128)}, 0.25, {
				ease: FlxEase.cubeInOut
			});
		 */
	}

	override function update(elapsed:Float)
	{
		if (closing)
			return;
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
}
