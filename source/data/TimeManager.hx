package data;

import Date;

class TimeManager
{
	public var utc(get, never):Int;
	public var date(get, never):Int;
	public var month(get, never):Int;
	public var year(get, never):Int;
	public var is_tankmas_month(get, never):Bool;

	public function new() {}

	public function get_utc():Int
		return Date.now().getUTCDate();

	// TODO: months after December
	public function get_date():Int
		return Date.now().getUTCDate();

	public function get_month():Int
		return Date.now().getUTCMonth() + 1;

	public function get_year():Int
		return Date.now().getUTCFullYear();

	public function get_is_tankmas_month():Bool
		return month == 11;
}
