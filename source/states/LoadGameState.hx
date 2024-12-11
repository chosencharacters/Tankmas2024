package states;

import flixel.util.FlxSave;
import net.tankmas.OnlineLoop;
import data.SaveManager;
#if newgrounds import ng.NewgroundsHandler; #end

enum LoadStep
{
	LoggingIn;
	NgPassportRequested;
	LoadingSave;
	Ready;
	Started;
}

/// This state runs before PlayState, to ensure both that the
/// NG session exists, and that the player's save data is up to date.
class LoadGameState extends BaseState
{
	var loading_state:LoadStep = LoggingIn;

	var passport_text:FlxText;

	var saved_session_id:FlxSave;

	public function new()
	{
		super();

		saved_session_id = new FlxSave();
		saved_session_id.bind('ng_session_id');

		trace(saved_session_id.data);

		#if newgrounds
		Main.ng_api = new NewgroundsHandler();

		if (saved_session_id.data.session_id != null)
		{
			Main.ng_api.NG_SESSION_ID = saved_session_id.data.session_id;
		}

		Main.ng_api.init(on_logged_in, ng_passport_requested);
		#else
		on_logged_in();
		#end
	}

	function ng_passport_requested()
	{
		loading_state = NgPassportRequested;
		passport_text = new FlxText(0, 0, 0, 'Tap to sign in using Newgrounds Passport');
		passport_text.setFormat(Paths.get('CharlieType-Heavy.otf'), 36, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		passport_text.alpha = 0;
		FlxTween.tween(passport_text, {"alpha": 1.0}, 0.3);
		add(passport_text);
	}

	function on_logged_in()
	{
		loading_state = LoadingSave;

		#if newgrounds
		Main.username = Main.ng_api.NG_USERNAME;
		Main.session_id = Main.ng_api.NG_SESSION_ID;

		saved_session_id.data.session_id = Main.session_id;
		saved_session_id.flush();

		if (Main.username == "")
		{
			Main.username = 'temporary_random_username_${Math.random()}';
		}
		#end

		SaveManager.init();
		SaveManager.load(on_save_loaded, on_save_loaded);
	}

	function on_save_loaded()
	{
		if (loading_state != LoadingSave)
			return;

		loading_state = Ready;
		OnlineLoop.init();
	}

	function start_game()
	{
		if (loading_state != Ready)
			return;
		loading_state = Started;
		FlxG.switchState(() -> new PlayState());
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		if (passport_text != null)
		{
			passport_text.x = FlxG.width * 0.5 - passport_text.width * 0.5;
			passport_text.y = FlxG.height * 0.5 - 32;
		}

		if (loading_state == NgPassportRequested)
		{
			if (FlxG.mouse.justPressed)
			{
				#if newgrounds
				Main.ng_api.launch_newgrounds_passport();
				loading_state = LoggingIn;
				#end
			}
		}
		if (loading_state == Ready)
			start_game();
	}
}
