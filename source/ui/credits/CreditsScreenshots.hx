package ui.credits;

class CreditsScreenshots extends FlxSpriteExt
{
	public var fireworks_remaining:Array<String> = [];

	var on_complete:CreditsFirework->Void;

	var fade_in_time:Int = 30;
	var fade_out_time:Int = 30;
	var idle_time:Float = 5.75;

	var count:Int = 0;
	var max:Int = 24;

	public function new()
	{
		super();

		loadAllFromAnimationSet("credits-screenshots");
		alpha = 0;

		sstate(INACTIVE);
	}

	override function update(elapsed:Float)
	{
		animation.frameIndex = count;
		fsm();
		super.update(elapsed);
	}

	public function start()
		sstate(FIRST_START_DELAY);

	function fsm()
		switch (cast(state, State))
		{
			default:
			case FIRST_START_DELAY:
				if (ttick() >= 180)
					sstate(IN);
			case IN_START_DELAY:
				if (ttick() >= 15)
					sstate(IN);
			case IN:
				alpha += 1 / fade_in_time;
				if (alpha >= 1)
				{
					alpha = 1;
					sstate(IDLE);
					tick = 0;
				}
			case IDLE:
				if (ttick() >= 60 * idle_time)
					sstate(OUT);
			case OUT:
				alpha = alpha - 1 / fade_out_time;
				if (alpha <= 0)
				{
					alpha = 0;
					count++;
					sstate(count >= max ? INACTIVE : IN);
					tick = 0;
				}
			case OUT_START_DELAY:
				if (ttick() >= 15)
					sstate(OUT);
			case INACTIVE:
		}
}

private enum abstract State(String) from String to String
{
	final FIRST_START_DELAY;
	final IN;
	final IN_START_DELAY;
	final IDLE;
	final OUT;
	final OUT_START_DELAY;
	final INACTIVE;
}
