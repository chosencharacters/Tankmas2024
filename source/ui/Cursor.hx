package ui;

class Cursor extends FlxSpriteExt
{
	public function new(?X:Float, ?Y:Float)
	{
		super(X, Y);

		if (FlxG.mouse.enabled)
			FlxG.mouse.visible = false;

		loadAllFromAnimationSet("cursor");

		setSize(1, 1);
		offset.set(50, 50);

		sstate(NEUTRAL);

		update(0);
	}

	override function update(elapsed:Float)
	{
		fsm();

		super.update(elapsed);
	}

	override function updateMotion(elapsed:Float)
	{
		FlxG.state.remove(this, true);
		FlxG.state.add(this);

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
