package tripletriangle;

import flixel.math.FlxPoint;
import coroutine.CoroutineRunner;
import coroutine.Routine;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.system.FlxAssets.FlxGraphicAsset;

#if ADVENT
import utils.OverlayGlobal as Global;
#else
import utils.Global;
#end

private class Animator {}
private class Stopwatch {}

enum abstract ESpikeAngle(Int)
{
	var right = 0;
	var left = 180;
	var down = 270;
}

class Spike extends FlxObject
{
    private var animator: Animator;
    public var popAngle: ESpikeAngle;
	public var firstSpike:FlxSprite;
	public var secondSpike:FlxSprite; // For the Triple Triangle pickup
	public var thirdSpike:FlxSprite; // For the Triple Triangle pickup

	private var extraSpikes_dx:Float;
	private var extraSpikes_dy:Float;

	override public function new(p_x:Float = 120, p_y:Float = 160, graphicAssetPath:String = "assets/images/Triangle Left.png",
			p_popAngle:ESpikeAngle = ESpikeAngle.left)
    {
		var graphicAsset = Global.asset(graphicAssetPath);
		super(p_x, p_y);
		popAngle = p_popAngle;
		firstSpike = new FlxSprite(p_x, p_y, graphicAsset);
		firstSpike.offset.x = 16;
		firstSpike.offset.y = 16;

		extraSpikes_dx = (p_popAngle == ESpikeAngle.down) ? 32 : 0;
		extraSpikes_dy = (p_popAngle == ESpikeAngle.down) ? 0 : 32;
		secondSpike = new FlxSprite(p_x + extraSpikes_dx, p_y + extraSpikes_dy, graphicAsset);
		thirdSpike = new FlxSprite(p_x - extraSpikes_dx, p_y - extraSpikes_dy, graphicAsset);
		secondSpike.visible = false;
		thirdSpike.visible = false;
		secondSpike.offset.x = 16;
		secondSpike.offset.y = 16;
		thirdSpike.offset.x = 16;
		thirdSpike.offset.y = 16;
		
		// animator = GetComponent<Animator>();

		var coInvisibilityRoutine = new CoroutineRunner();
		coInvisibilityRoutine.startCoroutine(SetInvisibility());
		new haxe.Timer(16).run = function()
		{
			// Customize how/when to update your coroutines
			// Set this at your convenience in your project
			var processor = CoroutineProcessor.of(coInvisibilityRoutine);
			processor.updateEnterFrame();
			processor.updateTimer(haxe.Timer.stamp());
			processor.updateExitFrame();
		}
    }

	public function AddToState(state:FlxState):Void
	{
		state.add(this);
		for (spike in [firstSpike, secondSpike, thirdSpike])
		{
			PlayState._spikeSpriteList.add(spike);
		}
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		firstSpike.setPosition(this.x, this.y);
		secondSpike.setPosition(this.x + extraSpikes_dx, this.y + extraSpikes_dy);
		thirdSpike.setPosition(this.x - extraSpikes_dx, this.y - extraSpikes_dy);
	}

	private function SetInvisibility():Routine
    {
		@yield return WaitEndOfFrame;
		trace("TO IMPLEMENT: SetInvisibility()");
		// animator.SetBool("IsInvisible", SkinManager.Main.AreSpikesInvisible);
		// animator.enabled = true;
		// animator.Play("Idle");
    }

    public function Launch()
    {
		trace("TO IMPLEMENT: Launch()");
		// animator.Play("Launch", -1, 0);
    }

    // This might be useless.
    public function GetPopAngleRaw(): ESpikeAngle
    {
        return popAngle;
    }

    // This value is set to the pop particle system.
	public function GetPopAngle():Int
    {
		return cast popAngle;
    }

	public function SetTripleSpikesActice(isActive:Bool)
    {
		trace("TO IMPLEMENT: SetTripleSpikesActice()");
		// secondSpike.SetActive(isActive);
		// thirdSpike.SetActive(isActive);
    }
}
