package;

import data.TimeManager;
import Paths.Manifest;
import data.loaders.NPCLoader;
import flixel.FlxGame;
import levels.LdtkProject;
import openfl.display.Sprite;
import utils.CrashHandler;
import data.TimeManager;
#if newgrounds import ng.NewgroundsHandler; #end

class Main extends Sprite
{
	public static var username:String = #if username haxe.macro.Compiler.getDefine("username") #elseif random_username 'poop_${Math.random()}' #else "lost soul" #end;

	public static var current_room_id:String = "1";

	public static var DEV:Bool = #if dev true #else false #end;

	public static var ldtk_project:LdtkProject = new LdtkProject();

	#if newgrounds
	public static var ng_api:NewgroundsHandler;
	#end

	public static var default_sticker_collection:Array<String> = ["common-tamago"];
	public static var default_sticker:String = "common-tamago";

	public static var default_costume_collection:Array<String> = ["tankman", "paco"];
	public static var default_costume:String = "tankman";

	public static var default_room:String = "outside_hotel";

	public static var ran:FlxRandom = new FlxRandom();

	public static var daily_sticker_draw_amount:Int = 4;

	public static var time:TimeManager = new TimeManager();

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

	public static function get_current_bg(day:Int):Int
	{
		/**if(day <= 3)**/
		return day
		/**else if(day <= 6) return 3
			else /**if(day <= ) return 7**/;
	}

	public function make_game()
	{
		Lists.init();
		#if newgrounds
		ng_api = new NewgroundsHandler(true, false, on_logged_in);
		#else
		on_logged_in();
		#end
	}
}
