package zones;

import ldtk.Json.EntityReferenceInfos;
import ldtk.Point;
import ldtk.Project;

/**
 * Sigh here we go again
 */
class Door extends FlxSpriteExt
{
	var linked_door_ref:EntityReferenceInfos;
	var spawn:FlxPoint;

	var next_world:String;

	static var level_transition_door_iid:String = "";

	var same_world_door:Bool = false;

	public function new(?X:Float, ?Y:Float, width:Int, height:Int, linked_door_ref:EntityReferenceInfos, spawn:FlxPoint, iid:String)
	{
		super(X, Y);

		this.linked_door_ref = linked_door_ref;
		this.iid = iid;

		this.spawn = spawn;

		makeGraphic(width, height, FlxColor.YELLOW);
		alpha = 0.5;

		PlayState.self.doors.add(this);

		sstate(IDLE);
		if (level_transition_door_iid == iid)
			start_door_in();
	}

	override function update(elapsed:Float)
	{
		fsm();
		super.update(elapsed);
	}

	function fsm()
		switch (cast(state, State))
		{
			default:
			case IDLE:
				if (overlaps(PlayState.self.player))
					start_door_out();
			case DOOR_OUT:
				// PUT TRANSITION HERE
				sstate(WAIT);
				same_world_door ? dip_to_same_world() : dip_to_different_world();
			case DOOR_IN:
				PlayState.self.player.center_on(spawn);
				PlayState.self.update_scroll_bounds();
				sstate(IDLE);
		}

	function start_door_out()
	{
		for (world in Main.ldtk_project.worlds)
			if (world.iid == linked_door_ref.worldIid)
				next_world = world.identifier;

		same_world_door = next_world == PlayState.self.current_world;

		level_transition_door_iid = linked_door_ref.entityIid;

		sstate(DOOR_OUT, fsm);
	}

	function dip_to_same_world()
	{
		for (door in PlayState.self.doors)
		{
			if (door.iid == level_transition_door_iid)
				door.start_door_in();
		}
	}

	public function start_door_in()
	{
		sstate(DOOR_IN);
	}

	function dip_to_different_world()
		FlxG.switchState(new PlayState(next_world));

	override function kill()
	{
		PlayState.self.doors.remove(this, true);
		super.kill();
	}
}

private enum abstract State(String) from String to String
{
	var IDLE;
	var DOOR_OUT;
	var DOOR_IN;
	var WAIT;
}
