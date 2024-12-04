package ui.popups;

import flixel.tweens.FlxEase;
import flixel.group.FlxContainer.FlxTypedContainer;

class ServerNotificationMessagePopup extends FlxTypedGroup<FlxObject>
{
	final notification_message_duration = 8.0;

	var persistent = false;

	var until_hide:Float = 0.0;

	var state:State = INACTIVE;

	var current_tween:FlxTween;

	var text_object:FlxText;

	public function new()
	{
		super();
		text_object = new FlxText(40, 40, 0, null, 40);
		add(text_object);
	}

	public function show(text:String, persistent = false)
	{
		state = ACTIVE;

		this.persistent = persistent;

		visible = true;

		until_hide = notification_message_duration;

		text_object.text = text;

		text_object.alpha = 0.0;
		text_object.x = FlxG.width * 0.5;
		text_object.y = FlxG.height * 0.4 - 8;

		if (current_tween != null)
			current_tween.cancel();
		current_tween = FlxTween.tween(text_object, {alpha: 1.0, y: FlxG.height * 0.4}, 0.45, {ease: FlxEase.circOut});
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
