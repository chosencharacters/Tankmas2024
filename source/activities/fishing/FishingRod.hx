package activities.fishing;

import entities.base.BaseUser;
import flixel.addons.plugin.taskManager.FlxTask;
import flixel.graphics.FlxAsepriteUtil;
import flixel.math.FlxMath;
import flixel.tweens.FlxEase.EaseFunction;
import flixel.tweens.FlxEase;

class FishingRod extends FlxSprite
{
	var start_tween:FlxTween;

	var _ang:Float = 0.0;

	var enabled = false;

	var player:BaseUser;

	// amount of shaking
	public var shake_force = 0.0;

	public var rotation = 0.0;

	var rot_vel = 0.0;
	var eased_rotation = 0.0;

	public function new(player:BaseUser)
	{
		super(x, y);
		this.player = player;

		loadGraphic(AssetPaths.Tankmas_Fishing_ROD__png);

		PlayState.self.objects.add(this);

		offset.x = 127;
		offset.y = 190;

		activate();
	}

	public function activate()
	{
		enabled = true;
		visible = true;

		if (start_tween != null)
			start_tween.cancel();

		_ang = 30.0;
		alpha = 0.0;

		start_tween = FlxTween.tween(this, {_ang: 0.0}, 0.45, {ease: FlxEase.elasticOut});

		x = player.x;
		y = player.y;
	}

	public function hide() {}

	var time:Float = 0.;

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		time += elapsed;

		if (enabled)
		{
			alpha += (1.0 - alpha) * 0.2;
		}
		else
		{
			alpha *= 0.5;
			if (alpha <= 0.1)
			{
				kill();
				return;
			}
		}

		var offset_x = 0.0;
		var rod_off_x = 65.0;

		if (player.flipX)
		{
			offset_x = player.width + offset.x - rod_off_x;
		}
		else
		{
			offset_x = -width + offset.x + rod_off_x;
		}

		// origin.x = flipX ? 128 - 16 : 16;

		flipX = player.flipX;

		var swayX = Math.sin(time * 1) * 12 * 0.7;
		var swayY = Math.sin(time * 2.5 + 3) * 8 * 0.7;

		var tx = player.x + swayX + offset_x;
		var ty = player.y + swayY + player.height * 0.5;

		x += (tx - x) * 0.3;
		y += (ty - y) * 0.3;

		rot_vel += (rotation - eased_rotation) * 0.47;
		eased_rotation += rot_vel;
		rot_vel *= 0.8;

		var new_angle = _ang + eased_rotation;

		angle = flipX ? -new_angle : new_angle;
	}
}
