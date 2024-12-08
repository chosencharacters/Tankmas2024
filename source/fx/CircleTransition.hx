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
	var radius:Int = 1920;

	/***Make an outer circle of black?***/
	var outerCircle:Bool = false;

	/**Darkness and shit*/
	var darkness:Float = 0;

	var finished:Bool = false;

	public function new(target:FlxSprite, ?duration:Float = 0.5, closing:Bool, ?on_complete:Void->Void)
	{
		super();

		shadow = new FlxSprite();

		shadow.makeGraphic(FlxG.width, FlxG.height, 0, true);
		makeGraphic(FlxG.width, FlxG.height, 0, true);

		FlxG.state.add(shadow);

		this.scrollFactor.set(0, 0);
		shadow.scrollFactor.set(0, 0);

		update_darkness(darkness);

		visible = false;

		immovable = true;

		scrollFactor.set(0, 0);

		always_on_screen = true;

		var from_radius:Float = closing ? radius : 0;
		var to_radius:Float = closing ? 0 : radius;

		var from_darkness:Float = !closing ? 1 : 0.5;
		var to_darkness:Float = !closing ? 0.5 : 1;

		from_darkness = to_darkness = 0;

		FlxTween.num(from_radius, to_radius, duration, {
			ease: FlxEase.cubeOut,
			onComplete: function(t)
			{
				on_complete != null ? on_complete() : null;
				kill();
			}
		}, update_radius);

		FlxTween.num(from_darkness, to_darkness, duration, {ease: FlxEase.cubeOut}, update_darkness);
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
		if (ttick() % 999 == 1)
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
