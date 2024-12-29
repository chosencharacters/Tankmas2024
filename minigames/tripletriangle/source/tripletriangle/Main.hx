package tripletriangle;

// import flixel.FlxG;
import flixel.FlxGame;
// import flixel.system.scaleModes.FixedScaleMode;
// import js.Lib;
import openfl.display.Sprite;

class Main extends Sprite
{
	public function new()
	{
		super();
		addChild(new FlxGame(320, 240, PlayState));

		// FlxG.scaleMode = new FixedScaleMode(); // Keep the base resolution for scaling
		// Lib.eval('document.querySelector("canvas").style.imageRendering = "pixelated";');
	}
}
