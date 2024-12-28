package tripletriangle;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxAngle;
import flixel.math.FlxPoint;
import flixel.util.FlxCollision;
import tripletriangle.GenericCircle.CircleType;
// using static GameManagerBase;
#if ADVENT
import utils.OverlayGlobal as Global;
#else
import utils.Global;
#end

private class Rigidbody2D {}
private class CircleCollider2D {}
private class Stopwatch {}

class BloonCircle extends GenericCircle
{
	public var currentVelocity:Float = 0;
	public var bloonAcceleration:Float;

	private var playgroundLeft:Float;
	private var playgroundRight:Float;
	private var playgroundWidth:Float;
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

	override public function new(p_x:Float = 120, p_y:Float = 160, graphicAssetPath:String = "assets/images/Circle Ena.png",
			p_type:CircleType = CircleType.Bloon, p_bloonAcceleration:Float = 25, p_startHp:Int = 1)
	{
		var graphicAsset = Global.asset(graphicAssetPath);
		super(p_x, p_y, graphicAsset);
		offset.set(width / 2, height / 2); // Center circle around position, by setting pivot point kinda.

		type = p_type;
		currentVelocity = 0;
		bloonAcceleration = p_bloonAcceleration;
		startHp = p_startHp;

		swCollision_lastOccurrenceTimeInSeconds = -999;

		var camera:FlxCamera = FlxG.camera;
		var playgroundHeight:Float = 240; // camera.orthographicSize * 2 -> camera.height * 2 -> 240
		playgroundWidth = 160; // cameraHeight * camera.aspect -> camera.width -> 160
		playgroundLeft = 80; // camera.transform.position.x - cameraWidth / 2 -> 80
		playgroundRight = 240; // playgroundLeft + playgroundWidth -> 240
		playgroundTop = 0; // camera.transform.position.y + playgroundHeight / 2; -> 0
		playgroundBottom = 240; // camera.transform.position.y - playgroundHeight / 2; -> 240

		setPosition(playgroundLeft + FlxG.random.float(0 + playgroundWidth * 0.1, playgroundWidth * 0.9), playgroundTop - 2);

		currHp = startHp;
	}

	private function HandleMovement(elapsed:Float)
	{
		currentVelocity += bloonAcceleration * elapsed;
		y += currentVelocity * elapsed;
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
		HandleMovement(elapsed);
		HandleOutOfScreen();
		HandleCollisions();

		super.update(elapsed);
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
		GameManagerBase.Main.OnCirclePopped(this);
		kill();
	}
}
