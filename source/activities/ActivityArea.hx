package activities;

import activities.ActivityAreaInstance;
import activities.bonfire.BonfireArea;
import activities.fishing.FishingAreaInstance;
import entities.Player;
import entities.base.BaseUser;
import haxe.Constraints;
import levels.LDTKLevel;
import levels.TankmasLevel;
import net.tankmas.NetDefs.NetEventDef;

typedef ActivityType = levels.LdtkProject.Enum_ActivityType;

enum AreaShape
{
	Circle;
	Rectangle;
}

class ActivityArea extends FlxSprite
{
	var active_players:Map<String, ActivityAreaInstance> = new Map();
	var activity_type:ActivityType;
	var shape:AreaShape;

	public function new(type:ActivityType, X, Y, w, h, shape = AreaShape.Circle)
	{
		super(X, Y);
		this.activity_type = type;
		height = h;
		width = w;
		this.shape = shape;
		PlayState.self.activity_areas.add(this);
	}

	public function in_area(x:Float, y:Float)
	{
		switch (shape)
		{
			case Circle:
				var dx = x - this.x;
				var dy = y - this.y;
				var r = width * 0.5;
				var rr = r * r;
				var dist_sq = dx * dx + dy * dy;
				return dist_sq < rr;
			case Rectangle:
				if (x < this.x)
					return false;
				if (y < this.y)
					return false;
				if (x > this.x + width)
					return false;
				if (y > this.y + height)
					return false;
				return true;
		}
		return false;
	}

	function create_instance(player:BaseUser):ActivityAreaInstance
	{
		switch (activity_type)
		{
			case Bonfire:
				return new BonfireArea(player, this);
			case Fishing:
				return new FishingAreaInstance(player, this);
		}
	}

	public function on_enter(player:BaseUser)
	{
		if (active_players[player.username] != null)
			return;

		var area = create_instance(player);

		active_players[player.username] = area;
	}

	public function on_leave(player:BaseUser)
	{
		var area = active_players[player.username];
		if (area == null)
			return;

		area.on_leave();
		active_players[player.username] = null;
	}

	public function on_event(event:NetEventDef, player:BaseUser)
	{
		var area_user_instance = active_players[player.username];
		if (area_user_instance == null)
			return;
		area_user_instance.on_event(event);
	}

	// Happens when the local player presses the interact button
	public function on_interact(player:Player)
	{
		var area = active_players[player.username];
		if (area == null)
			return;
		area.on_interact();
	}

	override function kill()
	{
		PlayState.self.activity_areas.remove(this, true);
		super.kill();
	}
}
