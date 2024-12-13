package entities.misc;

class GamingDevice extends Interactable
{
	public function new(?X:Float, ?Y:Float)
	{
		super(X, Y);

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
				visible = interactable = spawn_condition_check();
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

	function start_video() {}
}
