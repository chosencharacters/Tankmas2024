package net.tankmas;

import data.types.TankmasEnums.Costumes;
import entities.NetUser;
import entities.Player;
import entities.base.BaseUser;
import net.tankmas.TankmasClient;

/**
 * The main game online update loop, yea!
 */
class OnlineLoop
{
	static var tick_rate:Float = 0;

	static var last_update_timestamp:Float;
	static var current_timestamp(get, default):Float;

	static function get_current_timestamp():Float
		return haxe.Timer.stamp();

	public static function iterate()
	{
		var time_diff:Float = current_timestamp - last_update_timestamp;

		if (time_diff > tick_rate * .001)
		{
			last_update_timestamp = current_timestamp;
			OnlineLoop.update_player_position("1", PlayState.self.player);
		}
	}

	public static function update_player_position(room_id:String, user:Player)
	{
		TankmasClient.post_user(room_id, {
			name: Main.username,
			x: user.x.floor(),
			y: user.y.floor(),
			costume: user.costume.name
		}, update_user_visuals);
	}

	public static function update_room(room_id:String)
	{
		TankmasClient.get_users_in_room(room_id, update_user_visuals);
	}

	public static function update_user_visuals(data:String)
	{
		data = data.replace('\\\"', '\"').replace('\"{', '{').replace('}\"', '}');

		var pack = haxe.Json.parse(data);
		var users = pack.data;

		for (username in Reflect.fields(users))
		{
			var def:NetUserDef = Reflect.field(users, username);
			var user:BaseUser = BaseUser.get_user(username, function()
			{
				return new NetUser(0, 0, username, Costumes.string_to_costume(def.costume));
			});
			user.setPosition(def.x, def.y);
		}
		tick_rate = pack.tick_rate;
		trace(tick_rate);
	}
}