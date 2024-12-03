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

	public var opened:Bool = false;

	public var thumbnail:Thumbnail;

	var content:String;
	var day:Int = 0;
	var comic:Bool = false;

	var def:PresentDef;

	public function new(?X:Float, ?Y:Float, ?content:String = 'thedyingsun')
	{
		super(X, Y);
		detect_range = 300;
		this.content = content;

		// trace(content, JsonData.get_all_present_names());
		def = JsonData.get_present(this.content);
		if (def == null)
		{
			throw 'Error getting present: content ${content}; defaulting to default content';
			def = JsonData.get_present('thedyingsun');
		}
		comic = def.comicProperties != null ? true : false;

		openable = true;

		type = Interactable.InteractableType.PRESENT;

		loadAllFromAnimationSet("present-any", 'present-$content');

		PlayState.self.presents.add(this);
		thumbnail = new Thumbnail(x, y - 200, Paths.get(def.file));

		#if censor_presents
		thumbnail.color = FlxColor.BLACK;
		#end

		update_present_visible();
	}

	public function update_present_visible()
	{
		visible = Main.time.date >= def.day;
	}

	override function kill()
	{
		PlayState.self.presents.remove(this, true);
		super.kill();
	}

	public function checkOpen()
	{
		opened = SaveManager.savedPresents.contains(content);
		if (!opened)
		{
			sprite_anim.anim(PresentAnimation.IDLE);
			sstate(IDLE);
			frame = frames.frames[0];
		}
		else
		{
			sprite_anim.anim(PresentAnimation.OPENED);
			sstate(OPENED);
		}
	}

	override function update(elapsed:Float)
	{
		update_present_visible();
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

		if (mark)
			thumbnail.sstate("OPEN");
		else if (!mark)
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
			new FlxTimer().start(0.24, (tmr:FlxTimer) -> SoundPlayer.sound(Paths.get('present-open.ogg')));
			new FlxTimer().start(1.2, function(tmr:FlxTimer)
			{
				sstate(OPENED);
				thumbnail.sstate("OPEN");
				PlayState.self.openSubState(comic ? new ComicSubstate(content, true) : new ArtSubstate(content));
				opened = true;
				SaveManager.open_present(content, def.day);
			});
		}
		else
		{
			SoundPlayer.sound(Paths.get('present-open.ogg'));
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
