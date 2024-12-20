package fx;

import entities.base.NGSprite;
import states.PlayState;

class EmoteFX extends FlxSpriteExt
{
	var idle_time:Int = 60;
	var parent:FlxSpriteExt;
	var cover:FlxSpriteExt;

	/*since offset is actually used by animations*/
	var base_emote_offset_y:Int = -16;

	var on_complete:Void->Void;

	public function new(parent:NGSprite, name:String, on_complete:Void->Void)
	{
		super(Paths.get(name + ".png"));
		cover = new FlxSpriteExt().loadAllFromAnimationSet("emote-fx");

		this.on_complete = on_complete;

		this.parent = parent;

		PlayState.self.emotes.add(this);
		PlayState.self.emote_fx.add(cover);

		sstate(IN);

		trace_new_state = true;
	}

	override function updateMotion(elapsed:Float)
	{
		this.center_on_top(parent);
		this.y = y + base_emote_offset_y;

		cover.center_on(this);

		super.updateMotion(elapsed);
	}

	override function update(elapsed:Float)
	{
		fsm();
		visible = cover.animation.frameIndex >= 4 && cover.animation.frameIndex <= 19;
		super.update(elapsed);
	}

	function fsm()
		switch (cast(state, State))
		{
			case IN:
				cover.animProtect("in");
				if (cover.animation.finished)
					sstate(IDLE, fsm);
			case IDLE:
				cover.animProtect("idle");
				if (ttick() > idle_time)
					sstate(OUT);
			case OUT:
				cover.animProtect("out");
				if (cover.animation.finished)
					kill();
		}

	override function kill()
	{
		super.kill();
		cover.kill();
		on_complete != null ? on_complete() : null;
	}
}

private enum abstract State(String) from String to String
{
	var IN;
	var IDLE;
	var OUT;
}
