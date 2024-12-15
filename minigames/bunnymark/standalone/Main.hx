package;

import bunnymark.*;
import flixel.FlxG;
import flixel.FlxGame;
import openfl.display.Sprite;

class Main extends Sprite
{
	public function new()
	{
		super();
		addChild(new FlxGame(640, 480, BootState));
	}
}

class BootState extends flixel.FlxState
{
	override function create()
	{
		super.create();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		FlxG.switchState(new PlayState());
	}
}
