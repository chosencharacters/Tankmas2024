package ui;

import data.JsonData;
import data.SaveManager;
import entities.Player;
import flixel.tweens.FlxEase;
import squid.ext.FlxTypedGroupExt;
import ui.button.ActionStamp;
import ui.button.HoverButton;
import ui.popups.StickerPackOpening;
import ui.settings.BaseSettings;
import ui.sheets.SheetMenu;

class MainGameOverlay extends FlxTypedGroupExt<FlxSprite>
{
	var emote:HoverButton;
	var settings:HoverButton;
	var sticker_menu:FlxSpriteExt;
	var sticker_pack:HoverButton;
	var music_popup:MusicPopup;

	public var action_stamp:ActionStamp;

	var hide_speed:Float = 0.35;
	var reveal_speed:Float = 0.35;

	var player(get, default):Player;

	public function new()
	{
		super();

		add(music_popup = MusicPopup.get_instance());

		add(sticker_menu = new FlxSpriteExt(1520, 1030, Paths.get('charselect-mini-full.png')));

		add(settings = new HoverButton(1708, 20, Paths.get('settings.png'), (b) -> new BaseSettings()));

		add(emote = new HoverButton(20, 20, Paths.get('heart.png'), (b) -> player.use_sticker(SaveManager.current_emote)));

		add(sticker_pack = cast(new HoverButton().one_line("sticker-pack-icon"), HoverButton));
		sticker_pack.setPosition(emote.x + emote.width + 20, 20);

		add(action_stamp = new ActionStamp());

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

			var limit_list:Array<String> = [
				"toasty-warm",
				"edd-sticker",
				"mustard",
				"pink-kight-mondo",
				"tappy-sticker",
				"son-christmas",
				"sick-skull",
				"slashe-wave",
				"gimme-five",
				"john-sticker",
				"pico-sticker-swag"
			];

			sticker_pack.tween = FlxTween.tween(sticker_pack, {y: FlxG.height + sticker_pack.height}, 0.25, {
				onComplete: (t) -> FlxG.state.add(new StickerPackOpening(JsonData.random_draw_stickers(Main.daily_sticker_draw_amount, limit_list)))
			});

			return;
		}

		update_sticker_menu_button();
	}

	function get_player():Player
		return PlayState.self.player;

	/**The mouse is hovering over any of the ui elements, if so, don't let touch inputs happen*/
	public function mouse_is_over_ui():Bool
	{
		var mouse_over_no_no_zone:Bool = false;
		for (member in members)
			mouse_over_no_no_zone = mouse_over_no_no_zone || FlxG.mouse.overlaps(member);
		return mouse_over_no_no_zone;
	}

	function update_sticker_menu_button()
	{
		var twen:FlxTween = null;
		if (FlxG.mouse.overlaps(sticker_menu))
		{
			if (sticker_menu.y == 1030 && twen == null)
				twen = FlxTween.tween(sticker_menu, {y: 880}, 0.3, {
					onComplete: function(twn:FlxTween)
					{
						twen = null;
						sticker_menu.loadGraphic(Paths.get('charselect-mini-full.png'));
					}
				});
			if (FlxG.mouse.justReleased)
			{
				hide_top_ui();
				if (twen != null)
					twen.cancel();
				Ctrl.mode = ControlModes.NONE;
				twen = FlxTween.tween(sticker_menu, {y: 1180}, 0.3, {
					onComplete: (twn:FlxTween) ->
					{
						try
						{
							new SheetMenu();
						}
						catch (e)
						{
							trace(e, e.stack);
						}
						twen = null;
					}
				});
			}
			if (FlxG.mouse.pressed && sticker_menu.scale.x != 0.8)
				sticker_menu.scale.set(0.8, 0.8);
		}
		else
		{
			if (sticker_menu.scale.x != 1)
				sticker_menu.scale.set(1, 1);
			if ((sticker_menu.y == 880 || sticker_menu.y == 1180) && twen == null)
				twen = FlxTween.tween(sticker_menu, {y: 1030}, 0.3, {
					onComplete: function(twn:FlxTween)
					{
						twen = null;
						sticker_menu.loadGraphic(Paths.get('charselect-mini-full.png'));
					}
				});
		}
	}
}

private enum abstract State(String) from String to String
{
	var ALL_ACTIVE;
	var SUB_MENU_ACTIVE;
}
