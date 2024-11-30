package entities.base;

import activities.ActivityArea;
import data.JsonData;
import data.types.TankmasDefs.CostumeDef;
import data.types.TankmasEnums.PlayerAnimation;
import entities.base.NGSprite;
import net.tankmas.NetDefs.NetEventDef;
import net.tankmas.NetDefs.NetEventType;

class BaseUser extends NGSprite
{
	public var costume:CostumeDef;

	var move_acl:Int = 60;
	var move_speed:Int = 500;

	var shadow:FlxSpriteExt;
	var nameTag:FlxText;

	public var username:String;

	public var sticker_name:String;
	public var active_activity_area:ActivityArea;

	public function new(?X:Float, ?Y:Float, username:String)
	{
		super(X, Y);

		type = "base-user";
		
		this.username = username;

		new_costume(JsonData.get_costume("tankman"));
		sprite_anim.anim(PlayerAnimation.MOVING);

		nameTag = new FlxText(0, 0, 0, username.toUpperCase());
		nameTag.setFormat(Paths.get('CharlieType-Heavy.otf'), 24, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
		nameTag.bold = true;
		nameTag.offset.y = -30;
		PlayState.self.tags.add(nameTag);

		PlayState.self.users.add(this);
		PlayState.self.shadows.add(shadow = new FlxSpriteExt(Paths.get("player-shadow.png")));

		maxVelocity.set(move_speed, move_speed);

		sprite_anim.anim(PlayerAnimation.IDLE);

		drag.set(300, 300);
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
			default:
			case "idle" | null:
				if (moving)
					sprite_anim.anim(PlayerAnimation.MOVING);
			case "moving":
				if (!moving)
					sprite_anim.anim(PlayerAnimation.IDLE);
		}
	}

	public function new_costume(costume:CostumeDef)
	{
		loadGraphic(Paths.get('${costume.name}.png'));
		original_size.set(width, height);
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

	public function on_event(event:NetEventDef)
	{
		switch (event.type)
		{
			case NetEventType.STICKER:
				use_sticker(event.data.name);
		}

		if (active_activity_area != null)
		{
			active_activity_area.on_event(event, this);
		}
	}

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

		PlayState.self.users.remove(this, true);
		super.kill();
	}

	public static function get_user(username:String, ?make_user_function:Void->BaseUser):BaseUser
	{
		for (user in PlayState.self.users)
			if (user.username == username)
				return user;
		return make_user_function == null ? null : make_user_function();
	}
}
