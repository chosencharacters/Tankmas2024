package net.tankmas;

typedef NetUserDef =
{
	name:String,
	?x:Int,
	?y:Int,
	?costume:String,
	?timestamp:Int,
	?sticker:NetStickerDef
}

typedef NetStickerDef =
{
	name:String,
	timestamp:Float
}