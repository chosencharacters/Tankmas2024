package entities.base;

/**
 * Mostly pointless Hitbox class that could be useful in the future
 */
class Hitbox extends FlxSpriteExt
{
	var owner:NGSprite;

	public function new(?X:Float, ?Y:Float, width:Float, height:Float)
	{
		super(X, Y);

		makeGraphic(width.floor(), height.floor(), FlxColor.WHITE);

		PlayState.self.hitboxes.add(this);

		visible = Main.SHOW_HITBOXES;
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
		}

	override function kill()
	{
		super.kill();
	}
}

private enum abstract State(String) from String to String
{
	var IDLE;
}
