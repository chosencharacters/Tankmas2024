package levels;

import flixel.tile.FlxTilemap;
import levels.LdtkProject.LdtkProject_Level;

class LDTKLevel extends FlxTilemap
{
	public var tile_size:Int = 32;

	var lvl_width:Int = 0;
	var lvl_height:Int = 0;
	var array_len:Int = 0;

	public function new(level_name:String, tilesheet_graphic:String)
	{
		super();
		generate(level_name, tilesheet_graphic);
	}

	function generate(level_name:String, tilesheet_graphic:String)
	{
		if (tilesheet_graphic == null)
			return;

		var data:LdtkProject_Level = get_level_by_name(level_name);

		lvl_width = Math.floor(data.pxWid / tile_size);
		lvl_height = Math.floor(data.pxHei / tile_size);
		array_len = lvl_width * lvl_height;

		var layer_name:String = "Collision";

		var layer = data.resolveLayer(layer_name);

		var int_grid:Array<Int> = [];

		lvl_width = layer.cWid;
		lvl_height = layer.cHei;

		for (x in 0...lvl_width)
			for (y in 0...lvl_height)
			{
				var tile = switch (layer_name)
				{
					case "Tiles":
						data.l_Tiles.getTileStackAt(x, y);
					default:
						null;
				}

				var index:Int = Math.floor(x + y * lvl_width);
				int_grid[index] = tile.length > 0 ? tile[0].tileId : 0;
			}

		array_len = int_grid.length;
		loadMapFromArray(int_grid, lvl_width, lvl_height, tilesheet_graphic, tile_size, tile_size);
	}

	function get_level_by_name(level_name:String):LdtkProject_Level
	{
		for (world in Main.ldtk_project.worlds)
			for (level in world.levels)
				if (level.identifier == level_name)
					return level;
		throw "level does not exist by the name of '" + level_name + "'";
	}
}
