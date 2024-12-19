package entities;

import data.JsonData;
import data.types.TankmasDefs.PetDef;
import data.types.TankmasDefs.PetStats;
import data.types.TankmasEnums.PetAnimation;
import entities.base.BaseUser;
import entities.base.NGSprite;

class Pet extends NGSprite
{
	var owner:BaseUser;

	public var def:PetDef;

	public var stats(get, never):PetStats;
	public var name(get, never):String;

	var min_follow_distance:Int = 64;

	public static final default_stats:PetStats = {
		follow_speed: 300,
		follow_acl: 15,
		deadzone: 125,
		follow_offset_x: 32,
		follow_offset_y: 32,
		follow_accuracy: 0.9,
		drag: 0.975
	};

	var empty:Bool = false;

	public function new(?X:Float, ?Y:Float, owner:BaseUser, pet_type:String)
	{
		super(X, Y);

		this.owner = owner;

		change_pet(pet_type);

		PlayState.self.pets.add(this);
		PlayState.self.world_objects.add(this);

		sstate(IDLE);
		sprite_anim.anim(PetAnimation.IDLE);

		trace_new_state = true;

		// not the same as actual pets stats drag
		drag.set(200, 200);
	}

	override function update(elapsed:Float)
	{
		fsm();
		super.update(elapsed);
	}

	override function updateMotion(elapsed:Float)
	{
		visible = !empty;
		super.updateMotion(elapsed);
	}

	function fsm()
		switch (cast(state, State))
		{
			default:
			case FOLLOWING:
				if (ttick() > 15 && Math.abs(velocity.x) + Math.abs(velocity.y) > 30)
					sprite_anim.anim(PetAnimation.MOVING);
				follow_owner();
			case IDLE:
				if (ttick() > 30 && Math.abs(velocity.x) + Math.abs(velocity.y) < 30)
					sprite_anim.anim(PetAnimation.IDLE);
				var within_x_deadzone:Bool = Math.abs(owner.mp.x - mp.x) <= stats.deadzone;
				var within_y_deadzone:Bool = Math.abs(owner.mp.y - mp.y) <= stats.deadzone;
				do_stats_drag(within_x_deadzone, within_y_deadzone);
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
		PlayState.self.world_objects.remove(this, true);

		super.kill();
	}

	function move_towards(dest:FlxPoint):Bool
	{
		var within_x_deadzone:Bool = Math.abs(dest.x - mp.x) <= stats.deadzone;
		var within_y_deadzone:Bool = Math.abs(dest.y - mp.y) <= stats.deadzone;

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

		do_stats_drag(within_x_deadzone, within_y_deadzone);

		// if both are true, destination is reached
		// moved to the bottom so drag can apply
		return within_x_deadzone && within_y_deadzone;
	}

	function do_stats_drag(drag_x:Bool, drag_y:Bool)
	{
		if (drag_x)
		{
			acceleration.x = acceleration.x * def.stats.drag;
			velocity.x = velocity.x * def.stats.drag;
		}
		if (drag_y)
		{
			acceleration.y = acceleration.y * def.stats.drag;
			velocity.y = velocity.y * def.stats.drag;
		}
	}

	function get_stats():PetStats
		return def.stats;

	function get_name():String
		return def.name;

	public function change_pet(pet_type:String)
	{
		def = JsonData.get_pet(pet_type);

		if (def == null)
		{
			change_pet("invisible-pet");
			return;
		}

		loadAllFromAnimationSet(def.name);

		updateMotion(0);
	}
}

private enum abstract State(String) from String to String
{
	var IDLE;
	var FOLLOWING;
}
