package data;

import Date;
import datetime.DateTime;

class TimeManager
{
	public var datetime(get, never):DateTime;
	public var utc(get, never):Float;
	public var day(get, never):Int;
	public var month(get, never):Int;
	public var year(get, never):Int;
	public var is_tankmas_month(get, never):Bool;

	public function new() {}

	public function get_datetime():DateTime
		return DateTime.now().add(Hour(-4));

	function get_utc():Float
		return Date.now().getTime();

	function get_day():Int
		return datetime.getDay();

	function get_month():Int
		return datetime.getMonth();

	function get_year():Int
		return datetime.getYear();

	function get_is_tankmas_month():Bool
		return month == 12;
}
