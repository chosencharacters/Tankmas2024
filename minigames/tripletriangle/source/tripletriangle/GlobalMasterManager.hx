package tripletriangle;

import coroutine.CoroutineRunner;
import coroutine.Routine;
import flixel.FlxObject;
import haxe.Exception;

class GlobalMasterManager extends FlxObject
{
	override public function new()
	{
		super();

		var routine = new CoroutineRunner();
		routine.startCoroutine(IReadyManagers());
		new haxe.Timer(16).run = function()
		{
			// Customize how/when to update your coroutines
			// Set this at your convenience in your project
			var processor = CoroutineProcessor.of(routine);
			processor.updateEnterFrame();
			processor.updateTimer(haxe.Timer.stamp());
			processor.updateExitFrame();
		}
	}

	private function ReadyManagers()
	{
		try
		{
			// trace("TODO: ReadyManagers");
			// SettingsManager.Main.Initialize();
			// MainMenuManager.Main.Initialize();
			// CoinManager.Main.Initialize();
		}
		catch (e:Exception)
		{
			trace(e.message);
		}
	}

	// It's a coroutine because I want the Class.Main's to be initialized first, via their Class.Start()'s.
	private function IReadyManagers():Routine
	{
		@yield return WaitEndOfFrame;
		ReadyManagers();
	}
}
