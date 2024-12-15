package ui.sheets;

import data.JsonData;
import data.SaveManager;
import data.types.TankmasDefs.CostumeDef;
import data.types.TankmasDefs.EmoteDef;
import dn.struct.Grid;
import flixel.FlxBasic;
import flixel.addons.effects.chainable.FlxEffectSprite;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.math.FlxMath;
import flixel.tweens.FlxEase;
import flixel.tweens.misc.ColorTween;
import flixel.util.FlxTimer;
import squid.ext.FlxTypedGroupExt;
import ui.button.HoverButton;
import ui.sheets.SheetMenu.SheetPosition;
import ui.sheets.buttons.SheetButton;
import ui.sheets.defs.SheetDefs.SheetMenuDef;
import ui.sheets.defs.SheetDefs;

class BaseSelectSheet extends FlxTypedGroupExt<FlxSprite>
{
	var sheet_type:SheetType;

	public var def:SheetMenuDef;

	var outline:FlxSpriteExt;
	var bg:FlxSpriteExt;
	var bg_white:FlxSpriteExt;

	var description_text:FlxText;
	var title:FlxText;

	public var cursor:FlxSpriteExt;
	public var backTab:FlxSpriteExt;
	public var notepad:FlxSpriteExt;

	public var selection(default, set):Int = 0;

	var current_button(get, default):SheetButton;

	final description_group:FlxTypedSpriteGroup<FlxSprite> = new FlxTypedSpriteGroup<FlxSprite>(-440);

	public var seen:Array<String> = [];

	public var menu:SheetMenu;

	public var locked_selection_overlay:FlxSpriteExt;

	final close_speed:Float = 0.5;

	var rows:Int = 3;
	var cols:Int = 4;

	var control_cd:Int = 0;
	var control_cd_set:Int = 10;

	var multi_page:Bool = true;

	var prev_controller_selected_index:Int = 0;

	public var empty:Bool = true;

	public var unlocked_count:Int = 0;
	public var locked_count:Int = 0;
	public var total_count:Int = 0;

	/**
	 * This is private, should be only made through things that extend it
	 * @param saved_sheet
	 * @param saved_selection
	 */
	function new(sheet_name:String, menu:SheetMenu, ?sheet_type:SheetType = COSTUMES)
	{
		super();

		this.menu = menu;
		this.sheet_type = sheet_type;

		def = load_new_def(sheet_name);

		bg = new FlxSpriteExt(66, 239, Paths.image_path(def.name));
		bg_white = new FlxSpriteExt(46, 219).makeGraphicExt(1446, 852, FlxColor.WHITE);

		notepad = new FlxSpriteExt(Paths.image_path("notepad"));
		notepad.setPosition(bg_white.x + bg_white.width, 300);
		// description_group.add(notepad);

		description_text = new FlxText(notepad.x + 8, notepad.y + 12, 420);
		description_text.setFormat(Paths.get('CharlieType.otf'), 38, FlxColor.BLACK, LEFT);

		title = new FlxText(notepad.x + 8, notepad.y - 64 - 16, notepad.width, '');
		title.setFormat(Paths.get('CharlieType-Heavy.otf'), 60, FlxColor.BLACK, LEFT, OUTLINE, FlxColor.WHITE);
		title.borderSize = 6;
		// description_group.add(description_text);

		add(bg_white);

		add(notepad);
		add(description_text);

		add(bg);

		add(title);

		// add(description_group);

		add_buttons();

		cursor = new FlxSpriteExt().one_line("sheet-selector");
		add(cursor);

		update_cursor();

		sstate(ACTIVE);

		add(locked_selection_overlay = new FlxSpriteExt(Paths.get("locked-sheet-selection-overlay.png")));

		for (member in members)
			member.y += 8;

		var dev_page:Bool = def.name == "costume-series-D";

		for (button in def.grid_1D)
		{
			if (button.unlocked)
				unlocked_count++;
			if (!button.unlocked)
				locked_count++;
			if (!button.empty)
				total_count++;
		}

		if (locked_count == 0)
			empty = dev_page && unlocked_count == 0 || total_count == 0;

		update_locked_selection_overlay(SheetMenu.locked_selection.get(sheet_type));
	}

	public function update_unlocks()
		for (button in def.grid_1D)
			button.update_unlocked();

	function add_buttons()
	{
		def.grid_1D = [
			for (n in 0...(rows * cols))
				null
		];
		def.grid_2D = [
			for (c in 0...cols) [
				for (r in 0...rows)
					null
			]
		];
		for (i in 0...def.src.items.length)
		{
			var item_def:SheetItemDef = def.src.items[i];
			var button:SheetButton = new SheetButton(0, 0, item_def, sheet_type, (b) -> if (visible)
			{
				selection = i;
				lock_selection(b);
			});

			button.on_hover = (b) -> if (cast(b, SheetButton).unlocked)
			{
				if (i != prev_controller_selected_index)
				{
					prev_controller_selected_index = i;
					selection = i;
					update_cursor();
				}
			}

			var row:Int = (i / cols).floor();
			var col:Int = i % cols;

			// initial positions
			button.x = 190 + (340 * col);
			button.y = 320 + (270 * row);

			// button.setPosition(button.x + item_def?.xOffset ?? 0, button.y + item_def?.yOffset ?? 0);
			button.angle = item_def?.angle ?? 0.0;

			// trace(i, col, row, item_def.name, button.x, button.y, i / rows);

			def.grid_1D[i] = button;
			def.grid_2D[col][row] = button;

			add(button);
		}
	}

	public function update_locked_selection_overlay(locked_position:SheetPosition)
	{
		if (def.name == locked_position.sheet_name)
		{
			var selected_button:SheetButton = def.grid_1D[locked_position.selection];
			locked_selection_overlay.setPosition(selected_button.x, selected_button.y);
			locked_selection_overlay.angle = selected_button.angle;
			locked_selection_overlay.offset.copyFrom(selected_button.offset);
			locked_selection_overlay.visible = true;
		}
		else
		{
			locked_selection_overlay.visible = false;
		}
	}

	public function lock_selection(button:HoverButton)
	{
		Utils.shake("light");
		menu.save_locked_selection(sheet_type, {sheet_name: def.name, selection: selection});
		menu.update_locked_selection_overlays();
	}

	function load_new_def(name:String):SheetMenuDef
		throw "not implemented";

	function fsm()
		switch (cast(state, State))
		{
			default:
			case INACTIVE:
			case ACTIVE:
				control();
		}

	public function set_sheet_active(active:Bool)
		sstate(active ? ACTIVE : INACTIVE);

	override function update(elapsed:Float)
	{
		fsm();
		super.update(elapsed);
	}

	function control()
	{
		var any_button:Bool = Ctrl.cleft[1] || Ctrl.cright[1] || Ctrl.cup[1] || Ctrl.cdown[1];

		control_cd = any_button ? control_cd - 1 : 0;

		if (control_cd > 0)
			any_button = false;

		if (any_button)
		{
			control_cd = control_cd_set;

			def.grid_1D[selection].manual_button_hover = false;

			var col:Int = selection % cols;
			var row:Int = (selection / cols).floor();

			var on_max_left:Bool = col == 0;
			var on_max_right:Bool = col == cols - 1;
			var on_max_up:Bool = row == 0;
			var on_max_down:Bool = row == rows - 1;

			// trace('pre: $selection ($row , $col) $on_max_left $on_max_right $on_max_up $on_max_down');

			if (Ctrl.cleft[1])
			{
				if (on_max_left)
				{
					menu.prev_page();
					return;
				}
				else
					selection = selection - 1;
			}
			if (Ctrl.cright[1])
			{
				if (on_max_right)
				{
					menu.next_page();
					return;
				}
				else
					selection = selection + 1;
			}

			if (Ctrl.cup[1] && !on_max_up)
				selection = selection - cols;
			if (Ctrl.cdown[1] && !on_max_down)
				selection = selection + cols;

			prev_controller_selected_index = selection;
		}

		if (Ctrl.jinteract[1])
			if (current_button.unlocked)
				lock_selection(current_button);
		// trace('post: $selection ($row , $col) $on_max_left $on_max_right $on_max_up $on_max_down');
		update_cursor();
	}

	function update_sheet_graphics() {}

	function update_cursor()
	{
		for (button in def.grid_1D)
			button.manual_button_hover = false;

		current_button.manual_button_hover = true;
		cursor.center_on(current_button);
		cursor.angle = current_button.angle;
	}

	public function start_closing(?on_complete:Void->Void) {}

	override function kill()
	{
		save_selection();
		super.kill();
	}

	function save_selection()
		throw "not implemented";

	function get_current_button():SheetButton
		return def.grid_1D[selection];

	function set_selection(val:Int):Int
	{
		selection = val;

		var selection_name:String = def.grid_1D[selection].def.name;

		// Probably a better way of writing this but... oh well

		if (current_button.unlocked)
		{
			switch (sheet_type)
			{
				case COSTUMES:
					var costume_def:CostumeDef = JsonData.get_costume(selection_name);
					description_text.text = costume_def.desc;
					title.text = costume_def.display;
				case EMOTES:
					var emote_def:EmoteDef = JsonData.get_emote(selection_name);
					description_text.text = 'Made by ${emote_def.artist}';
					title.text = emote_def.properName;
			}
		}
		else
		{
			if (current_button.empty)
			{
				title.text = "";
				description_text.text = "";
			}
			else if (!current_button.unlocked)
			{
				title.text = "LOCKED";
				description_text.text = "???";
			}
		}

		title.offset.y = Math.abs(76 - title.height);

		update_cursor();

		return selection;
	}
}

enum abstract SheetType(String) from String to String
{
	final COSTUMES = "costumes";
	final EMOTES = "emotes";
}

private enum abstract State(String) from String to String
{
	var OPENING;
	var ACTIVE;
	var CLOSING;
	var INACTIVE;
}
