package data.types;

import data.types.TankmasEnums.UnlockCondition;

typedef CostumeDef =
{
	var name:String;
	var ?unlock:UnlockCondition;
	var ?data:Dynamic;
}

typedef SpriteAnimationDef =
{
	var name:String;
	var fps:Int;
	var ?looping:Bool;
	var frames:Array<SpriteAnimationFrameDef>;
	var ?finished:Bool;
}

typedef SpriteAnimationFrameDef =
{
	var ?x:Int;
	var ?y:Int;
	var ?width:Float;
	var ?height:Float;
	var ?angle:Int;
	var duration:Int;
}