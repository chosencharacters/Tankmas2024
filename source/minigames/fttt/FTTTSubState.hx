package minigames.fttt;

import flixel.FlxG;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxPoint;
import flixel.math.FlxRandom;
import flixel.math.FlxRect;
import squid.ext.FlxSubstateExt;
import squid.sprite.FlxSpriteExt;
import ui.button.HoverButton;

using Math;
using squid.util.FlxSpriteUtils;

class FTTTSubState extends FlxSubstateExt
{
	var bg:FlxSpriteExt;

	var things:FlxTypedGroup<FTTTThing> = new FlxTypedGroup<FTTTThing>();
	var menus:FlxTypedGroup<FlxSpriteExt> = new FlxTypedGroup<FlxSpriteExt>();

	var thing_count:Int = 15;

	public static var bounds:FlxRect;
	public static var spawn_margins:Int = 16;

	var ran:FlxRandom;

	var crosshair:FlxSpriteExt;

	final speed_difficulty_mod:Float = 1;
	final time_difficulty_mod:Float = 10;

	var current_speed:Int = 0;

	var max_time:Int = 60 * 10;
	var min_time:Int = 60;
	var current_time:Int;

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

		add(bg);
		add(things);
		add(menus);

		add(crosshair);

		cursor.kill();
		remove(cursor, true);

		sstate(INTRO, fsm);

		trace_new_state = true;
	}

	override function update(elapsed:Float)
	{
		crosshair.setPosition(FlxG.mouse.x, FlxG.mouse.y);

		super.update(elapsed);
		fsm();
	}

	function fsm()
		switch (cast(state, State))
		{
			default:
			case INTRO:
				new_menu("fttt-intro", GAME_START);
				sstate(WAIT, fsm);
			case GAME_START:
				make_things();
				sstate(GAME, fsm);
			case GAME:
				// nothing here lol
			case SUCCESS:
				new_menu("fttt-success", INTRO);
				sstate(WAIT, fsm);
			case FAILURE:
				new_menu("fttt-failure", INTRO);
				sstate(WAIT, fsm);
		}

	function new_menu(name:String, next_state:State)
	{
		menus.forEach((sprite) -> sprite.kill());
		menus.clear();

		menus.add(new HoverButton(Paths.get('$name.png'), function(b)
		{
			b.kill();
			sstate(next_state, fsm);
		}));

		for (menu in menus)
			menu.center_on(FlxPoint.weak(bounds.x + bounds.width / 2, bounds.y + bounds.height / 2));
	}

	function make_things()
		for (n in 0...thing_count)
		{
			var thing_x:Float = ran.float(bounds.x + spawn_margins, bounds.x + bounds.width - spawn_margins - 36).floor();
			var thing_y:Float = ran.float(bounds.x + spawn_margins, bounds.x + bounds.width - spawn_margins - 43).floor();
			var thing:FTTTThing = new FTTTThing(thing_x, thing_y, good_outcome, bad_outcome, n == 1);
			thing.x = ran.float(bounds.x + spawn_margins, bounds.x + bounds.width - spawn_margins - thing.width);
			thing.y = ran.float(bounds.y + spawn_margins, bounds.y + bounds.height - spawn_margins - thing.height);
			things.add(thing);
		}

	function clear_things()
	{
		for (thing in things)
			thing.kill();
		things.clear();
	}

	public function good_outcome()
	{
		clear_things();
		sstate(SUCCESS, fsm);
	}

	public function bad_outcome()
	{
		clear_things();
		sstate(FAILURE, fsm);
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
