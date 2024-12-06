package ui.sheets;

import data.SaveManager;
import data.types.TankmasDefs.CostumeDef;
import data.types.TankmasDefs.EmoteDef;
import flixel.FlxBasic;
import flixel.addons.effects.chainable.FlxEffectSprite;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.tweens.FlxEase;
import flixel.util.FlxTimer;
import squid.ext.FlxTypedGroupExt;
import ui.button.HoverButton;
import ui.sheets.buttons.SheetButton;
import ui.sheets.defs.SheetDefs.SheetMenuDef;
import ui.sheets.defs.SheetDefs;

class BaseSelectSheet extends FlxTypedGroupExt<FlxSprite>
{
	var sheet_type:SheetType;
	var def:SheetMenuDef;

	var outline:FlxSpriteExt;
	var bg:FlxSpriteExt;

	var description:FlxText;
	var title:FlxText;

	public var selector:FlxSpriteExt;
	public var backTab:FlxSpriteExt;
	public var notepad:FlxSpriteExt;

	var locked_sheet:Int = 0;
	var locked_selection:Int = 0;

	var selection = 0;

	final desc_group:FlxTypedSpriteGroup<FlxSprite> = new FlxTypedSpriteGroup<FlxSprite>(-440);

	public var seen:Array<String> = [];

	public var menu:SheetMenu;

	public var locked_selection_overlay:FlxSpriteExt;

	final close_speed:Float = 0.5;

	var rows:Int = 4;
	var cols:Int = 4;

	/**
	 * This is private, should be only made through things that extend it
	 * @param saved_sheet
	 * @param saved_selection
	 */
	function new(sheet_name:String, menu:SheetMenu, ?sheet_type:SheetType = COSTUME)
	{
		super();

		this.menu = menu;
		this.sheet_type = sheet_type;

		sstate(INACTIVE);

		add(desc_group);

		notepad = new FlxSpriteExt(1490, 300, Paths.get("sticker-sheet-note.png"));
		desc_group.add(notepad);

		description = new FlxText(1500, 325, 420, '');
		description.setFormat(Paths.get('CharlieType.otf'), 32, FlxColor.BLACK, LEFT);
		desc_group.add(description);

		add(backTab = new FlxSpriteExt(66 + (sheet_type == COSTUME ? 500 : 0), 130, Paths.get('${sheet_type == COSTUME ? 'emote-tab' : 'costume-tab'}.png')));

		add(outline = new FlxSpriteExt(46, 219).makeGraphicExt(1446, 852, FlxColor.WHITE));
		add(bg = new FlxSpriteExt(66, 239));

		title = new FlxText(70, 70, 1420, '');
		title.setFormat(Paths.get('CharlieType-Heavy.otf'), 60, FlxColor.BLACK, LEFT, OUTLINE, FlxColor.WHITE);
		title.borderSize = 6;
		add(title);

		def = load_new_def(sheet_name);

		add_sprites();
	}

	function add_sprites()
	{
		for (row in 0...rows)
			for (col in 0...cols)
				def.grid_2D[row][col] = null;

		for (i in 0...def.src.items.length)
		{
			var item_def:SheetItemDef = def.src.items[i];
			var button:HoverButton = new HoverButton(0, 0, item_def.name, (b) -> lock_choices());

			var row:Float = i / 4;
			var col:Float = i % 4;

			// initial positions
			button.x = 190 + (340 * col);
			button.y = 320 + (270 * row);

			// add offsets
			button.setPosition(button.x + item_def?.xOffset ?? 0, button.y + item_def?.yOffset ?? 0);

			button.angle = item_def?.angle ?? 0.0;

			def.grid_1D[i] = item_def;
			def.grid_2D[row][col] = item_def;

			add(button);
		}
	}

	function update_locked_selection_overlay() {}

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
		update_locked_selection_overlay();
		fsm();
		super.update(elapsed);
	}

	function control()
	{
		for (i in 0...characterSpritesArray[current_hover_sheet].length)
		{
			// TODO: make this mobile-friendly
			if (FlxG.mouse.overlaps(characterSpritesArray[current_hover_sheet].members[i]))
				selection = i;
		}
		if (Ctrl.cleft[1])
			selection = selection - 1;
		if (Ctrl.cright[1])
			selection = selection + 1;
		if (Ctrl.cup[1])
			selection = selection - cols;
		if (Ctrl.cdown[1])
			selection = selection + cols;

		selection = FlxMath.bound(selection, 0, rows * cols);

		if (Ctrl.jinteract[1])
			lock_choices();

		if (FlxG.mouse.overlaps(backTab))
		{
			if (backTab.y != 110)
				backTab.y = 110;
			if (FlxG.mouse.justPressed)
			{
				if (backTab.scale.x != 0.8)
					backTab.scale.set(0.8, 0.8);
				menu.next_tab();
			}
			else if (!FlxG.mouse.pressed && backTab.scale.x != 1.1)
				backTab.scale.set(1.1, 1.1);
		}
		else if (backTab.scale.x != 1)
			backTab.scale.set(1, 1);
	}

	function lock_choices(shake:Bool = true) {}

	function set_selection(val:Int):Int
		return selection;

	function update_sheet_graphics() {}

	function update_selection_graphics() {}

	public function start_closing(?on_complete:Void->Void) {}

	override function kill()
	{
		save_selection();
		super.kill();
	}

	function save_selection()
		throw "not implemented";
}

enum abstract SheetType(String) from String to String
{
	final COSTUME;
	final STICKER;
}

private enum abstract State(String) from String to String
{
	var OPENING;
	var ACTIVE;
	var CLOSING;
	var INACTIVE;
}
