package entities.misc;

import data.SaveManager;
import video.VideoSubstate;

class GamingDevice extends Interactable
{
	var url:String = "https://uploads.ungrounded.net/tmp/6257000/6257910/file/alternate/alternate_1.720p.mp4?f1733891286";
	// TEst video
	// var url = 'http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4';
	var video_overlay:VideoSubstate;

	public function new(?X:Float, ?Y:Float)
	{
		super(X, Y);

		PlayState.self.world_objects.add(this);

		loadAllFromAnimationSet("gaming-device");
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
			default:
			case IDLE:
				anim("idle");
			case NEARBY:
				animProtect("nearby");
		}

	override public function on_interact()
	{
		super.on_interact();
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
		if (video_overlay != null)
			return;
		video_overlay = new VideoSubstate(url);
		PlayState.self.openSubState(video_overlay);
		video_overlay.on_close = () ->
		{
			Flags.set_bool("MELLA_PRESENT_UNLOCKED", true);
			SaveManager.save();
			video_overlay = null;
		}
	}

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
}
