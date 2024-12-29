package minigames.fttt;

import minigames.fttt.FTTTSubState;
import ui.button.HoverButton;

class FTTTThing extends HoverButton
{
	var is_thing_thing:Bool = false;

	public var vel_x:Int = 200;
	public var vel_y:Int = 200;

	public function new(?X:Float, ?Y:Float, max_vel:Int, good_outcome:Void->Void, bad_outcome:Void->Void, is_thing_thing:Bool = false)
	{
		super(X, Y);

		this.is_thing_thing = is_thing_thing;

		on_pressed = (b) -> is_thing_thing ? good_outcome() : bad_outcome();
		sstate(MOVE);

		loadAllFromAnimationSet(is_thing_thing ? 'fttt-thing-thing' : 'fttt-grunt');

		animation.frameIndex = (Math.random() * animation.numFrames).floor();

		vel_x = ran.int(50, max_vel);
		vel_y = ran.int(50, max_vel);

		velocity.set(vel_x, vel_y);

		velocity.scale(ran.bool() ? -1 : 1, ran.bool() ? -1 : 1);
	}

	override function update(elapsed:Float)
	{
		if (x <= FTTTSubState.bounds.x)
		{
			velocity.x = vel_x;
			x = FTTTSubState.bounds.x;
		}
		if (x + width >= FTTTSubState.bounds.width + FTTTSubState.bounds.x)
		{
			velocity.x = -vel_x;
			x = FTTTSubState.bounds.width + FTTTSubState.bounds.x - width;
		}
		if (y <= FTTTSubState.bounds.y)
		{
			velocity.y = vel_y;
			y = FTTTSubState.bounds.y;
		}
		if (y + height >= FTTTSubState.bounds.height + FTTTSubState.bounds.y)
		{
			velocity.y = -vel_y;
			y = FTTTSubState.bounds.height + FTTTSubState.bounds.y - height;
		}

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
		}

	override function kill()
	{
		super.kill();
	}
}

private enum abstract State(String) from String to String
{
	final MOVE;
}
