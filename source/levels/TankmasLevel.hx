package levels;

import states.PlayState.YSortable;
import activities.ActivityArea;
import entities.Minigame;
import entities.NPC;
import entities.Player;
import entities.Present;
import entities.misc.GamingDevice;
import flixel.tile.FlxTilemap;
import flixel.util.FlxDirectionFlags;
import levels.LDTKLevel;
import levels.LdtkProject;
import zones.Door;

enum abstract RoomId(Int) from Int from Int
{
	final HotelCourtyard = 1;
	final HotelInterior = 2;
	final Theatre = 3;

	public static function from_string(world_identifier:String):RoomId
	{
		switch (world_identifier)
		{
			case "hotel_interior":
				return HotelInterior;
			case "outside_hotel":
				return HotelCourtyard;
			case "theatre":
				return Theatre;
		}

		throw 'Could not find room id by name ${world_identifier}, 
					 please add it to RoomId in TankmasLevel.hx';
	}
}

class TankmasLevel extends LDTKLevel
{
	public var bg:FlxSpriteExt;
	public var fg:FlxSpriteExt;

	public var level_data:LdtkProject_Level;

	var level_name:String;

	public function new(level:LdtkProject_Level, ?tilesheet_graphic:String)
	{
		this.level_data = level;
		super(level.identifier, tilesheet_graphic);
	}

	override function generate(LevelName:String, tilesheet_graphic:String)
	{
		PlayState.self.levels.add(this);

		level_name = LevelName;

		super.generate(level_name, tilesheet_graphic);

		// for (i in 0..._tileObjects.length)
		// setTileProperties(i, FlxObject.NONE);

		var data:LdtkProject_Level = get_level_by_name(level_name);

		setPosition(data.worldX, data.worldY);

		if (data.json.bgRelPath != null)
		{
			var image:String = data.json.bgRelPath.split("/").last().replace_multiple(["-reference", "-background", "-foreground", ".png", ".jpg"], "");
			PlayState.self.level_backgrounds.add(bg = new FlxSpriteExt(x, y, Paths.image_path('$image-background')));
			PlayState.self.level_foregrounds.add(fg = new FlxSpriteExt(x, y, Paths.image_path('$image-foreground')));
		}
	}

	public function place_entities()
	{
		var level:LdtkProject_Level = get_level_by_name(level_name);

		for (entity in level.l_Entities.all_Player.iterator())
			new Player(x + entity.pixelX, y + entity.pixelY);

		for (entity in level.l_Entities.all_NPC.iterator())
			new NPC(x + entity.pixelX, y + entity.pixelY, entity.f_name, Std.parseInt(entity.f_timelock));

		for (entity in level.l_Entities.all_Present.iterator())
			new Present(x + entity.pixelX, y + entity.pixelY, entity.f_username, Std.parseInt(entity.f_timelock));

		for (entity in level.l_Entities.all_Door.iterator())
		{
			var spawn:FlxPoint = new FlxPoint(x + entity.f_spawn.cx * 16, y + entity.f_spawn.cy * 16);
			new Door(x + entity.pixelX, y + entity.pixelY, entity.width, entity.height, entity.f_linked_door, spawn, entity.iid);
		}

		for (entity in level.l_Entities.all_Minigame.iterator())
			new Minigame(x + entity.pixelX, y + entity.pixelY, entity.width, entity.height, entity.f_minigame_id);

		for (entity in level.l_Entities.all_Activity_Area.iterator())
			new ActivityArea(entity.f_ActivityType, x + entity.pixelX, y + entity.pixelY, entity.width, entity.height);

		for (entity in level.l_Entities.all_Graphic)
		{
			var sprite:FlxSpriteExt = new FlxSpriteExt(x + entity.pixelX, y + entity.pixelY);
			sprite.loadAllFromAnimationSet(entity.f_name);

			if (!entity.f_Is_YSortable)
			{
				switch (entity.f_layer.getName().toLowerCase())
				{
					case "back":
						PlayState.self.props_background.add(sprite);
					case "front":
						PlayState.self.props_foreground.add(sprite);
				}
			}
			else
			{
				sprite.y_bottom_offset = 64;
				PlayState.self.world_objects.add(sprite);
			}
		}

		for (c in level.l_Entities.all_Misc)
		{
			switch (c.f_name)
			{
				case "gaming-device":
					new GamingDevice(c.worldPixelX, c.worldPixelY);
			}
		}

		/**
		 * Add collision shapes
		 */
		var colls = PlayState.self.collisions;
		for (c in level.l_Collision.all_CollisionCircle)
		{
			colls.add_circle(c.worldPixelX, c.worldPixelY, c.height * 0.5);
		}

		for (c in level.l_Collision.all_CollisionSquare)
		{
			colls.add_rect(c.worldPixelX, c.worldPixelY, c.width, c.height);
		}

		for (c in level.l_Collision.all_SlopeNE)
			colls.add_slope_ne(c.worldPixelX, c.worldPixelY, c.width, c.height);
		for (c in level.l_Collision.all_SlopeNW)
			colls.add_slope_nw(c.worldPixelX, c.worldPixelY, c.width, c.height);
		for (c in level.l_Collision.all_SlopeSE)
			colls.add_slope_se(c.worldPixelX, c.worldPixelY, c.width, c.height);
		for (c in level.l_Collision.all_SlopeSW)
			colls.add_slope_sw(c.worldPixelX, c.worldPixelY, c.width, c.height);

		/**
		 * Place decorations
		 */
		var add_ysortable = (wx:Float, wy:Float, graphic:flixel.system.FlxAssets.FlxGraphicAsset, tile, bottom_offset = 0.0) ->
		{
			var f = new YSortable(wx, wy);
			f.loadGraphic(graphic, true, tile.w, tile.h);
			f.frame = f.frames.getByIndex(Std.int(tile.x / tile.w));
			f.y_bottom_offset = bottom_offset;
			PlayState.self.world_objects.add(f);
		}

		var add_layer = ( //
			xl:Array<Entity_Decorations_XL>, //
			md:Array<Entity_Decorations_MD>, //
			sm:Array<Entity_Decorations_SM>, //
			trees:Array<Entity_Decorations_Trees>, //
		) ->
		{
			for (c in xl)
			{
				var tile = c.f_Tile_infos ?? c.tileInfos;
				add_ysortable(c.worldPixelX, c.worldPixelY, AssetPaths.decorations_xl__png, tile, 150);
			}
			for (c in md)
			{
				var tile = c.f_Tile_infos ?? c.tileInfos;
				add_ysortable(c.worldPixelX, c.worldPixelY, AssetPaths.decorations_md__png, tile, 150);
			}
			for (c in sm)
			{
				var tile = c.f_Tile_infos ?? c.tileInfos;
				add_ysortable(c.worldPixelX, c.worldPixelY, AssetPaths.decorations_sm__png, tile, 56);
			}
			for (c in trees)
			{
				var tile = c.f_Tile_infos ?? c.tileInfos;
				add_ysortable(c.worldPixelX, c.worldPixelY, AssetPaths.decorations_trees__png, tile, 96);
			}
		}

		add_layer( //
			level.l_Decorations1.all_Decorations_XL, //
			level.l_Decorations1.all_Decorations_MD, //
			level.l_Decorations1.all_Decorations_SM, //
			level.l_Decorations1.all_Decorations_Trees //
		);
		add_layer( //
			level.l_Decorations2.all_Decorations_XL, //
			level.l_Decorations2.all_Decorations_MD, //
			level.l_Decorations2.all_Decorations_SM, //
			level.l_Decorations2.all_Decorations_Trees //
		);
		add_layer( //
			level.l_Decorations3.all_Decorations_XL, //
			level.l_Decorations3.all_Decorations_MD, //
			level.l_Decorations3.all_Decorations_SM, //
			level.l_Decorations3.all_Decorations_Trees //
		);

		/**put entity iterators here**/
		/* 
			example:
				for (entity in data.l_Entities.all_Boy.iterator())
					new Boy(x + entity.pixelX, y + entity.pixelY);
		 */
	}

	public static function make_all_levels_in_world(world_name:String):Array<TankmasLevel>
	{
		var array:Array<TankmasLevel> = [];

		for (world in Main.ldtk_project.worlds)
			if (world.identifier == world_name)
				for (level in world.levels)
					array.push(new TankmasLevel(level));

		return array;
	}

	override function update(elapsed:Float)
	{
		// getTileCollisions(getTileIndexByCoords(PlayState.self.player.mp));
		super.update(elapsed);
	}
}
