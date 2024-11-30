package entities;

import data.JsonData;
import data.types.TankmasDefs.CostumeDef;
import data.types.TankmasEnums.PlayerAnimation;
import entities.Interactable;
import entities.base.BaseUser;
import net.tankmas.NetDefs.NetUserDef;
import net.tankmas.OnlineLoop;

class Player extends BaseUser
{
	var move_no_input_drag:Float = 0.9;
	var move_reverse_mod:Float = 3;

	var last_update_json:NetUserDef;

	static var debug_costume_rotation:Array<CostumeDef>;

	/**We send this once*/
	public var queued_online_sticker:String;

	public var sticker:String = "common-tamago";

	public function new(?X:Float, ?Y:Float)
	{
		super(X, Y, Main.username);

		debug_costume_rotation = JsonData.all_costume_defs.copy();
		costume = debug_costume_rotation[0];

		while (costume.name != "tankman")
			debug_rotate_costumes();

		#if vanity
		while (costume.name != "sodaman")
			debug_rotate_costumes();
		#end

		last_update_json = {name: username};

		type = "player";

		PlayState.self.player = this;

		sprite_anim.anim(PlayerAnimation.MOVING);

		sstate(NEUTRAL);
	}

	function debug_rotate_costumes()
	{
		if (!Main.DEV)
			return;
		costume = debug_costume_rotation[0];
		debug_costume_rotation.push(debug_costume_rotation.shift());
		new_costume(costume);
	}

	override public function new_costume(costume:CostumeDef)
		super.new_costume(costume);

	override function update(elapsed:Float)
	{
		if (Main.DEV && Ctrl.any(Ctrl.jaction) && !interact_in_use())
			debug_rotate_costumes();

		fsm();
		super.update(elapsed);
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
		}

	function general_movement()
	{
		final UP:Bool = Ctrl.up[1];
		final DOWN:Bool = Ctrl.down[1];
		final LEFT:Bool = Ctrl.left[1];
		final RIGHT:Bool = Ctrl.right[1];
		final NO_KEYS:Bool = !UP && !DOWN && !LEFT && !RIGHT;

		if (Ctrl.jspecial[1])
			use_sticker(sticker);
		// keeping the sheet menus right next to each other makes sense, no?

		if (UP)
			velocity.y -= move_speed / move_acl * (velocity.y > 0 ? 1 : move_reverse_mod);
		else if (DOWN)
			velocity.y += move_speed / move_acl * (velocity.y < 0 ? 1 : move_reverse_mod);

		if (LEFT)
			velocity.x -= move_speed / move_acl * (velocity.x > 0 ? 1 : move_reverse_mod);
		else if (RIGHT)
			velocity.x += move_speed / move_acl * (velocity.x < 0 ? 1 : move_reverse_mod);

		if (!LEFT && !RIGHT)
			velocity.x = velocity.x * .95;
		else
			flipX = RIGHT;
		// flipX = velocity.x > 0;

		if (!UP && !DOWN)
			velocity.y = velocity.y * move_no_input_drag;

		move_animation_handler(!NO_KEYS);

		// move_animation_handler(velocity.x.abs() + velocity.y.abs() > 10);
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
		if (Ctrl.jaction[1])
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

		if (Ctrl.jaction[1])
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
			OnlineLoop.post_sticker(Main.current_room_id, sticker_name);
		#end
		return sticker_got_used;
	}

	public function get_user_update_json(force_send_full_user:Bool = false):NetUserDef
	{
		var def:NetUserDef = {name: username};

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
			name: username,
			x: x.floor(),
			y: y.floor(),
			sx: new_sx,
			costume: costume.name
		};

		return def;
	}
}

private enum abstract State(String) from String to String
{
	final NEUTRAL;
	final JUMPING;
	final EMOTING;
}
