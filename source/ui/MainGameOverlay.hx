package ui;

import data.JsonData;
import data.SaveManager;
import entities.Player;
import flixel.tweens.FlxEase;
import squid.ext.FlxTypedGroupExt;
import ui.button.HoverButton;
import ui.button.StickerPackButton;
import ui.popups.OfflineIndicator;
import ui.popups.StickerPackOpening;
import ui.settings.BaseSettings;
import ui.sheets.EmoteSelectSheet;
import ui.sheets.SheetMenu;

class MainGameOverlay extends FlxTypedGroupExt<FlxSprite>
{
	var emote:HoverButton;
	var settings:HoverButton;
	var sticker_menu:HoverButton;
	var sticker_menu_y = 1010;

	var sticker_pack:HoverButton;
	var music_popup:MusicPopup;

	public var offline_indicator:ui.popups.OfflineIndicator;

	var hide_speed:Float = 0.35;
	var reveal_speed:Float = 0.35;

	var player(get, default):Player;

	public function new()
	{
		super();

		add(emote = new HoverButton(20, 20, Paths.get('heart.png'), do_emote));
		add(settings = new HoverButton(1708, 20, Paths.get('settings.png'), open_settings));
		add(sticker_menu = new HoverButton(1520, sticker_menu_y, Paths.get('charselect-mini-full.png'), open_sticker_menu));
		sticker_menu.on_hover = on_sticker_menu_hover;
		sticker_menu.on_neutral = on_sticker_menu_out;

		add(offline_indicator = new OfflineIndicator());

		#if !sticker_whatevey
		add(sticker_pack = new StickerPackButton(emote.x + emote.width + 20, 20));
		#end

		add(music_popup = MusicPopup.get_instance());

		for (sprite in [emote, settings])
			sprite.offset.y = sprite.height;

		reveal_top_ui();

		for (member in members)
			member.scrollFactor.set(0, 0);
	}

	override function update(elapsed:Float)
	{
		#if !sticker_whatevey sticker_pack.visible = Player.has_emote_pack; #end
		super.update(elapsed);
	}

	override function draw()
	{
		super.draw();
		var left_x = FlxG.camera.viewLeft;
		var top_x = FlxG.camera.viewTop;

		emote.x = 20;
		emote.y = 20;
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

	function open_settings(btn:HoverButton)
		new BaseSettings();

	function do_emote(btn:HoverButton)
		player.use_emote(SaveManager.current_emote);

	var sticker_menu_tween:FlxTween = null;

	function on_sticker_menu_hover(btn:HoverButton)
	{
		sticker_menu_tween = FlxTween.tween(sticker_menu, {y: 880}, 0.3, {
			onComplete: function(twn:FlxTween)
			{
				sticker_menu_tween = null;
				sticker_menu.loadGraphic(Paths.get('charselect-mini-full.png'));
			},
			ease: FlxEase.smootherStepInOut
		});
	}

	function on_sticker_menu_out(btn:HoverButton)
	{
		if (sticker_menu.scale.x != 1)
			sticker_menu.scale.set(1, 1);
		sticker_menu_tween = FlxTween.tween(sticker_menu, {y: sticker_menu_y}, 0.4, {
			onComplete: function(twn:FlxTween)
			{
				sticker_menu_tween = null;
				sticker_menu.loadGraphic(Paths.get('charselect-mini-full.png'));
			},
			ease: FlxEase.elasticOut
		});
	}

	function open_sticker_menu(btn:HoverButton)
	{
		hide_top_ui();
		if (sticker_menu_tween != null)
			sticker_menu_tween.cancel();
		Ctrl.mode = ControlModes.NONE;
		sticker_menu_tween = FlxTween.tween(sticker_menu, {y: 1180}, 0.3, {
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
				sticker_menu_tween = null;
			}
		});
	}

	function get_player():Player
		return PlayState.self.player;

	/**The mouse is hovering over any of the ui elements, if so, don't let touch inputs happen*/
	public function mouse_is_over_ui():Bool
	{
		var mouse_over_no_no_zone:Bool = false;
		for (member in members)
		{
			if (!member.visible)
				continue;
			if (FlxG.mouse.overlaps(member))
			{
				mouse_over_no_no_zone = true;
				break;
			}
		}
		return mouse_over_no_no_zone;
	}
}

private enum abstract State(String) from String to String
{
	var ALL_ACTIVE;
	var SUB_MENU_ACTIVE;
}
