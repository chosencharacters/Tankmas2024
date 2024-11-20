#if http_client
package net.tankmas;

import data.Costumes;
import data.types.TankmasDefs.CostumeDef;
import entities.NetUser;
import entities.Player;
import entities.base.BaseUser;
import net.tankmas.OnlineDefs;
import net.tankmas.deprecated.TankmasClientHttp;

/**
 * The main game online update loop, yea!
 */
class OnlineLoopHttp
{
	public static var post_tick_rate:Float = 0;
	public static var get_tick_rate:Float = 0;

	public static var emote_tick_limit:Int = 1000;

	// base server tick rate is 200 rn
	public static var post_tick_rate_multiplier:Float = 1;
	public static var get_tick_rate_multiplier:Float = 5;

	static var last_post_timestamp:Float;
	static var last_get_timestamp:Float;

	public static var current_timestamp(get, default):Float;

	public static var force_send_full_user:Bool;

	static function get_current_timestamp():Float
		return haxe.Timer.stamp();

	public static function init()
	{
		#if offline return; #end

		force_send_full_user = true;

		post_tick_rate = 0;
		get_tick_rate = 0;

		last_post_timestamp = current_timestamp;
		last_get_timestamp = current_timestamp;
	}

	public static function iterate()
	{
		#if offline return; #end

		var post_time_diff:Float = current_timestamp - last_post_timestamp;
		var get_time_diff:Float = current_timestamp - last_get_timestamp;

		if (post_time_diff > post_tick_rate * .001 && post_tick_rate > -1)
		{
			last_post_timestamp = current_timestamp;
			OnlineLoop.post_player("1", force_send_full_user, PlayState.self.player);
		}

		if (get_time_diff > get_tick_rate * .001 && get_tick_rate > -1)
		{
			last_get_timestamp = current_timestamp;
			OnlineLoop.get_room("1");
		}
	}

	/**This is a post request**/
	public static function post_player(room_id:String, force_send_full_user:Bool = false, user:Player)
	{
		post_tick_rate = 999;
		var json:NetUserDef = user.get_user_update_json();

		if (json.x != null || json.y != null || json.costume != null || json.sticker != null)
		{
			trace(json);
			TankmasClientHttp.post_user(room_id, json, after_post_player);
		}
	}

	/**This is a get request**/
	public static function get_room(room_id:String)
	{
		get_tick_rate = 999;
		TankmasClientHttp.get_users_in_room(room_id, update_user_visuals);
	}

	public static function after_post_player(data:Dynamic)
	{
		post_tick_rate = data.tick_rate * post_tick_rate_multiplier;
		if (data.request_for_more_info)
		{
			force_send_full_user = true;
			data.tick_rate = 0;
		}
	}

	public static function update_user_visuals(data:Dynamic)
	{
		#if !ghost_town
		var usernames:Array<String> = Reflect.fields(data.data);

		usernames.remove(Main.username);

		trace(usernames);

		for (username in usernames)
		{
			var def:NetUserDef = Reflect.field(data.data, username);
			var costume:CostumeDef = Costumes.get(def.costume);
			var user:BaseUser = BaseUser.get_user(username, function()
			{
				return new NetUser(def.x, def.y, username, costume);
			});

			cast(user, NetUser).move_to(def.x, def.y);

			trace(def);
			trace(def.sticker);

			if (def.sticker != null)
				trace(def.sticker.timestamp - current_timestamp);

			if (user.costume == null || user.costume.name != costume.name)
				user.new_costume(costume);
		}
		get_tick_rate = data.tick_rate * get_tick_rate_multiplier;
		#end
	}
}
#end