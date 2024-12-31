package states.substates;

import data.JsonData;
import data.loaders.TankmasChroniclesLoader.TankmasChroniclesChoice;
import data.loaders.TankmasChroniclesLoader.TankmasChroniclesPassage;
import flixel.tweens.FlxEase;
import squid.ext.FlxSubstateExt;
import ui.button.HoverButton;

class TankmasChroniclesSubstate extends FlxSubstateExt
{
	var image:FlxSpriteExt;

	var passage:TankmasChroniclesPassage;

	var sounds_to_play:Array<String> = [];
	var sound:FlxSound;

	var substate:FlxSubstateExt;

	var page:Int = 1;
	var pages:Int;

	var right_arrow:HoverButton;
	var back_arrow:HoverButton;

	var image_name:String;
	var image_base:String;

	var black:FlxSpriteExt;

	var old_music_volume:Float;

	var has_choices(get, never):Bool;
	var final_passage(get, never):Bool;

	var choice_buttons:Array<HoverButton> = [];

	/**
	 * This is private, should be only made through things that extend it
	 * @param saved_sheet
	 * @param saved_page
	 */
	public function new(starting_passage_name:String)
	{
		super();

		old_music_volume = FlxG.sound.music.volume;

		var black:FlxSpriteExt = new FlxSpriteExt(0, 0).makeGraphicExt(FlxG.width, FlxG.height, FlxColor.BLACK);
		black.setPosition(0, 0);
		black.alpha = 0.5;
		add(black);

		image = new FlxSpriteExt();

		Ctrl.mode = ControlModes.TALKING;

		// right_arrow = new HoverButton(Paths.image_path("right-arrow"), (b) -> next_linear_passage());
		right_arrow = new HoverButton(Paths.image_path("right-arrow"));
		back_arrow = new HoverButton(Paths.image_path("back-arrow"), (b) -> close_ui());

		add(image);

		add(back_arrow);

		switch_passage(starting_passage_name);

		FlxG.state.openSubState(this);

		members.for_all_members((member) -> cast(member, FlxSprite).scrollFactor.set(0, 0));

		//		members.for_all_members((member) -> cast(member, FlxSprite).offset.y = -FlxG.height);

		black.offset.y = 0;
	}

	override function update(elapsed:Float)
	{
		for (button in choice_buttons)
		{
			button.setPosition(image.x, image.y);
			button.offset.set(image.offset.x, image.offset.y);
		}
		fsm();
		super.update(elapsed);
	}

	function fsm()
		switch (cast(state, State))
		{
			default:
			case NEW_PASSAGE:
			case IDLE:
				if (ttick() >= 60)
					if (!has_choices && !final_passage && FlxG.mouse.justPressed && FlxG.mouse.overlaps(image))
					{
						next_linear_passage();
						tick = 0;
					}
		}

	override function kill()
	{
		FlxG.sound.music.volume = old_music_volume;
		Ctrl.mode = ControlModes.OVERWORLD;
		super.kill();
	}

	public function next_linear_passage()
		switch_passage(passage.next_passage);

	public function switch_passage(passage_name:String)
	{
		if (sound != null)
		{
			sound.stop();
			sound.kill();
		}

		passage = Lists.tankmas_chronicles_passages.get(passage_name);
		sounds_to_play = passage.sounds.copy();

		new_visuals();

		if (sounds_to_play.length > 0)
			next_sound();

		// right_arrow.visible = passage.next_passage != "" && passage.next_passage != null && !has_choices;
	}

	function next_sound()
	{
		sound = SoundPlayer.sound(sounds_to_play.shift(), 1);
		if (sounds_to_play.length > 0)
			sound.onComplete = () -> next_sound();
	}

	public function new_visuals()
	{
		for (button in choice_buttons)
		{
			button.kill();
			remove(button, true);
		}
		choice_buttons = [];

		image.loadGraphic(Paths.image_path(passage.image_name));

		// var scale_x:Float = 1920 / image.width;
		// var scale_y:Float = 1080 / image.height;

		var scale_x:Float = 1808 / image.width;
		var scale_y:Float = 1017 / image.height;

		if (scale_x > scale_y)
			scale_x = scale_y;
		else if (scale_y > scale_x)
			scale_y = scale_x;

		image.scale.x = scale_x;
		image.scale.y = scale_y;

		image.screenCenter();

		back_arrow.setPosition(FlxG.width - back_arrow.width, FlxG.height - back_arrow.height);

		right_arrow.screenCenter();
		right_arrow.x = FlxG.width - right_arrow.width;

		sstate(NEW_PASSAGE);

		members.for_all_members((member) -> cast(member, FlxSprite).offset.y = -FlxG.height);

		members.for_all_members(function(member)
		{
			FlxTween.tween(cast(member, FlxSprite).offset, {y: 0}, 0.25, {ease: FlxEase.cubeInOut});
			sstate(IDLE);
		});

		trace(passage.choices);
		for (choice in passage.choices)
		{
			var button_linked_passage:TankmasChroniclesPassage = Lists.tankmas_chronicles_passages.get(choice.link_passage);

			var button:HoverButton = new HoverButton(image.x, image.y, Paths.image_path(choice.choice_name),
				(b) -> switch_passage(button_linked_passage.passage_name));
			button.pixel_perfect = true;
			button.scrollFactor.set();

			button.base_scale = scale_x;
			button.no_scale = true;

			trace(button.base_scale);

			choice_buttons.push(button);

			add(button);
		}
	}

	public function close_ui()
	{
		if (state != IDLE)
			return;

		sstate(CLOSE);

		Ctrl.mode = ControlModes.OVERWORLD;
		close();
	}

	public function get_has_choices():Bool
		return passage.choices.length > 0;

	public function get_final_passage():Bool
		return passage.next_passage == null || passage.next_passage == "" || passage.passage_name == "outro-page-3";
}

private enum abstract State(String) from String to String
{
	var IDLE;
	var NEW_PASSAGE;
	var CLOSE;
}
