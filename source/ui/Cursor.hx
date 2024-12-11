package ui;

import flixel.FlxState;

class Cursor extends FlxSpriteExt
{
	var parent_state:FlxState;

	public function new(parent_state:FlxState)
	{
		super();

		this.parent_state = parent_state;

		if (FlxG.mouse.enabled)
			FlxG.mouse.visible = false;

		loadAllFromAnimationSet("cursor");

		setSize(1, 1);
		offset.set(50, 50);

		sstate(NEUTRAL);

		update(0);

		visible = !FlxG.onMobile;
	}

	override function update(elapsed:Float)
	{
		fsm();

		super.update(elapsed);
	}

	override function updateMotion(elapsed:Float)
	{
		parent_state.remove(this, true);
		parent_state.add(this);

		setPosition(FlxG.mouse.x, FlxG.mouse.y);
		super.updateMotion(elapsed);
	}

	function fsm()
		switch (cast(state, State))
		{
			default:
			case NEUTRAL:
				anim("neutral");
				if (FlxG.mouse.pressed)
					sstate(TO_HOLD);
			case HOLD:
				anim("hold");
				if (FlxG.mouse.released)
					sstate(RELEASE);
			case RELEASE:
				anim_protect_then_function("release", () -> sstate(NEUTRAL, fsm));
			case TO_HOLD:
				anim_protect_then_function("to-hold", () -> sstate(HOLD, fsm));
		}

	override function kill()
	{
		super.kill();
	}
}

private enum abstract State(String) from String to String
{
	final NEUTRAL;
	final HOLD;
	final RELEASE;
	final TO_HOLD;
}
