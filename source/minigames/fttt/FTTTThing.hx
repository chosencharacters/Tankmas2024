package minigames.fttt;

import minigames.fttt.FTTTSubState;
import ui.button.HoverButton;

class FTTTThing extends HoverButton
{
	var is_thing_thing:Bool = false;

	public function new(?X:Float, ?Y:Float, good_outcome:Void->Void, bad_outcome:Void->Void, is_thing_thing:Bool = false)
	{
		super(X, Y);
		this.is_thing_thing = is_thing_thing;
		on_pressed = (b) -> is_thing_thing ? good_outcome : bad_outcome;
		sstate(MOVE);

		loadAllFromAnimationSet(is_thing_thing ? 'fttt-thing-thing' : 'fttt-grunt');
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
	final MOVE;
}
