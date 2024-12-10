package entities;

import data.JsonData;
import data.types.TankmasDefs.CostumeDef;
import entities.base.BaseUser;
import flixel.math.FlxVelocity;
import net.tankmas.OnlineLoop;

class NetUser extends BaseUser
{
	var move_tween:FlxTween;
	var last_hit:Int = 0;

	var min_move_dist:Int = 32;

	var teleport_move:Bool = true;

	var moving:Bool = false;

	var move_target:FlxPoint = new FlxPoint();

	var facing_dir:Int = 0;

	public function new(?X:Float, ?Y:Float, username:String, ?costume:CostumeDef)
	{
		super(X, Y, username);
		type = "net-user";

		if (costume == null)
			costume = JsonData.get_costume(Main.default_costume);

		new_costume(costume);
		move_to(X, Y, true);
		trace("NEW USER " + username);
	}

	override function update(elapsed:Float)
	{
		if (moving && distance(move_target) > 0)
			move_update();

		move_animation_handler(moving);

		super.update(elapsed);
	}

	override function updateMotion(elapsed:Float)
	{
		// var prev_x:Float = x;
		// var prev_y:Float = y;

		super.updateMotion(elapsed);

		// var total_move_dist:Float = Math.abs(x - prev_x) + Math.abs(y - prev_y);

		if (Math.abs(hitbox.velocity.x) > 0.2)
		{
			flipX = hitbox.velocity.x > 0;
		}
		else if (facing_dir != 0)
		{
			flipX = facing_dir < 0;
		}
	}

	public function move_update()
	{
		if (distance(move_target) < min_move_dist)
		{
			move_to(move_target.x, move_target.y, true);
			return;
		}

		FlxVelocity.moveTowardsPoint(this, move_target, move_speed);
	}

	public function move_to(X:Float, Y:Float, teleport:Bool = false, sx:Int = 0)
	{
		if (teleport)
		{
			hitbox.setPosition(x, y);
			hitbox.velocity.set(0, 0);
			hitbox.acceleration.set(0, 0);
			moving = false;

			return;
		}

		facing_dir = sx;

		moving = true;

		move_target.set(X, Y).add(origin.x, origin.y);

		move_update();
	}
}
