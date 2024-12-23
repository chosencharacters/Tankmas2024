package tripletriangle;

import flixel.util.FlxTimer;
import lime.math.Vector2;
import tripletriangle.BasicCircle.Circle_AngleAmount;
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

private class Rigidbody2D {}
private class CircleCollider2D {}
private class Stopwatch {}

class MoleCircle extends BasicCircle
{
    var playgroundMiddle:Vector2;

	override public function new(p_x:Float = 120, p_y:Float = 160, graphicAssetPath:String = "assets/images/Circle Angry Faic.png", p_type:CircleType = CircleType.Mole,
        p_angleAmount:Circle_AngleAmount = Circle_AngleAmount.Two, p_force:Float = 50, p_min_first_angle:Float = 30, p_max_first_angle:Float = 85,
        p_min_second_angle:Float = 95, p_max_second_angle:Float = 150, p_startHp:Int = 1)
	{
		super(p_x, p_y, graphicAssetPath, p_type,
			p_angleAmount, p_force, p_min_first_angle, p_max_first_angle,
			p_min_second_angle, p_max_second_angle, p_startHp);

        velocityWoRotation = new FlxPoint();  // Stop motion until Launch().
        
        playgroundMiddle = new Vector2(playgroundLeft + playgroundWidth / 2, playgroundTop + playgroundHeight / 2);

		var startAngle:Float = FlxG.random.float(0, 360);
    	var startDistance:Float = FlxG.random.float(0, 4);
    	var startVector:Vector2 = new Vector2(Math.cos(startAngle) * startDistance, Math.sin(startAngle) * startDistance);
		
        var startPosition:Vector2 = playgroundMiddle.add(startVector);
    	setPosition(startPosition.x, startPosition.y);
		
    	//Instantiate(_psMoleEffect, transform.position, Quaternion.identity);
    	//SoundManager.Main.PlaySound("Mole Burrow");
		
        // haxe.Timer.delay(function () { LaunchToWall(); }, 1);  // Doesn't wait
        // new FlxTimer().start(1, LaunchToWall);  // Error
        haxe.Timer.delay(LaunchToWall, 1000);
		/*var timer = new haxe.Timer(1000); // 1000ms delay
		timer.run = function() { ... }*/
	    //Invoker.InvokeDelayed(LaunchToWall, 1);
	}
	
	/*override public function new(p_x:Float = 120, p_y:Float = 160, graphicAssetPath:String = "assets/images/Circle Angry Faic.png",
			p_type:CircleType = CircleType.Mole,
			p_minFirstAngle:Float = 30, p_maxFirstAngle:Float = 85, p_minSecondAngle:Float = 95, p_maxSecondAngle:Float = 150, p_startHp:Int = 1)
	{
		var graphicAsset = Global.asset(graphicAssetPath);
		super(p_x, p_y, graphicAsset);
		offset.set(width / 2, height / 2); // Center circle around position, by setting pivot point kinda.

		type = p_type;
		currentVelocity = 0;
		bloonAcceleration = p_minFirstAngle  ;
		
		
		
		startHp = p_startHp;

		swCollision_lastOccurrenceTimeInSeconds = -999;

		var camera:FlxCamera = FlxG.camera;
		var playgroundHeight:Float = 240; // camera.orthographicSize * 2 -> camera.height * 2 -> 240
		playgroundWidth = 160; // cameraHeight * camera.aspect -> camera.width -> 160
		playgroundLeft = 80; // camera.transform.position.x - cameraWidth / 2 -> 80
		playgroundRight = 240; // playgroundLeft + playgroundWidth -> 240
		playgroundTop = 0; // camera.transform.position.y + playgroundHeight / 2; -> 0
		playgroundBottom = 240; // camera.transform.position.y - playgroundHeight / 2; -> 240
    
		//setPosition(playgroundLeft + FlxG.random.float(0 + playgroundWidth * 0.1, playgroundWidth * 0.9), playgroundTop - 2);
		
		var startAngle:Float = UnityEngine.Random.Range(0f, 360);
    var startDistance:Float = UnityEngine.Random.Range(0, 4);
    var startVector:Vector2 = startDistance * new Vector2(Mathf.Cos(startAngle), Mathf.Sin(startAngle));
    
    transform.position = _cameraMiddle + startVector;
    
    //Instantiate(_psMoleEffect, transform.position, Quaternion.identity);
    //SoundManager.Main.PlaySound("Mole Burrow");
    
    Invoker.InvokeDelayed(LaunchToWall, 1);
		
		currHp = startHp;
	}*/

	/*private function HandleMovement(elapsed:Float){
		currentVelocity += bloonAcceleration * elapsed;
		y += currentVelocity * elapsed;
	}*/

	/*private function HandleOutOfScreen()
	{
		if (y - radius > playgroundBottom)
		{
			// Passed the bottom of the screen.
			GameManagerBase.Main.OnCircleEscaped(this);
			super.kill();
		}
	}*/

	override public function update(elapsed:Float)
	{
		HandleBounce(elapsed);
		HandleMovement(elapsed);
		HandleOutOfScreen();
		HandleCollisions();
		
		// super.update(elapsed);  // Gotta override the HandleMovement() and HandleBounce() functions.
	}

    // Bounces only once.
    private override function HandleBounce(elapsed:Float){
		var currentTimeInSeconds = haxe.Timer.stamp();
		if (currentTimeInSeconds > swCollision_lastOccurrenceTimeInSeconds + swCollision_cooldownInSeconds)
		{
			if (x - radius < playgroundLeft)
			{
				// Bounced off the left wall.
				Bounce(1);
                Launch();
				swCollision_lastOccurrenceTimeInSeconds = currentTimeInSeconds;
			}
			else if (x + radius > playgroundRight)
			{
				// Bounced off the right wall.
				Bounce(-1);
                Launch();
				swCollision_lastOccurrenceTimeInSeconds = currentTimeInSeconds;
			}
		}
	}

    private function Launch()
    {
        velocity = new FlxPoint();
        var targetVector:Vector2 = new Vector2(playgroundMiddle.x + FlxG.random.float(-playgroundWidth / 4, playgroundWidth / 4), playgroundBottom);
        // trace("]]] " + playgroundMiddle.x + " becomes!: " + targetVector.x);
        var currentPosition = getPosition();
        var circleAngle = Math.atan2(currentPosition.y - targetVector.y, targetVector.x - currentPosition.x) * FlxAngle.TO_DEG + 180;  // + 180 because unlike the OG Triple Triangle, the direction is down, and not up. Also flipped subtraction order.
        trace("]]] " + circleAngle + " | " + currentPosition.x);
        AddForceAtAngle(force, circleAngle);
    }
	
	private function LaunchToWall()
  	{
    	// trace("TODO: LaunchAtWall()");
		AddForceAtAngle(force, FlxG.random.int(0, 1) * 180, false);  // either 0 or 180
    	//EnemyCircle.AddForceAtAngle(force, FlxG.random.float(0, 2) * 180);  // either 0 or 180
  	}
  
  	// TODO: Take directly from Basic Circle? Maybe inherit Basic Circle, qnd override Start()?
	/*private function HandleCollisions()
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
	}*/

	/*private function OnCollisionWithSpike(spike:FlxSprite)
	{
		if (!spike.visible)
			return;
		GameManagerBase.Main.OnCirclePopped(this);
		kill();
	}*/
}
