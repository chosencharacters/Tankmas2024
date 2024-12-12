package ui.popups;

import flixel.tweens.FlxEase;

class OfflineIndicator extends FlxSprite
{
	public function new()
	{
		super(null, null, AssetPaths.offline_marker__png);
		x = (FlxG.width - width) * 0.5;
		y = 0;
		visible = false;
	}

	public function show()
	{
		visible = true;
		alpha = 0.0;
		y = -20;
		FlxTween.tween(this, {alpha: 1.0, y: 0.0}, 0.2, {ease: FlxEase.circOut});
	}
}
