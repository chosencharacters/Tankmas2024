package ui.credits;

import levels.TankmasLevel;
import ui.credits.CreditsWord;

class Credits extends FlxTypedGroupExt<FlxSprite>
{
	var words:Array<CreditsWord> = [];
	var fireworks:Array<CreditsFirework> = [];

	var mountains:FlxSpriteExt;
	var stars:FlxSpriteExt;
	var aurora:FlxSpriteExt;

	var words_x:Int = 0;
	var words_width:Int = 1060;
	var line_y_padding:Int = 16;

	var credits_duration_in_seconds:Int = 60 * 2 + 30;

	public function new(bg_x:Float, bg_y:Float)
	{
		super();

		FlxG.state.add(this);

		var bg_x:Float = FlxG.camera.minScrollX;
		var by_y:Float = FlxG.camera.minScrollY;

		aurora = new FlxSpriteExt(bg_x, bg_y);
		stars = new FlxSpriteExt(bg_x, by_y);
		mountains = new FlxSpriteExt(bg_x, bg_y);

		aurora.loadAllFromAnimationSet("pinnacle-4-aurora");
		stars.loadAllFromAnimationSet("pinnacle-3-stars");
		mountains.loadAllFromAnimationSet("pinnacle-2-mountains");

		add(aurora);
		add(stars);
		add(mountains);

		make_words();

		sstate(IDLE);

		members.for_all_members((member) -> member.scrollFactor.set(0, 0));
	}

	function make_words()
	{
		var data:String = Utils.load_file_string("credits.txt");

		var line_y:Int = 0;

		for (text in data.split("\n"))
			if (text != "\n" && text.length > 2)
			{
				var word:CreditsWord = new CreditsWord(0, line_y, words_width, text);
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

		return return_me;
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
