package;

import Paths;
import data.SaveManager;
import data.TimeManager;
import data.loaders.NPCLoader;
import flixel.FlxGame;
import flixel.FlxState;
import flixel.system.debug.log.LogStyle;
import flixel.util.typeLimit.NextState.InitialState;
import levels.LdtkProject;
import levels.TankmasLevel.RoomId;
import openfl.display.Sprite;
import states.*;
import states.debug.*;
#if newgrounds import ng.NewgroundsHandler; #end
import utils.CrashHandler;
import flixel.system.debug.log.LogStyle;

class Main extends Sprite
{
	public static var username:String = #if username haxe.macro.Compiler.getDefine("username") #elseif random_username 'poop_${Math.random()}' #else "lost_soul" #end;
	public static var session_id:String = #if (offline || !newgrounds) "test_session" #else null #end;

	public static var current_room_id:RoomId = HotelCourtyard;

	public static var DEV:Bool = #if dev true #else false #end;

	public static var ldtk_project:LdtkProject = new LdtkProject();

	#if newgrounds
	public static var ng_api:NewgroundsHandler;
	#end

	public static var default_emote_collection:Array<String> = ["common-tamago", "gimme-five", "john-sticker", "why-coal"];
	public static var default_emote:String = "common-tamago";

	public static var default_costume_collection:Array<String> = ["tankman", "paco"];
	public static var default_costume:String = "tankman";
	public static var default_pet:String = "invisible-pet";

	public static final default_world:String = #if test_arcade "hotel_interior" #else "outside_hotel" #end;

	public static var ran:FlxRandom = new FlxRandom();

	public static var daily_emote_draw_amount:Int = 4;
	public static var rare_emote_draw_amount:Int = 16;

	public static var time:TimeManager = new TimeManager();

	public static var initial_state(get, never):InitialState;

	public static var default_song:String = "visual-snow-redux";

	public static var current_song:String;

	public static var use_small_assets:Bool = false;

	public static final GOLDEN_MARSHMALLOWS_SCOREBOARD:Int = 14324;
	public static final FIND_THE_THING_THING_SCOREBOARD:Int = 14434;
	public static final TRIPLE_TRIANGLE_SCOREBOARD:Int = 14435;

	public static function main():Void
	{
		// We need to make the crash handler LITERALLY FIRST so nothing EVER gets past it.why-coal
		CrashHandler.initialize();
		CrashHandler.queryStatus();

		current_song = default_song;

		LogStyle.ERROR.errorSound = null;
		LogStyle.WARNING.errorSound = null;

		openfl.Lib.current.addChild(new Main());
	}

	public function new()
	{
		super();
		#if sys
		sys.ssl.Socket.DEFAULT_VERIFY_CERT = false;
		#end
		Manifest.init(make_game);
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
		#if sys
		LogStyle.ERROR.errorSound = Paths.get("error.ogg");
		LogStyle.WARNING.errorSound = Paths.get("error.ogg");
		#end
		Lists.init();
		addChild(new FlxGame(1920, 1080, get_initial_state(), true));
	}

	static function get_initial_state():InitialState
	{
		#if debug_sheet_menu
		return states.debug.DebugSheetMenuState;
		#end
		return LoadGameState;
	}
}
