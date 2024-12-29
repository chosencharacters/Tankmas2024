package minigames.fttt;

import flixel.FlxG;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxPoint;
import flixel.math.FlxRandom;
import flixel.math.FlxRect;
import flixel.text.FlxBitmapFont;
import flixel.text.FlxBitmapText;
import flixel.ui.FlxBar;
import squid.ext.FlxSubstateExt;
import squid.sprite.FlxSpriteExt;
import ui.button.HoverButton;

using Math;
using squid.util.FlxSpriteUtils;

class FTTTSubState extends FlxSubstateExt
{
	var bg:FlxSpriteExt;

	var things:FlxTypedGroup<FTTTThing> = new FlxTypedGroup<FTTTThing>();
	var menus:FlxTypedGroup<HoverButton> = new FlxTypedGroup<HoverButton>();

	var thing_count:Int = 15;

	public static var bounds:FlxRect;
	public static var spawn_margins:Int = 16;

	var ran:FlxRandom;

	var crosshair:FlxSpriteExt;

	final speed_difficulty_mod:Float = 25;
	final time_difficulty_mod:Float = 30;

	var current_speed:Int = 0;

	var max_thing_vel:Int = 250;

	var max_time:Int = 60 * 10;
	var min_time:Int = 60;
	var current_round_max_time:Int;

	var streak:Int = 0;
	var best_streak:Int = 0;

	var play_song:Bool = true;

	var streak_text:FlxBitmapText;

	var music:FlxSound;

	var time_bar:FlxSpriteExt;

	var time_percent(get, never):Float;

	function get_time_percent():Float
		return 1 - (tick / current_round_max_time);

	override function create()
	{
		super.create();

		bounds = new FlxRect(0, 0, 320, 240);
		// bounds.x = FlxG.width / 2 - bounds.width / 2;
		// bounds.y = FlxG.height / 2 - bounds.height / 2;

		bg = new FlxSpriteExt(0, 0).makeGraphicExt(FlxG.width, FlxG.height, 0xffa8a8a8);

		crosshair = new FlxSpriteExt();
		crosshair.loadAllFromAnimationSet("fttt-crosshair");
		crosshair.offset.set(15, 15);

		ran = new FlxRandom();

		streak_text = new FlxBitmapText(FlxBitmapFont.fromMonospace(Paths.image_path("fttt-font"), "1234567890", FlxPoint.get(35, 46)));

		time_bar = new FlxSpriteExt(0, 240 - 16).makeGraphicExt(320, 16, FlxColor.BLACK);
		time_bar.alpha = 0.5;

		add(bg);
		add(things);
		add(streak_text);
		add(menus);

		add(time_bar);

		add(crosshair);

		cursor.kill();
		remove(cursor, true);

		sstate(INTRO, fsm);

		trace_new_state = true;
	}

	override function update(elapsed:Float)
	{
		crosshair.setPosition(FlxG.mouse.x, FlxG.mouse.y);

		streak_text.text = Std.string(streak);
		time_bar.visible = false;

		fsm();
		super.update(elapsed);
	}

	function fsm()
		switch (cast(state, State))
		{
			default:
			case INTRO:
				new_menu("fttt-intro", GAME_START);
				sstate(WAIT, fsm);
				if (play_song)
				{
					play_song = false;
					music = SoundPlayer.sound("fttt-theme");
					music.looped = true;
				}
				SoundPlayer.sound("fttt-announcer-intro");
			case GAME_START:
				make_things();
				current_round_max_time = (max_time - streak * time_difficulty_mod).floor();
				if (current_round_max_time < min_time)
					current_round_max_time = min_time;
				tick = 0;
				sstate(GAME, fsm);
			case GAME:
				ttick();
				time_bar.scale.x = time_percent;
				time_bar.visible = true;
			// nothing here lol
			case SUCCESS:
				SoundPlayer.sound('fttt-announcer-success-${ran.int(1, 8)}');
				new_menu("fttt-success", GAME_START);
				sstate(WAIT, fsm);
			case FAILURE:
				SoundPlayer.sound('fttt-announcer-fail-${ran.int(1, 6)}');
				new_menu("fttt-failure", INTRO);
				sstate(WAIT, fsm);
		}

	function new_menu(name:String, next_state:State)
	{
		menus.forEach((sprite) -> sprite.kill());
		menus.clear();

		menus.add(new HoverButton(Paths.get('$name.png')));

		menus.members.last().on_pressed = function(b)
		{
			b.kill();
			sstate(next_state, fsm);
		};

		for (menu in menus)
			menu.center_on(FlxPoint.weak(bounds.x + bounds.width / 2, bounds.y + bounds.height / 2));
	}

	function make_things()
	{
		var thing_vel:Int = 100 + (streak * speed_difficulty_mod).floor();
		if (thing_vel >= max_thing_vel)
			thing_vel = max_thing_vel;
		for (n in 0...thing_count)
		{
			var thing_x:Float = ran.float(bounds.x + spawn_margins, bounds.x + bounds.width - spawn_margins - 36).floor();
			var thing_y:Float = ran.float(bounds.x + spawn_margins, bounds.x + bounds.width - spawn_margins - 43).floor();
			var thing:FTTTThing = new FTTTThing(thing_x, thing_y, thing_vel, good_outcome, bad_outcome, n == 1);
			thing.x = ran.float(bounds.x + spawn_margins, bounds.x + bounds.width - spawn_margins - thing.width);
			thing.y = ran.float(bounds.y + spawn_margins, bounds.y + bounds.height - spawn_margins - thing.height);
			things.add(thing);
		}
	}

	function clear_things()
	{
		for (thing in things)
			thing.kill();
		things.clear();
	}

	public function good_outcome()
	{
		SoundPlayer.sound('fttt-shoot');
		streak++;
		clear_things();
		sstate(SUCCESS);
	}

	public function bad_outcome()
	{
		SoundPlayer.sound('fttt-shoot');
		#if newgrounds
		if (streak >= best_streak)
			Main.ng_api.post_score(1, Main.FIND_THE_THING_THING_SCOREBOARD);
		#end
		streak = 0;
		clear_things();
		sstate(FAILURE);
	}

	override function kill()
	{
		killMembers();
		music.kill();
		super.kill();
	}
}

private enum abstract State(String) from String to String
{
	final INTRO;
	final GAME_START;
	final GAME;
	final SUCCESS;
	final FAILURE;
	final WAIT;
}
