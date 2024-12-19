package entities.base;

/// Add fields here that should be synced
/// to other users in game.
/// Remember to make em optional (? before var name)
typedef BaseUserSharedData =
{
	var ?pet:String;
	var ?marshmallow_streak:Int;
	var ?scale:Float;
}
