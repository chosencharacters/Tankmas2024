package states.substates;

import data.JsonData;
import flixel.tweens.FlxEase;
import squid.ext.FlxSubstateExt;
import ui.button.HoverButton;

class ComicSubstate extends FlxSubstateExt
{
	var comic:FlxSpriteExt;

	var substate:FlxSubstateExt;

	var page:Int = 1;
	var pages:Int;

	var left_arrow:HoverButton;
	var right_arrow:HoverButton;
	var back_arrow:HoverButton;

	var comic_name:String;
	var comic_base:String;

	var black:FlxSpriteExt;

	/**
	 * This is private, should be only made through things that extend it
	 * @param saved_sheet
	 * @param saved_page
	 */
	public function new(comic_name:String)
	{
		super();

		var black:FlxSpriteExt = new FlxSpriteExt(0, 0).makeGraphicExt(FlxG.width, FlxG.height, FlxColor.BLACK);
		black.setPosition(0, 0);
		black.alpha = 0.5;
		add(black);

		this.comic_name = comic_name;
		comic_base = 'comic-${comic_name}';

		Ctrl.mode = ControlModes.TALKING;

		comic = new FlxSpriteExt();

		pages = Paths.get_every_file_of_type(".png", 'assets', 'comic-${comic_name}').length;

		left_arrow = new HoverButton(Paths.image_path("left-arrow"), (b) -> prev_page());
		right_arrow = new HoverButton(Paths.image_path("right-arrow"), (b) -> next_page());
		back_arrow = new HoverButton(Paths.image_path("back-arrow"), (b) -> close_ui());

		add(comic);

		add(right_arrow);
		add(left_arrow);
		add(back_arrow);

		sstate(OPEN);

		switch_page();

		members.for_all_members((member) -> cast(member, FlxSprite).scrollFactor.set(0, 0));

		FlxG.state.openSubState(this);

		members.for_all_members((member) -> cast(member, FlxSprite).offset.y = -FlxG.height);

		members.for_all_members(function(member)
		{
			FlxTween.tween(cast(member, FlxSprite).offset, {y: 0}, 0.25, {ease: FlxEase.cubeInOut});
			sstate(IDLE);
		});

		black.offset.y = 0;
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

	public function next_page()
	{
		page++;
		if (page > pages)
			page = 1;
		switch_page();
	}

	public function prev_page()
	{
		page--;
		if (page < 1)
			page = pages;
		switch_page();
	}

	public function close_ui()
	{
		if (state != IDLE)
			return;
		sstate(CLOSE);
		// members.for_all_members(function(member)
		// {
		// 	FlxTween.tween(cast(member, FlxSpriteExt).offset, {y: -FlxG.height}, 0.25, {ease: FlxEase.cubeInOut});
		// 	if (member == members[0])
		// 		cast(member, FlxSpriteExt).tween();
		// });

		// black.offset.y = 0;

		Ctrl.mode = ControlModes.OVERWORLD;
		close();
	}

	public function switch_page()
	{
		comic.loadGraphic(Paths.image_path('$comic_base-$page'));
		comic.setGraphicSize(comic.width > comic.height ? 1920 : 0, comic.height >= comic.width ? 1080 : 0);

		comic.screenCenter();
		left_arrow.screenCenter();
		right_arrow.screenCenter();
		back_arrow.setPosition(FlxG.width - back_arrow.width, FlxG.height - back_arrow.height);

		right_arrow.x = comic.x + comic.width;
		left_arrow.x = comic.x - left_arrow.width;

		left_arrow.visible = left_arrow.enabled = page > 1;
		right_arrow.visible = right_arrow.enabled = page < pages;
	}
}

private enum abstract State(String) from String to String
{
	var IDLE;
	var OPEN;
	var CLOSE;
}
