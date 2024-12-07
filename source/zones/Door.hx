package zones;

import entities.Player;
import flixel.math.FlxVelocity;
import fx.CircleTransition;
import ldtk.Json.EntityReferenceInfos;
import states.PlayState;

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

	var door_travel_dist:Int = 100;

	var entering_player:Player;

	public function new(?X:Float, ?Y:Float, width:Int, height:Int, linked_door_ref:EntityReferenceInfos, spawn:FlxPoint, iid:String)
	{
		super(X, Y);

		this.linked_door_ref = linked_door_ref;
		this.iid = iid;

		this.spawn = spawn;

		makeGraphic(width, height, FlxColor.YELLOW);
		alpha = 0.5;

		#if !show_zones
		visible = false;
		#end

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
				if (PlayState.self.player.can_enter_doors && overlaps(PlayState.self.player))
					start_door_out(PlayState.self.player);
			case DOOR_OUT:
				// PUT TRANSITION HERE
				sstate(WAIT);
				Ctrl.mode = ControlModes.NONE;
				FlxG.camera.fade(FlxColor.BLACK, 0.8, false);
				FlxG.state.add(new CircleTransition(PlayState.self.player, 0.85, true, post_circle_transition_out));
				player_enter_door_anim();
			case DOOR_IN:
				PlayState.self.player.center_on(spawn);
				PlayState.self.update_scroll_bounds();
				FlxG.camera.fade(FlxColor.BLACK, 0.8, true);
				FlxG.state.add(new CircleTransition(PlayState.self.player, 0.85, false, function()
				{
					Ctrl.mode = ControlModes.OVERWORLD;
				}));
				player_exit_door_anim();
				sstate(IDLE);
		}

	function start_door_out(player:Player)
	{
		for (world in Main.ldtk_project.worlds)
			if (world.iid == linked_door_ref.worldIid)
				next_world = world.identifier;

		same_world_door = next_world == PlayState.self.current_world;

		level_transition_door_iid = linked_door_ref.entityIid;

		sstate(DOOR_OUT, fsm);
	}

	function dip_to_same_world()
		for (door in PlayState.self.doors)
			if (door.iid == level_transition_door_iid)
				door.start_door_in();

	public function start_door_in()
	{
		sstate(DOOR_IN);
	}

	function player_enter_door_anim()
	{
		var player:Player = PlayState.self.player;

		player.immovable = true;
		player.enter_door();

		var destination:FlxPoint = player.getPosition().copy();
		destination.add(player.mp.x > mp.x ? -door_travel_dist : door_travel_dist);

		player.tween = FlxTween.tween(player, {x: destination.x, y: destination.y}, 0.8);
	}

	function player_exit_door_anim()
	{
		// do not judge me for what I do here :(
		var player:Player = PlayState.self.player;
		player.center_on(spawn);

		var destination:FlxPoint = player.getPosition().copy();
		destination.add(spawn.x > mp.x ? -door_travel_dist : door_travel_dist);

		player.immovable = true;
		player.center_on_x(this);
		player.exit_door();

		player.tween = FlxTween.tween(player, {x: destination.x, y: destination.y}, 0.8, {
			onComplete: function(t)
			{
				player.immovable = false;
				player.sstate("NEUTRAL");
			}
		});
	}

	function dip_to_different_world()
		FlxG.switchState(new PlayState(next_world));

	override function kill()
	{
		PlayState.self.doors.remove(this, true);
		super.kill();
	}

	function post_circle_transition_out()
	{
		sstate(IDLE);
		same_world_door ? dip_to_same_world() : dip_to_different_world();
	}
}

private enum abstract State(String) from String to String
{
	var IDLE;
	var DOOR_OUT;
	var DOOR_IN;
	var WAIT;
}
