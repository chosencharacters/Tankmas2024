package states;

import net.tankmas.OnlineLoop;
import data.SaveManager;
import flixel.FlxState;

class LoadGameState extends FlxState
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
		FlxG.switchState(new PlayState());
	}
}
