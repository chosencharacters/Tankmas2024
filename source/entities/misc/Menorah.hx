package entities.misc;

class Menorah extends FlxSpriteExt
{
	var denominational:Bool = false;

	public function new(?X:Float, ?Y:Float)
	{
		super(X, Y);

		sstate(IDLE);

		loadAllFromAnimationSet("menorah");

		PlayState.self.world_objects.add(this);
	}

	override function update(elapsed:Float)
	{
		#if newgrounds
		if (!denominational && PlayState.self.player.distance_to_sprite(this) < 300)
			Main.ng_api.medal_popup(Main.ng_api.medals.get("denominational"));
		#end
		if (ttick() % 20 == 1)
			anim(Std.string(Main.time.hanukkah_day));
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
