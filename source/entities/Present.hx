package entities;

import data.types.TankmasEnums.PresentAnimation;
import entities.base.NGSprite;
import flixel.util.FlxTimer;
import fx.Thumbnail;
import states.substates.ArtSubstate;
import states.substates.ComicSubstate;

class Present extends Interactable
{
	public var openable:Bool = true;
	public static var opened:Bool = false;

	public var thumbnail:Thumbnail;
	var content:String;
	var comic:Bool = false;

	public function new(?X:Float, ?Y:Float, ?content:String = 'thedyingsun', opened:Bool = false, isComic:Bool = false)
	{
		super(X, Y);
		detect_range = 300;
		interactable = true;
		this.content = content;
		this.comic = isComic;

		type = Interactable.InteractableType.PRESENT;
		
		// TODO: make presents look for skins based on content string (need to get present assets done first)
		loadAllFromAnimationSet('present-1');

		PlayState.self.presents.add(this);

		if (!opened)
		{
			sprite_anim.anim(PresentAnimation.IDLE);
			sstate(IDLE);
		}
		else
		{
			// sprite_anim.anim(PresentAnimation.OPENED);
			sstate(OPENED);
		}
		thumbnail = new Thumbnail(x, y - 200, Paths.get((content + (comic ? '-0' : '') + '.png')));
	}

	override function kill()
	{
		PlayState.self.presents.remove(this, true);
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
				sprite_anim.anim(PresentAnimation.IDLE);
				if (thumbnail.state != "CLOSE")
					thumbnail.sstate("CLOSE");
			case NEARBY:
				sprite_anim.anim(PresentAnimation.NEARBY);
				thumbnail.sstate("OPEN");
				if (Ctrl.interact[1])
					open();
			case OPENING:
				// animProtect("opening");
			case OPENED:			
				// animProtect("opened");
		}

	override public function mark_target(mark:Bool)
	{
		if (!opened)
		{
			if (mark && openable)
				sstate(NEARBY);
			if (!mark && openable)
				sstate(IDLE);
		}
		else
		{
			if (mark /** && thumbnail.scale.x == 0**/)
			{
				thumbnail.sstate("OPEN");
				if (Ctrl.interact[1])
					open();
			}
			else if (!mark /** && thumbnail.scale.x != 0 && thumbnail.state != "CLOSE"**/)
				thumbnail.sstate("CLOSE");
		}
	}

	override function updateMotion(elapsed:Float)
	{
		super.updateMotion(elapsed);
		// TODO: thumbnail here
	}

	public function open()
	{
		// if (openable)
		// {
		if (state != "OPENED")
		{
			sstate(OPENING);
			new FlxTimer().start(1, function(tmr:FlxTimer)
			{
				// TODO: sound effect
				sstate(OPENED);
				PlayState.self.openSubState(comic ? new ComicSubstate(content, true) : new ArtSubstate(content));
				opened = true;
			});
		}
		else
		{
			// TODO: sound effect
			PlayState.self.openSubState(comic ? new ComicSubstate(content, false) : new ArtSubstate(content));
		}
		// openable = false;
		// }
	}
}

private enum abstract State(String) from String to String
{
	final IDLE;
	final NEARBY;
	final OPENING;
	final OPENED;
}
