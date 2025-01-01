package activities.fishing;

import flixel.graphics.FlxAsepriteUtil;
import activities.fishing.Fish.FishZone;
import flixel.tweens.FlxEase;

class FishingUI extends FlxTypedGroup<FlxObject>
{
	var area:FishingAreaInstance;

	var zone_select:FlxSprite;

	var zone_deep:FlxSprite;
	var zone_mid:FlxSprite;
	var zone_shallow:FlxSprite;

	var cursor:FlxSprite;
	var hit_marker:FlxSprite;

	var frame:FlxSprite;

	final ZONE_SELECT_INTERVAL = 1.0;
	var current_zone = 0;
	var elapsed_time_total = 0.0;
	// Goes from 0 to 1 for each zone (0.5 is perfect middle)
	var current_zone_ratio = 0.0;

	var reel_time = 0.0;
	var reel_loop_interval = 2.0;
	var reel_cursor_pos = 0.0;
	var reel_target:FlxSprite;
	var new_loop_cooldown = 0.0;

	var reel_perfection = 1.0;

	var reel_sprite:FlxSprite;

	public function new(area_instance:FishingAreaInstance)
	{
		super();
		this.area = area_instance;
		PlayState.self.add(this);

		zone_select = new FlxSprite(0, 0, AssetPaths.FishingZoneSelect__png);
		zone_select.scrollFactor.set(0, 0);
		add(zone_select);

		zone_mid = new FlxSprite(0, 0, AssetPaths.FishingMarker__png);
		zone_shallow = new FlxSprite(0, 0, AssetPaths.FishingMarker__png);
		zone_deep = new FlxSprite(0, 0, AssetPaths.FishingMarker__png);
		add(zone_deep);
		add(zone_mid);
		add(zone_shallow);
		zone_deep.scrollFactor.set(0, 0);
		zone_mid.scrollFactor.set(0, 0);
		zone_shallow.scrollFactor.set(0, 0);

		reel_target = new FlxSprite(0, 0, AssetPaths.FishingHitMarker__png);
		reel_target.alpha = 0.0;
		reel_target.scrollFactor.set(0, 0);
		reel_target.centerOrigin();
		add(reel_target);

		cursor = new FlxSprite(0, 0, AssetPaths.FishingCursor__png);
		cursor.scrollFactor.set(0, 0);
		add(cursor);

		frame = new FlxSprite(0, 0, AssetPaths.FishingBarFrame__png);
		frame.scrollFactor.set(0, 0);
		add(frame);

		frame.alpha = cursor.alpha = zone_select.alpha = 0.0;
		FlxTween.tween(frame, {alpha: 1.0}, 0.3, {ease: FlxEase.smootherStepInOut});

		reel_sprite = new FlxSprite();
		FlxAsepriteUtil.loadAseAtlas(reel_sprite, AssetPaths.FishingRodReel__png, AssetPaths.FishingRodReel__json);

		add(reel_sprite);
		reel_sprite.alpha = 0;
		reel_sprite.animation.frameIndex = 0;
		reel_sprite.centerOrigin();
		reel_sprite.centerOffsets();
		reel_sprite.scrollFactor.zero();
	}

	public function reset()
	{
		elapsed_time_total = 0;
		current_zone = 0;
		reel_perfection = 1.0;
		reel_loop_interval = 2.0;
	}

	public function can_do_reel()
	{
		return new_loop_cooldown <= 0;
	}

	public function do_reel()
	{
		var current_pos = reel_time / reel_loop_interval;
		var dist = Math.abs(reel_cursor_pos - current_pos);

		new_loop_cooldown = 0.5;

		reel_sprite.angle = -360.0 + FlxG.random.float(-30, 30);
		reel_sprite.scale.x = reel_sprite.scale.y = 1.1 + Math.random() * 0.2;

		FlxTween.tween(reel_sprite, {angle: 0, "scale.x": 1, "scale.y": 1}, 0.4, {ease: FlxEase.elasticOut});

		var target_pos = reel_target.x + reel_target.width * 0.5 - cursor.width * 0.5;
		if (dist < 0.03)
			FlxTween.tween(cursor, {x: target_pos}, 0.3, {ease: FlxEase.elasticOut});

		if (dist < 0.03)
			return 1.0;
		if (dist < 0.06)
			return 0.98;
		if (dist < 0.08)
			return 0.95;
		if (dist <= 0.1)
			return 0.9;

		return 0.0;
	}

	public function start_reeling_in()
	{
		new_reel_loop();
	}

	function new_reel_loop()
	{
		reel_time = 0.0;
		reel_cursor_pos = Math.random() * 0.6 + 0.2;
		if (reel_perfection > 0.8)
		{
			reel_loop_interval *= 0.95;
		}
	}

	public function get_throw_info()
	{
		var dist = 1.0 - (Math.abs(0.5 - current_zone_ratio) * 1.0);
		return {
			zone: current_zone,
			perfection: dist,
		}
	}

	public override function update(elapsed:Float)
	{
		super.update(elapsed);

		var w = FlxG.width;
		var h = FlxG.height;

		frame.x = (w - frame.width) * 0.5;
		frame.y = (h - frame.height - 50) + (1 - frame.alpha) * 8.0;
		zone_select.x = frame.x;
		zone_select.y = frame.y;

		if (area.current_state == Throwing)
		{
			elapsed_time_total += elapsed;
			if (elapsed_time_total >= ZONE_SELECT_INTERVAL)
			{
				current_zone++;
				if (current_zone > Std.int(FishZone.Deep))
				{
					current_zone = 0;
				}
				elapsed_time_total -= ZONE_SELECT_INTERVAL;
			}
		}

		var total = FlxEase.smootherStepInOut(elapsed_time_total / ZONE_SELECT_INTERVAL);
		current_zone_ratio = total;
		cursor.y = frame.y;
		zone_shallow.y = zone_mid.y = zone_deep.y = frame.y;

		var frame_width = 1310.0;

		var step_size = (frame_width) / 3.0;
		zone_shallow.x = zone_select.x + 6 + step_size * 0.5;
		zone_mid.x = zone_select.x + 6 + step_size * 1.5;
		zone_deep.x = zone_select.x + 6 + step_size * 2.5;

		if (area.current_state == Throwing)
		{
			cursor.alpha = frame.alpha;
			cursor.x = zone_select.x + 6 + step_size * (current_zone + total);
			zone_select.alpha = frame.alpha;
		}
		else if (area.float.float_state == Waiting)
		{
			zone_select.alpha *= 0.92;
			zone_deep.alpha = zone_mid.alpha = zone_shallow.alpha = zone_select.alpha * 0.1;
			cursor.alpha = zone_select.alpha;
		}
		else if (area.current_state == ReelingIn)
		{
			reel_sprite.alpha += (1 - reel_sprite.alpha) * 0.1;
			reel_target.alpha = reel_sprite.alpha;

			reel_target.y = frame.y;
			reel_target.x = frame.x + 6 + frame_width * reel_cursor_pos;

			if (new_loop_cooldown > 0)
			{
				new_loop_cooldown -= elapsed;
				// reel_sprite.animation.frameIndex = 1;
				// cursor.x += (reel_target.x - cursor.x) * 0.1;
				if (new_loop_cooldown <= 0)
				{
					new_reel_loop();
				}
				return;
			}
			reel_sprite.animation.frameIndex = 0;

			reel_time += elapsed;

			cursor.alpha = reel_target.alpha;

			cursor.y = reel_target.y;
			if (reel_time >= reel_loop_interval)
			{
				reel_perfection *= 0.95;
				reel_time -= reel_loop_interval;
			}

			cursor.x = frame.x + 6 + frame_width * (reel_time / reel_loop_interval);
		}

		reel_sprite.x = frame.x - reel_sprite.width;
		reel_sprite.y = frame.y - reel_sprite.height * 0.5 + frame.height * 0.5;

		zone_deep.alpha = zone_mid.alpha = zone_shallow.alpha = zone_select.alpha * 0.4;
	}
}
