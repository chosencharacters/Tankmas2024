package ui;

import bunnymark.PlayState;
import squid.sprite.TempSprite;

enum PressType
{
	Tap;
	Hold;
}

class TouchOverlay extends FlxTypedGroupExt<FlxSpriteExt>
{
	final TAP_TIME_THRESHOLD = 0.3; // Time mouse button being held until it doesn't count as a tap anymore, but a hold
	final TAP_DRAG_DISTANCE_THRESHOLD = 30.0; // Press and drag threshold to count a tap as a hold/drag

	var press_type:PressType = Tap;
	var press_position:FlxPoint;
	var press_duration = 0.0;

	public function new(?X:Float, ?Y:Float)
	{
		super();
		sstate(IDLE);
	}

	override function update(elapsed:Float)
	{
		fsm(elapsed);
		super.update(elapsed);
	}

	function fsm(elapsed:Float)
		switch (cast(state, State))
		{
			default:
			case IDLE:
				if (!Ctrl.mode.can_move)
					return;
				if (PlayState.self.ui_overlay.mouse_is_over_ui())
					return;
				if (FlxG.mouse.justPressed)
					start_touch_move();
			case PRESSING:
				process_touch_move(elapsed);
		}

	function start_touch_move()
	{
		if (distance_to_mouse() < 100)
			return;

		sstate(PRESSING);

		press_type = Tap;
		press_position = FlxG.mouse.getScreenPosition();
		press_duration = 0.0;
	}

	function end_touch_move()
	{
		sstate(IDLE);

		if (press_type == Tap)
		{
			var move_fx = new TempSprite("move-circle", this);
			move_fx.center_on(FlxG.mouse.getWorldPosition());
			add(move_fx);
		}
		else
		{
			PlayState.self.player.stop_auto_move();
		}
	}

	function distance_to_mouse()
	{
		var mouse_pos = FlxG.mouse.getWorldPosition();
		return PlayState.self.player.distance(mouse_pos);
	}

	function process_touch_move(elapsed:Float)
	{
		if (press_type == Tap)
		{
			press_duration += elapsed;
			var drag_dist = press_position.dist(FlxG.mouse.getScreenPosition());
			if (press_duration > TAP_TIME_THRESHOLD || drag_dist > TAP_DRAG_DISTANCE_THRESHOLD)
			{
				press_type = Hold;
			}
		}

		move_to_position();

		if (!FlxG.mouse.pressed)
			end_touch_move();
	}

	function move_to_position()
	{
		PlayState.self.player.start_auto_move(FlxG.mouse.getWorldPosition());
	}

	override function kill()
	{
		super.kill();
	}
}

private enum abstract State(String) from String to String
{
	var IDLE;
	var PRESSING;
}
