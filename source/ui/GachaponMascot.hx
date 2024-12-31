package ui;

class GachaponMascot extends FlxSpriteExt
{
	var hold_time:Int = 10 * 6;

	public static var TOTAL_PULLS:Int = 0;
	public static var PULLS_IN_ONE_RUN:Int = 0;

	public function new()
	{
		super();

		loadAllFromAnimationSet("gachapon-mascot");
		scale.set(1, 1);
		updateHitbox();

		scrollFactor.set(0, 0);

		y = FlxG.height - height;
		x = 0;

		SoundPlayer.sound("GACHAPON", 1);

		sstate(IN);
	}

	override function update(elapsed:Float)
	{
		fsm();
		super.update(elapsed);
	}

	function fsm()
		switch (cast(state, State))
		{
			case IN:
				animProtect("in");
				if (animation.finished && ttick() > hold_time)
					sstate(OUT);
			case OUT:
				animProtect("out");
				if (animation.finished)
					kill();
			default:
		}
}

private enum abstract State(String) from String to String
{
	var IN;
	var OUT;
}
