package net.tankmas;

typedef NetUserDef =
{
	name:String,
	?x:Int,
	?y:Int,
	?sx:Int, // Scale x, if facing right or left
	?costume:String,
	?timestamp:Float,
	?room_id:Int,
	// Data can contain specific user flags that the user can set.
	// Sort of like a save file but you can read other players data too.
	// WIP - no calls in client for this yet.
	?data:
		{
			?test_value:Int,
			?marshmallows_thrown:Int,
		}
}

typedef NetEventDef =
{
	username:String,
	type:String,
	data:Dynamic,
}

enum abstract NetEventType(String) from String to String
{
	final STICKER = "sticker";
	final DROP_MARSHMALLOW = "drop_marshmallow";
}
