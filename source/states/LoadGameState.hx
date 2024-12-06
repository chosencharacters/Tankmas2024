package states;

import net.tankmas.OnlineLoop;
import data.SaveManager;
import flixel.FlxState;

/// This state runs before PlayState, to ensure both that the
/// NG session exists, and that the player's save data is up to date.
class LoadGameState extends BaseState
{
	public function new()
	{
		super();

		SaveManager.init();
		SaveManager.load(start_game, start_game);
	}

	function start_game()
	{
		OnlineLoop.init();
		FlxG.switchState(() -> new PlayState());
	}
}
