package ui.button;

import flixel.system.FlxAssets.FlxGraphicAsset;

class HoverButton extends FlxSpriteExt
{
	public var on_release:HoverButton->Void;

	var enabled:Bool = true;

	public function new(?X:Float = 0, ?Y:Float = 0, ?SimpleGraphic:FlxGraphicAsset, ?on_release:HoverButton->Void)
	{
		super(X, Y, SimpleGraphic);
		this.on_release = on_release;
	}

	override function update(elapsed:Float)
	{
		var overlapping:Bool = FlxG.mouse.overlaps(this) && enabled;
		var overlap_scale:Float = overlapping ? 1.1 : 1;

		if (FlxG.mouse.pressed && overlapping)
			overlap_scale = 1.35;

		scale.set(overlap_scale, overlap_scale);

		if (overlapping && FlxG.mouse.justReleased)
			if (on_release != null)
				on_release(this);

		super.update(elapsed);
	}

	public function disable()
		enabled = false;

	public function enable()
		enabled = true;
}
