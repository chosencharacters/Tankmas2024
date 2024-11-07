package entities;

import entities.base.NGSprite;

class Present extends NGSprite
{
	public var detect_range:Int = 300;

	public var openable:Bool = true;

	public function new(?X:Float, ?Y:Float)
	{
		super(X, Y);
		loadAllFromAnimationSet("present");

		PlayState.self.presents.add(this);
		screenCenter();

		x += 500;
	}

	override function kill() {
		PlayState.self.presents.remove(this,true);
		super.kill();
	}

	override function update(elapsed:Float)
	{
		fsm();
		super.update(elapsed);
	}

	function fsm()
		switch (cast(state, State))
		{
			default:
			case IDLE:
				animProtect("idle");
			case NEARBY:
				animProtect("nearby");
			case OPENING:
				animProtect("opening");
				if(animation.finished)
					sstate(OPENED);
			case OPENED:			
				animProtect("opened");

		
		}

	public static function find_present_in_detect_range(player:Player):Present
	{
		var presents_in_range:Array<{present:Present, distance:Float}>=[];
		var mp_player:FlxPoint = player.mp;

		for(present in PlayState.self.presents){
			var distance:Float = present.mp.distance(player.mp);
			if(distance<=present.detect_range)
				presents_in_range.push({present:present, distance:distance});
		}

		if(presents_in_range.length>0){
			presents_in_range.sort((a, b) -> a.distance > b.distance ? 1 : -1); //might be other way around
			return presents_in_range.pop().present; // or this might be shift
		}

		return null;
	}
	public static function un_mark_all_presents()
	{
		for (present in PlayState.self.presents)
			present.mark_target(false);
	}

	public function mark_target(mark:Bool)
	{
		if (mark && openable)
			sstate(NEARBY);
		if (!mark && openable)
			sstate(IDLE);
	}

	public function open()
	{
		if (openable)
			sstate(OPENING);
		openable = false;
	}
}

private enum abstract State(String) from String to String {
	final IDLE;
	final NEARBY;
	final OPENING;
	final OPENED;
}
