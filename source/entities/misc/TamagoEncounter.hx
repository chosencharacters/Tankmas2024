package entities.misc;

class TamagoEncounter extends Interactable
{
	var max_player_run_speed:Int = 200;
	var alert_dist_x:Int = 800;
	var alert_dist_y:Int = 500;

	var alert_time:Int = 0;
	var max_alert_time:Int = 15;

	var creature_run_speed:Int = 500;

	var org:FlxPoint;

	public function new(?X:Float, ?Y:Float)
	{
		super(X, Y);
		loadAllFromAnimationSet("tamago-encounter");
		detect_range = 100;
		sstate(IDLE);

		scale.set(2, 2);

		org = new FlxPoint(X, Y);

		PlayState.self.world_objects.add(this);
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
	{
		var player_velocity:Float = Math.abs(PlayState.self.player.velocity.x) + Math.abs(PlayState.self.player.velocity.y);
		var player_too_fast:Bool = player_velocity >= max_player_run_speed;
		var in_alert_range:Bool = Math.abs(PlayState.self.player.x - org.x) <= alert_dist_x
			&& Math.abs(PlayState.self.player.y - org.y) <= alert_dist_y;
		switch (cast(state, State))
		{
			default:
			case IDLE:
				interactable = true;
				alert_time = 0;
				flipX = false;
				animProtect("idle");
				if (alpha == 0 && isOnScreen())
					SoundPlayer.sound("teleport");
				if (alpha < 1)
					alpha += 0.1;
				if (player_too_fast && in_alert_range)
					sstate(ALERT);
			case ALERT:
				interactable = false;
				alpha = 1;
				animProtect("alert");
				if (player_too_fast && in_alert_range)
				{
					alert_time++;
					tick = 0;
					if (alert_time > max_alert_time)
						sstate(RUN, fsm);
				}
				if (ttick() > 60)
					sstate(IDLE, fsm);
			case RUN:
				interactable = false;
				alert_time = 0;
				animProtect("run");
				flipX = true;
				velocity.x = creature_run_speed;
				if (ttick() > 120 && !in_alert_range)
				{
					setPosition(org.x, org.y);
					velocity.x = 0;
					sstate(IDLE);
					alpha = 0;
				}
		}
	}

	override function on_interact()
	{
		Utils.shake("light");
		FlxG.camera.flash(FlxColor.CYAN);
		Flags.set_bool("TAMAGO_ENCOUNTERED");
		SoundPlayer.sound("rare-tamago-encountered");
		super.on_interact();
	}

	override function kill()
	{
		super.kill();
	}
}

private enum abstract State(String) from String to String
{
	var IDLE;
	var ALERT;
	var RUN;
}
