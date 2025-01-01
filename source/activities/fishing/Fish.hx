package activities.fishing;

import flixel.graphics.FlxAsepriteUtil;

enum abstract FishType(Int) to Int
{
	var None = -1;
	var Basic = 0; //
	var LilBlue = 1; //
	var Webfish = 2; //
	var Squid = 4; //
	var Crabby = 5; //
	var TankFish = 6; //
	var Picounder = 7; //
	var Boyfrish = 8; //
	var Maddie = 9; //
	var HalloweenGuy = 10; //
	var SkeletonGuy = 11; //
	var PunchFish = 12; //
	var Redvil = 13; //
}

enum abstract FishZone(Int) from Int to Int
{
	var Shallow = 0;
	var Medium = 1;
	var Deep = 2;
}

class Fish extends FlxSprite
{
	var type:FishType = LilBlue;
	var perfection_percent:Float = 0.0;

	static final fish_zones:Map<FishZone, Array<FishType>> = [
		FishZone.Shallow => [Basic, LilBlue, Webfish, Squid],
		FishZone.Medium => [Crabby, Picounder, Boyfrish, Squid],
		Deep => [PunchFish, HalloweenGuy, SkeletonGuy, TankFish, Maddie, Redvil],
	];

	public function new()
	{
		super();
		FlxAsepriteUtil.loadAseAtlas(this, AssetPaths.fishes__png, AssetPaths.fishes__json);
		randomize_fish(Deep);
	}

	public function randomize_fish(zone:FishZone, perfection_percent = 0.0)
	{
		var fish_array = fish_zones[zone];
		this.type = fish_array[Std.int(Math.random() * fish_array.length)];
		this.perfection_percent = perfection_percent;
		if (type != None)
		{
			animation.frameIndex = this.type;
		}
	}
}
