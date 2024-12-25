package entities.misc;

import data.SaveManager;
import video.VideoSubstate;

class PianoMan extends Interactable
{
	var url:String = "https://uploads.ungrounded.net/tmp/6257000/6257910/file/alternate/alternate_1.720p.mp4?f1733891286";
	// TEst video
	// var url = 'http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4';
	var video_overlay:VideoSubstate;

	var sound_played:Bool = false;

	public function new(?X:Float, ?Y:Float, width:Int, width:Int)
	{
		super(X, Y);

		PlayState.self.world_objects.add(this);

		makeGraphic(width, width, FlxColor.TRANSPARENT);

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
			case NEARBY:
		}

	override public function on_interact()
	{
		super.on_interact();
		FlxG.state.add(new ui.jukebox.SongBookUI());
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
}
