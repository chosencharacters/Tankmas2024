package ui.button;

import flixel.system.FlxAssets.FlxGraphicAsset;

class HoverButton extends FlxSpriteExt
{
	public var on_pressed:HoverButton->Void;
	public var on_released:HoverButton->Void;
	public var on_hover:HoverButton->Void;
	public var on_neutral:HoverButton->Void;

	public var enabled:Bool = true;

	var is_pressed = false;
	var is_hovered = false;

	public var manual_button_hover:Bool = false;

	public var base_scale:Float = 1;

	public var pixel_perfect:Bool = false;

	public var no_scale:Bool = false;

	public function new(?X:Float = 0, ?Y:Float = 0, ?SimpleGraphic:FlxGraphicAsset, ?on_released:HoverButton->Void)
	{
		super(X, Y, SimpleGraphic);
		this.on_released = on_released;
	}

	override function update(elapsed:Float)
	{
		var mouse_down = FlxG.mouse.pressed;
		var hovering:Bool = enabled
			&& (!pixel_perfect && FlxG.mouse.overlaps(this))
			|| (pixel_perfect && pixelsOverlapPoint(FlxG.mouse.getPosition()));

		var hover_scale:Float = base_scale * ((hovering && !mouse_down || manual_button_hover) ? 1.1 : 1);

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
			hover_scale = base_scale * 1.35;

		if (!no_scale)
			scale.set(hover_scale, hover_scale);

		if (hovering && FlxG.mouse.justPressed)
			if (on_pressed != null)
				on_pressed(this);

		if (hovering && FlxG.mouse.justReleased)
		{
			if (is_pressed && on_released != null)
				on_released(this);

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
