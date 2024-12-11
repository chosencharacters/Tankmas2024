package physics;

import differ.Collision;
import differ.shapes.Polygon;
import differ.shapes.Circle;
import lime.math.Rectangle;

class CollisionResolver
{
	var shapes:Array<differ.shapes.Shape> = [];

	public function new() {}

	public function add_circle(x:Float, y:Float, r:Float)
	{
		shapes.push(new Circle(x, y, r));
	}

	public function add_rect(x:Float, y:Float, w:Float, h:Float)
	{
		shapes.push(Polygon.rectangle(x, y, w, h, false));
	}

	public function resolve_circle(shape:Circle)
	{
		var moved = false;
		var sx = shape.x;
		var sy = shape.y;
		// Just move the shape out of any other shape, resolve up to 5 times but break if no collision exists anymore.
		for (tests in 0...5)
		{
			var test = Collision.shapeWithShapes(shape, shapes);
			for (coll in test)
			{
				shape.x += coll.separationX;
				shape.y += coll.separationY;
				moved = true;
				continue;
			}

			if (test.length == 0)
				break;
		}

		return moved ? {"dx": shape.x - sx, "dy": shape.y - sy} : null;
	}

	public function clear()
	{
		shapes = [];
	}
}
