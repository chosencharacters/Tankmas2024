package net.core;

import haxe.io.Bytes;
import hx.ws.Log;
import hx.ws.WebSocket;

class Client
{
	static var client(get, default):WebSocket;

	public static function login(url:String)
	{
		if (client == null)
		{
			Log.mask = Log.INFO | Log.DEBUG | Log.DATA;
			client = new WebSocket("ws://localhost:5000");
			client.additionalHeaders.set("Content-Type", "application/json");
			client.onopen = logged_in;
			client.onerror = on_error;
			#if sys
			Sys.getChar(true);
			#end
		}
	}

	static function logged_in()
		message("LOGGED IN!");

	public static function get_client():WebSocket
	{
		// if (client == null)
		// throw "client is null! probably not logged in!";
		return client;
	}

	/**
	 * GET function
	 * @param url target url
	 * @param on_data return function on success
	 */
	public static function get(url:String, ?on_data:Dynamic->Void)
	{
		throw "not implemented";
	}

	/**
	 * POST a JSON object
	 * @param url target url
	 * @param data JSON object
	 * @param on_data return function on success
	 */
	public static function post(url:String, data:Dynamic, ?on_data:Dynamic->Void)
	{
		throw "not implemented";
	}

	public static function send(type:String, data:Dynamic)
	{
		client.send({type: String, data: data});
	}

	public static function message(text:String)
		send("message", {message: text});

	static function on_error(error:Dynamic)
		#if trace_net
		trace('CLIENT ERROR: ${error}');
		#else
		false;
		#end
}
