package fx;

import flash.display.BitmapData;
import flash.display.BitmapDataChannel;
import flixel.FlxCamera;
import flixel.math.FlxMath;
import flixel.math.FlxRandom;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.tweens.FlxEase;
import openfl.geom.ColorTransform;
import openfl.geom.Point;
import openfl.geom.Rectangle;

using flixel.util.FlxSpriteUtil;

/**
 * ...
 * @author
 */
class CircleTransition extends FlxSpriteExt
{
	/***Big black sprite that represents darkness***/
	var shadow:FlxSprite;

	/***Darkness of the shadow***/
	var shadowDarkness:FlxColor;

	/***Is the shadow being removed from the game? Alpha fade out effect***/
	var fadeOut:Bool = false;

	/***Sources of light***/
	var sources:FlxTypedGroup<FlxSprite> = new FlxTypedGroup<FlxSprite>();

	/***Variable strengths of light***/
	var radius:Int = 1280;

	/***Make an outer circle of black?***/
	var outerCircle:Bool = false;

	/**Darkness and shit*/
	var darkness:Float = 1;

	public function new(?darkness:Float = 0.7, defaultOff:Bool = false)
	{
		super();

		shadow = new FlxSprite();

		shadow.makeGraphic(FlxG.width, FlxG.height, 0, true);
		makeGraphic(FlxG.width, FlxG.height, 0, true);

		FlxG.state.add(shadow);

		this.scrollFactor.set(0, 0);
		shadow.scrollFactor.set(0, 0);

		trace("THE DARKNESS BECOMES ME AND IT IS OF THE SPECIFIC VALUE: ", darkness);
		this.darkness = darkness == null ? 0.7 : darkness;
		update_darkness(darkness);

		visible = false;

		immovable = true;

		if (defaultOff)
		{
			turnOff();
			shadow.alpha = 0;
		}

		scrollFactor.set(0, 0);

		always_on_screen = true;

		FlxTween.num(radius, 0, 1.5, {ease: FlxEase.cubeOut}, update_radius);
		FlxTween.num(darkness, 1, 1.5, {ease: FlxEase.cubeOut}, update_darkness);
	}

	function update_radius(val:Float)
	{
		radius = val.floor();
	}

	function update_darkness(val:Float)
	{
		darkness = val;
		shadowDarkness = new FlxColor(0xFF000000);
		shadowDarkness.alphaFloat = (1 - darkness);
	}

	override public function update(elapsed:Float):Void
	{
		shadowDraw();
		super.update(elapsed);
	}

	function getSources()
	{
		sources.clear();

		addSource(PlayState.self.player, 128);
	}

	function addSource(sprite:FlxSprite, brightnessSet:Int)
		sources.add(sprite);

	function shadowDraw()
	{
		if (shadow.alpha <= 0)
			return;
		// refresh
		getSources();
		shadow.graphic.bitmap.fillRect(shadow.graphic.bitmap.rect, FlxColor.BLACK);
		graphic.bitmap.fillRect(graphic.bitmap.rect, shadowDarkness); // lower alpha is darker
		// draw
		if (sources.length > 0)
			for (s in sources)
				lightCircleDraw(s, this, false);
		shadow = invertedAlphaMaskFlxSprite(shadow, this, shadow);
	}

	var waver:Int = 0;

	var midpoint:FlxPoint = new FlxPoint();

	function lightCircleDraw(p:FlxSprite, target:FlxSprite, outlineMode:Bool)
	{
		p.getMidpoint(midpoint);
		midpoint.set(midpoint.x - camera.scroll.x, midpoint.y - camera.scroll.y);
		if (!outlineMode)
			FlxSpriteUtil.drawCircle(target, midpoint.x, midpoint.y, radius, FlxColor.WHITE, {color: FlxColor.BLACK});
		if (outlineMode)
			FlxSpriteUtil.drawCircle(target, midpoint.x, midpoint.y, radius, FlxColor.TRANSPARENT, {color: FlxColor.BLACK});
	}

	override public function kill():Void
	{
		FlxG.state.remove(shadow);
		shadow.kill();
		super.kill();
	}

	function invertedAlphaMaskFlxSprite(sprite:FlxSprite, mask:FlxSprite, output:FlxSprite):FlxSprite
	{
		// From WY Leong at http://coinflipstudios.com/devblog/?p=421
		// Solution based on the discussion here:
		// https://groups.google.com/forum/#!topic/haxeflixel/fq7_Y6X2ngY

		// NOTE: The code below is the same as FlxSpriteUtil.alphaMaskFlxSprite(),
		// except it has an EXTRA section below.

		// sprite.drawFrame(); //commenting this out potentiall introduces glitches but hey it's an extra draw call
		var data:BitmapData = sprite.pixels.clone();
		data.copyChannel(mask.pixels, new Rectangle(0, 0, sprite.width, sprite.height), new Point(), BitmapDataChannel.ALPHA, BitmapDataChannel.ALPHA);

		// EXTRA:
		// this code applies a -1 multiplier to the alpha channel,
		// turning the opaque circle into a transparent circle.
		data.colorTransform(new Rectangle(0, 0, sprite.width, sprite.height), new ColorTransform(0, 0, 0, -1, 0, 0, 0, 255));
		// end EXTRA

		output.pixels = data;
		return output;
	}
}
