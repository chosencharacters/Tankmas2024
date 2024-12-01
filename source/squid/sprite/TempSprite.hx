package squid.sprite;

/**
 * Lasts until animation is over then kills itself :(
 * @author Squidly
 */
class TempSprite extends FlxSpriteExt
{
	/***Previous frame of animation***/
	public var prevFrame:Int = 0;

	var tickSet:Int = 0;

	var life_tick:Int = 0;

	// this is different from on_update()
	public var onUpdate:Void->Void;
	public var onComplete:Void->Void;

	var dynamic_group:FlxTypedGroup<Dynamic>;

	public var no_auto_kill:Bool = false;

	var resolved:Bool = false;

	public function new(?X:Float = 0, ?Y:Float = 0, ?point:FlxPoint, ?tickSet:Int = 0, ?sprite_load:String = "", ?dynamic_group:FlxTypedGroup<Dynamic>,
			?onComplete:Void->Void)
	{
		super(X, Y);

		if (point != null)
			this.copy_from_position(point);

		this.life_tick = tickSet;
		this.tickSet = tickSet;
		this.onComplete = onComplete;

		if (sprite_load != "")
			loadAllFromAnimationSet(sprite_load);

		this.dynamic_group = dynamic_group;

		if (dynamic_group != null)
			dynamic_group.add(this);
	}

	override public function update(elapsed:Float):Void
	{
		if (resolved)
			return;

		if (onUpdate != null)
			onUpdate();
		trailUpdate();
		life_tick--;
		if (animation.finished && tickSet <= 0 || life_tick <= 0 && tickSet > 0)
		{
			if (!no_auto_kill)
				kill();
			onComplete != null ? onComplete() : null;
			resolved = true;
		}
		prevFrame = animation.frameIndex;

		super.update(elapsed);
	}

	override public function kill():Void
	{
		FlxG.state.remove(this, true);

		if (dynamic_group != null)
			dynamic_group.remove(this, true);

		super.kill();
	}

	var trailTarget:FlxSprite;
	var trailInt:Int = 0;
	var frameMode:Bool = false;
	var trailOffset:FlxPoint;

	// frame mode to toggle between trailSet being for time or frames
	public function setTrail(trailTargetSet:FlxSprite, trailIntSet:Int, frameModeSet:Bool = false)
	{
		trailTarget = trailTargetSet;
		trailInt = trailIntSet;
		frameMode = frameModeSet;
		trailOffset = new FlxPoint(x - trailTarget.x, y - trailTarget.y);
	}

	function trailUpdate()
	{
		if (trailTarget == null)
			return;
		if (!frameMode)
			trailInt--;
		if (frameMode && animation.frameIndex < trailInt || !frameMode && trailInt > 0)
		{
			setPosition(trailTarget.x + trailOffset.x, trailTarget.y + trailOffset.y);
		}
	}

	override public function isOnScreen(?Camera:FlxCamera):Bool
	{
		return true;
	}
}
