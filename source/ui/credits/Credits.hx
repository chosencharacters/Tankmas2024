package ui.credits;

import data.JsonData;
import flixel.tweens.FlxEase;
import levels.TankmasLevel;
import tripletriangle.PlayState;
import ui.credits.CreditsWord;

class Credits extends FlxTypedGroupExt<FlxSprite>
{
	var words:Array<CreditsWord> = [];
	var fireworks:Array<CreditsFirework> = [];
	var screenshots:CreditsScreenshots;

	var mountains:FlxSpriteExt;

	var aurora:FlxSpriteExt;
	var aurora_fx:FlxSpriteExt;

	var stars:FlxSpriteExt;
	var stars_fx:FlxSpriteExt;

	var perch:FlxSpriteExt;

	var words_x:Int = 64;
	var words_width:Int = 1060 - 64;
	var line_y_padding:Int = 16;

	var lvl_height:Int = 4000;

	var credits_duration_in_seconds:Int = 60 * 2 + 30;

	var origin:FlxPoint;

	var cam_scroll_rate:Int = 12;

	var start_time:Float = 1735767900;

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
		aurora_fx = new FlxSpriteExt(perch.x, perch.y);

		aurora_fx.alpha = 0.25;

		stars = new FlxSpriteExt(perch.x, perch.y);
		stars_fx = new FlxSpriteExt(perch.x, perch.y);

		screenshots = new CreditsScreenshots();

		screenshots.setPosition(perch.right_x - screenshots.width, perch.top_y + FlxG.height / 2 - screenshots.height / 2);

		stars.visible = false;

		mountains = new FlxSpriteExt(perch.x, perch.y);

		aurora.loadAllFromAnimationSet("pinnacle-4-aurora");
		aurora_fx.loadAllFromAnimationSet("pinnacle-4-aurora-fx");

		stars.loadAllFromAnimationSet("pinnacle-3-stars");
		stars_fx.loadAllFromAnimationSet("pinnacle-3-stars-fx");

		aurora_fx.scale.set(2, 2);
		stars_fx.scale.set(2, 2);

		aurora_fx.alpha = 0;

		stars_fx.updateHitbox();
		aurora_fx.updateHitbox();

		mountains.loadAllFromAnimationSet("pinnacle-2-mountains");

		add(aurora);
		add(stars);
		add(mountains);

		sstate(WAIT);
	}

	function fsm()
		switch (cast(state, State))
		{
			default:
			case WAIT:
				trace(Main.time.utc, start_time * 1000);
				if (Main.time.utc >= start_time * 1000)
					sstate(START_DELAY, fsm);
			case START_DELAY:
				aurora_fx.alpha += 1 / 180;
				if (ttick() == 1 && FlxG.sound.music != null)
					FlxG.sound.music.fadeOut(1, 0, function(t)
					{
						FlxG.sound.music.stop();
						FlxG.sound.music.setPosition();
						SoundPlayer.music(JsonData.get_track("visual-snow-redux"));
						FlxG.sound.volume = 1;
					});
				if (aurora_fx.alpha >= 1)
				{
					aurora_fx.alpha = 1;
					tick = 0;
					sstate(START);
				}
			case START:
				make_words();
				screenshots.start();
				sstate(ACTIVE);
			case ACTIVE:
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
		members.push(aurora_fx);
		members.push(stars);
		members.push(stars_fx);
		members.push(mountains);

		for (member in fireworks)
			members.push(member);
		for (member in words)
			members.push(member);

		members.push(screenshots);

		return return_me;
	}

	override function update(elapsed:Float)
	{
		cam_manager();
		fsm();
		super.update(elapsed);
	}

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
		{
			if (FlxG.camera.scroll.y > FlxG.camera.maxScrollY)
				FlxG.camera.scroll.y = FlxG.camera.maxScrollY;
			if (FlxG.camera.scroll.y < FlxG.camera.maxScrollY)
				FlxG.camera.scroll.y = FlxG.camera.maxScrollY;
		}
	}

	override function kill()
	{
		super.kill();
	}
}

private enum abstract State(String) from String to String
{
	final WAIT;
	final START_DELAY;
	final START;
	final ACTIVE;
	final END;
}
