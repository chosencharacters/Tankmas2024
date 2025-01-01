package activities.fishing;

import flixel.tweens.FlxEase;
import activities.fishing.Fish.FishZone;
import entities.base.BaseUser;
import net.tankmas.NetDefs.NetEventDef;
import net.tankmas.NetDefs.NetEventType;
import net.tankmas.OnlineLoop;

enum FishingState
{
	Throwing;
	Waiting;
	ReelingIn;
	Caught;
}

class FishingAreaInstance extends ActivityAreaInstance
{
	public var local:Bool;

	var rod:FishingRod;

	public var float:FishingFloat;

	var ui:FishingUI = null;

	public var current_state:FishingState = Throwing;

	var ps:PlayState;

	public var active_zone:FishZone = Shallow;

	// Perfections determine the total size of the fish (1 = perfect, 0 = eh)
	var zone_perfection = 0.0;
	var pull_perfection = 0.0;
	var reel_perfection = 1.0;

	public function new(player:BaseUser, area:ActivityArea)
	{
		super(player, area);
		local = player == PlayState.self.player;

		ps = PlayState.self;
		PlayState.self.objects.add(this);

		rod = new FishingRod(player);

		visible = false;

		if (local)
		{
			ui = new FishingUI(this);
		}

		float = new FishingFloat(this);
		float.visible = false;
		ps.objects.add(float);
	}

	override function on_leave()
	{
		super.on_leave();
		kill();
		rod.kill();
		if (local)
			FlxG.camera.follow(player);
		if (ui != null)
			ui.kill();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		switch (current_state)
		{
			case Throwing:
				rod.rotation = 30.0;
			case Waiting:
				rod.rotation = 0.0;
			default:
		}
	}

	override function on_interact()
	{
		switch (current_state)
		{
			case Throwing:
				{
					on_throw_line();
				}
			case Waiting:
				{
					on_start_reeling();
				}
			case ReelingIn:
				on_reel();
			default:
		}
	}

	public function on_throw_line()
	{
		if (current_state != Throwing)
			return;

		var info = ui.get_throw_info();
		var zone = info.zone;
		var perfection = info.perfection;

		Ctrl.mode = ControlModes.FISHING;
		current_state = Waiting;

		active_zone = zone;
		zone_perfection = perfection;

		float.visible = true;
		var float_pos = player.getMidpoint();
		float.setPosition(float_pos.x, float_pos.y);
		float.throw_out();

		FlxG.camera.shake(0.001, 0.2);
		FlxG.camera.follow(float, null, 0.1);
	}

	public function on_start_reeling()
	{
		if (current_state != Waiting)
			return;
		current_state = ReelingIn;
		pull_perfection = float.start_reel_in();
		if (pull_perfection == 0)
		{
			trace('missed reel.');
			reset_game();
			return;
		}

		if (ui != null)
			ui.start_reeling_in();
	}

	function on_reel()
	{
		if (ui != null && ui.can_do_reel())
		{
			rod.rotation += (Math.random() * 20 + 30.0);
			FlxTween.tween(rod, {rotation: 0}, 0.2, {ease: FlxEase.elasticOut});
			var perfection = ui.do_reel();
			if (perfection > 0)
			{
				reel_perfection *= perfection;
				float.pull_closer();
			}
		}
	}

	public function reset_game()
	{
		float.reset_float();
		current_state = Throwing;
		pull_perfection = 0.0;
		zone_perfection = 0.0;
		reel_perfection = 1.0;
		ui.reset();
		Ctrl.mode = ControlModes.OVERWORLD;
		if (local)
			FlxG.camera.follow(player);
	}

	override function on_event(event:NetEventDef)
	{
		super.on_event(event);

		if (local)
			return;

		if (event.type == THROW_LINE) {}
		if (event.type == REEL_IN) {}

		/*
			if (event.type == NetEventType.DROP_MARSHMALLOW)
			{
				var level:Int = cast(event.data.level, Int);
				if (stick.marshmallow != null)
				{
					stick.marshmallow.set_level(level);
				}
				stick.shake_off();
			}
		 */
	}
}
