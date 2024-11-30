package ui.sheets;

import data.types.TankmasDefs.CostumeDef;
import data.types.TankmasDefs.StickerDef;
import entities.base.NGSprite;
import flixel.FlxBasic;
import flixel.addons.effects.chainable.FlxEffectSprite;
import flixel.addons.effects.chainable.FlxOutlineEffect;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.tweens.FlxEase;
import flixel.util.FlxTimer;
import squid.ext.FlxGroupExt;
import states.substates.SheetSubstate;
import ui.sheets.defs.SheetDefs;

class BaseSelectSheet extends FlxGroupExt<FlxSprite>
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

	var current_sheet(default, set):Int = 0;
	var current_selection(default, set):Int = 0;
	final descGroup:FlxTypedSpriteGroup<FlxSprite> = new FlxTypedSpriteGroup<FlxSprite>(-440);

	var graphicSheet:Bool = false;

	public var canSelect:Bool = false;

	public var seen:Array<String> = [];

	/**
	 * This is private, should be only made through things that extend it
	 * @param saved_sheet
	 * @param saved_selection
	 */
	function new(saved_sheet:Int, saved_selection:Int, ?type:SheetType = COSTUME, ?newState:Bool = true)
	{
		super();

		this.type = type;

		if (newState)
			FlxG.state.openSubState(new SheetSubstate(this));

		add(descGroup);

		final notepad:FlxSpriteExt = new FlxSpriteExt(1490, 300, Paths.get("stickersheet-note.png"));
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

			for (i in 0...sheet.items.length - 1)
			{
				if (sheet.items[i].name == null)
					continue;
				final identity:SheetItemDef = sheet.items[i];
				final sprite:FlxSpriteExt = new FlxSpriteExt(0, 0);
				sprite.ID = i;
				if (type == STICKER)
				{
					final sticker:StickerDef = data.JsonData.get_sticker(identity.name);
					if (!data.JsonData.check_for_unlock_sticker(sticker))
						continue;
					sprite.loadGraphic(Paths.get('${sticker.name}.png'));
				}
				else
				{
					final character:CostumeDef = data.JsonData.get_costume(identity.name);
					if (!data.JsonData.check_for_unlock_costume(character))
						continue;
					sprite.loadGraphic(Paths.get('${character.name}.png'));
				}
				var sprite_position:FlxPoint = FlxPoint.weak();

				// initial positions
				sprite_position.x = 190 + (340 * (i % 4));
				sprite_position.y = 320 + (270 * Math.floor(i / 4));

				// add offsets
				sprite_position.x += identity.xOffset;
				sprite_position.y += identity.yOffset;

				sprite.setPosition(sprite_position.x, sprite_position.y);

				if (identity.angle != null)
					sprite.angle = identity.angle;
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

		selector = new FlxSpriteExt().one_line("item-navigator");
		selector.anim("hover");
		add(selector);

		current_selection = saved_selection;
		current_sheet = saved_sheet;

		members.for_all_members((member:FlxBasic) ->
		{
			final daMem:FlxObject = cast(member, FlxObject);
			daMem.y += 1300;
			daMem.scrollFactor.set(0, 0);
			FlxTween.tween(daMem, {y: daMem.y - 1300}, 0.8, {ease: FlxEase.cubeInOut});
		});
		new FlxTimer().start(0.8, function(tmr:FlxTimer)
		{
			canSelect = true;
			FlxTween.tween(descGroup, {x: 0}, 0.5, {ease: FlxEase.cubeOut});
		});
	}

	function make_sheet_collection():SheetFileDef
		throw "not implemented";

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		Ctrl.update();
		control();
	}

	function control()
	{
		if (!canSelect)
			return;
		for (i in 0...characterSpritesArray[current_sheet].length)
		{
			// TODO: make this mobile-friendly
			if (FlxG.mouse.overlaps(characterSpritesArray[current_sheet].members[i]))
				current_selection = i;
		}
		if (Ctrl.cleft[1])
			current_selection = current_selection - 1;
		if (Ctrl.cright[1])
			current_selection = current_selection + 1;
		if (Ctrl.cup[1])
			current_sheet = current_sheet + 1;
		if (Ctrl.cdown[1])
			current_sheet = current_sheet - 1;
		if (FlxG.mouse.overlaps(backTab))
		{
			if (backTab.y != 110)
				backTab.y = 110;
			if (FlxG.mouse.justPressed)
			{
				if (backTab.scale.x != 0.8)
					backTab.scale.set(0.8, 0.8);
				SheetSubstate.instance.reload(type == COSTUME ? "STICKER" : "COSTUME");
			}
			else if (!FlxG.mouse.pressed && backTab.scale.x != 1.1)
				backTab.scale.set(1.1, 1.1);
		}
		else if (backTab.scale.x != 1)
			backTab.scale.set(1, 1);
	}

	function set_current_sheet(val:Int):Int
	{
		if (characterSpritesArray.length > 1)
		{
			characterSpritesArray[current_sheet].kill();
			notSeenGroup[current_sheet].kill();
		}

		if (val < 0)
			current_sheet = characterSpritesArray.length - 1;
		else if (val > characterSpritesArray.length - 1)
			current_sheet = 0;
		else
			current_sheet = val;

		update_sheet_graphics();

		return current_sheet;
	}

	function set_current_selection(val:Int):Int
	{
		// characterSpritesArray[current_sheet].members[current_selection].scale.set(1, 1);

		if (val < 0)
			current_selection = characterSpritesArray[current_sheet].members.length - 1;
		else if (val > characterSpritesArray[current_sheet].members.length - 1)
			current_selection = 0;
		else
			current_selection = val;

		if (notSeenGroup[current_sheet].members.length > 0)
		{
			final matches:Array<FlxSpriteExt> = notSeenGroup[current_sheet].members.filter(i ->
				i.ID == characterSpritesArray[current_sheet].members[current_selection].ID);
			if (matches.length > 0)
			{
				seen.push(characterNames[current_sheet][current_selection]);
				notSeenGroup[current_sheet].members.remove(matches[0]);
			}
		}
		update_selection_graphics();

		return current_selection;
	}

	function update_sheet_graphics()
	{
		graphicSheet = sheet_collection.sheets[current_sheet].graphic != null ? true : false;
		if (graphicSheet)
			stickerSheetBase.loadGraphic(Paths.get(sheet_collection.sheets[current_sheet].graphic + '.png'));
		else
			stickerSheetBase.makeGraphic(1430, 845, FlxColor.BLACK);

		characterSpritesArray[current_sheet].revive();
		notSeenGroup[current_sheet].revive();

		update_selection_graphics();
	}

	function update_selection_graphics()
	{
		if (type == STICKER)
		{
			final sticker:StickerDef = data.JsonData.get_sticker(characterNames[current_sheet][current_selection]);
			title.text = sticker.properName.toUpperCase();
			description.text = (sticker.desc != null ? (sticker.desc + ' ') : '') + 'Created by ${sticker.artist != null ? sticker.artist : "Unknown"}';
			// selector.setPosition(characterSpritesArray[current_sheet].members[current_selection].x + (characterSpritesArray[current_sheet].members[current_selection].width / 2) - 175, characterSpritesArray[current_sheet].members[current_selection].y + (characterSpritesArray[current_sheet].members[current_selection].height / 2) - 177);
		}
		else
		{
			final costume:CostumeDef = data.JsonData.get_costume(characterNames[current_sheet][current_selection]);
			title.text = costume.display.toUpperCase();
			description.text = (costume.desc != null ? costume.desc : '');
			// selector.setPosition(characterSpritesArray[current_sheet].members[current_selection].x - 110, characterSpritesArray[current_sheet].members[current_selection].y - 80);
		}
		selector.setPosition(characterSpritesArray[current_sheet].members[current_selection].x
			+ (characterSpritesArray[current_sheet].members[current_selection].width / 2)
			- 175,
			characterSpritesArray[current_sheet].members[current_selection].y
				+ (characterSpritesArray[current_sheet].members[current_selection].height / 2)
				- 167);
		// characterSpritesArray[current_sheet].members[current_selection].scale.set(1.1, 1.1);
	}

	public function transOut()
	{
		canSelect = false;
		FlxTween.tween(descGroup, {x: -440}, 0.5, {ease: FlxEase.quintIn});
		new FlxTimer().start(0.3, function(tmr:FlxTimer)
		{
			members.for_all_members((member:FlxBasic) ->
			{
				final daMem:FlxObject = cast(member, FlxObject);
				FlxTween.tween(daMem, {y: daMem.y + 1300}, 1, {ease: FlxEase.cubeInOut});
			});
		});
	}
}

enum abstract SheetType(String) from String to String
{
	final COSTUME;
	final STICKER;
}
