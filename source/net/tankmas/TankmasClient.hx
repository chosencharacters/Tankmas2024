package net.tankmas;

import net.core.Client;
import net.tankmas.OnlineDefs;

class TankmasClient
{
	static var base_url:String = #if test_local 'http://127.0.0.1:5000' #else "http://78.108.218.30:25567" #end;

	public static function login()
	{
		Client.login(base_url);
	}
	
	public static function get_users_in_room(room_id:String, ?on_complete:Dynamic->Void)
	{
		var url:String = '$base_url/rooms/$room_id/users';

		Client.get(base_url, on_complete);
	}

	public static function post_user(room_id:String, user:NetUserDef, ?on_complete:Dynamic->Void)
	{
		Client.message("post user");
	}
}