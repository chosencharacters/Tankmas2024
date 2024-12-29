package tripletriangle;

import flixel.FlxSprite;

class FlxColor{public static var WHITE: FlxColor;}

enum SkinType
{
    circleSkin;
  	spikeSkin;
    bgSkin;
    juiceSkin;
}

abstract class Skin
{
    public var price: UInt;
    public var id: String;
    public var displayName: String;
    public var description: String;
    public var displaySprite: FlxSprite;
    public var displayTint: FlxColor = FlxColor.WHITE;
    public var skinType: SkinType;

    public function new(p_price: UInt, p_id: String, p_displayName: String, p_description: String, p_displaySprite: FlxSprite, p_displayTint: FlxColor, p_skinType: SkinType)
    {
      	price = p_price;
      	id = p_id;
      	displayName = p_displayName;
      	description = p_description;
      	displaySprite = p_displaySprite;
      	displayTint = p_displayTint;
      	skinType = p_skinType;
    }

  	/*public id: String
    {
        get => name;
    }*/
  
  /*@:isVar public var x(get, set):String;

  function get_x() {
    return x;
  }

  function set_x(x) {
    return this.x = x;
  }*/
}


class CircleSkin extends Skin
{
    //[Header("Circle: 1 = Basic, 2 = Torpedo, 3 = Big, 4 = Bloon, 5 = Mole")]
    public var circleSpriteArr: Array<FlxSprite>;  // This and the tints are a list, for all types of circles included, and moar.
    public var circleTintArr: Array<FlxColor>;

    public function new(p_price: UInt, p_id: String, p_displayName: String, p_description: String, p_displaySprite: FlxSprite, p_displayTint: FlxColor)
    {
      	super(p_price, p_id, p_displayName, p_description, p_displaySprite, p_displayTint, SkinType.circleSkin);
    }
}

class Test {
  static function main() {
    trace("Haxe is great!");
    
    var circleSkin: CircleSkin = new CircleSkin(5, "skin_dummy", "Dummy Circle", "It's a dummy.", null, null);
    trace(circleSkin.displayName);
    
    var circle: BasicCircle = new BasicCircle(CircleType.Basic, 50, Circle_AngleAmount.One, 30, 80, 100, 150, 1);
    trace(circle.force);
  }
}
