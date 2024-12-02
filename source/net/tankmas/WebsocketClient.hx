package net.tankmas;

import net.tankmas.NetDefs.NetUserDef;
import haxe.Json;
#if websocket
import hx.ws.WebSocket;
import haxe.io.Bytes;
#end

enum abstract WebsocketEventType(Int)
{
	var SignIn = 1;
	var PositionUpdate = 2;
	var Event = 3;
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

	public function new()
	{
		connect();
	}

	function connect()
	{
		#if websocket
		socket = new WebSocket(address);
		socket.onmessage = on_message;
		socket.onopen = on_connect;
		socket.onerror = on_error;
		socket.onclose = on_close;
		#end
	}

	function on_error(error)
	{
		trace(error);
		connected = false;
	}

	function on_close()
	{
		trace('disconnect');
		connected = false;
	}

	function on_connect()
	{
		connected = true;
		sign_in(Main.username);
	}

	function on_message(message)
	{
		trace(message);
	}

	var queued_messages:Array<Dynamic> = [];

	var flush_interval = 0.5;
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
			type: WebsocketEventType.PositionUpdate,
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

	public function sign_in(username:String)
	{
		send({
			type: WebsocketEventType.SignIn,
			data: {
				username: username,
			}
		}, true);
	}
}
