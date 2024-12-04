package net.tankmas;

import openfl.events.EventDispatcher;
import net.tankmas.NetDefs.NetEventType;
import net.tankmas.NetDefs.GenerateBasicAuthHeader;
import http.HttpRequest;
import net.tankmas.NetDefs.NetEventDef;
import hx.ws.Types.MessageType;
import net.tankmas.NetDefs.NetUserDef;
import haxe.Json;
#if websocket
import hx.ws.WebSocket;
import haxe.io.Bytes;
#end

enum abstract WebsocketEventType(Int)
{
	// Called whenever the state of a player changes.
	// This can be the position / costume / room / data
	var PlayerStateUpdate = 2;

	// Custom events, such as using stickers or doing activities in minigames.
	var CustomEvent = 3;

	// Called when player disconnects or leaves the room.
	var PlayerLeft = 4;

	// Received when the server broadcasts a message.
	var NotificationMessage = 12;
}

typedef WebsocketEvent =
{
	type:WebsocketEventType,
	?timestamp:Float,

	?name:String,

	?data:Dynamic,

	?room_id:Int,
	?username:String,
}

class WebsocketClient
{
	static var address:String = #if host_address 'ws://${haxe.macro.Compiler.getDefine("host_address")}' #elseif test_local 'ws://127.0.0.1:5000' #else "wss://tankmas.kornesjo.se:25567" #end;

	#if websocket
	var socket:WebSocket;
	#end

	var connected = false;
	var username:String = null;
	var session_id:String = null;

	var connection_retries = 0;
	var max_connection_retries = 5;
	var retry_connection = false;

	var until_retry_s = 3.0;
	var retry_interval = 5.0;

	var closed = false;

	public var on_socket_timeout:() -> Void = null;

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

		session_id = Main.session_id;

		if (session_id != null && username != null)
		{
			connect();
		}
	}

	public function close()
	{
		#if websocket
		if (socket != null)
			socket.close();
		closed = true;
		connected = false;
		#end
	}

	function connect()
	{
		#if websocket
		if (username == null || session_id == null)
		{
			trace("Trying to connect with a session id or username");
			return;
		}

		try
		{
			// var auth = GenerateBasicAuthHeader(username, session_id);
			// /socket = new WebSocket(address, true, ["Authorization" => auth]);
			var url = '${address}?username=${username}&session=${session_id}';
			socket = new WebSocket(url);
			socket.onmessage = on_message;
			socket.onopen = on_connect;
			socket.onerror = on_error;
			socket.onclose = on_close;
		}
		catch (err)
		{
			trace('Could not create websocket: $err');
			start_reconnection();
		}
		#end
	}

	function on_error(_err)
	{
		trace(_err);
		#if websocket
		start_reconnection();
		#end
	}

	function start_reconnection()
	{
		until_retry_s = retry_interval;
		connection_retries++;

		socket = null;

		if (connection_retries > max_connection_retries)
		{
			trace('could not connect to socket after max retries');
			if (on_socket_timeout != null)
				on_socket_timeout();
		}
		else
		{
			trace('socket crashed, retry connection in a while...');
			retry_connection = true;
		}
	}

	function on_close()
	{
		connected = false;
		if (!closed)
		{
			start_reconnection();
		}
		else
		{
			trace('Disconnected to server.');
		}
	}

	function on_connect()
	{
		trace('Connected to server.');
		retry_connection = false;
		connection_retries = 0;
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
							if (d.username == Main.username)
								continue;
							OnlineLoop.update_user_visual(d.username, d);
						}

						if (event.type == PlayerLeft)
						{
							var d:NetUserDef = event.data;
							PlayState.self.remove_user(d.username);
						}

						if (event.type == CustomEvent)
						{
							var net_event:NetEventDef = {
								room_id: event.room_id,
								type: event.name,
								data: event.data,
								timestamp: event.timestamp,
								username: event.username,
							}
							PlayState.self.on_net_event_received(net_event);
						}

						if (event.type == NotificationMessage)
						{
							var data:
								{
									?text:String,
									?persistent:Bool
								} = event.data;

							if (data == null || data.text == null)
								return;

							PlayState.self.notification_message.show(data.text, data.persistent);
						}
					}
				default:
			}
		}
		catch (err)
		{
			trace(err.stack);
		}
	}

	var queued_messages:Array<WebsocketEvent> = [];

	var flush_interval = 0.2;
	var until_flush = 0.0;

	public function update(elapsed:Float)
	{
		if (retry_connection && socket == null)
		{
			until_retry_s -= elapsed;
			if (until_retry_s < 0)
			{
				until_retry_s = retry_interval;
				connect();
			}
		}

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
		if (!connected || socket == null)
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

	function send(event:WebsocketEvent, immediate = false, overwriteIfExisting = false)
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
		{
			if (overwriteIfExisting)
			{
				var index = -1;
				for (i in 0...queued_messages.length)
				{
					if (queued_messages[i].type == event.type)
					{
						queued_messages[i] = event;
						return;
					}
				}
			}

			queued_messages.push(event);
		}
		#end
	}

	public function send_player(player:NetUserDef)
	{
		send({
			type: WebsocketEventType.PlayerStateUpdate,
			data: player,
		});
	}

	public function send_event(type:NetEventType, data:Dynamic = null, immediate = false)
	{
		send({
			type: WebsocketEventType.CustomEvent,
			name: type,
			data: data,
		}, immediate);
	}
}
