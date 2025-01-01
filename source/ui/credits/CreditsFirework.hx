package ui.credits;

class CreditsFirework extends FlxSpriteExt
{
	public var fireworks_remaining:Array<String> = [];

	var on_complete:CreditsFirework->Void;

	public function new(point:FlxPoint, on_complete:CreditsFirework->Void)
	{
		super();

		this.on_complete = on_complete;

		if (fireworks_remaining.length == 0)
			fireworks_remaining = ["mella", "gooble", "ghost", "boyfriend", "paco"];

		ran.shuffle(fireworks_remaining);

		loadAllFromAnimationSet("fireworks");

		anim(fireworks_remaining.shift());

		this.center_on(point);

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
					on_complete(this);
					kill();
				}
		}
}

private enum abstract State(String) from String to String
{
	final FIRING;
}
