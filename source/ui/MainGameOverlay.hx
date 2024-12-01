package ui;

import data.JsonData;
import data.SaveManager;
import entities.Player;
import flixel.tweens.FlxEase;
import squid.ext.FlxTypedGroupExt;
import ui.popups.StickerPackOpening;
import ui.sheets.SheetMenu;

class MainGameOverlay extends FlxTypedGroupExt<FlxSpriteExt>
{
	var emote:FlxSpriteExt;
	var settings:FlxSpriteExt;
	var sticker_menu:FlxSpriteExt;
	var sticker_pack:FlxSpriteExt;

	var hide_speed:Float = 0.35;
	var reveal_speed:Float = 0.35;

	var player(get, default):Player;

	public function new()
	{
		super();

		add(emote = new FlxSpriteExt(20, 20, Paths.get('heart.png')));
		add(settings = new FlxSpriteExt(1708, 20, Paths.get('settings.png')));
		add(sticker_menu = new FlxSpriteExt(1520, 1030, Paths.get('charselect-mini-bg.png')));

		sticker_pack = new FlxSpriteExt().one_line("sticker-pack-icon");
		sticker_pack.setPosition(20, FlxG.height - sticker_pack.height - 20);
		add(sticker_pack);

		for (sprite in [emote, settings])
			sprite.offset.y = sprite.height;

		reveal_top_ui();

		for (member in members)
			member.scrollFactor.set(0, 0);

		sticker_pack.visible = Player.has_sticker_pack;
	}

	override function update(elapsed:Float)
	{
		sticker_pack.visible = Player.has_sticker_pack;
		hover_handler();
		super.update(elapsed);
	}

	public function hide_top_ui(?on_complete:FlxTween->Void)
	{
		for (sprite in [emote, settings])
			sprite.tween = FlxTween.tween(sprite.offset, {y: sprite.height + 16}, hide_speed, {ease: FlxEase.quadInOut});
		emote.tween.onComplete = on_complete;
	}

	public function reveal_top_ui(?on_complete:FlxTween->Void)
	{
		for (sprite in [emote, settings])
		{
			sprite.tween = FlxTween.tween(sprite.offset, {y: 0}, reveal_speed, {ease: FlxEase.quadInOut});
			sprite.offset.y = 0;
		}
		emote.tween.onComplete = on_complete;
	}

	public function hover_handler()
	{
		if (!Ctrl.mode.can_open_menus)
			return;

		if (sticker_pack.visible && FlxG.mouse.overlaps(sticker_pack) && FlxG.mouse.pressed && Ctrl.mode.can_open_menus)
		{
			Ctrl.mode = ControlModes.NONE;

			sticker_pack.tween = FlxTween.tween(sticker_pack, {y: FlxG.height + sticker_pack.height}, 0.25, {
				onComplete: (t) -> FlxG.state.add(new StickerPackOpening(JsonData.random_draw_stickers(Main.daily_sticker_draw_amount)))
			});

			return;
		}

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
							player.use_sticker(SaveManager.current_emote);
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
