package net.tankmas;

import net.core.Client;

typedef NetUserDef =
{
	name:String,
	x:Int,
	y:Int,
	costume:String,
	?timestamp:Int
}

class TankmasClient
{
	static var address:String = #if test_local 'http://127.0.0.1:5000' #else "http://78.108.218.30:25567" #end;

	public static function get_users_in_room(room_id:String, ?on_complete:String->Void)
	{
		var url:String = '$address/rooms/$room_id/users';

		Client.get(url, on_complete);
	}

	public static function post_user(room_id:String, user:NetUserDef, ?on_complete:String->Void)
	{
		var url:String = '$address/rooms/$room_id/users';

		Client.post(url, haxe.Json.stringify(user), on_complete);
	}
}