package states;

import net.tankmas.OnlineLoop;
import data.SaveManager;
import flixel.FlxState;
#if newgrounds import ng.NewgroundsHandler; #end

enum LoadStep
{
	LoggingIn;
	LoadingSave;
	Ready;
	Started;
}

/// This state runs before PlayState, to ensure both that the
/// NG session exists, and that the player's save data is up to date.
class LoadGameState extends BaseState
{
	var loading_state:LoadStep = LoggingIn;

	public function new()
	{
		super();

		#if newgrounds
		Main.ng_api = new NewgroundsHandler();
		Main.ng_api.init(true, false, on_logged_in);
		#else
		on_logged_in();
		#end
	}

	function on_logged_in()
	{
		loading_state = LoadingSave;
		#if newgrounds
		Main.username = Main.ng_api.NG_USERNAME;
		Main.session_id = Main.ng_api.NG_SESSION_ID;

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
		if (loading_state == Ready)
			start_game();
	}
}
