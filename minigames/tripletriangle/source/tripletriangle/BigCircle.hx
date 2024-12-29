package tripletriangle;

import tripletriangle.BasicCircle.Circle_AngleAmount;
import tripletriangle.GenericCircle.CircleType;

class BigCircle extends BasicCircle
{
	override public function new(p_x:Float = 120, p_y:Float = 160, graphicAssetPath:String = "assets/images/Circle P-Bot.png", p_type:CircleType = CircleType.Big,
        p_angleAmount:Circle_AngleAmount = Circle_AngleAmount.Two, p_force:Float = 30, p_min_first_angle:Float = 30, p_max_first_angle:Float = 60,
        p_min_second_angle:Float = 120, p_max_second_angle:Float = 150, p_startHp:Int = 3, p_radius:Int = 24)
	{
		super(p_x, p_y, graphicAssetPath, p_type,
			p_angleAmount, p_force, p_min_first_angle, p_max_first_angle,
			p_min_second_angle, p_max_second_angle, p_startHp);
		radius = p_radius;
	}
}