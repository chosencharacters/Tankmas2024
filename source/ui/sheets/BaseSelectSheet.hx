package ui.sheets;

import data.SaveManager;
import data.types.TankmasDefs.CostumeDef;
import data.types.TankmasDefs.StickerDef;
import flixel.FlxBasic;
import flixel.addons.effects.chainable.FlxEffectSprite;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.tweens.FlxEase;
import flixel.util.FlxTimer;
import squid.ext.FlxTypedGroupExt;
import ui.button.HoverButton;
import ui.sheets.buttons.SheetButton;
import ui.sheets.defs.SheetDefs;

class BaseSelectSheet extends FlxTypedGroupExt<FlxSprite>
{
	var sheet_type:SheetType;
	var def:SheetDef;

	var stickerSheetOutline:FlxSpriteExt;
	var stickerSheetBase:FlxSpriteExt;
	var effectSheet:FlxEffectSprite;
	var description:FlxText;
	var title:FlxText;

	public var selector:FlxSpriteExt;
	public var backTab:FlxSpriteExt;

	final characterSpritesArray:Array<FlxTypedSpriteGroup<FlxSpriteExt>> = [];
	final notSeenGroup:Array<FlxTypedSpriteGroup<FlxSpriteExt>> = [];
	final characterNames:Array<Array<String>> = [];

	var current_hover_sheet(default, set):Int = 0;
	var current_hover_selection(default, set):Int = 0;

	var locked_sheet:Int = 0;
	var locked_selection:Int = 0;

	final descGroup:FlxTypedSpriteGroup<FlxSprite> = new FlxTypedSpriteGroup<FlxSprite>(-440);

	var graphicSheet:Bool = false;

	public var seen:Array<String> = [];

	public var menu:SheetMenu;

	public var locked_selection_overlay:FlxSpriteExt;

	final close_speed:Float = 0.5;

	var grid:SheetMenuDef;

	/**
	 * This is private, should be only made through things that extend it
	 * @param saved_sheet
	 * @param saved_selection
	 */
	function new(menu:SheetMenu, saved_sheet:Int, saved_selection:Int, ?sheet_type:SheetType = COSTUME)
	{
		super();

		this.menu = menu;
		this.sheet_type = sheet_type;

		sstate(INACTIVE);

		add(descGroup);

		final notepad:FlxSpriteExt = new FlxSpriteExt(1490, 300, Paths.get("sticker-sheet-note.png"));
		descGroup.add(notepad);

		description = new FlxText(1500, 325, 420, '');
		description.setFormat(Paths.get('CharlieType.otf'), 32, FlxColor.BLACK, LEFT);
		descGroup.add(description);

		add(backTab = new FlxSpriteExt(66 + (sheet_type == COSTUME ? 500 : 0), 130, Paths.get('${sheet_type == COSTUME ? 'emote-tab' : 'costume-tab'}.png')));

		add(stickerSheetOutline = new FlxSpriteExt(46, 219).makeGraphicExt(1446, 852, FlxColor.WHITE));
		add(stickerSheetBase = new FlxSpriteExt(66, 239));

		title = new FlxText(70, 70, 1420, '');
		title.setFormat(Paths.get('CharlieType-Heavy.otf'), 60, FlxColor.BLACK, LEFT, OUTLINE, FlxColor.WHITE);
		title.borderSize = 6;
		add(title);

		def = load_def();

		add_sprites();

		sheet_collection = make_sheet_collection();

		var sprite_position:FlxPoint = FlxPoint.weak();
	}

	function add_sprites()
	{
		var row:Array<SheetButton> = [];
		var rows:Array<Array<SheetButton>> = [];

		for (item in rows)
		{
			var row:Array<SheetButton> = [];
			for (row in rows)
			{
				// initial positions
				sprite_position.x = 190 + (340 * (i % 4));
				sprite_position.y = 320 + (270 * Math.floor(i / 4));

				// add offsets
				sprite_position.x += identity?.xOffset ?? 0;
				sprite_position.y += identity?.yOffset ?? 0;
				sprite.setPosition(sprite_position.x, sprite_position.y);

				sprite.angle = identity?.angle ?? 0.0;
				characterSprites.add(sprite);
			}
		}
	}

	function update_locked_selection_overlay() {}

	function load_def():SheetMenuDef
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
				current_hover_selection = i;
		}
		if (Ctrl.cleft[1])
			current_hover_selection = current_hover_selection - 1;
		if (Ctrl.cright[1])
			current_hover_selection = current_hover_selection + 1;
		if (Ctrl.cup[1])
			current_hover_sheet = current_hover_sheet + 1;
		if (Ctrl.cdown[1])
			current_hover_sheet = current_hover_sheet - 1;
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

	function set_current_hover_sheet(val:Int):Int
	{
		return current_hover_sheet;
	}

	function set_current_hover_selection(val:Int):Int
	{
		return current_hover_selection;
	}

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
