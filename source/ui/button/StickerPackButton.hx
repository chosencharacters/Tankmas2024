package ui.button;

import data.JsonData;
import data.SaveManager;
import ui.popups.StickerPackOpening;

class StickerPackButton extends HoverButton
{
	var rare:Bool = false;

	public function new(?X:Float, ?Y:Float)
	{
		super(X, Y);
		on_pressed = open_sticker_pack;
		// sticker_pack.setPosition(20, FlxG.height - sticker_pack.height - 20);

		rare = SaveManager.has_rare_emote_pack;
		visible = rare;

		loadAllFromAnimationSet(rare ? "rare-sticker-pack-icon" : "sticker-pack-icon");
	}

	override function update(elapsed:Float)
	{
		rare = SaveManager.has_rare_emote_pack;
		visible = rare;

		super.update(elapsed);
	}

	function open_sticker_pack(btn:HoverButton)
	{
		if (!visible)
			return;
		Ctrl.mode = ControlModes.NONE;

		tween = FlxTween.tween(this, {y: FlxG.height + height}, 0.25, {
			onComplete: (t) -> FlxG.state.add(new StickerPackOpening(JsonData.random_draw_emotes(Main.rare_emote_draw_amount), rare))
		});
	}
}
