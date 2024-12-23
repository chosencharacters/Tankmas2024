package minigames.fttt.source;

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
	var menu:HoverButton;
	var things:FlxTypedGroup<FTTTThing>;

	var thing_count:Int = 15;

	public static var bounds:FlxRect;
	public static var spawn_margins:Int = 16;

	var ran:FlxRandom = new FlxRandom();

	override function create()
	{
		super.create();

		bounds = new FlxRect(0, 0, 320, 240);
		// bounds.x = FlxG.width / 2 - bounds.width / 2;
		// bounds.y = FlxG.height / 2 - bounds.height / 2;

		bg = new FlxSpriteExt(0, 0).makeGraphicExt(FlxG.width, FlxG.height, 0xffa8a8a8);

		add(bg);
		add(things = new FlxTypedGroup<FTTTThing>());

		sstate(INTRO, fsm);

		cursor.kill();
		remove(cursor, true);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		fsm();
	}

	function fsm()
		switch (cast(state, State))
		{
			case INTRO:
				if (ttick() == 1)
					new_menu("fttt-intro", GAME_START);
			case GAME_START:
				make_things();
				sstate(GAME, fsm);
			case GAME:
				// nothing here lol
			case SUCCESS:
				if (ttick() == 1)
					new_menu("fttt-success", INTRO);
			case FAILURE:
				if (ttick() == 1)
					new_menu("fttt-failure", INTRO);
		}

	function new_menu(name:String, next_state:State)
	{
		if (menu != null)
		{
			remove(menu, true);
			menu.kill();
		}

		add(menu = new HoverButton('minigames/fttt/assets/$name.png', function(b)
		{
			menu.kill();
			sstate(next_state, fsm);
		}));

		menu.center_on(FlxPoint.weak(bounds.x + bounds.width / 2, bounds.y + bounds.height / 2));

		trace(menu.getPosition());
	}

	override function kill()
	{
		super.kill();
	}

	function make_things()
	{
		for (n in 0...thing_count)
		{
			var thing:FTTTThing = new FTTTThing(good_outcome, bad_outcome, n == 1);
			thing.x = ran.float(bounds.x + spawn_margins, bounds.x + bounds.width - spawn_margins - thing.width);
			thing.y = ran.float(bounds.y + spawn_margins, bounds.y + bounds.height - spawn_margins - thing.height);

			things.add(thing);
		}
	}

	public function good_outcome()
		sstate(SUCCESS, fsm);

	public function bad_outcome()
		sstate(SUCCESS, fsm);
}

private enum abstract State(String) from String to String
{
	final INTRO;
	final GAME_START;
	final GAME;
	final SUCCESS;
	final FAILURE;
}
