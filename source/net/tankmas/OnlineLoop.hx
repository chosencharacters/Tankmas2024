package net.tankmas;

import data.JsonData;
import data.SaveManager;
import data.types.TankmasDefs.CostumeDef;
import entities.NetUser;
import entities.Player;
import entities.base.BaseUser;
import net.tankmas.NetDefs;
import net.tankmas.TankmasClient;

/**
 * The main game online update loop, yea!
 */
class OnlineLoop
{
	public static var rooms_post_tick_rate:Float = 0;
	public static var rooms_get_tick_rate:Float = 0;
	public static var events_get_tick_rate:Float = 0;

	public static var emote_tick_limit:Int = 1000;

	// base server tick rate is 200 rn
	public static var rooms_post_tick_rate_multiplier:Float = 1;
	public static var rooms_get_tick_rate_multiplier:Float = 5;
	public static var events_get_tick_rate_multiplier:Float = 5;

	static var last_rooms_post_timestamp:Float;
	static var last_rooms_get_timestamp:Float;
	static var last_events_get_timestamp:Float;

	static final tick_wait_timeout:Int = -1;

	public static var current_timestamp(get, default):Float;

	public static var force_send_full_user:Bool;

	static function get_current_timestamp():Float
		return haxe.Timer.stamp();

	public static function init()
	{
		#if offline return; #end

		force_send_full_user = true;

		rooms_post_tick_rate = 0;
		rooms_get_tick_rate = 0;
		events_get_tick_rate = 0;

		last_rooms_post_timestamp = current_timestamp;
		last_rooms_get_timestamp = current_timestamp;
		last_events_get_timestamp = current_timestamp;
	}

	public static function iterate()
	{
		#if offline return; #end

		var post_time_diff:Float = current_timestamp - last_rooms_post_timestamp;
		var get_time_diff:Float = current_timestamp - last_rooms_get_timestamp;

		if (post_time_diff > rooms_post_tick_rate * .001 && rooms_post_tick_rate > -1)
		{
			last_rooms_post_timestamp = current_timestamp;
			OnlineLoop.post_player("1", force_send_full_user, PlayState.self.player);
		}

		if (get_time_diff > rooms_get_tick_rate * .001 && rooms_get_tick_rate > -1)
		{
			last_rooms_get_timestamp = current_timestamp;
			OnlineLoop.get_room("1");
		}
		if (get_time_diff > events_get_tick_rate * .001 && events_get_tick_rate > -1)
		{
			last_events_get_timestamp = current_timestamp;
			OnlineLoop.get_events("1");
		}
	}

	/**This is a post request**/
	public static function post_player(room_id:String, force_send_full_user:Bool = false, user:Player)
	{
		rooms_post_tick_rate = tick_wait_timeout;
		var json:NetUserDef = user.get_user_update_json();

		if (json.x != null || json.y != null || json.costume != null || json.sx != null)
			TankmasClient.post_user(room_id, json, after_post_player);
	}

	/**This is a post request**/
	public static function post_sticker(room_id:String, sticker_name:String)
	{
		TankmasClient.post_event(room_id, {type: "sticker", data: {"name": sticker_name}, username: Main.username});
	}

	public static function post_marshmallow_discard(room_id:String, marshmallow_level:Int)
	{
		#if offline return #end
		TankmasClient.post_event(room_id, {type: "drop_marshmallow", data: {"level": marshmallow_level}, username: Main.username});
	}

	/**This is a post request**/
	public static function post_event(room_id:String, event:NetEventDef)
	{
		TankmasClient.post_event(room_id, event);
	}

	/**This is a get request**/
	public static function get_room(room_id:String)
	{
		rooms_get_tick_rate = tick_wait_timeout;
		TankmasClient.get_users_in_room(room_id, update_user_visuals);
	}

	/**This is a post request**/
	public static function get_events(room_id:String)
	{
		events_get_tick_rate = tick_wait_timeout;
		TankmasClient.get_events(room_id, update_user_events);
	}

	public static function after_post_player(data:Dynamic)
	{
		rooms_post_tick_rate = data.tick_rate * rooms_post_tick_rate_multiplier;
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

		for (username in usernames)
		{
			if (username.contains("temporary_random_username"))
				continue;

			var def:NetUserDef = Reflect.field(data.data, username);
			var costume:CostumeDef = JsonData.get_costume(def.costume);

			if (costume == null)
				costume = JsonData.get_costume(Main.default_costume);

			var user:BaseUser = BaseUser.get_user(username, function()
			{
				return new NetUser(def.x, def.y, username, costume);
			});

			cast(user, NetUser).move_to(def.x, def.y, def.sx);

			if (user.costume == null || user.costume.name != costume.name)
				user.new_costume(costume);
		}

		PlayState.self.users.remove(PlayState.self.player, true);
		PlayState.self.users.add(PlayState.self.player);

		rooms_get_tick_rate = data.tick_rate * rooms_get_tick_rate_multiplier;
		rooms_post_tick_rate = data.tick_rate * rooms_post_tick_rate_multiplier;

		events_get_tick_rate = data.tick_rate * events_get_tick_rate_multiplier;
		#end
	}

	public static function update_user_events(data:Dynamic)
	{
		#if !ghost_town
		var events:Array<NetEventDef> = data.data.events;

		for (event in events)
		{
			var user = BaseUser.get_user(event.username);
			if (user != null)
				user.on_event(event);
		}
		rooms_get_tick_rate = data.tick_rate * rooms_get_tick_rate_multiplier;
		#end
	}
}
