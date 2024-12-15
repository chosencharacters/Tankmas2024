package tripletriangle;

import coroutine.CoroutineRunner;
import coroutine.Routine;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.input.FlxPointer;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import lime.math.Vector2;

#if ADVENT
import utils.OverlayGlobal as Global;
#else
import utils.Global;
#end

private class Rigidbody2D {}
private class Stopwatch {}

class SpikesController extends FlxObject // importantly includes position.
{
	public static var Main:SpikesController;

	private var swTapCooldown:Stopwatch;
	private var swtTapCooldown:Float = 1;
	private var swTapCooldownWasRunningBeforePause:Bool = false;

	public var topSpike:Spike;
	public var rightSpike:Spike;
	public var leftSpike:Spike;

	private final spikeAnimationTime:Float = 1;

	//private var _soundManager:SoundManager;

	private var playgroundRight:Int;
	private var playgroundLeft:Int;
	private var playgroundTop:Int;
	private var playgroundBottom:Int;
	
	private var pointer:FlxPointer;

	override public function new(p_state:FlxState)
	{
		super();
		if (Main == null)
			Main = this;

		topSpike = new Spike(120 + 16, 240 - 32, "assets/images/Triangle Bottom.png", Spike.ESpikeAngle.down);
		rightSpike = new Spike(240 - 32, 120 - 16, "assets/images/Triangle Right.png", Spike.ESpikeAngle.right);
		leftSpike = new Spike(80, 120 - 16);
		for (spike in [topSpike, rightSpike, leftSpike])
		{
			spike.AddToState(p_state);
		}
		// p_spikeGroup.add(topSpike);
		// p_spikeGroup.add(rightSpike);
		// p_spikeGroup.add(leftSpike);

		pointer = new FlxPointer();

		//swTapCooldown = new Stopwatch();

		//_soundManager = GetComponent<SoundManager>();

		playgroundLeft = 80; // camera.transform.position.x - cameraWidth / 2 -> 80
		playgroundRight = 240; // playgroundLeft + playgroundWidth -> 240
		playgroundTop = 0; // camera.transform.position.y + playgroundHeight / 2; -> 0
		playgroundBottom = 240; // camera.transform.position.y - playgroundHeight / 2; -> 240
	}

	override public function update(elapsed:Float)
	{
		var clampedPosition:Vector2;
		// FlxG.mouse.getWorldPosition().inCoords(x, y, width, height)
		// FlxG.mouse.x
		var pointer:FlxPoint = FlxG.mouse.getWorldPosition();

		if (FlxG.mouse.justPressed)
		{
			//clampedPosition = new Vector2(FlxMath.wrap(Camera.main.ScreenToWorldPoint(Input.mousePosition).x, cameraLeft, cameraRight),
			//	Mathf.Clamp(Camera.main.ScreenToWorldPoint(Input.mousePosition).y, cameraBottom, cameraTop));
			clampedPosition = new Vector2(FlxMath.bound(cast pointer.x, playgroundLeft, playgroundRight- 32),
				FlxMath.bound(cast pointer.y, playgroundTop, playgroundBottom - 32));
			ActivateSpikes(clampedPosition);
			//swTapCooldown.Restart();
		}
		
		/*HandleBounce(elapsed);
		HandleMovement(elapsed);
		HandleOutOfScreen();*/

		super.update(elapsed);
	}
	
	function Update(elapsed:Float)
	{
		var clampedPosition:Vector2;

		/*if ((!swTapCooldown.IsRunning || swTapCooldown.Elapsed.TotalSeconds > swtTapCooldown))
		{
			// Touch = Opposite of hold n' release - Touch to activate spikes.
			if (SettingsManager.Main._isTouchEnabled)
			{
				if (Input.GetMouseButtonDown(0))
				{
					clampedPosition = new Vector2(Mathf.Clamp(Camera.main.ScreenToWorldPoint(Input.mousePosition).x, cameraLeft, cameraRight),
						Mathf.Clamp(Camera.main.ScreenToWorldPoint(Input.mousePosition).y, cameraBottom, cameraTop));
					ActivateSpikes(clampedPosition);
					swTapCooldown.Restart();
				}
			}
			else
			{
				// Hold n' release
				clampedPosition = new Vector2(Mathf.Clamp(Camera.main.ScreenToWorldPoint(Input.mousePosition).x, cameraLeft, cameraRight),
					Mathf.Clamp(Camera.main.ScreenToWorldPoint(Input.mousePosition).y, cameraBottom, cameraTop));

				if (Input.GetMouseButton(0))
				{
					PrepareSpikes(clampedPosition);
				}
				else if (Input.GetMouseButtonUp(0))
				{
					ActivateSpikes(clampedPosition);
					swTapCooldown.Restart();
				}
			}
		}*/
	}

	// Setup function, called by GameManagerBase.cs
	public function OnStartGame(GameManagerBase:GameManagerBase)
	{
		//GlobalMasterManager.Main.GameState = EGameState.Game;
		topSpike = GameManagerBase.topSpike;
		rightSpike = GameManagerBase.rightSpike;
		leftSpike = GameManagerBase.leftSpike;
	}

	private function PrepareSpikes(tapPos:Vector2)
	{
		var newTopSpikePosition = new Vector2(tapPos.x, topSpike.getPosition().y);
		topSpike.setPosition(newTopSpikePosition.x, newTopSpikePosition.y);
		var newRightSpikePosition = new Vector2(rightSpike.getPosition().x, tapPos.y);
		rightSpike.setPosition(newRightSpikePosition.x, newRightSpikePosition.y);
		var newLeftSpikePosition = new Vector2(leftSpike.getPosition().x, tapPos.y);
		leftSpike.setPosition(newLeftSpikePosition.x, newLeftSpikePosition.y);
	}

	private function ActivateSpikes(tapPos:Vector2)
	{
		var newTopSpikePosition = new Vector2(tapPos.x, topSpike.getPosition().y);
		topSpike.setPosition(newTopSpikePosition.x, newTopSpikePosition.y);
		var newRightSpikePosition = new Vector2(rightSpike.getPosition().x, tapPos.y);
		rightSpike.setPosition(newRightSpikePosition.x, newRightSpikePosition.y);
		var newLeftSpikePosition = new Vector2(leftSpike.getPosition().x, tapPos.y);
		leftSpike.setPosition(newLeftSpikePosition.x, newLeftSpikePosition.y);
		//topSpike.GetComponentInChildren<Spike>().Launch();
		//rightSpike.GetComponentInChildren<Spike>().Launch();
		//leftSpike.GetComponentInChildren<Spike>().Launch();
		//SoundManager.Main.PlaySound("Spike Launch");
		//StartCoroutine(FinishCombo());
	}

	private function FinishCombo():Routine
	{
		@yield return WaitDelay(spikeAnimationTime);
		//ComboManager.Main.FinishCombo();
	}
}
