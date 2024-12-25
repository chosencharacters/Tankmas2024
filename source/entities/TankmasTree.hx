package entities;

import states.PlayState.YSortable;

class TankmasTree extends YSortable
{
	public function new(?X:Float, ?Y:Float)
	{
		super(X, Y);

		PlayState.self.world_objects.add(this);

		loadGraphic(Paths.image_path("tankmas-tree"));
	}

	override function update(elapsed:Float)
	{
		alpha += 0.01;

		if (PlayState.self.player.overlaps(this) && PlayState.self.player.bottom_y < y + height - 300)
			alpha -= 0.02;

		if (alpha > 1)
			alpha = 1;
		if (alpha < 0.35)
			alpha = 0.35;

		super.update(elapsed);
	}

	override function kill()
	{
		PlayState.self.world_objects.remove(this, true);

		super.kill();
	}
}
