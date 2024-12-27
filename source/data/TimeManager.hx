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
	public var hour(get, never):Int;
	public var hanukkah_day(get, never):Int;
	public var is_tankmas_month(get, never):Bool;

	public function new() {}

	public function get_datetime():DateTime
		return DateTime.now().add(Hour(-5));

	function get_utc():Float
		return #if sys Sys.time() * 1000.0 #else Date.now().getTime() #end;

	function get_day():Int
		return datetime.getDay();

	function get_month():Int
		return datetime.getMonth();

	function get_year():Int
		return datetime.getYear();

	function get_hour():Int
		return datetime.getHour();

	function get_is_tankmas_month():Bool
		return month == 12;

	function get_hanukkah_day():Int
	{
		var return_day:Int = 0;
		switch (get_day())
		{
			case 25:
				return_day = 1;
			case 26:
				return_day = 2;
			case 27:
				return_day = 3;
			case 28:
				return_day = 4;
			case 29:
				return_day = 5;
			case 30:
				return_day = 6;
			case 31:
				return_day = 7;
			case 1:
				return_day = 8;
		}
		if (hour < 18)
			return_day--;
		return return_day;
	}
}
