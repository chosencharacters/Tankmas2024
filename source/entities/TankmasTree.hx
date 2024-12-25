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
		if (PlayState.self.player.pixel_overlaps(this))
			alpha -= 0.01;
		else
			alpha += 0.01;

		if (alpha > 1)
			alpha = 1;
		if (alpha < 0.25)
			alpha = 0.25;

		super.update(elapsed);
	}

	override function kill()
	{
		PlayState.self.world_objects.remove(this, true);

		super.kill();
	}
}
