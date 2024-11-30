package entities;

import data.JsonData;
import data.SaveManager;
import data.types.TankmasDefs.PresentDef;
import data.types.TankmasEnums.PresentAnimation;
import entities.base.NGSprite;
import flixel.util.FlxTimer;
import fx.Thumbnail;
import states.substates.ArtSubstate;
import states.substates.ComicSubstate;

class Present extends Interactable
{
	public var openable(default, set):Bool = true;

	function set_openable(o)
	{
		interactable = o;
		return openable = o;
	}

	public static var opened:Bool = false;

	public var thumbnail:Thumbnail;

	var content:String;
	var day:Int = 0;
	var comic:Bool = false;

	public function new(?X:Float, ?Y:Float, ?content:String = 'thedyingsun')
	{
		super(X, Y);
		detect_range = 300;
		this.content = content;
		var presentData:PresentDef = JsonData.get_present(this.content);
		if (presentData == null)
		{
			throw 'Error getting present: content ${content}; defaulting to default content';
			presentData = JsonData.get_present('thedyingsun');
		}
		comic = presentData.comicProperties != null ? true : false;
		opened = SaveManager.savedPresents.contains(content);
		day = Std.parseInt(presentData.day);

		openable = true;

		type = Interactable.InteractableType.PRESENT;

		loadGraphic(Paths.get('present-$content.png'), true, 94, 94);

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
			case NEARBY:
				sprite_anim.anim(PresentAnimation.NEARBY);
			case OPENING:
				sprite_anim.anim(PresentAnimation.OPENING);
			case OPENED:
				sprite_anim.anim(PresentAnimation.OPENED);
		}

	override function on_interact()
	{
		open();
	}

	override public function mark_target(mark:Bool)
	{
		if (!openable)
			return;

		if (mark)
			sstate(opened ? OPENED : NEARBY);
		else
			sstate(IDLE);

		if (!opened)
			return;

		if (mark /** && thumbnail.scale.x == 0**/)
		{
			thumbnail.sstate("OPEN");
		}
		else if (!mark /** && thumbnail.scale.x != 0 && thumbnail.state != "CLOSE"**/)
			thumbnail.sstate("CLOSE");
	}

	override function updateMotion(elapsed:Float)
	{
		super.updateMotion(elapsed);
		// TODO: thumbnail here
	}

	public function open()
	{
		if (state != "OPENED")
		{
			sstate(OPENING);
			new FlxTimer().start(1, function(tmr:FlxTimer)
			{
				// TODO: sound effect
				sstate(OPENED);
				thumbnail.sstate("OPEN");
				PlayState.self.openSubState(comic ? new ComicSubstate(content, true) : new ArtSubstate(content));
				opened = true;
				SaveManager.open_present(content, day);
			});
		}
		else
		{
			// TODO: sound effect
			PlayState.self.openSubState(comic ? new ComicSubstate(content, false) : new ArtSubstate(content));
		}
	}
}

private enum abstract State(String) from String to String
{
	final IDLE;
	final NEARBY;
	final OPENING;
	final OPENED;
}
