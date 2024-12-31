package ui;

import flixel.tweens.FlxEase;
import squid.ext.FlxSubstateExt;
import ui.button.HoverButton;

class GachaSpawnUI extends FlxSpriteExt
{
	var image:HoverButton;
	var display_text:FlxText;

	static var images_not_got:Array<String> = [];

	var black:FlxSpriteExt;

	var substate:FlxSubstateExt;

	public function new()
	{
		super();

		FlxG.state.openSubState(substate = new FlxSubstateExt());

		black = new FlxSpriteExt().makeGraphicExt(FlxG.width, FlxG.height, FlxColor.BLACK);
		black.scrollFactor.set(0, 0);
		substate.add(black);
		black.alpha = 0;

		black.tween = FlxTween.tween(black, {alpha: 0.5}, 0.25);

		loadAllFromAnimationSet("gacha-spawn-ui");
		scale.set(3, 3);
		updateHitbox();

		screenCenter();

		sstate(IN);

		substate.add(this);

		scrollFactor.set(0, 0);

		if (images_not_got.length <= 0)
			for (image in Paths.path_cache.keys())
				if (image.contains("pico-cross-"))
					images_not_got.push(image);

		ran.shuffle(images_not_got);
	}

	override function update(elapsed:Float)
	{
		fsm();
		super.update(elapsed);
	}

	override function updateMotion(elapsed:Float)
	{
		super.updateMotion(elapsed);
	}

	function fsm()
		switch (cast(state, State))
		{
			default:
			case IN:
				anim_protect_then_function("in", () -> spawn_image());
			case OPEN:
				anim_protect_then_function("out", () -> sstate(IDLE, fsm));
			case IDLE:
			case OUT:
		}

	function spawn_image()
	{
		image = new HoverButton((b) -> if (state == IDLE)
		{
			if (state == IDLE)
			{
				image.tween = FlxTween.tween(image, {y: -image.height}, 0.5, {
					ease: FlxEase.cubeInOut,
					onComplete: (t) -> FlxG.state.closeSubState()
				});
				tween = FlxTween.tween(this, {y: FlxG.height}, 0.5, {
					ease: FlxEase.cubeInOut,
				});
				FlxTween.tween(display_text, {y: FlxG.height}, 0.5, {
					ease: FlxEase.cubeInOut,
				});
				black.tween = FlxTween.tween(black, {alpha: 0}, 0.25);
				sstate(OUT);
			}
		});

		var image_file:String = images_not_got.pop();

		image.base_scale = 0.75;
		image.loadAllFromAnimationSet(image_file);
		image.scrollFactor.set(0, 0);
		image.updateHitbox();
		image.screenCenter();

		FlxG.camera.flash();

		image.scrollFactor.set(0, 0);
		substate.add(image);

		display_text = new FlxText(0, 980, 1920, 'by ${image_file.split(".")[0].replace("pico-cross-", "")}');
		display_text.setFormat(Paths.get('CharlieType-Heavy.otf'), 64, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		display_text.center_on_bottom(image);
		display_text.scrollFactor.set(0, 0);
		display_text.y -= 32;

		substate.add(display_text);

		sstate(OPEN);

		image.y -= 32;
		image.tween = FlxTween.tween(image, {y: image.y + 32}, 0.25);
	}

	override function kill()
	{
		substate.remove(this, true);
		substate.remove(image, true);
		substate.remove(display_text, true);

		display_text.kill();
		image.kill();

		super.kill();
	}
}

private enum abstract State(String) from String to String
{
	final IN;
	final IDLE;
	final OPEN;
	final OUT;
}
