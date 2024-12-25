package tripletriangle;

import coroutine.Routine;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.text.FlxBitmapText;
import flixel.text.FlxText.FlxTextAlign;
#if ADVENT
import utils.OverlayGlobal as Global;
#else
import utils.Global;
#end

class ComboManager extends FlxObject
{
	public static var Main:ComboManager;

	private var comboCounter:Int = 0;

	override public function new()
	{
		super();
		if (Main == null)
			Main = this;
	}

	public function AddToCombo(toAdd:Int)
	{
		comboCounter += toAdd;
		// GameManagerBase.Main.OnCombo(comboCounter);  // Redundant RN.
	}

	public function FinishCombo():Routine
	{
		trace("DOING: FinishCombo()");

		// Combo and coin pop-up text
		// GameManagerBase.Main.OnFinishCombo();  // Redundant RN.

		if (comboCounter >= 3)
		{
			var comboText:FlxBitmapText = PlayState.comboText;
			comboText.text = "COMBO: " + comboCounter + "!";
			comboText.setPosition(160 - (comboText.width / 2), 120 - (comboText.height / 2));
			comboText.alignment = FlxTextAlign.CENTER;

			var coinComboText:FlxBitmapText = PlayState.coinComboText;
			// Coin pop-up
			switch (comboCounter)
			{
				case 3:
					coinComboText.text = "+1 coin!";
					GameManagerBase.Main.AddToScore(1);
					FlxG.sound.play(Global.asset("assets/sounds/JSFXR Combo 3.ogg"), 0.9);
				case 4:
					coinComboText.text = "+3 coins!";
					GameManagerBase.Main.AddToScore(3);
					FlxG.sound.play(Global.asset("assets/sounds/JSFXR Combo 4.ogg"), 0.9);
				default: // >= 5
					coinComboText.text = "+5 coins!";
					GameManagerBase.Main.AddToScore(5);
					FlxG.sound.play(Global.asset("assets/sounds/JSFXR Combo 5.ogg"), 0.9);
			}
			coinComboText.setPosition(160 - (coinComboText.width / 2), 140 - (coinComboText.height / 2));
			coinComboText.alignment = FlxTextAlign.CENTER;

			comboCounter = 0;

			final textDisplayDeltaTime:Float = 1.075;
			comboText.visible = true;
			coinComboText.visible = true;
			@yield return WaitDelay(textDisplayDeltaTime);
			comboText.visible = false;
			coinComboText.visible = false;
		}
		comboCounter = 0;
	}
}
