package entities.misc;

import data.SaveManager;
import tripletriangle.PlayState;
import ui.GachaSpawnUI;
import video.VideoSubstate;

class Gachapon extends Interactable
{
	var gacha_cd_interval:Int = (60 * 1).floor();

	var gacha_cd_count:Int = 0;
	var gacha_cd_max:Int = 5;

	public static var TOTAL_PULLS:Int = 0;
	public static var PULLS_IN_ONE_GAME:Int = 0;

	public function new(?X:Float, ?Y:Float)
	{
		super(X, Y);

		PlayState.self.world_objects.add(this);

		loadAllFromAnimationSet("gachapon");
		sstate(IDLE);

		detect_range = 300;

		interactable = true;
	}

	override function update(elapsed:Float)
	{
		fsm();
		super.update(elapsed);
	}

	function fsm()
		switch (cast(state, State))
		{
			case IDLE:
			case NEARBY:
			case SUMMONING:
				interactable = false;
				if (new_frame_check(9))
					new GachaSpawnUI();
				animProtect("activate");
				if (animation.finished)
					sstate(POST_SUMMON);
			case POST_SUMMON:
				sstate(COOLDOWN);
				gacha_cd_count = 1;
				animProtect('cd-1');
			case COOLDOWN:
				if (ttick() >= gacha_cd_interval)
				{
					gacha_cd_count++;
					if (isOnScreen())
						sound("gachapon-cooldown", 0.5);
					if (gacha_cd_count > gacha_cd_max)
					{
						tick = 0;
						sstate(RESET);
						fsm();
					}
					else
					{
						tick = 0;
						animProtect('cd-${gacha_cd_count}');
						sstate(COOLDOWN);
					}
				}
			case RESET:
				animProtect("reset");
				if (animation.finished)
				{
					interactable = true;
					sstate(IDLE);
				}
		}

	override public function on_interact()
	{
		super.on_interact();
		TOTAL_PULLS++;
		trace(TOTAL_PULLS);
		#if newgrounds
		if (TOTAL_PULLS == 43)
			Main.ng_api.medal_popup(Main.ng_api.medals.get("pull-all-pico-cross"));
		#end
		SoundPlayer.sound("gachapon-activate");
		interactable = false;
		sstate(SUMMONING);
	}

	override public function mark_target(mark:Bool)
	{
		if (mark && interactable)
			sstate(NEARBY);
		if (!mark && interactable)
			sstate(IDLE);
	}

	function start_video() {}

	override function kill()
	{
		PlayState.self.world_objects.remove(this, true);
		super.kill();
	}
}

private enum abstract State(String) from String to String
{
	final IDLE;
	final NEARBY;
	final SUMMONING;
	final POST_SUMMON;
	final COOLDOWN;
	final RESET;
}
