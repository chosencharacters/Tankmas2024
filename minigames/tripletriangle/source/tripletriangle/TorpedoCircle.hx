package tripletriangle;

import tripletriangle.BasicCircle.Circle_AngleAmount;
import tripletriangle.GenericCircle.CircleType;

// TODO: Remove the parameters graphicAssetPath, p_type, p_angleAmount in favour of constants. I guess. Not really important.
class TorpedoCircle extends BasicCircle
{
	override public function new(p_x:Float = 120, p_y:Float = 160, graphicAssetPath:String = "assets/images/Circle Nene.png", p_type:CircleType = CircleType.Torpedo,
        p_angleAmount:Circle_AngleAmount = Circle_AngleAmount.One, p_force:Float = 65, p_min_first_angle:Float = 75, p_max_first_angle:Float = 105,
        p_min_second_angle:Float = 0, p_max_second_angle:Float = 0, p_startHp:Int = 1)
	{
		super(p_x, p_y, graphicAssetPath, p_type,
			p_angleAmount, p_force, p_min_first_angle, p_max_first_angle,
			p_min_second_angle, p_max_second_angle, p_startHp);
	}
}