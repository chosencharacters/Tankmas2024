package;

import Paths.Manifest;
import flixel.FlxGame;
import openfl.display.Sprite;

class Main extends Sprite
{
	public static var DEV:Bool = #if dev true #else false #end;

	public function new()
	{
		super();
		Manifest.init(make_game);
	}

	public function make_game()
	{
		Lists.init();
		addChild(new FlxGame(1920, 1080, PlayState, true));
	}
}
