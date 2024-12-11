package ui.button;

import flixel.system.FlxAssets.FlxGraphicAsset;

class HoverButton extends FlxSpriteExt
{
	public var on_release:HoverButton->Void;
	public var on_hover:HoverButton->Void;
	public var on_neutral:HoverButton->Void;

	var enabled:Bool = true;

	public var manual_button_hover:Bool = false;

	public function new(?X:Float = 0, ?Y:Float = 0, ?SimpleGraphic:FlxGraphicAsset, ?on_release:HoverButton->Void)
	{
		super(X, Y, SimpleGraphic);
		this.on_release = on_release;
	}

	override function update(elapsed:Float)
	{
		var hovering:Bool = FlxG.mouse.overlaps(this) && enabled || manual_button_hover;
		var hover_scale:Float = hovering ? 1.1 : 1;

		if (hovering)
			if (on_hover != null)
				on_hover(this);
		if (!hovering)
			if (on_neutral != null)
				on_neutral(this);

		if (FlxG.mouse.pressed && hovering)
			hover_scale = 1.35;

		scale.set(hover_scale, hover_scale);

		if (hovering && FlxG.mouse.justReleased)
			if (on_release != null)
				on_release(this);

		super.update(elapsed);
	}

	public function disable()
		enabled = false;

	public function enable()
		enabled = true;
}
