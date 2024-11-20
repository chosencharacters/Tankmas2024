package entities;

import data.Costumes;
import data.types.TankmasDefs.CostumeDef;
import data.types.TankmasEnums.PlayerAnimation;
import entities.base.BaseUser;
import net.tankmas.OnlineDefs;
import net.tankmas.OnlineLoop;

class Player extends BaseUser
{
	var move_no_input_drag:Float = 0.9;
	var move_reverse_mod:Float = 3;

	var last_update_json:NetUserDef;

	static var debug_costume_rotation:Array<CostumeDef>;

	/**We send this once*/
	public var queued_online_sticker:String;

	public function new(?X:Float, ?Y:Float)
	{
		super(X, Y, Main.username);

		debug_costume_rotation = Costumes.all_defs.copy();
		costume = debug_costume_rotation[0];

		while (costume.name != "tankman")
			debug_rotate_costumes();

		last_update_json = {name: username};

		type = "player";

		PlayState.self.player = this;

		sprite_anim.anim(PlayerAnimation.MOVING);

		sstate(NEUTRAL);

		screenCenter();
	}

	function debug_rotate_costumes()
	{
		if (!Main.DEV)
			return;
		costume = debug_costume_rotation[0];
		debug_costume_rotation.push(debug_costume_rotation.shift());
		new_costume(costume);
	}

	override function new_costume(costume:CostumeDef)
		super.new_costume(costume);

	override function update(elapsed:Float)
	{
		if (Main.DEV && Ctrl.any(Ctrl.jaction))
			debug_rotate_costumes();

		fsm();
		super.update(elapsed);
	}

	function fsm()
		switch (cast(state, State))
		{
			case NEUTRAL:
				general_movement();
				detect_presents();
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

		if (Ctrl.jjump[1])
			use_sticker("common-tamago");

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

	function detect_presents()
	{
		var present:Present = Present.find_present_in_detect_range(this);

		Present.un_mark_all_presents();

		if (present == null)
			return;

		present.mark_target(true);
	}

	override function kill()
	{
		PlayState.self.player = null;
		super.kill();
	}
	override function use_sticker(sticker_name:String):Bool
	{
		var sticker_got_used:Bool = super.use_sticker(sticker_name);
		if (sticker_got_used)
			queued_online_sticker = sticker_name;
		return sticker_got_used;
	}

	public function get_user_update_json(force_send_full_user:Bool = false):NetUserDef
	{
		var def:NetUserDef = {name: username};


		if (last_update_json.x != x.floor() || force_send_full_user)
			def.x = x.floor();

		if (last_update_json.y != y.floor() || force_send_full_user)
			def.y = y.floor();


		if (last_update_json.costume != costume.name || force_send_full_user)
			def.costume = costume.name;

		if (queued_online_sticker != null)
		{
			def.sticker = {timestamp: OnlineLoop.current_timestamp, name: queued_online_sticker};
			queued_online_sticker = null;
			trace(def.sticker);
		}

		last_update_json = {
			name: username,
			x: x.floor(),
			y: y.floor(),
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
