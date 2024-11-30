package states;

import activities.ActivityArea;
import data.SaveManager;
import entities.Interactable;
import entities.Minigame;
import entities.NPC;
import entities.Player;
import entities.Present;
import entities.base.BaseUser;
import entities.base.NGSprite;
import flixel.tile.FlxTilemap;
import fx.StickerFX;
import fx.Thumbnail;
import levels.TankmasLevel;
import minigames.MinigameHandler;
import net.tankmas.OnlineLoop;
import ui.DialogueBox;
import ui.sheets.*;
import zones.Door;

class PlayState extends BaseState
{
	public static var self:PlayState;

	static final default_world:String = "outside_hotel";

	var current_world:String;

	public var player:Player;
	public var users:FlxTypedGroup<BaseUser> = new FlxTypedGroup<BaseUser>();
	public var presents:FlxTypedGroup<Present> = new FlxTypedGroup<Present>();
	public var objects:FlxTypedGroup<FlxSprite> = new FlxTypedGroup<FlxSprite>();
	public var thumbnails:FlxTypedGroup<Thumbnail> = new FlxTypedGroup<Thumbnail>();
	public var shadows:FlxTypedGroup<FlxSpriteExt> = new FlxTypedGroup<FlxSpriteExt>();
	public var stickers:FlxTypedGroup<StickerFX> = new FlxTypedGroup<StickerFX>();
	public var sticker_fx:FlxTypedGroup<NGSprite> = new FlxTypedGroup<NGSprite>();
	public var dialogues:FlxTypedGroup<DialogueBox> = new FlxTypedGroup<DialogueBox>();
	public var npcs:FlxTypedGroup<NPC> = new FlxTypedGroup<NPC>();
	public var minigames:FlxTypedGroup<Minigame> = new FlxTypedGroup<Minigame>();

	public var levels:FlxTypedGroup<TankmasLevel> = new FlxTypedGroup<TankmasLevel>();
	public var level_backgrounds:FlxTypedGroup<FlxSprite> = new FlxTypedGroup<FlxSprite>();
	public var level_collision:FlxTypedGroup<FlxTilemap> = new FlxTypedGroup<FlxTilemap>();

	/**Do not add to state*/
	public var interactables:FlxTypedGroup<Interactable> = new FlxTypedGroup<Interactable>();

	public var activity_areas:FlxTypedGroup<ActivityArea> = new FlxTypedGroup();

	public var doors:FlxTypedGroup<Door> = new FlxTypedGroup<Door>();

	public var ui:FlxTypedGroup<FlxSpriteExt> = new FlxTypedGroup<FlxSpriteExt>();

	public function new(?world_to_load:String)
	{
		if (world_to_load != null)
			current_world = world_to_load
		else
			current_world = SaveManager.savedRoom == null ? default_world : SaveManager.savedRoom;
		super();
	}

	override public function create()
	{
		super.create();
		self = this;

		OnlineLoop.init();

		bgColor = FlxColor.BLACK;

		add(level_backgrounds);
		add(levels);
		add(level_collision);

		add(shadows);
		add(minigames);
		add(npcs);
		add(presents);
		add(users);
		add(objects);
		add(thumbnails);
		add(stickers);
		add(sticker_fx);
		add(dialogues);

		add(doors);

		add(ui);

		// add(new DialogueBox(Lists.npcs.get("thomas").get_state_dlg("default")));

		make_world();
		make_ui();

		MinigameHandler.instance.initialize();

		FlxG.autoPause = false;
		FlxG.camera.target = player;

		var bg:FlxObject = level_backgrounds.members[0];

		FlxG.worldBounds.set(bg.x, bg.y, bg.width, bg.height);

		#if !show_collision
		level_collision.visible = false;
		#end

		SaveManager.load_costumes();
		SaveManager.load_emotes();

		// FlxG.camera.setScrollBounds(bg.x, bg.width, bg.y, bg.height);

		OnlineLoop.iterate();
	}

	override public function update(elapsed:Float)
	{
		OnlineLoop.iterate();

		super.update(elapsed);
		// Ctrl.update();

		if (Ctrl.reset[1])
			FlxG.switchState(new PlayState());
		if (Ctrl.jaction[1] && !player.interact_in_use())
			new CostumeSelectSheet();
		if (Ctrl.jspecial[1])
			new StickerSelectSheet();
		for (mem in ui.members)
			switch (ui.members.indexOf(mem))
			{
				case 2:
					var twen:FlxTween = null;
					if (FlxG.mouse.overlaps(mem))
					{
						if (mem.y == 1030 && twen == null)
							twen = FlxTween.tween(mem, {y: 880}, 0.3, {
								onComplete: function(twn:FlxTween)
								{
									twen = null;
									mem.loadGraphic(Paths.get('charselect_mini_FULL.png'));
								}
							});
						if (FlxG.mouse.justReleased)
						{
							if (twen != null)
								twen.cancel();
							twen = FlxTween.tween(mem, {y: 1180}, 0.3, {
								onComplete: (twn:FlxTween) ->
								{
									new CostumeSelectSheet();
									twen = null;
								}
							});
						}
						if (FlxG.mouse.pressed && mem.scale.x != 0.8)
							mem.scale.set(0.8, 0.8);
					}
					else
					{
						if (mem.scale.x != 1)
							mem.scale.set(1, 1);
						if ((mem.y == 880 || mem.y == 1180) && twen == null)
							twen = FlxTween.tween(mem, {y: 1030}, 0.3, {
								onComplete: function(twn:FlxTween)
								{
									twen = null;
									mem.loadGraphic(Paths.get('charselect_mini_BG.png'));
								}
							});
					}

				case 1:
					if (FlxG.mouse.overlaps(mem))
					{
						// if(FlxG.mouse.justReleased) openSubState(new OptionsSubState());
						if (FlxG.mouse.pressed && mem.scale.x != 0.8)
							mem.scale.set(0.8, 0.8)
						else if (!FlxG.mouse.pressed && mem.scale.x != 1.1)
							mem.scale.set(1.1, 1.1);
					}
					else if (mem.scale.x != 1)
						mem.scale.set(1, 1);

				case 0:
					if (FlxG.mouse.overlaps(mem))
					{
						if (FlxG.mouse.justReleased)
							player.use_sticker(player.sticker);
						if (FlxG.mouse.pressed && mem.scale.x != 0.8)
							mem.scale.set(0.8, 0.8)
						else if (!FlxG.mouse.pressed && mem.scale.x != 1.1)
							mem.scale.set(1.1, 1.1);
					}
					else if (mem.scale.x != 1)
						mem.scale.set(1, 1);
			}
		/**if (Ctrl.jspecial[1])
			new StickerSelectSheet();**/
		handle_collisions();
	}

	function handle_collisions()
		FlxG.collide(level_collision, player);

	override function destroy()
	{
		self = null;
		super.destroy();
	}

	function make_world()
	{
		TankmasLevel.make_all_levels_in_world(current_world);
		for (level in levels)
			level.place_entities();
	}

	function make_ui()
	{
		ui.add(new FlxSpriteExt(20, 20, Paths.get('heart.png')));
		ui.add(new FlxSpriteExt(1708, 20, Paths.get('settings.png')));
		ui.add(new FlxSpriteExt(1520, 1030, Paths.get('charselect_mini_BG.png')));
		ui.forEach((spr:FlxSpriteExt) ->
		{
			spr.scrollFactor.set(0, 0);
		});
	}
}
