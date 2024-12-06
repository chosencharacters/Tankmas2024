package;

import Paths.Manifest;
import data.SaveManager;
import data.TimeManager;
import data.loaders.NPCLoader;
import flixel.FlxGame;
import flixel.FlxState;
import flixel.util.typeLimit.NextState.InitialState;
import levels.LdtkProject;
import openfl.display.Sprite;
import states.*;
import states.debug.*;
#if newgrounds import ng.NewgroundsHandler; #end
import utils.CrashHandler;

class Main extends Sprite
{
	public static var username:String = #if username haxe.macro.Compiler.getDefine("username") #elseif random_username 'poop_${Math.random()}' #else "lost_soul" #end;
	public static var session_id:String = #if (offline || !newgrounds) "test_session" #else null #end;

	public static var current_room_id:Int = 1;

	public static var DEV:Bool = #if dev true #else false #end;

	public static var ldtk_project:LdtkProject = new LdtkProject();

	#if newgrounds
	public static var ng_api:NewgroundsHandler;
	#end

	public static var default_emote_collection:Array<String> = ["common-tamago", "ilho-gift"];
	public static var default_emote:String = "common-tamago";

	public static var default_costume_collection:Array<String> = ["tankman", "paco"];
	public static var default_costume:String = "tankman";

	public static var default_room:String = "outside_hotel";

	public static var ran:FlxRandom = new FlxRandom();

	public static var daily_emote_draw_amount:Int = 4;

	public static var time:TimeManager = new TimeManager();

	public static var initial_state(get, never):InitialState;

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

	static function get_initial_state():InitialState
	{
		#if debug_menu
		return DebugMenuState;
		#end
		return PlayState;
	}
}
