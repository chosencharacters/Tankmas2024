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

	public var error_text:String;

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
		error_text = 'Welcome to Tankmas ADVENTure 2024!\n\nWe hope you enjoy your visit. If you want to earn medals, score on leaderboards, and save your costumes and progress, please login to Newgrounds on your next visit!';
		#if newgrounds
		if(ng_api.NG_LOGGED_IN) {
			username = ng_api.NG_USERNAME;
			if (username == "")
			{
				username = 'temporary_random_username_${Math.random()}';
			}
			addChild(new FlxGame(1920, 1080, PlayState, true));
		} else {
			if(ng_api.NG_LOGIN_ERROR != null) error_text = 'ERROR WHILE LOADING LOGIN: ${ng_api.NG_LOGIN_ERROR}\n\nPlease screenshot this and share with Tankmas ADVENTure 2024 developers. Login functions are deactivated.';
			#end
			username = 'temporary_random_username_${Math.random()}';
			TextState.text_to_write = error_text;
			addChild(new FlxGame(1920, 1080, TextState, true));
		#if newgrounds
		}
		#end

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
		ng_api = new NewgroundsHandler(true, true, on_logged_in);
		#else
		on_logged_in();
		#end
	}
}
