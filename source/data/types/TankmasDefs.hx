package data.types;

import data.types.TankmasEnums.UnlockCondition;
import dn.achievements.AbstractAchievementPlatform;

typedef CostumeDef =
{
	var name:String;
	var display:String;
	var ?desc:String;
	var ?unlock:UnlockCondition;
	var ?data:Dynamic;
}

typedef TrackDef =
{
	var id:String;
	var name:String;
	var artist:String;
	// Unlock condition
	var ?unlock:UnlockCondition;
	var ?data:Dynamic;
}

typedef StickerDef =
{
	var name:String;
	var properName:String;
	var artist:String;
	var ?desc:String;
	var ?unlock:UnlockCondition;
	var ?data:Dynamic;
}

typedef PresentDef =
{
	var day:Int;
	var title:String;
	var artist:String;
	var file:String;
	var ?link:String;
	var ?comicProperties:ComicDef;
	var ?costumeUnlock:String;
	var ?timelock:Int;
}

typedef ComicDef =
{
	var pages:Int;
	var ?audio:String;
	var ?timing:Array<Float>;
	var ?cover:Bool;
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
	var ?frameNum:Int;
}
