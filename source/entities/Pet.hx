package entities;

import data.types.TankmasDefs.PetDef;
import data.types.TankmasDefs.PetStats;
import data.types.TankmasEnums.PetAnimation;
import entities.base.BaseUser;
import entities.base.NGSprite;

class Pet extends NGSprite
{
	var owner:BaseUser;

	var def:PetDef;

	public var stats(get, never):PetStats;
	public var name(get, never):String;

	var min_follow_distance:Int = 64;

	public static final default_stats:PetStats = {
		follow_speed: 300,
		follow_acl: 15,
		deadzone: 125,
		follow_offset_x: 32,
		follow_offset_y: 32,
		follow_accuracy: 0.9
	};

	public function new(?X:Float, ?Y:Float, owner:BaseUser, def:PetDef)
	{
		super(X, Y);

		this.owner = owner;
		this.def = def;

		loadAllFromAnimationSet(def.name);

		PlayState.self.pets.add(this);
		PlayState.self.world_objects.add(this);

		sstate(IDLE);
		sprite_anim.anim(PetAnimation.IDLE);

		trace_new_state = true;

		drag.set(200, 200);
	}

	override function update(elapsed:Float)
	{
		fsm();
		super.update(elapsed);
	}

	override function updateMotion(elapsed:Float)
	{
		super.updateMotion(elapsed);
	}

	function fsm()
		switch (cast(state, State))
		{
			default:
			case FOLLOWING:
				sprite_anim.anim(PetAnimation.MOVING);
				follow_owner();
			case IDLE:
				if (ttick() > 30 && velocity.x == 0 && velocity.y == 0)
					sprite_anim.anim(PetAnimation.IDLE);
				var within_x_deadzone:Bool = Math.abs(owner.mp.x - mp.x) <= stats.deadzone;
				var within_y_deadzone:Bool = Math.abs(owner.mp.y - mp.y) <= stats.deadzone;
				if (!within_x_deadzone || !within_y_deadzone)
					sstate(FOLLOWING);
		}

	function follow_owner()
	{
		var target:FlxPoint = FlxPoint.get().copyFrom(owner.mp);

		// offset so it follows behind the player
		// reminder that owner.flipX = player facing right
		target.x = target.x + stats.follow_offset_x * (owner.flipX ? -1 : 1);

		var reached_destination:Bool = move_towards(target);
		if (reached_destination)
			sstate(IDLE);

		target.put();
	}

	override function kill()
	{
		PlayState.self.pets.remove(this, true);
		super.kill();
	}

	function move_towards(dest:FlxPoint):Bool
	{
		var within_x_deadzone:Bool = Math.abs(dest.x - mp.x) <= stats.deadzone;
		var within_y_deadzone:Bool = Math.abs(dest.y - mp.y) <= stats.deadzone;

		// destination reached
		if (within_x_deadzone && within_y_deadzone)
			return true;

		if (!within_x_deadzone)
			if (dest.x > mp.x)
			{
				acceleration.x = stats.follow_speed;
				if (velocity.x < 0)
				{
					acceleration.x = stats.follow_speed * 2.5;
					velocity.x *= stats.follow_accuracy;
				}
			}
			else
			{
				acceleration.x = -stats.follow_speed;
				if (velocity.x > 0)
				{
					acceleration.x = -stats.follow_speed * 2.5;
					velocity.x *= stats.follow_accuracy;
				}
			}

		if (!within_y_deadzone)
			if (dest.y > mp.y)
			{
				acceleration.y = stats.follow_speed;
				if (velocity.y < 0)
				{
					acceleration.y = stats.follow_speed * 2.5;
					velocity.y *= stats.follow_accuracy;
				}
			}
			else
			{
				acceleration.y = -stats.follow_speed;
				if (velocity.y > 0)
				{
					acceleration.y = -stats.follow_speed * 2.5;
					velocity.y *= stats.follow_accuracy;
				}
			}

		if (!within_x_deadzone)
			flipX = dest.x > mp.x;

		return false;
	}

	function get_stats():PetStats
		return def.stats;

	function get_name():String
		return def.name;
}

private enum abstract State(String) from String to String
{
	var IDLE;
	var FOLLOWING;
}
