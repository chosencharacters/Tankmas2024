package net.tankmas;

import haxe.Json;
import haxe.io.Bytes;
import hx.ws.Types.MessageType;
import hx.ws.WebSocket;
import net.tankmas.NetDefs.GenerateBasicAuthHeader;
import net.tankmas.NetDefs.NetEventDef;
import net.tankmas.NetDefs.NetEventType;
import net.tankmas.NetDefs.NetUserDef;

enum abstract WebsocketEventType(Int)
{
	// Called whenever the state of a player changes.
	// This can be the position / costume / room / data
	var PlayerStateUpdate = 2;

	// Custom events, such as using emotes or doing activities in minigames.
	var CustomEvent = 3;

	// Called when player disconnects or leaves the room.
	var PlayerLeft = 4;

	// Received when the server broadcasts a message.
	var NotificationMessage = 12;

	// The server sends this when another session is started,
	// asks the client not to reconnect again
	var PleaseLeave = 74;
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
	static final address:String = OnlineLoop.ws_address;

	var socket:WebSocket;

	var connected = false;
	var username:String = null;
	var session_id:String = null;

	var connection_retries = 0;
	var max_connection_retries = 7;
	var retry_connection = false;

	var until_retry_s = 3.0;
	var retry_interval = 5.0;

	var closed = false;

	public var on_socket_timeout:() -> Void = null;
	public var on_socket_closed:() -> Void = null;

	public function new()
	{
		#if offline
		return;
		#end
	}

	public function close()
	{
		#if websocket
		retry_connection = false;

		trace('Closing socket...');

		closed = true;
		connected = false;

		if (socket != null)
			socket.close();
		if (on_socket_closed != null)
			on_socket_closed();
		#end
	}

	public function connect()
	{
		if (socket != null)
		{
			return;
		}

		username = Main.username;
		session_id = Main.session_id;

		#if dev
		if (session_id == null || session_id == "")
		{
			session_id = "dev_test_session";
		}
		#end

		#if websocket
		if (username == null || session_id == null || username == "" || session_id == "")
		{
			trace('Trying to connect without a session id or username ($username, $session_id)');
			return;
		}

		try
		{
			var url = '${address}?username=${username}&session=${session_id}';
			trace('connecting to $url');

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
		trace('Uh oh websocket errorrr!!');
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
			retry_connection = false;
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

		// We are ready to go, force send full user on next tick.
		OnlineLoop.force_send_full_user = true;
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

						if (event.type == PleaseLeave)
						{
							trace('received good bye');
							close();
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
		{
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
