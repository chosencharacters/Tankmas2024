package ui.credits;

import flixel.tweens.FlxEase;
import levels.TankmasLevel;
import tripletriangle.PlayState;
import ui.credits.CreditsWord;

class Credits extends FlxTypedGroupExt<FlxSprite>
{
	var words:Array<CreditsWord> = [];
	var fireworks:Array<CreditsFirework> = [];

	var mountains:FlxSpriteExt;
	var stars:FlxSpriteExt;
	var aurora:FlxSpriteExt;

	var words_x:Int = 64;
	var words_width:Int = 1060 - 64;
	var line_y_padding:Int = 16;

	var lvl_height:Int = 4000;

	var credits_duration_in_seconds:Int = 60 * 2 + 30;

	var cam_tween:FlxTween;
	var cam_tween_target:Float = -1;

	var origin:FlxPoint;

	var perch:FlxSpriteExt;

	public function new(spawn_x:Float, spawn_y:Float)
	{
		super();

		for (lvl in PlayState.self.levels)
			if (lvl.level_name.contains("pinnacle"))
				for (bg in lvl.bgs)
					if (bg.loaded_image.contains("pinnacle-1-perch-background"))
						perch = bg;

		origin = new FlxPoint(perch.x, perch.y);

		FlxG.state.add(this);

		aurora = new FlxSpriteExt(perch.x, perch.y);
		stars = new FlxSpriteExt(perch.x, perch.y);
		mountains = new FlxSpriteExt(perch.x, perch.y);

		aurora.loadAllFromAnimationSet("pinnacle-4-aurora");
		stars.loadAllFromAnimationSet("pinnacle-3-stars");
		mountains.loadAllFromAnimationSet("pinnacle-2-mountains");

		make_words();

		add(aurora);
		add(stars);
		add(mountains);

		sstate(IDLE);

		cam_tween_target = FlxG.camera.maxScrollY;
	}

	function make_words()
	{
		var data:String = Utils.load_file_string("credits.txt");

		var line_y:Int = 0;

		for (text in data.split("\n"))
			if (text != "\n" && text.length > 2)
			{
				var word:CreditsWord = new CreditsWord(perch.x + words_x, perch.y + line_y, words_width, text);

				words.push(word);
				add(word);

				if (text.charAt(0) == "*")
					line_y = line_y + 16;

				line_y = line_y + word.height.floor() + line_y_padding;
			}
			else
			{
				line_y = line_y + 96;
			}

		for (word in words)
		{
			word.y += FlxG.height;
			FlxTween.tween(word, {y: word.y - line_y}, credits_duration_in_seconds);
		}
	}

	override function add(basic:FlxSprite):FlxSprite
	{
		var return_me:FlxSprite = super.add(basic);

		members = [];

		members.push(aurora);
		members.push(stars);

		for (member in fireworks)
			members.push(member);
		for (member in words)
			members.push(member);

		members.push(mountains);

		// for (word in words)
		// word.scrollFactor.set(0, 0);

		// for (word in fireworks)
		// word.scrollFactor.set(0, 0);

		return return_me;
	}

	override function update(elapsed:Float)
	{
		cam_manager();
		fsm();
		super.update(elapsed);
	}

	var cam_scroll_rate:Int = 12;

	function cam_manager()
	{
		var in_view_area:Bool = PlayState.self.player.y < perch.y + FlxG.height;

		var cam_max_y:Float = in_view_area ? perch.y + 1080 : perch.bottom_y;

		if (FlxG.camera.maxScrollY == cam_max_y)
			return;

		var y_diff:Float = Math.abs(FlxG.camera.maxScrollY - cam_max_y) / 16;

		if (FlxG.camera.maxScrollY > cam_max_y)
			FlxG.camera.maxScrollY -= y_diff;

		if (FlxG.camera.maxScrollY < cam_max_y)
			FlxG.camera.maxScrollY += y_diff;

		if (Math.abs(FlxG.camera.maxScrollY - cam_max_y) < 16)
			FlxG.camera.maxScrollY = cam_max_y;

		if (in_view_area)
			if (FlxG.camera.scroll.y > FlxG.camera.maxScrollY)
				FlxG.camera.scroll.y = FlxG.camera.maxScrollY;

		// trace(in_view_area, FlxG.camera.maxScrollY, cam_max_y, "player", PlayState.self.player.y, "perch", perch.y + FlxG.height);

		// cam_tween_target = cam_max_y;
		// cam_tween = FlxTween.tween(FlxG.camera, {maxScrollY: cam_tween_target}, 0.5);
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
	final IDLE;
}
