package physics;

import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxTileFrames;
import flixel.tile.FlxTilemap;
import differ.shapes.Shape;
import differ.data.ShapeCollision;
import differ.math.Vector;
import differ.Collision;
import differ.shapes.Polygon;
import differ.shapes.Circle;
import lime.math.Rectangle;

class CollisionResolver
{
	var shapes:Array<differ.shapes.Shape> = [];

	// var col:FlxTileFrames;

	public function new()
	{
		// var g = FlxGraphic.fromAssetKey(AssetPaths.tile_collision__png);
		// col = FlxTileFrames.fromGraphic(g, new FlxPoint(32, 32));
	}

	public function add_circle(x:Float, y:Float, r:Float)
	{
		shapes.push(new Circle(x, y, r));

		/*
			var sp = new FlxSprite(x, y);
			sp.setFrames(col);
			sp.setGraphicSize(r * 2, r * 2);
			sp.frame = col.getByTilePosition(0, 1);
			PlayState.self.objects.add(sp);
		 */
	}

	public function add_rect(x:Float, y:Float, w:Float, h:Float)
	{
		shapes.push(Polygon.rectangle(x, y, w, h, false));

		/*
			var sp = new FlxSprite(x + w * 0.5, y + h * 0.5);
			sp.setFrames(col);
			sp.setGraphicSize(w, h);
			sp.frame = col.getByTilePosition(1, 0);
			PlayState.self.objects.add(sp);
		 */
	}

	public function add_slope_ne(x:Float, y:Float, w:Float, h:Float)
	{
		var vertices:Array<Vector> = new Array<Vector>();
		vertices.push(new Vector(0, 0));
		vertices.push(new Vector(w, h));
		vertices.push(new Vector(0, h));

		shapes.push(new Polygon(x, y, vertices));
	}

	public function add_slope_nw(x:Float, y:Float, w:Float, h:Float)
	{
		var vertices:Array<Vector> = new Array<Vector>();
		vertices.push(new Vector(w, 0));
		vertices.push(new Vector(w, h));
		vertices.push(new Vector(0, h));
		shapes.push(new Polygon(x, y, vertices));
	}

	public function add_slope_se(x:Float, y:Float, w:Float, h:Float)
	{
		var vertices:Array<Vector> = new Array<Vector>();
		vertices.push(new Vector(0, 0));
		vertices.push(new Vector(w, 0));
		vertices.push(new Vector(0, h));
		shapes.push(new Polygon(x, y, vertices));
	}

	public function add_slope_sw(x:Float, y:Float, w:Float, h:Float)
	{
		var vertices:Array<Vector> = new Array<Vector>();
		vertices.push(new Vector(0, 0));
		vertices.push(new Vector(w, 0));
		vertices.push(new Vector(w, h));
		shapes.push(new Polygon(x, y, vertices));
	}

	public function resolve_circle(shape:Circle)
	{
		var moved = false;
		var sx = shape.x;
		var sy = shape.y;
		var hit_shapes:Array<Shape> = [];

		// Just move the shape out of any other shape, resolve up to 5 times but break if no collision exists anymore.
		for (tests in 0...5)
		{
			var test = Collision.shapeWithShapes(shape, shapes);
			if (test.length == 0)
				break;

			var closest:ShapeCollision = null;

			var closest_dist = 9999.0;
			for (coll in test)
			{
				if (hit_shapes.contains(coll.shape2))
					continue;

				moved = true;
				if (coll.overlap < closest_dist)
				{
					closest = coll;
					closest_dist = coll.overlap;
				}
			}

			if (closest != null)
			{
				shape.x += closest.separationX;
				shape.y += closest.separationY;
				hit_shapes.push(closest.shape2);
			}
			else
			{
				break;
			}
		}

		return moved ? {"dx": shape.x - sx, "dy": shape.y - sy} : null;
	}

	public function clear()
	{
		shapes = [];
	}
}
