package net.tankmas;

import net.core.Client;
import net.tankmas.NetDefs;

class TankmasClient
{
	static var address:String = #if test_local 'http://127.0.0.1:5000' #else "https://tankmas.kornesjo.se:25567" #end;

	public static function get_users_in_room(room_id:String, ?on_complete:Dynamic->Void)
	{
		var url:String = '$address/rooms/$room_id/users';

		Client.get(url, on_complete);
	}

	public static function get_user(username:String, ?on_complete:?NetUserDef->Void)
	{
		var url:String = '$address/users/$username';
		var on_user_loaded = (res:{?data:NetUserDef}) ->
		{
			if (on_complete != null)
			{
				on_complete(res.data);
			}
		}
		Client.get(url, on_user_loaded);
	}

	public static function post_user(room_id:String, user:NetUserDef, ?on_complete:Dynamic->Void)
	{
		var url:String = '$address/rooms/$room_id/users';

		user.name = Main.username;
		if (user.name == null || user.name.length == 0)
		{
			return;
		}

		Client.post(url, user, on_complete);
	}

	public static function get_events(room_id:String, ?on_complete:Dynamic->Void)
	{
		var url:String = '$address/rooms/$room_id/events/get';

		Client.post(url, {username: Main.username}, on_complete);
	}

	public static function post_event(room_id:String, event:NetEventDef, ?on_complete:Dynamic->Void)
	{
		var url:String = '$address/rooms/$room_id/events/post';

		Client.post(url, event, on_complete);
	}

	public static function get_save(username:String, ?on_complete:Dynamic->Void)
	{
		var url:String = '$address/saves/get';

		Client.post(url, {username: username}, on_complete);
	}

	public static function post_save(username:String, save:String, ?on_complete:Dynamic->Void)
	{
		var url:String = '$address/saves/post';

		Client.post(url, {username: username, data: save}, on_complete);
	}

	public static function get_premieres(?on_complete:Dynamic->Void)
	{
		var url:String = '$address/premieres';
		Client.get(url, on_complete);
	}
}
