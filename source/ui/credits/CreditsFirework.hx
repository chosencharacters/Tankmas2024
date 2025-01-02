package ui.credits;

class CreditsFirework extends FlxSpriteExt
{
	static var fireworks_remaining:Array<String> = [];

	var on_complete:CreditsFirework->Void;

	public function new(point:FlxPoint, on_complete:CreditsFirework->Void)
	{
		super();

		this.on_complete = on_complete;

		if (fireworks_remaining.length == 0)
			fireworks_remaining = ["mella", "gooble", "ghost", "boyfriend", "paco"];

		ran.shuffle(fireworks_remaining);

		scale.set(6, 6);
		updateHitbox();

		loadAllFromAnimationSet("fireworks");

		anim(fireworks_remaining.shift());

		this.center_on(point);

		trace(getPosition());

		SoundPlayer.alt_sound("firework", true, ["firework-1", "firework-2", "firework-3"], 0.25);
		sstate(FIRING);
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
		switch (cast(state, State))
		{
			default:
			case FIRING:
				if (animation.finished)
				{
					trace("Yo");
					on_complete(this);
					kill();
				}
		}
}

private enum abstract State(String) from String to String
{
	final FIRING;
}
