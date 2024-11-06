package net.core;

import haxe.Http;
import haxe.http.HttpStatus;

class Client
{
	public static function basic_request(url:String, ?on_data:String->Void):Http
	{
		var request:Http = new haxe.Http(url);
		request.onError = on_error;
		request.onStatus = on_status;

		if (on_data != null)
			request.onData = on_data;

		return request;
	}

	public static function get(url:String, ?on_data:String->Void)
	{
		var request:Http = basic_request(url, on_data);

		trace('GET <- $url');

		request.request(false);
	}

	public static function post(url:String, data:String, ?on_data:String->Void)
	{
		var request:Http = basic_request(url, on_data);

		trace('POST -> $url>>\tdata = $data');

		request.setPostData(data);

		request.addHeader("Content-Type", "application/json");

		request.request(true);
	}

	static function on_error(msg:String)
		trace('ERROR: $msg');

	static function on_status(status:HttpStatus)
		trace('STATUS: $status');
}