package ui;

import flixel.tweens.FlxEase;
import ui.button.HoverButton;

class GachaSpawnUI extends FlxSpriteExt
{
	var image:HoverButton;

	static var images_not_got:Array<String> = [];

	public function new()
	{
		super();

		loadAllFromAnimationSet("gacha-spawn-ui");
		scale.set(3, 3);
		updateHitbox();

		screenCenter();

		sstate(IN);

		PlayState.self.add(this);

		scrollFactor.set(0, 0);

		if (images_not_got.length <= 0)
			for (image in Paths.path_cache.keys())
				if (image.contains("pico-cross-"))
					images_not_got.push(image);

		trace(images_not_got);
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
				image.tween = FlxTween.tween(image, {y: image.y + 32}, 0.5, {ease: FlxEase.cubeInOut});
				sstate(OUT);
			}
			kill();
		});

		image.base_scale = 0.75;
		image.loadAllFromAnimationSet(images_not_got.pop());
		image.scrollFactor.set(0, 0);
		image.updateHitbox();
		image.screenCenter();

		FlxG.camera.flash();

		image.scrollFactor.set(0, 0);
		PlayState.self.add(image);
		sstate(OPEN);

		image.y -= 32;
		image.tween = FlxTween.tween(image, {y: image.y + 32}, 0.25);
	}

	override function kill()
	{
		PlayState.self.remove(this, true);
		PlayState.self.remove(image, true);

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
