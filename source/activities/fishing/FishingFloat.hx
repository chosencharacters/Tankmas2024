package activities.fishing;

import flixel.tweens.FlxEase;
import flixel.graphics.FlxAsepriteUtil;
import flixel.math.FlxMath;

enum FishingFloatState
{
	Idle;
	Thrown;
	Waiting;
	Baited;
	Reeling;
}

class FishingFloat extends FlxSprite
{
	final DEEP_X = 350.0;
	final MID_X = 800.0;
	final SHALLOW_X = 1300.0;

	var target_x = 0.0;
	var target_y = 0.0;

	var dist_x = 0.0;

	var area:FishingAreaInstance;

	public var float_state:FishingFloatState = Idle;

	public var bait_duration = 0.0;

	public var time_until_shake = 0.5;
	public var time_until_bait = 1.0;

	public var on_caught:Void->Void = null;

	public function new(area:FishingAreaInstance)
	{
		super();
		FlxAsepriteUtil.loadAseAtlas(this, AssetPaths.FishingRodFloat__png, AssetPaths.FishingRodFloat__json);
		animation.frameIndex = 0;
		this.area = area;

		// Fade out other player's floats
		if (!area.local)
			alpha = 0.5;
	}

	public function reset_float()
	{
		alpha = 0.0;
		float_state = Idle;
		animation.frameIndex = 0;
	}

	public function throw_out()
	{
		if (float_state == Thrown)
			return;

		alpha = 1.0;
		if (!area.local)
			alpha = 0.5;

		switch (area.active_zone)
		{
			case Shallow:
				target_x = SHALLOW_X;
			case Medium:
				target_x = MID_X;
			case Deep:
				target_x = DEEP_X;
		}

		target_y = area.player.getMidpoint().y;

		target_x += FlxG.random.float(-100.0, 100.0);
		target_y += FlxG.random.float(-20.0, 20.0);

		dist_x = x - target_x;
		float_state = Thrown;
		bait_duration = 0.;
	}

	public function pull_closer(perfection = 1.0)
	{
		var power = 1.0;
		if (perfection > 0.8)
			power *= 1.1;
		target_x += Math.random() * 50 * power + 90;

		if (target_x >= 1720 && on_caught != null)
		{
			on_caught();
		}
	}

	public function start_reel_in()
	{
		if (float_state != Baited)
			return 0.0;

		float_state = Reeling;

		if (bait_duration < 0.1)
			return 1.0;
		if (bait_duration < 0.15)
			return 0.95;
		if (bait_duration < 0.2)
			return 0.9;
		if (bait_duration < 0.5)
			return 0.7;
		if (bait_duration < 0.6)
			return 0.5;

		return 0.0;
	}

	function on_landed()
	{
		if (float_state == Waiting)
			return;
		float_state = Waiting;

		time_until_bait = 6.0 + Math.random() * 5.0;
		time_until_shake = Math.random() * 2.0 + 0.5;
	}

	function on_bait()
	{
		if (float_state == Baited)
			return;

		bait_duration = 0.0;
		float_state = Baited;
		animation.frameIndex = 1;
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		switch (float_state)
		{
			case Thrown:
				{
					var vx = (target_x - x) * 0.06;
					if (Math.abs(vx) > 50)
						vx = -50;
					x += vx;
					var dx = (x - target_x) / dist_x;
					y = target_y - Math.sin(dx * Math.PI) * 200;
					if (dx < 0.1)
					{
						on_landed();
					}
				}

			case Waiting:
				{
					time_until_bait -= elapsed;
					time_until_shake -= elapsed;
					if (time_until_shake <= 0)
					{
						angle = FlxG.random.float(-30, 30);
						FlxTween.tween(this, {angle: 0}, 0.5, {ease: FlxEase.elasticOut});
						time_until_shake = Math.random() * 1.0 + 0.6;
					}

					if (time_until_bait <= 0)
					{
						on_bait();
					}
				}
			case Baited:
				angle = FlxG.random.float(-10, 10);
				bait_duration += elapsed;
			case Reeling:
				x += (target_x - x) * 0.1;
			default:
		}
	}
}
