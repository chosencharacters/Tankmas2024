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
import net.tankmas.NetDefs.NetUserDef;
import net.tankmas.OnlineLoop;
import net.tankmas.TankmasClient;
import ui.DialogueBox;
import ui.MainGameOverlay;
import ui.TouchOverlay;
import ui.popups.StickerPackOpening;
import ui.sheets.*;
import ui.sheets.SheetMenu;
import video.PremiereHandler;
import zones.Door;

class PlayState extends BaseState
{
	public static var self:PlayState;

	static final default_world:String = "outside_hotel";

	var current_world:String;

	public var player:Player;
	public var users:FlxTypedGroup<BaseUser> = new FlxTypedGroup<BaseUser>();
	public var username_tags:FlxTypedGroup<FlxText> = new FlxTypedGroup<FlxText>();
	public var presents:FlxTypedGroup<Present> = new FlxTypedGroup<Present>();
	public var objects:FlxTypedGroup<FlxSprite> = new FlxTypedGroup<FlxSprite>();
	public var thumbnails:FlxTypedGroup<Thumbnail> = new FlxTypedGroup<Thumbnail>();
	public var shadows:FlxTypedGroup<FlxSpriteExt> = new FlxTypedGroup<FlxSpriteExt>();
	public var stickers:FlxTypedGroup<StickerFX> = new FlxTypedGroup<StickerFX>();
	public var sticker_fx:FlxTypedGroup<NGSprite> = new FlxTypedGroup<NGSprite>();
	public var dialogues:FlxTypedGroup<DialogueBox> = new FlxTypedGroup<DialogueBox>();
	public var npcs:FlxTypedGroup<NPC> = new FlxTypedGroup<NPC>();
	public var minigames:FlxTypedGroup<Minigame> = new FlxTypedGroup<Minigame>();
	public var misc_sprites:FlxTypedGroup<FlxSpriteExt> = new FlxTypedGroup<FlxSpriteExt>();

	public var levels:FlxTypedGroup<TankmasLevel> = new FlxTypedGroup<TankmasLevel>();
	public var level_backgrounds:FlxTypedGroup<FlxSprite> = new FlxTypedGroup<FlxSprite>();
	public var level_collision:FlxTypedGroup<FlxTilemap> = new FlxTypedGroup<FlxTilemap>();

	/**Do not add to state*/
	public var interactables:FlxTypedGroup<Interactable> = new FlxTypedGroup<Interactable>();

	public var activity_areas:FlxTypedGroup<ActivityArea> = new FlxTypedGroup();

	public var doors:FlxTypedGroup<Door> = new FlxTypedGroup<Door>();

	public var ui_overlay:MainGameOverlay;

	public var sheet_menu:SheetMenu;

	public var touch:TouchOverlay;

	public static var show_usernames(default, set):Bool = true;

	public var premieres:PremiereHandler;

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

		Ctrl.mode = ControlModes.OVERWORLD;

		self = this;

		OnlineLoop.init();

		premieres = new PremiereHandler();

		bgColor = FlxColor.BLACK;

		make_world();
		make_ui();

		add(level_backgrounds);
		add(levels);
		add(level_collision);

		add(touch = new TouchOverlay());

		add(shadows);

		add(misc_sprites);

		add(minigames);
		add(npcs);
		add(presents);
		add(username_tags);
		add(users);
		add(objects);
		add(thumbnails);
		add(stickers);
		add(sticker_fx);
		add(dialogues);

		add(doors);

		add(ui_overlay);

		// add(new DialogueBox(Lists.npcs.get("thomas").get_state_dlg("default")));

		MinigameHandler.instance.initialize();

		FlxG.autoPause = false;
		FlxG.camera.target = player;

		var bg:FlxObject = level_backgrounds.members[0];

		FlxG.worldBounds.set(bg.x, bg.y, bg.width, bg.height);
		FlxG.camera.setScrollBoundsRect(bg.x, bg.y, bg.width, bg.height);

		#if !show_collision
		level_collision.visible = false;
		#end

		SaveManager.load_costumes();
		SaveManager.load_emotes();

		// FlxG.camera.setScrollBounds(bg.x, bg.width, bg.y, bg.height);

		OnlineLoop.iterate();

		// runs nearby animation if not checked here
		for (mem in presents.members)
			mem.checkOpen();

		SaveManager.save_room();

		// Check if player exists, and load their position.
		// A bit jank now since it does it after the player is spawned.
		// Also this could be loaded in the user's save file instead
		#if (!offline)
		TankmasClient.get_user(Main.username, player_loaded);
		#end
	}

	function player_loaded(?p:NetUserDef)
	{
		if (p != null)
		{
			// player.x = p.x;
			// player.y = p.y;
		}
	}

	override public function update(elapsed:Float)
	{
		OnlineLoop.iterate();

		premieres.update(elapsed);

		super.update(elapsed);
		// Ctrl.update();

		#if dev
		if (Ctrl.reset[1] && !FlxG.keys.pressed.SHIFT)
			FlxG.switchState(new PlayState());

		if (Ctrl.reset[1] && FlxG.keys.pressed.SHIFT)
			SaveManager.upload();
		#end

		if (Ctrl.mode.can_open_menus)
			if (Ctrl.jmenu[1])
				try
				{
					new SheetMenu();
				}
				catch (e)
				{
					trace(e);
				}

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
		final date:Date = Date.now();
		final theNum:Int = Main.get_current_bg(date.getMonth() != 11 ? 32 : date.getDate());
		TankmasLevel.make_all_levels_in_world(current_world);
		for (level in levels)
			level.place_entities();
	}

	function make_ui()
	{
		ui_overlay = new MainGameOverlay();
	}

	public static function set_show_usernames(val:Bool):Bool
	{
		for (username_tag in self.username_tags.members)
			username_tag.visible = val;
		return show_usernames = val;
	}
}
