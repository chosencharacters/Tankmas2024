package ui.button;

import flixel.system.FlxAssets.FlxGraphicAsset;

class HoverButton extends FlxSpriteExt
{
	public var on_pressed:HoverButton->Void;
	public var on_hover:HoverButton->Void;
	public var on_neutral:HoverButton->Void;

	var enabled:Bool = true;

	var is_pressed = false;
	var is_hovered = false;

	public function new(?X:Float = 0, ?Y:Float = 0, ?SimpleGraphic:FlxGraphicAsset, ?on_pressed:HoverButton->Void)
	{
		super(X, Y, SimpleGraphic);
		this.on_pressed = on_pressed;
	}

	override function update(elapsed:Float)
	{
		var mouse_down = FlxG.mouse.pressed;
		var hovering:Bool = FlxG.mouse.overlaps(this) && enabled;
		var hover_scale:Float = (hovering && !mouse_down) ? 1.1 : 1;

		if (FlxG.mouse.justPressed && hovering)
			is_pressed = true;
		else if (!hovering && !mouse_down)
			is_pressed = false;

		var hover_enabled = !mouse_down || (mouse_down && is_pressed);

		if (hovering && hovering != is_hovered && hover_enabled)
			if (on_hover != null)
				on_hover(this);
		if (!hovering && hovering != is_hovered && hover_enabled)
			if (on_neutral != null)
				on_neutral(this);

		if (FlxG.mouse.pressed && hovering && is_pressed)
			hover_scale = 1.35;

		scale.set(hover_scale, hover_scale);

		if (hovering && FlxG.mouse.justReleased)
		{
			if (is_pressed && on_pressed != null)
				on_pressed(this);

			is_pressed = false;
		}

		is_hovered = hovering;

		super.update(elapsed);
	}

	public function disable()
		enabled = false;

	public function enable()
		enabled = true;
}
