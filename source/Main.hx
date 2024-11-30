package;

import Paths.Manifest;
import data.loaders.NPCLoader;
import flixel.FlxGame;
import levels.LdtkProject;
import openfl.display.Sprite;
import utils.CrashHandler;
#if newgrounds import ng.NewgroundsHandler; #end

class Main extends Sprite
{
	public static var username:String = #if random_username 'poop_${Math.random()}' #else "" #end;

	public static var current_room_id:String = "1";

	public static var DEV:Bool = #if dev true #else false #end;

	public static var ldtk_project:LdtkProject = new LdtkProject();

	#if newgrounds
	public static var ng_api:NewgroundsHandler;
	#end

	public static function main():Void
	{
		// We need to make the crash handler LITERALLY FIRST so nothing EVER gets past it.
		CrashHandler.initialize();
		CrashHandler.queryStatus();

		openfl.Lib.current.addChild(new Main());
	}

	public function new()
	{
		super();
		Manifest.init(make_game);
	}

	function on_logged_in()
	{
		#if newgrounds
		username = ng_api.NG_USERNAME;
		if (username == "")
		{
			username = 'temporary_random_username_${Math.random()}';
		}
		#end
		addChild(new FlxGame(1920, 1080, PlayState, true));
	}

	public function make_game()
	{
		Lists.init();
		trace("initin");
		#if newgrounds
		ng_api = new NewgroundsHandler(true, false, on_logged_in);
		#else
		on_logged_in();
		#end
	}
}
