package net.core;

import haxe.Http;
import haxe.http.HttpStatus;

class Client
{
	public static function basic_request(url:String, ?trace_error:Bool = true, ?trace_status:Bool = true, ?on_data:String->Void):Http
	{
		var request:Http = new haxe.Http(url);

		#if trace_net
		if (trace_error)
			request.onError = on_error;
		if (trace_status)
			request.onStatus = on_status;
		#end

		if (on_data != null)
			request.onData = on_data;

		return request;
	}

	/**
	 * GET function
	 * @param url target url
	 * @param on_data return function on success
	 */
	public static function get(url:String, ?on_data:String->Void)
	{
		var request:Http = basic_request(url, on_data);

		#if trace_net
		trace('GET <- $url');
		#end

		request.request(false);
	}

	/**
	 * POST a JSON object
	 * @param url target url
	 * @param data JSON object as String
	 * @param on_data return function on success
	 */
	public static function post(url:String, data:String, ?on_data:String->Void)
	{
		var request:Http = basic_request(url, on_data);

		#if trace_net
		trace('POST -> $url>>\tdata = $data');
		#end

		request.setPostData(data);

		request.addHeader("Content-Type", "application/json");

		request.request(true);
	}

	static function on_error(msg:String)
		trace('ERROR: $msg');

	static function on_status(status:HttpStatus)
		trace('STATUS: $status');
}
