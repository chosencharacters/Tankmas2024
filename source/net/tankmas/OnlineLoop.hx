package net.tankmas;

import data.JsonData;
import data.SaveManager;
import data.types.TankmasDefs.CostumeDef;
import entities.NetUser;
import entities.Player;
import entities.base.BaseUser;
import levels.TankmasLevel.RoomId;
import net.tankmas.NetDefs;
import net.tankmas.TankmasClient;

/**
 * The main game online update loop, yea!
 */
class OnlineLoop
{
	static final host_uri:String =
		#if host_address
		'${haxe.macro.Compiler.getDefine("host_address")}'
		#elseif test_local
		'127.0.0.1:5000'
		#elseif dev
		"test.tankmas-adventure.com"
		#else
		"tankmas.kornesjo.se:25567"
		#end;

	static final use_tls:Bool =
		#if use_tls
		true
		#elseif (test_local || host_address)
		false
		#else
		true
		#end;

	public static final http_address = '${use_tls ? 'https://' : 'http://'}${host_uri}';
	public static final ws_address = '${use_tls ? 'wss://' : 'ws://'}${host_uri}';

	public static var emote_tick_limit:Int = 1000;

	static var last_websocket_player_tick_timestamp:Float;
	static final websocket_tick_rate = 2;
	static final websocket_state_send_interval = 1.0 / websocket_tick_rate;

	static var last_room_id:Null<RoomId> = null;

	public static var current_timestamp(get, default):Float;

	static final default_throttle_delay = 0.2;
	static final event_throttle_delays:Map<NetEventType, Float> = [
		// Event delays, timeout in seconds between messages,
		// if sent quicker than this interval, they'll be ignored.
		OPEN_PRESENT => 1.0,
		DROP_MARSHMALLOW => 0.5,
		STICKER => 0.8,
	];

	static var event_send_timestamps:Map<NetEventType, Float> = new Map();

	public static var force_send_full_user:Bool;

	static var websocket:WebsocketClient;

	public static var on_entered_offline_mode:Void->Void = null;

	static function get_current_timestamp():Float
		return haxe.Timer.stamp();

	public static var is_offline = false;

	/**
	 * Runs once at game startup
	 */
	public static function init()
	{
		#if offline return; #end

		#if (dev && test_local && !newgrounds)
		Main.session_id = 'test_session';
		#end

		if (is_offline)
		{
			trace('Player is offline, do nothing.');
			return;
		}

		if (websocket == null)
		{
			trace('initing online loop');
			websocket = new WebsocketClient();
		}

		websocket.connect();

		force_send_full_user = true;

		last_websocket_player_tick_timestamp = current_timestamp;

		websocket.on_socket_closed = OnlineLoop.on_websocket_died;
		websocket.on_socket_timeout = OnlineLoop.on_websocket_died;
	}

	static function on_websocket_died()
	{
		OnlineLoop.is_offline = true;
		if (OnlineLoop.on_entered_offline_mode != null)
		{
			OnlineLoop.on_entered_offline_mode();
		}
	}

	/**
	 * Runs whenever the user enters a new room,
	 * we send the full player state to the server,
	 */
	public static function init_room()
	{
		force_send_full_user = true;
		send_player_state(true);
	}

	public static function iterate(elapsed:Float = 0.0)
	{
		#if offline return; #end

		if (websocket != null)
			websocket.update(elapsed);

		if (Main.current_room_id != last_room_id)
		{
			force_send_full_user = true;
			last_room_id = Main.current_room_id;
		}

		// If playstate is not active, or lacks player, we're not yet online.
		if (PlayState.self == null || PlayState.self.player == null)
			return;

		var tick_diff = current_timestamp - last_websocket_player_tick_timestamp;
		if (!force_send_full_user && tick_diff < websocket_state_send_interval)
			return;

		last_websocket_player_tick_timestamp = current_timestamp;

		send_player_state(force_send_full_user);
		force_send_full_user = false;
	}

	public static function send_player_state(do_full_update:Bool = false)
	{
		#if offline return; #end

		if (PlayState.self == null)
			return;
		var json:NetUserDef = PlayState.self.player.get_user_update_json(do_full_update);
		if (json.x != null || json.y != null || json.costume != null || json.sx != null || json.data != null)
		{
			websocket.send_player(json);
		}
	}

	/**This is a post request**/
	public static function post_emote(emote_name:String)
	{
		post_event({type: STICKER, data: {"name": emote_name}});
	}

	public static function post_marshmallow_discard(marshmallow_level:Int)
	{
		post_event({type: DROP_MARSHMALLOW, data: {"level": marshmallow_level}});
	}

	public static function post_present_open(day:Int, earned_medal = false, first_time = true)
	{
		post_event({type: OPEN_PRESENT, data: {"day": day, "medal": earned_medal, "first_time": first_time}}, true, first_time);
	}

	public static function post_event(event:NetEventDef, immediate = false, force = false)
	{
		#if offline return; #end

		// Check if event is not spammed too quickly
		var now = current_timestamp;
		var throttle_interval = event_throttle_delays.exists(event.type) ? event_throttle_delays[event.type] : default_throttle_delay;

		if (!force && event_send_timestamps.exists(event.type))
		{
			var time_delta = now - event_send_timestamps[event.type];
			if (time_delta < throttle_interval)
			{
				trace('Tried to send event ${event.type} too quickly.');
				return;
			}
		}

		event_send_timestamps[event.type] = now;

		websocket.send_event(event.type, event.data, immediate);
	}

	public static function update_user_visual(username:String, def:NetUserDef)
	{
		if (PlayState.self == null)
			return;

		#if ghosttown return; #end

		var is_local_player = username == Main.username;

		if (is_local_player && !def.immediate)
			return;

		var costume:CostumeDef = JsonData.get_costume(def.costume);

		var create_function = () ->
		{
			return new NetUser(def.x, def.y, username, costume);
		}

		var user:BaseUser = BaseUser.get_user(username, !is_local_player ? create_function : null);

		if (user == null)
			return;

		var new_x = def.x != null ? def.x : user.x;
		var new_y = def.y != null ? def.y : user.y;
		var new_sx = def.sx;

		if (!def.immediate)
		{
			var net_user = cast(user, NetUser);
			if (net_user != null)
				net_user.move_to(new_x, new_y, new_sx);
		}
		else
		{
			user.x = new_x;
			user.y = new_y;
		}

		if (costume != null && (user.costume == null || user.costume.name != costume.name))
			user.new_costume(costume);

		if (def.data != null)
		{
			user.merge_data_field(def.data);

			/// user changed their pet type
			if (def.data.pet != null)
			{
				var new_pet_type = user.data.pet;
				trace('$username changed their pet to $new_pet_type');
				user.pet_changed(new_pet_type);
			}

			/// user changed their scale
			if (def.data.scale != null)
			{
				var new_user_scale = user.data.scale;
				trace('$username changed scale to $new_user_scale');
				user.scale_changed(new_user_scale);
			}

			if (def.data.marshmallow_streak != null)
			{
				// trace('$username marshmallows: ${def.data.marshmallow_streak}');
			}
		}
	}
}
