package ui.popups;

import flixel.addons.display.FlxSpriteAniRot;
import flixel.tweens.FlxEase;
import squid.ext.FlxTypedGroupExt;

class StickerPackOpening extends FlxTypedGroupExt<FlxSpriteExt>
{
	var sticker_pack:FlxSpriteExt;

	var sticker_pack_descent_speed:Float = 0.5;

	var black:FlxSpriteExt;
	var black_alpha:Float = 0.75;

	static final max_hits:Int = 4;

	var initial_idle:Int = 30;
	var post_hit_wait:Int = 5;

	var hits:Int = 0;

	public function new()
	{
		super();

		black = new FlxSpriteExt().makeGraphicExt(FlxG.width, FlxG.height, FlxColor.BLACK);
		black.alpha = 0;

		sticker_pack = new FlxSpriteExt(0, 0).one_line("sticker-pack-opening");

		add(black);
		add(sticker_pack);

		sticker_pack.offset.set(0, -FlxG.height);
		sticker_pack.screenCenter();

		black.tween = FlxTween.tween(black, {alpha: black_alpha}, sticker_pack_descent_speed, {ease: FlxEase.quadInOut});

		sticker_pack.tween = FlxTween.tween(sticker_pack.offset, {y: 0}, sticker_pack_descent_speed, {
			ease: FlxEase.quadInOut,
			onComplete: (t) -> sstate(INITIAL_IDLE)
		});

		sstate(STICKER_PACK_IN);

		for (member in members)
			member.scrollFactor.set(0, 0);
	}

	override function update(elapsed:Float)
	{
		fsm();
		super.update(elapsed);
	}

	function fsm()
		switch (cast(state, State))
		{
			default:
			case INITIAL_IDLE:
				if (ttick() > 30)
					sstate(HIT_IT, fsm);
			case HIT_IT:
				hits++;
				sticker_pack.animProtect('${hits}');
				sstate(HITTING, fsm);
			case HITTING:
				if (sticker_pack.animation.finished)
					sstate(POST_HIT, fsm);
			case POST_HIT:
				if (ttick() > post_hit_wait)
					sstate(hits == max_hits ? PRE_KABOOM : HIT_IT, fsm);
			case PRE_KABOOM:
				sticker_pack.animProtect("pre-kaboom");
				if (sticker_pack.animation.finished)
				{
					FlxG.camera.flash();
					sstate(KABOOM, fsm);
				}
			case KABOOM:
				sticker_pack.animProtect("kaboom");
				if (sticker_pack.animation.finished)
					sstate(KABOOM);
		}

	override function kill()
	{
		super.kill();
	}
}

private enum abstract State(String) from String to String
{
	final STICKER_PACK_IN;
	final INITIAL_IDLE;
	final HIT_IT;
	final HITTING;
	final POST_HIT;
	final PRE_KABOOM;
	final KABOOM;
}
