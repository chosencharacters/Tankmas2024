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
import ui.sheets.defs.SheetDefs;

class BaseSelectSheet extends FlxTypedGroupExt<FlxSprite>
{
	var type:SheetType;

	var stickerSheetOutline:FlxSpriteExt;
	var stickerSheetBase:FlxSpriteExt;
	var effectSheet:FlxEffectSprite;
	var description:FlxText;
	var title:FlxText;

	public var selector:FlxSpriteExt;
	public var backTab:FlxSpriteExt;

	var sheet_collection:SheetFileDef;
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

	/**
	 * This is private, should be only made through things that extend it
	 * @param saved_sheet
	 * @param saved_selection
	 */
	function new(menu:SheetMenu, saved_sheet:Int, saved_selection:Int, ?type:SheetType = COSTUME)
	{
		super();

		this.menu = menu;
		this.type = type;

		sstate(INACTIVE);

		add(descGroup);

		final notepad:FlxSpriteExt = new FlxSpriteExt(1490, 300, Paths.get("sticker-sheet-note.png"));
		descGroup.add(notepad);

		description = new FlxText(1500, 325, 420, '');
		description.setFormat(Paths.get('CharlieType.otf'), 32, FlxColor.BLACK, LEFT);
		descGroup.add(description);

		add(backTab = new FlxSpriteExt(66 + (type == COSTUME ? 500 : 0), 130, Paths.get('${type == COSTUME ? 'emote-tab' : 'costume-tab'}.png')));

		add(stickerSheetOutline = new FlxSpriteExt(46, 219).makeGraphicExt(1446, 852, FlxColor.WHITE));
		add(stickerSheetBase = new FlxSpriteExt(66, 239));

		title = new FlxText(70, 70, 1420, '');
		title.setFormat(Paths.get('CharlieType-Heavy.otf'), 60, FlxColor.BLACK, LEFT, OUTLINE, FlxColor.WHITE);
		title.borderSize = 6;
		add(title);

		sheet_collection = make_sheet_collection();

		for (sheet in sheet_collection.sheets)
		{
			final characterSprites:FlxTypedSpriteGroup<FlxSpriteExt> = new FlxTypedSpriteGroup<FlxSpriteExt>();
			add(characterSprites);

			final notSeenSprites:FlxTypedSpriteGroup<FlxSpriteExt> = new FlxTypedSpriteGroup<FlxSpriteExt>();
			add(notSeenSprites);

			final daNames:Array<String> = [];

			for (i in 0...sheet.items.length)
			{
				if (sheet.items[i].name == null)
					continue;
				final identity:SheetItemDef = sheet.items[i];
				final sprite:HoverButton = new HoverButton(0, 0);
				sprite.on_release = (b) -> lock_choices();
				sprite.ID = i;
				if (type == STICKER)
				{
					final sticker:StickerDef = data.JsonData.get_sticker(identity.name);

					if (sticker == null)
						continue;

					if (!data.JsonData.check_for_unlock_sticker(sticker))
						continue;

					sprite.loadGraphic(Paths.get('${sticker.name}.png'));
				}
				else
				{
					final costume:CostumeDef = data.JsonData.get_costume(identity.name);

					if (costume == null)
						continue;

					var unlocked:Bool = data.JsonData.check_for_unlock_costume(costume);

					if (!unlocked)
						continue;

					sprite.loadGraphic(Paths.get('${costume.name}.png'));
				}
				var sprite_position:FlxPoint = FlxPoint.weak();

				// initial positions
				sprite_position.x = 190 + (340 * (i % 4));
				sprite_position.y = 320 + (270 * Math.floor(i / 4));

				// add offsets
				sprite_position.x += identity?.xOffset ?? 0;
				sprite_position.y += identity?.yOffset ?? 0;

				sprite.setPosition(sprite_position.x, sprite_position.y);

				sprite.angle = identity?.angle ?? 0.0;
				characterSprites.add(sprite);
				daNames.push(identity.name);

				if (!seen.contains(identity.name))
				{
					final newFrame:FlxSpriteExt = new FlxSpriteExt(sprite_position.x + (sprite.width / 2) - 141, sprite_position.y + (sprite.height / 2) - 163);
					newFrame.loadAllFromAnimationSet('new-sticker-overlay');
					newFrame.ID = i;
					notSeenSprites.add(newFrame);
					@:privateAccess
					newFrame.anim('idle');
					new FlxTimer().start(4.3, function(tmr:FlxTimer)
					{
						if (!newFrame.alive)
							return;
						newFrame.anim('shine');
						new FlxTimer().start(0.5, function(tmr:FlxTimer)
						{
							newFrame.anim('idle');
						});
					}, 0);
				}
			}

			if (characterSprites.members.length != 0)
			{
				characterSpritesArray.push(characterSprites);
				if (sheet.graphic != null)
					Paths.get(sheet.graphic + '.png');
				characterNames.push(daNames);
				notSeenGroup.push(notSeenSprites);
			}
			characterSprites.kill();
			notSeenSprites.kill();
		}

		final curTab:FlxSpriteExt = new FlxSpriteExt(66 + (type == STICKER ? 500 : 0), 130,
			Paths.get((type == STICKER ? 'emote-tab' : 'costume-tab') + '.png'));
		curTab.scale.set(1.1, 1.1);
		add(curTab);

		add(locked_selection_overlay = new FlxSpriteExt().one_line("locked-sticker-selection-overlay"));
		locked_selection_overlay.scrollFactor.set(0, 0);
		update_locked_selection_overlay();

		selector = new FlxSpriteExt(0, 0).one_line("item-navigator");
		selector.anim("hover");
		add(selector);

		current_hover_selection = saved_selection;
		current_hover_sheet = saved_sheet;
		locked_sheet = saved_sheet;
		locked_selection = saved_selection;

		members.for_all_members((member:FlxBasic) ->
		{
			final daMem:FlxObject = cast(member, FlxObject);
			daMem.y += 1300;
			daMem.scrollFactor.set(0, 0);
			FlxTween.tween(daMem, {y: daMem.y - 1300}, 0.8, {ease: FlxEase.cubeInOut});
		});
		new FlxTimer().start(0.8, function(tmr:FlxTimer)
		{
			sstate(ACTIVE);
			FlxTween.tween(descGroup, {x: 0}, 0.5, {ease: FlxEase.cubeOut});
		});
	}

	function update_locked_selection_overlay()
	{
		var target:FlxSpriteExt = characterSpritesArray[locked_sheet].members[locked_selection];

		if (target == null)
			return;

		locked_selection_overlay.center_on(target);
		locked_selection_overlay.angle = target.angle;
		locked_selection_overlay.scale.copyFrom(target.scale);

		// this is untested cause we only have one sheet
		locked_selection_overlay.visible = locked_sheet == current_hover_sheet;
	}

	function make_sheet_collection():SheetFileDef
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

	function lock_choices(shake:Bool = true)
	{
		if (shake)
			Utils.shake(ShakePreset.LIGHT);
		locked_selection = current_hover_selection;
		locked_sheet = current_hover_sheet;
		update_locked_selection_overlay();
		save_selection();
	}

	function set_current_hover_sheet(val:Int):Int
	{
		if (characterSpritesArray.length > 1)
		{
			characterSpritesArray[current_hover_sheet].kill();
			notSeenGroup[current_hover_sheet].kill();
		}

		if (val < 0)
			current_hover_sheet = characterSpritesArray.length - 1;
		else if (val > characterSpritesArray.length - 1)
			current_hover_sheet = 0;
		else
			current_hover_sheet = val;

		update_sheet_graphics();

		return current_hover_sheet;
	}

	function set_current_hover_selection(val:Int):Int
	{
		// characterSpritesArray[current_hover_sheet].members[current_hover_selection].scale.set(1, 1);

		if (val < 0)
			current_hover_selection = characterSpritesArray[current_hover_sheet].members.length - 1;
		else if (val > characterSpritesArray[current_hover_sheet].members.length - 1)
			current_hover_selection = 0;
		else
			current_hover_selection = val;

		if (notSeenGroup[current_hover_sheet].members.length > 0)
		{
			final matches:Array<FlxSpriteExt> = notSeenGroup[current_hover_sheet].members.filter(i ->
				i.ID == characterSpritesArray[current_hover_sheet].members[current_hover_selection].ID);
			if (matches.length > 0)
			{
				var character_name:String = characterNames[current_hover_sheet][current_hover_selection];
				if (!seen.contains(character_name))
				{
					seen.push(character_name);
				}
				notSeenGroup[current_hover_sheet].members.remove(matches[0]);
			}
		}
		update_selection_graphics();

		return current_hover_selection;
	}

	function update_sheet_graphics()
	{
		graphicSheet = sheet_collection.sheets[current_hover_sheet].graphic != null ? true : false;
		if (graphicSheet)
			stickerSheetBase.loadGraphic(Paths.get(sheet_collection.sheets[current_hover_sheet].graphic + '.png'));
		else
			stickerSheetBase.makeGraphic(1410, 845, FlxColor.BLACK);

		characterSpritesArray[current_hover_sheet].revive();
		notSeenGroup[current_hover_sheet].revive();

		update_selection_graphics();
	}

	function update_selection_graphics()
	{
		if (type == STICKER)
		{
			final sticker:StickerDef = data.JsonData.get_sticker(characterNames[current_hover_sheet][current_hover_selection]);
			title.text = sticker.properName.toUpperCase();
			description.text = (sticker.desc != null ? (sticker.desc + ' ') : '') + 'Created by ${sticker.artist != null ? sticker.artist : "Unknown"}';
			// selector.setPosition(characterSpritesArray[current_hover_sheet].members[current_hover_selection].x + (characterSpritesArray[current_hover_sheet].members[current_hover_selection].width / 2) - 175, characterSpritesArray[current_hover_sheet].members[current_hover_selection].y + (characterSpritesArray[current_hover_sheet].members[current_hover_selection].height / 2) - 177);
		}
		else
		{
			final costume:CostumeDef = data.JsonData.get_costume(characterNames[current_hover_sheet][current_hover_selection]);
			title.text = costume.display.toUpperCase();
			description.text = (costume.desc != null ? costume.desc : '');
			// selector.setPosition(characterSpritesArray[current_hover_sheet].members[current_hover_selection].x - 110, characterSpritesArray[current_hover_sheet].members[current_hover_selection].y - 80);
		}
		var target:FlxSpriteExt = characterSpritesArray[current_hover_sheet].members[current_hover_selection];

		selector.setPosition(target.x + (target.width / 2) - 175, target.y + (target.height / 2) - 167);
		selector.angle = target.angle;

		// characterSpritesArray[current_hover_sheet].members[current_hover_selection].scale.set(1.1, 1.1);
	}

	public function start_closing(?on_complete:Void->Void)
	{
		var dumb_on_complete_bool:Bool = true;
		sstate(CLOSING);
		FlxTween.tween(descGroup, {x: -440}, close_speed * 0.5, {ease: FlxEase.quintIn});
		new FlxTimer().start(close_speed * .3, function(tmr:FlxTimer)
		{
			members.for_all_members((member:FlxBasic) ->
			{
				final daMem:FlxObject = cast(member, FlxObject);
				var tween:FlxTween = FlxTween.tween(daMem, {y: daMem.y + 1300}, close_speed, {ease: FlxEase.cubeInOut});
				if (dumb_on_complete_bool)
					tween.onComplete = (t) -> on_complete();
				dumb_on_complete_bool = false;
			});
		});
	}

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
