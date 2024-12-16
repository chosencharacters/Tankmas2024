package entities.misc;

import video.VideoSubstate;

class GamingDevice extends Interactable
{
	var url:String = "https://uploads.ungrounded.net/tmp/6257000/6257910/file/alternate/alternate_1.720p.mp4?f1733891286";

	public function new(?X:Float, ?Y:Float)
	{
		super(X, Y);

		PlayState.self.props_foreground.add(this);

		loadAllFromAnimationSet("gaming-device");
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
			case IDLE:
				anim("idle");
			case NEARBY:
				animProtect("nearby");
				if (Ctrl.mode.can_move && (Ctrl.jinteract[1] || FlxG.mouse.overlaps(this) && FlxG.mouse.justReleased))
					start_video();
		}

	override public function mark_target(mark:Bool)
	{
		if (mark && interactable)
			sstate(NEARBY);
		if (!mark && interactable)
			sstate(IDLE);
	}

	function start_video()
	{
		PlayState.self.openSubState(new VideoSubstate(url));
	}

	override function kill()
	{
		PlayState.self.props_foreground.remove(this, true);
		super.kill();
	}
}

private enum abstract State(String) from String to String
{
	final IDLE;
	final NEARBY;
}
