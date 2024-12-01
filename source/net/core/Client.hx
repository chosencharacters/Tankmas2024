package net.core;

import haxe.Http;
import haxe.http.HttpStatus;
import http.HttpClient;
import http.HttpError;

class Client
{
	static var client(get, default):HttpClient;

	public static function get_client():HttpClient
	{
		if (client == null)
		{
			client = new HttpClient();
			client.defaultRequestHeaders = ["Content-Type" => "application/json"];
		}
		return client;
	}

	/**
	 * GET function
	 * @param url target url
	 * @param on_data return function on success
	 */
	public static function get(url:String, ?on_data:Dynamic->Void)
	{
		#if trace_net
		trace('GET <- $url');
		#end

		client.get(url).then(response ->
		{
			#if trace_net trace('STATUS: ${response.httpStatus}'); #end
			on_data(response.bodyAsJson);
		}, (error:HttpError) ->
			{
				trace('GET ERROR @ $url');
				on_error(error);
			});
	}

	/**
	 * POST a JSON object
	 * @param url target url
	 * @param data JSON object
	 * @param on_data return function on success
	 */
	public static function post(url:String, data:Dynamic, ?on_data:Dynamic->Void)
	{
		#if trace_net
		trace('POST -> $url>>\tdata = $data');
		#end

		client.post(url, data).then(response ->
		{
			#if trace_net trace('STATUS: ${response.httpStatus}'); #end
			if (on_data != null) on_data(response.bodyAsJson);
		}, (error:HttpError) ->
			{
				trace('POST ERROR @ $url');
				on_error(error);
			});
	}

	static function on_error(error:HttpError)
		#if trace_net
		trace('ERROR ${error.httpStatus}: ${error.message}');
		#else
		false;
		#end
}
