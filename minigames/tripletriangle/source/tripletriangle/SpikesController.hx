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
import flixel.text.FlxBitmapText;
import flixel.text.FlxText.FlxTextAlign;
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

	private var swSpikeActivation_lastOccurrenceTimeInSeconds:Float = -999;
	private final swSpikeActivation_cooldownInSeconds:Float = 1.075; // Just a bit more than 1. Otherwise, spikes might activate while they are not in rest position, causing mispositions.

	// private var swtTapCooldown:Float = 1;
	// private var swTapCooldownWasRunningBeforePause:Bool = false;
	public var topSpike:Spike; // TODO: Rename topSpike to bottomSpike
	public var rightSpike:Spike;
	public var leftSpike:Spike;

	private final spikeAnimationTime:Float = 1;

	// private var _soundManager:SoundManager;
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

		var halfSpikeWidth = 16; // Or height.
		topSpike = new Spike(120 + 16 + halfSpikeWidth, 240 + halfSpikeWidth, "assets/images/Triangle Bottom.png", Spike.ESpikeAngle.down);
		rightSpike = new Spike(240 + halfSpikeWidth, 120 - 16 + halfSpikeWidth, "assets/images/Triangle Right.png", Spike.ESpikeAngle.right);
		leftSpike = new Spike(80 - halfSpikeWidth, 120 - 16 + halfSpikeWidth);
		topSpike.visible = false;
		for (spike in [topSpike, rightSpike, leftSpike])
		{
			spike.AddToState(p_state);
		}
		// p_spikeGroup.add(topSpike);
		// p_spikeGroup.add(rightSpike);
		// p_spikeGroup.add(leftSpike);

		pointer = new FlxPointer();

		// swTapCooldown = new Stopwatch();

		// _soundManager = GetComponent<SoundManager>();

		playgroundLeft = 80; // camera.transform.position.x - cameraWidth / 2 -> 80
		playgroundRight = 240; // playgroundLeft + playgroundWidth -> 240
		playgroundTop = 0; // camera.transform.position.y + playgroundHeight / 2; -> 0
		playgroundBottom = 240; // camera.transform.position.y - playgroundHeight / 2; -> 240
	}

	override public function update(elapsed:Float)
	{
		var currentTimeInSeconds = haxe.Timer.stamp();

		var clampedPosition:Vector2;
		var pointer:FlxPoint = FlxG.mouse.getWorldPosition();

		if (currentTimeInSeconds > swSpikeActivation_lastOccurrenceTimeInSeconds + swSpikeActivation_cooldownInSeconds)
		{
			if (FlxG.mouse.justPressed)
			{
				clampedPosition = new Vector2(FlxMath.bound(cast pointer.x, playgroundLeft, playgroundRight - 32),
					FlxMath.bound(cast pointer.y, playgroundTop, playgroundBottom - 32));
				ActivateSpikes(clampedPosition);
				swSpikeActivation_lastOccurrenceTimeInSeconds = currentTimeInSeconds;
			}
		}

		super.update(elapsed);
	}

	/*function Update(elapsed:Float)
		{
			var clampedPosition:Vector2;

			if ((!swTapCooldown.IsRunning || swTapCooldown.Elapsed.TotalSeconds > swtTapCooldown))
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
			}
	}*/
	// Setup function, called by GameManagerBase.cs
	public function OnStartGame(GameManagerBase:GameManagerBase)
	{
		// GlobalMasterManager.Main.GameState = EGameState.Game;
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

	/*var idleBottomSpikePosition:Vector2;
		var idleRightSpikePosition:Vector2;
		var idleLeftSpikePosition:Vector2;
		var launchedBottomSpikePosition:Vector2;
		var launchedRightSpikePosition:Vector2;
		var launchedLeftSpikePosition:Vector2; */
	private function ActivateSpikes(tapPos:Vector2)
	{
		var idleBottomSpikePosition = new Vector2(tapPos.x, topSpike.getPosition().y);
		StartCoroutine(topSpike.Launch(idleBottomSpikePosition, idleBottomSpikePosition.add(new Vector2(0, -32))));
		var idleRightSpikePosition = new Vector2(rightSpike.getPosition().x, tapPos.y);
		StartCoroutine(rightSpike.Launch(idleRightSpikePosition, idleRightSpikePosition.add(new Vector2(-32, 0))));
		var idleLeftSpikePosition = new Vector2(leftSpike.getPosition().x, tapPos.y);
		StartCoroutine(leftSpike.Launch(idleLeftSpikePosition, idleLeftSpikePosition.add(new Vector2(32, 0))));

		var flxSound = FlxG.sound.play(Global.asset("assets/sounds/FS spike_merged.ogg"), 0.6);
		flxSound.pitch = FlxG.random.float(0.95, 1.05);
		StartCoroutine(FinishCombo());
	}

	// TODO: Make this static, move to another class, and access it from anywhere you wanna start a routine.
	private function StartCoroutine(routine:Routine)
	{
		var routineRunner = new CoroutineRunner();
		routineRunner.startCoroutine(routine);
		new haxe.Timer(16).run = function()
		{
			var processor = CoroutineProcessor.of(routineRunner);
			processor.updateEnterFrame();
			processor.updateTimer(haxe.Timer.stamp());
			processor.updateExitFrame();
		}
	}

	private function FinishCombo():Routine
	{
		@yield return WaitDelay(spikeAnimationTime);
		StartCoroutine(ComboManager.Main.FinishCombo());
	}
}
