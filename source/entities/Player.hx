package entities;

import data.JsonData;
import data.SaveManager;
import data.types.TankmasDefs.CostumeDef;
import data.types.TankmasEnums.PlayerAnimation;
import entities.Interactable;
import entities.base.BaseUser;
import flixel.math.FlxVelocity;
import minigames.MinigameHandler;
import net.tankmas.NetDefs.NetUserDef;
import net.tankmas.OnlineLoop;

class Player extends BaseUser
{
	var move_no_input_drag:Float = 0.9;
	var move_reverse_mod:Float = 3;

	var last_update_json:NetUserDef;

	static var debug_costume_rotation:Array<CostumeDef>;

	public static var has_sticker_pack:Bool = true;

	var auto_moving:Bool = false;
	var auto_move_dest:FlxPoint;
	final auto_move_deadzone:Int = 32;

	var wavedash_cd:Int = 0;

	var prev_velocity:FlxPoint = new FlxPoint();

	public var can_enter_doors(get, default):Bool;

	public function new(?X:Float, ?Y:Float)
	{
		super(X, Y, Main.username);

		/*
			debug_costume_rotation = JsonData.all_costume_defs.copy();
			costume = debug_costume_rotation[0];

			while (costume.name != "tankman")
			{
				debug_rotate_costumes();
				trace(costume.name);
			}

			#if vanity
			while (costume.name != "sodaman")
				debug_rotate_costumes();
			#end
		 */

		last_update_json = {username: username};

		type = "player";

		PlayState.self.player = this;

		sprite_anim.anim(PlayerAnimation.MOVING);

		sstate(NEUTRAL);
	}

	// Called once the save data is up to date after fetching it from the server.
	public function on_save_loaded()
	{
		var saved_costume_name = SaveManager.current_costume;
		var costume = JsonData.get_costume(saved_costume_name);
		if (costume == null)
			costume = JsonData.get_costume("tankman");

		new_costume(costume);
	}

	public function start_auto_move(auto_move_dest:FlxPoint)
	{
		this.auto_move_dest = auto_move_dest.copy();
		auto_moving = true;
	}

	function debug_rotate_costumes()
	{
		costume = debug_costume_rotation[0];
		debug_costume_rotation.push(debug_costume_rotation.shift());
		new_costume(costume);
	}

	override public function new_costume(costume:CostumeDef)
		super.new_costume(costume);

	override function update(elapsed:Float)
	{
		nameTag.text = Main.username;
		/**if (Main.DEV && Ctrl.any(Ctrl.menu))
			debug_rotate_costumes();**/

		if (wavedash_cd > 0)
			wavedash_cd--;

		fsm();
		super.update(elapsed);
	}

	override function updateMotion(elapsed:Float)
	{
		if (prev_velocity.x > 0 && velocity.x < 0 || prev_velocity.x < 0 && velocity.x > 0)
		{
			if (wavedash_cd < 300)
				wavedash_cd += 35;
			if (wavedash_cd >= 150)
				SoundPlayer.alt_sound("controller", true, ["controller-1", "controller-2", "controller-3", "controller-4"]);
		}
		prev_velocity.copyFrom(velocity);

		super.updateMotion(elapsed);
	}

	function fsm()
		switch (cast(state, State))
		{
			case NEUTRAL:
				general_movement();
				process_activity_area();
				detect_interactables();
			case JUMPING:
			case EMOTING:
			case ENTERING_DOOR:
				sprite_anim.anim(PlayerAnimation.MOVING);
			case EXITING_DOOR:
				sprite_anim.anim(PlayerAnimation.MOVING);
		}

	function general_movement()
	{
		var UP:Bool = Ctrl.up[1];
		var DOWN:Bool = Ctrl.down[1];
		var LEFT:Bool = Ctrl.left[1];
		var RIGHT:Bool = Ctrl.right[1];

		final NO_KEYS:Bool = !UP && !DOWN && !LEFT && !RIGHT;

		// if any key pressed, cancel auto_move
		if (!NO_KEYS || Ctrl.jemote[1] || !Ctrl.mode.can_move)
			auto_moving = false;

		if (Ctrl.jemote[1] && !MinigameHandler.instance.is_minigame_active())
			use_sticker(SaveManager.current_emote);

		if (auto_moving)
			auto_movement(UP, DOWN, LEFT, RIGHT, NO_KEYS);
		else
			manual_movement(UP, DOWN, LEFT, RIGHT, NO_KEYS);

		var moving:Bool = !NO_KEYS && Ctrl.mode.can_move || auto_moving;

		// keeping the sheet menus right next to each other makes sense, no?

		move_animation_handler(moving);

		// move_animation_handler(velocity.x.abs() + velocity.y.abs() > 10);
	}

	function auto_movement(UP:Bool, DOWN:Bool, LEFT:Bool, RIGHT:Bool, NO_KEYS:Bool)
	{
		// only move if we're not within deadzones
		var within_x_deadzone:Bool = Math.abs(auto_move_dest.x - mp.x) <= auto_move_deadzone;
		var within_y_deadzone:Bool = Math.abs(auto_move_dest.y - mp.y) <= auto_move_deadzone;

		/*
			if (!within_x_deadzone)
			{
				LEFT = auto_move_dest.x < mp.x;
				RIGHT = !RIGHT;
			}
			if (!within_y_deadzone)
			{
				UP = auto_move_dest.y < mp.y;
				DOWN = !UP;
		}*/
		FlxVelocity.moveTowardsPoint(this, auto_move_dest, move_speed);

		flipX = velocity.x > 0;

		// normally we'd snap to position on this deadzone condition but we can do that later cause you could use it to clip through walls
		// if we're not careful
		if (within_x_deadzone && within_y_deadzone)
		{
			velocity.scale(0.5, 0.5);
			auto_moving = false;
		}

		// manual_movement(UP, DOWN, LEFT, RIGHT, NO_KEYS);
	}

	function manual_movement(UP:Bool, DOWN:Bool, LEFT:Bool, RIGHT:Bool, NO_KEYS:Bool)
	{
		if (Ctrl.mode.can_move)
		{
			var reversing_x:Bool = velocity.x > 0 && LEFT || velocity.x < 0 && RIGHT;
			var reversing_y:Bool = velocity.y > 0 && UP || velocity.y < 0 && DOWN;

			var move_speed_x:Float = move_speed / move_acl * (reversing_x ? move_reverse_mod : 1);
			var move_speed_y:Float = move_speed / move_acl * (reversing_y ? move_reverse_mod : 1);

			if (UP)
				velocity.y -= move_speed_y;
			else if (DOWN)
				velocity.y += move_speed_y;

			if (LEFT)
				velocity.x -= move_speed_x;
			else if (RIGHT)
				velocity.x += move_speed_x;

			if (LEFT || RIGHT)
				flipX = RIGHT;

			if (!LEFT && !RIGHT)
				velocity.x = velocity.x * move_no_input_drag;
			if (!UP && !DOWN)
				velocity.y = velocity.y * move_no_input_drag;
		}
	}

	function post_start_stop()
	{
		final MOVING:Bool = velocity.x.abs() + velocity.y.abs() > 10;
		sprite_anim.anim(MOVING ? PlayerAnimation.MOVING : PlayerAnimation.IDLE);
	}

	function process_activity_area()
	{
		if (active_activity_area == null)
			return;
		if (Ctrl.jinteract[1] || FlxG.mouse.overlaps(active_activity_area) && FlxG.mouse.justReleased)
		{
			active_activity_area.on_interact(this);
		}
	}

	var active_interactable:Interactable;

	// returns true if either in an activity area, or if close to an interactable.
	// If false, the use button can be used for other stuff
	public function interact_in_use()
	{
		return active_activity_area != null || (active_interactable != null && active_interactable.interactable);
	}

	function detect_interactables()
	{
		// Disable interactions if in activity area
		if (active_activity_area != null)
		{
			Interactable.unmark_all(PlayState.self.interactables);
			return;
		}

		var closest:Interactable = Interactable.find_closest_in_array(this, Interactable.find_in_detect_range(this, PlayState.self.interactables));
		var target_changed = closest != active_interactable;

		if (target_changed && active_interactable != null)
		{
			active_interactable.marked = false;
		}

		if (closest == null)
		{
			active_interactable = null;
			return;
		}

		switch (cast(closest.type, InteractableType))
		{
			case InteractableType.NPC:
				// nothin
			case InteractableType.PRESENT:
				// nothin
			case InteractableType.MINIGAME:
				// nothin
		}

		closest.marked = true;
		active_interactable = closest;

		if (Ctrl.jinteract[1] || FlxG.mouse.overlaps(this) && FlxG.mouse.justReleased)
		{
			active_interactable.on_interact();
		}
	}

	override function kill()
	{
		PlayState.self.player = null;
		super.kill();
	}

	override function use_sticker(sticker_name:String):Bool
	{
		var sticker_got_used:Bool = super.use_sticker(sticker_name);
		#if !offline
		if (sticker_got_used)
			OnlineLoop.post_sticker(sticker_name);
		#end
		return sticker_got_used;
	}

	public function get_user_update_json(force_send_full_user:Bool = false):NetUserDef
	{
		var def:NetUserDef = {username: username, room_id: Main.current_room_id};
		var new_sx = flipX ? -1 : 1;
		if (last_update_json.x != x.floor() || force_send_full_user)
		{
			def.x = x.floor();
			def.sx = new_sx;
		}

		if (last_update_json.y != y.floor() || force_send_full_user)
			def.y = y.floor();

		if (last_update_json.costume != costume.name || force_send_full_user)
			def.costume = costume.name;

		last_update_json = {
			username: username,
			x: x.floor(),
			y: y.floor(),
			sx: new_sx,
			costume: costume.name
		};

		// When sending full players,
		// Also request the state of all other players
		// in the room at the same time.
		if (force_send_full_user)
			def.request_full_room = true;

		return def;
	}

	public function enter_door()
		sstate(ENTERING_DOOR);

	public function exit_door()
		sstate(EXITING_DOOR);

	function get_can_enter_doors():Bool
		return ![ENTERING_DOOR, EXITING_DOOR].contains(state);
}

private enum abstract State(String) from String to String
{
	final NEUTRAL;
	final JUMPING;
	final EMOTING;
	final ENTERING_DOOR;
	final EXITING_DOOR;
}
