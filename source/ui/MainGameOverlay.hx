package ui;

import entities.Player;
import flixel.tweens.FlxEase;
import squid.ext.FlxTypedGroupExt;
import ui.sheets.SheetMenu;

class MainGameOverlay extends FlxTypedGroupExt<FlxSpriteExt>
{
	var emote:FlxSpriteExt;
	var settings:FlxSpriteExt;
	var sticker_menu:FlxSpriteExt;

	var hide_speed:Float = 0.5;
	var reveal_speed:Float = 0.5;

	var player(get, default):Player;

	public function new()
	{
		super();

		add(emote = new FlxSpriteExt(20, 20, Paths.get('heart.png')));
		add(settings = new FlxSpriteExt(1708, 20, Paths.get('settings.png')));
		add(sticker_menu = new FlxSpriteExt(1520, 1030, Paths.get('charselect-mini-bg.png')));

		for (sprite in [emote, settings])
			sprite.offset.y = sprite.height;

		reveal_top_ui();

		for (member in members)
			member.scrollFactor.set(0, 0);
	}

	override function update(elapsed:Float)
	{
		hover_handler();
		super.update(elapsed);
	}

	public function hide_top_ui(?on_complete:FlxTween->Void)
	{
		for (sprite in [emote, settings])
			sprite.tween = FlxTween.tween(sprite.offset, {y: -emote.height}, hide_speed, {ease: FlxEase.quadInOut});
		emote.tween.onComplete = on_complete;
	}

	public function reveal_top_ui(?on_complete:FlxTween->Void)
	{
		for (sprite in [emote, settings])
			sprite.tween = FlxTween.tween(sprite.offset, {y: 0}, hide_speed, {ease: FlxEase.quadInOut});
		emote.tween.onComplete = on_complete;
	}

	public function hover_handler()
	{
		for (member in members)
			switch (members.indexOf(member))
			{
				case 2:
					var twen:FlxTween = null;
					if (FlxG.mouse.overlaps(member))
					{
						if (member.y == 1030 && twen == null)
							twen = FlxTween.tween(member, {y: 880}, 0.3, {
								onComplete: function(twn:FlxTween)
								{
									twen = null;
									member.loadGraphic(Paths.get('charselect-mini-full.png'));
								}
							});
						if (FlxG.mouse.justReleased)
						{
							hide_top_ui();
							if (twen != null)
								twen.cancel();
							twen = FlxTween.tween(member, {y: 1180}, 0.3, {
								onComplete: (twn:FlxTween) ->
								{
									new SheetMenu();
									twen = null;
								}
							});
						}
						if (FlxG.mouse.pressed && member.scale.x != 0.8)
							member.scale.set(0.8, 0.8);
					}
					else
					{
						if (member.scale.x != 1)
							member.scale.set(1, 1);
						if ((member.y == 880 || member.y == 1180) && twen == null)
							twen = FlxTween.tween(member, {y: 1030}, 0.3, {
								onComplete: function(twn:FlxTween)
								{
									twen = null;
									member.loadGraphic(Paths.get('charselect-mini-bg.png'));
								}
							});
					}

				case 1:
					if (FlxG.mouse.overlaps(member))
					{
						// if(FlxG.mouse.justReleased) openSubState(new OptionsSubState());
						if (FlxG.mouse.pressed && member.scale.x != 0.8)
							member.scale.set(0.8, 0.8)
						else if (!FlxG.mouse.pressed && member.scale.x != 1.1)
							member.scale.set(1.1, 1.1);
					}
					else if (member.scale.x != 1)
						member.scale.set(1, 1);

				case 0:
					if (FlxG.mouse.overlaps(member))
					{
						if (FlxG.mouse.justReleased)
							player.use_sticker(player.sticker);
						if (FlxG.mouse.pressed && member.scale.x != 0.8)
							member.scale.set(0.8, 0.8)
						else if (!FlxG.mouse.pressed && member.scale.x != 1.1)
							member.scale.set(1.1, 1.1);
					}
					else if (member.scale.x != 1)
						member.scale.set(1, 1);
			}
	}

	function get_player():Player
		return PlayState.self.player;
}

private enum abstract State(String) from String to String
{
	var ALL_ACTIVE;
	var SUB_MENU_ACTIVE;
}
