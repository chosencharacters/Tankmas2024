package entities.base;

import states.PlayState.YSortable;
import activities.ActivityArea;
import data.JsonData;
import data.types.TankmasDefs.CostumeDef;
import data.types.TankmasEnums.PlayerAnimation;
import entities.base.NGSprite;
import net.tankmas.NetDefs.NetEventDef;
import net.tankmas.NetDefs.NetEventType;
import squid.sprite.TempSprite;

// TEst enum for pet types
enum abstract PetType(String) from String to String
{
	var None;
	var Dog = 'dog';
	var Cat = 'cat';
}

class BaseUser extends NGSprite
{
	public var costume:CostumeDef;

	var move_acl:Int = 25;
	var move_speed:Int = 500;

	var shadow:FlxSpriteExt;
	var nameTag:FlxText;

	public var username:String;

	public var sticker_name:String;
	public var active_activity_area:ActivityArea;

	// Add custom values here. If you change the values of these
	// in Player.hx, it will be synced to every other user ingame.
	// To Add more values, define them in BaseUserSharedData.hx
	public var data:BaseUserSharedData = {
		pet: PetType.Dog,
		marshmallow_streak: 0,
		scale: 1.0,
	}

	var sakura_fx_rate:Int = 20;

	var move_anim_name(get, never):String;

	function get_move_anim_name():String
	{
		if (costume.walk != null)
			return costume.walk;
		return "moving";
	}

	public function new(?X:Float, ?Y:Float, username:String, costume:String = "tankman")
	{
		super(X, Y);

		type = "base-user";

		ran = new FlxRandom();

		this.username = username;

		new_costume(JsonData.get_costume(costume));
		sprite_anim.anim(PlayerAnimation.MOVING);

		nameTag = new FlxText(0, 0, 0, username.toUpperCase());
		nameTag.setFormat(Paths.get('CharlieType-Heavy.otf'), 36, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
		nameTag.bold = true;
		nameTag.offset.y = -46;
		PlayState.self.username_tags.add(nameTag);

		PlayState.self.world_objects.add(this);
		PlayState.self.shadows.add(shadow = new FlxSpriteExt(Paths.get("player-shadow.png")));

		maxVelocity.set(move_speed, move_speed);

		sprite_anim.anim(PlayerAnimation.IDLE);

		drag.set(300, 300);
	}

	override function update(elapsed:Float)
	{
		ttick();
		super.update(elapsed);
	}

	public function use_sticker(sticker_name:String):Bool
	{
		if (this.sticker_name == sticker_name)
			return false;
		this.sticker_name = sticker_name;
		new fx.StickerFX(this, sticker_name, () -> this.sticker_name = null);
		return true;
	}

	function move_animation_handler(moving:Bool)
	{
		switch (sprite_anim.name)
		{
			// default:
			case "idle" | null:
				if (moving)
					sprite_anim.anim(get_move_animation());
			case move_anim_name:
				walk_fx();
				if (!moving)
					sprite_anim.anim(PlayerAnimation.IDLE);
		}
	}

	function walk_fx()
	{
		/*
			switch (costume.fx)
			{
				case "sakura":
					if (tick % sakura_fx_rate == 1)
					{
						var big:Bool = ran.int(0, 100) > 50;
						var fx:TempSprite = new TempSprite('sakura-${big ? 'small' : 'medium'}', PlayState.self.user_fx);
						fx.setPosition(x + (flipX ? width : 0), y + height - fx.height);
						fx.flipX = flipX;
					}
		}*/
	}

	public function new_costume(costume:CostumeDef)
	{
		loadGraphic(Paths.get('${costume.name}.png'));
		original_size.set(width, height);
		this.costume = costume;
	}

	override function updateMotion(elapsed:Float)
	{
		super.updateMotion(elapsed);

		shadow.center_on_bottom(this);
		shadow.offset.x = offset.x;
		shadow.updateMotion(elapsed);

		nameTag.center_on_bottom(this);

		check_current_area();
	}

	function check_current_area()
	{
		var prev_area = active_activity_area;
		var new_area:ActivityArea = null;
		for (area in PlayState.self.activity_areas.iterator())
		{
			if (area.in_area(x, y))
			{
				new_area = area;
				break;
			}
		}

		if (prev_area == new_area)
		{
			return;
		}

		if (new_area != null)
		{
			enter_activity_area(new_area);
		}
		else
		{
			leave_activity_area();
		}
	}

	// Received when player did action.
	public function on_event(event:NetEventDef)
	{
		// Ignore these events if they come from the local player.
		if (event.username == Main.username)
		{
			return;
		}

		switch (event.type)
		{
			case NetEventType.STICKER:
				use_sticker(event.data.name);
			case NetEventType.DROP_MARSHMALLOW:
				// Another user dropped a marshmallow
			case OPEN_PRESENT:
				// Another user opened a present.
				trace('${event.username} opened present ${event.data.day}. Get medal: ${event.data.medal}');
		}

		if (active_activity_area != null)
		{
			active_activity_area.on_event(event, this);
		}
	}

	public function merge_data_field(incoming_data:Dynamic)
	{
		if (incoming_data == null)
			return;

		for (field in Reflect.fields(incoming_data))
		{
			var value = Reflect.field(incoming_data, field);
			Reflect.setField(data, field, value);
			on_data_property_changed(field, value);
		}
	}

	function on_data_property_changed(name:String, value:Dynamic) {}

	public function leave_activity_area()
	{
		if (active_activity_area != null)
		{
			active_activity_area.on_leave(this);
		}

		active_activity_area = null;
	}

	public function enter_activity_area(area:ActivityArea)
	{
		if (area == active_activity_area)
			return;
		leave_activity_area();
		active_activity_area = area;
		area.on_enter(this);
	}

	override function kill()
	{
		leave_activity_area();

		shadow.destroy();
		nameTag.destroy();

		PlayState.self.world_objects.remove(this, true);
		super.kill();
	}

	public function on_user_left()
	{
		kill();
	}

	public static function get_user(username:String, ?make_user_function:Void->BaseUser):BaseUser
	{
		var existing_user = PlayState.self.get_user(username);
		if (existing_user != null)
			return existing_user;
		return make_user_function == null ? null : make_user_function();
	}

	/// Override these how you want in NetUser/Player

	public function pet_changed(pet_type:PetType) {}

	public function scale_changed(scale:Float) {}

	function get_move_animation():PlayerAnimation
	{
		switch (move_anim_name)
		{
			default:
				return PlayerAnimation.MOVING;
			case "hop":
				return PlayerAnimation.HOPPING;
		}
	}
}
