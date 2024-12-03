package activities.bonfire;

import flixel.graphics.FlxAsepriteUtil;
import flixel.util.FlxSpriteUtil;

class Marshmallow extends FlxSprite
{
	public var current_level = 0;

	var discarded:Bool = false;
	var vx:Float = 0.0;
	var vy:Float = 0.0;
	var vr:Float = 0.0;

	var ground_y:Float = 0.0;

	var burned:Bool = false;

	var discard_time = 0.0;

	var current_heat = 0.0;

	var heat_levels = [30.0, 60.0, 80.0, 90.0, 98.0, 100.0];

	public static final GOLDEN_MARSHMALLOW_LEVEL:Int = 5;

	var level_up_sounds = [
		AssetPaths.grill_1__wav,
		AssetPaths.grill_2__wav,
		AssetPaths.grill_3__wav,
		AssetPaths.grill_4__wav,
		AssetPaths.grill_5__wav,
		AssetPaths.burned_marshmallow__wav,
	];

	var own = false;

	public function new(x, y, own = true)
	{
		super(x, y);
		this.own = own;
		loadGraphic(AssetPaths.marshmallow__png, true, 64, 64);
		alpha = 0.0;
		FlxTween.tween(this, {alpha: 1.0}, 0.15);
	}

	public function discard()
	{
		if (discarded)
			return;
		discarded = true;
		vx = FlxG.random.float(-7.0, 7.0);
		vy = FlxG.random.float(-5.0, -20.0);
		vr = FlxG.random.float(-20.0, 20.0);

		ground_y = y + FlxG.random.float(30.0, 50.0);
	}

	public function heat(distance:Float, elapsed:Float)
	{
		var max_distance = 160.0;
		if (distance > max_distance)
			return;

		if (burned)
			return;

		// Total amount of time until burnt
		var heat_speed = 10.0;

		if (distance < 100)
		{
			heat_speed = 6.0;
		}

		if (distance < 50)
		{
			heat_speed = 3.0;
		}

		if (distance < 20)
		{
			heat_speed = 1.0;
		}

		var heat_per_second = 100.0 / heat_speed;
		if (!own)
			heat_per_second *= 0.9;
		current_heat += heat_per_second * elapsed;

		if (current_heat > heat_levels[current_level])
		{
			level_up();
		}
	}

	function burned_through()
	{
		burned = true;
	}

	public function set_level(level:Int)
	{
		current_level = level;
		animation.frameIndex = current_level;

		if (current_level >= heat_levels.length)
		{
			burned_through();
			return;
		}
	}

	function level_up()
	{
		if (burned)
			return;

		if (own)
			FlxG.sound.play(level_up_sounds[current_level], 0.3);
		set_level(current_level + 1);
	}

	public static function on_cooked_perfect():Void
	{
		// Earn a medal, if applicable.

		trace("YA DID IT MAN! YA DID IT!");
		Main.ng_api.medal_popup(Main.ng_api.medals.get("golden-marshmallow"));

		final GOLDEN_MARSHMALLOWS_SCOREBOARD:Int = 14324;

		Main.ng_api.post_score(1, GOLDEN_MARSHMALLOWS_SCOREBOARD);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (!discarded)
		{
			return;
		}

		discard_time += elapsed;

		x += vx;
		y += vy;

		if (y > ground_y)
		{
			y = ground_y;
			vy *= -0.8;
			vx *= 0.8;
			vr *= 0.7;
		}

		angle += vr;

		vx *= 0.99;
		vy += 1.4;
		vr *= 0.98;

		if (discard_time > 1.8)
		{
			alpha *= 0.8;
		}

		if (alpha <= 0.01)
		{
			destroy();
		}
	}
}
