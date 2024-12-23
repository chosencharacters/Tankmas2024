package tripletriangle;

import flixel.FlxSprite;
import tripletriangle.GenericCircle.CircleType;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.math.FlxAngle;
import flixel.math.FlxPoint;
import flixel.util.FlxCollision;

#if ADVENT
import utils.OverlayGlobal as Global;
#else
import utils.Global;
#end

// using static GameManagerBase;

class Rigidbody2D {}
class CircleCollider2D {}
class Stopwatch {}

enum Circle_AngleAmount
{
	One;
	Two;
}
class BasicCircle extends GenericCircle
{
	public var force:Float = 50;
	public var angleAmount:Circle_AngleAmount; // Leave the second angle be if you chose one angle.
	public var min_first_angle:Float = 30;
	public var max_first_angle:Float = 80;
	public var min_second_angle:Float = 100;
	public var max_second_angle:Float = 150;

	private var playgroundLeft:Float;
	private var playgroundRight:Float;
	private var playgroundWidth:Float;
	private var playgroundHeight:Float;
	private var playgroundTop:Float;
	private var playgroundBottom:Float;

	private var rb:Rigidbody2D;
	private var bouncebox:CircleCollider2D;
	private var swCollision_lastOccurrenceTimeInSeconds:Float; // System.Diagnostics.Stopwatch
	private final swCollision_cooldownInSeconds:Float = 0.15; // const
	public var velocityWoRotation:FlxPoint;

	private var damage:Int;
	private var wasPopped:Bool = false;

	private var previousElapsed:Float = 0;

	override public function new(p_x:Float = 120, p_y:Float = 160, graphicAssetPath:String = "assets/images/Circle Madness.png",
			p_type:CircleType = CircleType.Basic,
			p_angleAmount:Circle_AngleAmount = Circle_AngleAmount.Two, p_force:Float = 50, p_min_first_angle:Float = 30, p_max_first_angle:Float = 80,
			p_min_second_angle:Float = 100, p_max_second_angle:Float = 150, p_startHp:Int = 1)
	{
		var graphicAsset = Global.asset(graphicAssetPath);
		super(p_x, p_y, graphicAsset);
		// centerOrigin();
		// origin = new FlxPoint(radius, radius);
		// setPosition(x - origin.x, y - origin.y); // Center circle around position.
		offset.set(width / 2, height / 2); // Center circle around position, by setting pivot point kinda.

		type = p_type;
		force = p_force;
		angleAmount = p_angleAmount;
		min_first_angle = p_min_first_angle;
		max_first_angle = p_max_first_angle;
		min_second_angle = p_min_second_angle;
		max_second_angle = p_max_second_angle;
		startHp = p_startHp;

		swCollision_lastOccurrenceTimeInSeconds = -999;

		var camera:FlxCamera = FlxG.camera;
		playgroundHeight = 240; // camera.orthographicSize * 2 -> camera.height * 2 -> 240
		playgroundWidth = 160; // cameraHeight * camera.aspect -> camera.width -> 160
		playgroundLeft = 80; // camera.transform.position.x - cameraWidth / 2 -> 80
		playgroundRight = 240; // playgroundLeft + playgroundWidth -> 240
		playgroundTop = 0; // camera.transform.position.y + playgroundHeight / 2; -> 0
		playgroundBottom = 240; // camera.transform.position.y - playgroundHeight / 2; -> 240

		setPosition(playgroundLeft + FlxG.random.float(0 + playgroundWidth * 0.1, playgroundWidth * 0.9), playgroundTop - 2);
		// Use <force> to do this, and the angle variables too.
		var xSpeedPerFrame:Float = 0.25;
		var ySpeedPerFrame:Float = 0.25;
		// velocityWoRotation = new FlxPoint(xSpeedPerFrame, ySpeedPerFrame);
		velocityWoRotation = new FlxPoint(0, 0);
		var circleAngle:Float;
		if (angleAmount == Circle_AngleAmount.One)
		{
			// 90 = upwards
			circleAngle = FlxG.random.float(min_first_angle, max_first_angle);
		}
		else
		{
			circleAngle = FlxG.random.float(0, 2) == 1 ? FlxG.random.float(min_first_angle, max_first_angle) : FlxG.random.float(min_second_angle, max_second_angle);
		}
		AddForceAtAngle(force, circleAngle); // force depends on size?

		currHp = startHp;
	}

	private function HandleBounce(elapsed:Float){
		var currentTimeInSeconds = haxe.Timer.stamp();
		if (currentTimeInSeconds > swCollision_lastOccurrenceTimeInSeconds + swCollision_cooldownInSeconds)
		{
			if (x - radius < playgroundLeft)
			{
				// Bounced off the left wall.
				Bounce(1);
				swCollision_lastOccurrenceTimeInSeconds = currentTimeInSeconds;
			}
			else if (x + radius > playgroundRight)
			{
				// Bounced off the right wall.
				Bounce(-1);
				swCollision_lastOccurrenceTimeInSeconds = currentTimeInSeconds;
			}
		}
	}

	private function HandleMovement(elapsed:Float){
		x += velocityWoRotation.x * elapsed;
		y += velocityWoRotation.y * elapsed;
	}

	private function HandleOutOfScreen()
	{
		if (y - radius > playgroundBottom)
		{
			// Passed the bottom of the screen.
			GameManagerBase.Main.OnCircleEscaped(this);
			super.kill();
		}
	}

	override public function update(elapsed:Float)
	{
		HandleBounce(elapsed);
		HandleMovement(elapsed);
		HandleOutOfScreen();
		HandleCollisions();
		
		super.update(elapsed);
	}

	public function BounceStatic(circle: BasicCircle, xDirection:Float)
	{
		velocityWoRotation = new FlxPoint(Math.abs(velocityWoRotation.x) * xDirection, velocityWoRotation.y);
		// Play SFX
		var flxSound = FlxG.sound.play(Global.asset("assets/sounds/JSFXR Bounce.ogg"), 0.9);
		flxSound.pitch = FlxG.random.float(0.8, 1.2);
		// var snd:String = FlxG.random.getObject(["assets/alien_die0.wav", "assets/alien_die1.wav"]);
		// FlxG.sound.play(snd, 0.9);
		// SoundManager.Main.PlaySound("Bounce", true);
	}
	private function Bounce(xDirection:Float)
	{
		BounceStatic(this, xDirection);
	}

	public function AddForceAtAngleStatic(circle:BasicCircle, force:Float, angle:Float, forceYMovement:Bool=true)
	{
		var angle_radians:Float = angle * FlxAngle.TO_RAD;
		var xcomponent:Float = Math.cos(angle_radians) * force;
		var ycomponent:Float = Math.sin(angle_radians) * force;
		if (forceYMovement && ycomponent < 30)
		{
			ycomponent = 30;
		}
		circle.velocityWoRotation += new FlxPoint(xcomponent, ycomponent);
	}
	
	public function AddForceAtAngle(force:Float, angle:Float, forceYMovement:Bool=true)
	{
		AddForceAtAngleStatic(this, force, angle, forceYMovement);
	}
	private function HandleCollisions()
	{
		// Imperfectly inefficient implementation of the collision (circle to polygon would be efficient), but no biggie.
		for (spike in PlayState._spikeSpriteList.members)
		{
			if (spike != null && FlxCollision.pixelPerfectCheck(this, cast spike))
			{
				OnCollisionWithSpike(cast spike);
			}
		}
		// FlxG.overlap(this, PlayState._spikeSpriteList, OnCollisionWithSpike);
	}

	private function OnCollisionWithSpike(spike:FlxSprite)
	{
		if (!spike.visible)
			return;
		var damage = GameManagerBase.Main._damage;
		// CameraShake.Main.TriggerShake(0.25f, 0.2f);

		if (currHp - damage <= 0 && !wasPopped)
			{
				wasPopped = true;
				GameManagerBase.Main.OnCirclePopped(this);
				var flxSound = FlxG.sound.play(Global.asset("assets/sounds/FS circle_squish.ogg"), 0.9);
				flxSound.pitch = FlxG.random.float(0.8, 1.2);
				// SoundManager.Main.PlaySound("Circle Squish", true);
				// ParticleManager.Main.SpawnPop((transform.position + collision.transform.position) / 2, collision.GetComponentInParent<Spike>().GetPopAngle(), _type);
				// ParticleManager.Main.SpawnSplat(transform.position, _type);
				kill();
			}
			else
			{
				currHp -= damage;
				// SoundManager.Main.PlaySound("Circle Squish (Small)", true);
				var flxSound = FlxG.sound.play(Global.asset("assets/sounds/FS Small Squish.ogg"), 0.9);
				flxSound.pitch = FlxG.random.float(0.8, 1.2);
			}
	}
	/*
		private void OnTriggerEnter2D(Collider2D collision)
		{
			try
			{
				if (collision.CompareTag("Miss Zone"))
				{
					GameManagerBase.Main.OnCircleEscaped(gameObject);
					Destroy(gameObject);
				}
				if (collision.CompareTag("Spike") && transform.position.y > GameManager.Main.PopZone.position.y)
				{
					damage = GameManagerBase.Main.Damage;
					CameraShake.Main.TriggerShake(0.25f, 0.2f);
					if (currHp - damage <= 0 && !wasPopped)
					{
						wasPopped = true;
						GameManagerBase.Main.OnCirclePopped(gameObject);
						SoundManager.Main.PlaySound("Circle Squish", true);
						ParticleManager.Main.SpawnPop((transform.position + collision.transform.position) / 2, collision.GetComponentInParent<Spike>().GetPopAngle(), _type);
						ParticleManager.Main.SpawnSplat(transform.position, _type);
						Destroy(gameObject);
					}
					else
					{
						currHp -= damage;
						SoundManager.Main.PlaySound("Circle Squish (Small)", true);
					}
				}
			}
			catch(System.Exception e)
			{
				ErrorScreenManager.Main.ShowError(e.ToString());
			}
			// If wall, do nothing??
		}*/
}
