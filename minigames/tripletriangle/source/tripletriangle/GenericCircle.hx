package tripletriangle;

import flixel.FlxSprite;

enum abstract CircleType(Int) {
    var Inexistent = -1;
    var Basic;
    var Torpedo;
    var Big;
    var Bloon;
    var Mole;
}

class GenericCircle extends FlxSprite // importantly includes position.
{
	public var type:CircleType = CircleType.Inexistent;
	public var startHp:Int = 1;
	private var currHp:Int;
	public var radius:Float = 16; // New variable for Haxe version. Half width in pixels. Changes from circle to circle.
	public var deathScore:Int = 1; // New variable for Haxe version.
}