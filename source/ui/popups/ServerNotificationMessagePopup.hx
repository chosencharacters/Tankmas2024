package ui.popups;

import flixel.tweens.FlxEase;
import flixel.group.FlxContainer.FlxTypedContainer;

class ServerNotificationMessagePopup extends FlxTypedGroup<FlxText>
{
	final notification_message_duration = 8.0;

	var persistent = false;

	var until_hide:Float = 0.0;

	var state:State = INACTIVE;

	var current_tween:FlxTween;

	var text_object:FlxText;

	public function new()
	{
		super(10);

		text_object = new FlxText(40, 40, 0, '', 40);
		// text_object.color.setRGB(140, 140, 140);
		// text_object.setFormat(, 40, 0xff3d4880); // , "left", FlxTextBorderStyle.OUTLINE, 0xFF16122C);
		// text_object.shadowOffset.set(1, 1);
		// text_object.borderSize = 4;

		text_object.scrollFactor.set(0, 0);

		add(text_object);
	}

	public function show(text:String, persistent = false)
	{
		state = ACTIVE;

		this.persistent = persistent;

		visible = true;

		until_hide = notification_message_duration;

		text_object.text = text;

		var text_y = FlxG.height * 0.3;

		text_object.alpha = 0.0;
		text_object.x = Math.round((FlxG.width - text_object.width) * 0.5);
		text_object.y = text_y - 12;

		if (current_tween != null)
			current_tween.cancel();
		current_tween = FlxTween.tween(text_object, {alpha: 1.0, y: Math.round(text_y)}, 0.35, {ease: FlxEase.elasticOut});
	}

	public function hide()
	{
		if (state != ACTIVE)
			return;

		state = FADING_OUT;

		if (current_tween != null)
			current_tween.cancel();
		current_tween = FlxTween.tween(text_object, {alpha: 0.0}, 0.45, {ease: FlxEase.circOut, onComplete: finish_fadeout});
	}

	override function draw()
	{
		super.draw();
	}

	function finish_fadeout(_cb)
	{
		if (state != FADING_OUT)
			return;
		state = INACTIVE;
		visible = false;
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (persistent)
			return;

		switch (state)
		{
			case ACTIVE:
				until_hide -= elapsed;
				if (until_hide <= 0)
					hide();

			default:
		}
	}
}

private enum abstract State(String) from String to String
{
	var INACTIVE;
	var ACTIVE;
	var FADING_OUT;
}
