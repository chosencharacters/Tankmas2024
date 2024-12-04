package fx;

import flixel.math.FlxMath;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.tweens.FlxEase;

class Thumbnail extends FlxSpriteExt
{
	public static var OPEN_TIME:Float = 0.5;
	public static var CLOSE_TIME:Float = 0.5;

	inline static var BOB_DIS = 7;
	inline static var BOB_PERIOD = 2.0;

	private var theY:Float = 0;
	private var scaleX:Float = 0.0;
	private var scaleY:Float = 0.0;
	private var timer:Float = 0.0;

	public function new(X:Float, Y:Float, content:FlxGraphicAsset)
	{
		super(X, Y, content);
		theY = Y;
		scale.set(0.07, 0.07);
		updateHitbox();
		scaleX = scale.x;
		scaleY = scale.y;
		x -= (width / 4);
		scale.x = 0;
		PlayState.self.thumbnails.add(this);
	}

	override function kill()
	{
		PlayState.self.thumbnails.remove(this, true);
		super.kill();
	}

	override function update(elapsed:Float)
	{
		fsm();
		super.update(elapsed);
		if (scale.x != 0)
		{
			y = theY + Math.round(FlxMath.fastCos(timer / BOB_PERIOD * Math.PI) * BOB_DIS);
			timer += elapsed;
		}
	}

	public function show()
		sstate(SHOW);

	public function hide()
		sstate(HIDE);

	function fsm()
		switch (cast(state, State))
		{
			default:
			case SHOW:
				if (scale.x == 0)
					FlxTween.tween(this.scale, {x: scaleX}, OPEN_TIME, {
						ease: FlxEase.elasticInOut,
						onComplete: function(twn:FlxTween)
						{
							sstate(IDLE);
						}
					});
			case HIDE:
				if (scale.x == scaleX)
					FlxTween.tween(this.scale, {x: 0}, CLOSE_TIME, {
						ease: FlxEase.elasticInOut,
						onComplete: function(twn:FlxTween)
						{
							sstate(IDLE);
							timer = 0;
						}
					});
		}
}

private enum abstract State(String) from String to String
{
	final IDLE;
	final SHOW;
	final HIDE;
}
