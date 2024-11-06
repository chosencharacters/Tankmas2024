package net.tankmas;

import data.types.TankmasEnums.Costumes;
import entities.NetUser;
import entities.Player;
import haxe.Json;
import net.tankmas.TankmasClient.NetUserDef;
import net.tankmas.TankmasClient;

/**
 * The main game online update loop, yea!
 */
class OnlineLoop
{
	final BASE_TICK_RATE:Int = 100;

	var last_update_timestamp:Int = 0;

	static var username:String = "squidly";

	public static function post_player(room_id:String, user:Player)
	{
		TankmasClient.post_user(room_id, {
			name: username,
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
		trace(data);

		var users = haxe.Json.parse(data);

		for (username in Reflect.fields(users))
		{
			var user:NetUserDef = Reflect.field(users, username);
			new NetUser(user.x, user.y, Costumes.string_to_costume(user.costume));
		}
	}
}