class Wombo extends FlxSpriteExt
{
	public function new(?X:Float, ?Y:Float)
	{
		super(X, Y);
		sstate(IDLE);
	}

	override function kill()
	{
		super.kill();
	}

	override function update(elapsed:Float)
	{
		fsm();
		super.update(elapsed);
	}

	function fsm()
		switch (cast(state, State))
		{
			default:
		}
}

private enum abstract State(String) from String to String
{
	var IDLE;
}
