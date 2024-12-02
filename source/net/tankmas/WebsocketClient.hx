package net.tankmas;

import hx.ws.Types.MessageType;
import net.tankmas.NetDefs.NetUserDef;
import haxe.Json;
#if websocket
import hx.ws.WebSocket;
import haxe.io.Bytes;
#end

enum abstract WebsocketEventType(Int)
{
	var PlayerStateUpdate = 2;
	var Event = 3; // Events are custom types, the contain names

	var PlayerLeft = 4; // When player disconnects or goes to another room
}

typedef WebsocketEvent =
{
	type:WebsocketEventType,
	?name:String,
	?data:Dynamic,
}

class WebsocketClient
{
	static var address:String = #if test_local 'ws://127.0.0.1:8000' #else "wss://tankmas.kornesjo.se:25567" #end;

	#if websocket
	var socket:WebSocket;
	#end

	var connected = false;
	var username:String = null;
	var session_id:String = null;

	public function new()
	{
		#if offline
		return;
		#end

		username = Main.username;
		session_id = null;

		#if newgrounds
		session_id = Main.ng_api.NG_SESSION_ID;
		username = Main.ng_api.NG_USERNAME;
		#end

		#if (dev && test_local)
		session_id = 'test_dev_session';
		#end

		if (session_id != null && username != null)
		{
			connect();
		}
	}

	function connect()
	{
		#if websocket
		if (username == null || session_id == null)
		{
			trace("Trying to connect with a session id or username");
			return;
		}

		var url = '${address}?username=${username}&session=${session_id}';
		socket = new WebSocket(url);
		socket.onmessage = on_message;
		socket.onopen = on_connect;
		socket.onerror = on_error;
		socket.onclose = on_close;
		#end
	}

	function on_error(error)
	{
		trace(error);
	}

	function on_close()
	{
		trace('Disconnected to server.');
		connected = false;
	}

	function on_connect()
	{
		trace('Connected to server.');
		connected = true;
	}

	function on_message(data:MessageType)
	{
		try
		{
			switch (data)
			{
				case StrMessage(content):
					var events:{events:Array<WebsocketEvent>} = Json.parse(content);
					if (events == null || events.events == null)
						return;
					for (event in events.events)
					{
						if (event.type == PlayerStateUpdate)
						{
							var d:NetUserDef = event.data;
							OnlineLoop.update_user_visual(d.username, d);
						}
						if (event.type == PlayerLeft)
						{
							var d:NetUserDef = event.data;
							PlayState.self.remove_user(d.username);
						}
					}
				default:
			}
		}
		catch (err)
		{
			trace(err);
		}
	}

	var queued_messages:Array<Dynamic> = [];

	var flush_interval = 0.2;
	var until_flush = 0.0;

	public function update(elapsed:Float)
	{
		until_flush -= elapsed;
		if (until_flush <= 0)
		{
			flush_messages();
		}
	}

	function flush_messages()
	{
		until_flush = flush_interval;
		#if websocket
		if (!connected)
			return;

		if (queued_messages.length == 0)
			return;

		var message = {
			events: queued_messages
		}

		var data = Json.stringify(message);
		queued_messages = [];

		socket.send(data);
		#end
	}

	function send(event:WebsocketEvent, immediate = false)
	{
		#if websocket
		if (socket == null)
			return;
		if (immediate)
		{
			queued_messages.insert(0, event);
			flush_messages();
		}
		else
			queued_messages.push(event);
		#end
	}

	public function send_player(player:NetUserDef)
	{
		send({
			type: WebsocketEventType.PlayerStateUpdate,
			data: player,
		});
	}

	public function send_event(type:String, data:Dynamic = null, immediate = false)
	{
		send({
			type: WebsocketEventType.Event,
			name: type,
			data: data,
		}, immediate);
	}
}
