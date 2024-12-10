package entities.base;

import entities.base.BaseUser.PetType;

/// Add fields here that should be synced
/// to other users in game.
/// Remember to make em optional (? before var name)
typedef BaseUserSharedData =
{
	var ?pet:PetType;
	var ?marshmallow_streak:Int;
	var ?scale:Float;
}
