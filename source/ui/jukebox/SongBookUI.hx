package ui.jukebox;

import data.JsonData;
import flixel.tweens.FlxEase;
import squid.ext.FlxSubstateExt;
import ui.button.HoverButton;

class SongBookUI extends FlxTypedGroupExt<FlxSprite>
{
	var book:FlxSpriteExt;

	var substate:FlxSubstateExt;

	var selection:Int = 0;

	var songs:Array<String>;

	var left_arrow:HoverButton;
	var right_arrow:HoverButton;
	var back_arrow:HoverButton;

	/**
	 * This is private, should be only made through things that extend it
	 * @param saved_sheet
	 * @param saved_selection
	 */
	public function new()
	{
		super();

		Ctrl.mode = ControlModes.TALKING;

		book = new FlxSpriteExt(0, 0);
		book.loadAllFromAnimationSet("song-book-ui");

		songs = book.animation.getNameList();

		selection = songs.indexOf(Main.current_song);

		switch_song();

		add(book);

		book.scale.set(2, 2);

		book.updateHitbox();

		book.screenCenter();

		left_arrow = new HoverButton(Paths.image_path("left-arrow"), (b) -> next_song());
		right_arrow = new HoverButton(Paths.image_path("right-arrow"), (b) -> prev_song());
		back_arrow = new HoverButton(Paths.image_path("back-arrow"), (b) -> close());

		left_arrow.screenCenter();
		right_arrow.screenCenter();
		back_arrow.screenCenter();

		right_arrow.x = book.x + book.width;
		left_arrow.x = book.x - left_arrow.width;
		back_arrow.y = book.y + book.height - back_arrow.height;

		add(right_arrow);
		add(left_arrow);
		add(back_arrow);

		sstate(OPEN);

		members.for_all_members((member) -> cast(member, FlxSprite).scrollFactor.set(0, 0));

		members.for_all_members((member) -> cast(member, FlxSprite).offset.y = -FlxG.height);

		members.for_all_members(function(member)
		{
			FlxTween.tween(cast(member, FlxSprite).offset, {y: 0}, 0.25, {ease: FlxEase.cubeInOut});
			sstate(IDLE);
		});
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
	}

	override function kill()
	{
		Ctrl.mode = ControlModes.OVERWORLD;
		super.kill();
	}

	public function next_song()
	{
		selection++;
		if (selection >= songs.length)
			selection = 0;
		switch_song();
	}

	public function prev_song()
	{
		selection--;
		if (selection < 0)
			selection = songs.length;
		switch_song();
	}

	public function close()
	{
		if (state != IDLE)
			return;
		sstate(CLOSE);
		members.for_all_members(function(member)
		{
			FlxTween.tween(cast(member, FlxSprite).offset, {y: -FlxG.height}, 0.25, {ease: FlxEase.cubeInOut});
			kill();
		});
	}

	public function switch_song()
	{
		book.anim(songs[selection]);
		SoundPlayer.music(JsonData.get_track(book.animation.name));
	}
}

private enum abstract State(String) from String to String
{
	var IDLE;
	var OPEN;
	var CLOSE;
}
