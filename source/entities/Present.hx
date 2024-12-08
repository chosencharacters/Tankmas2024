package entities;

import net.tankmas.OnlineLoop;
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

	var username:String;
	var day:Int = 0;
	var comic:Bool = false;

	var def:PresentDef;

	var time_activated(get, never):Bool;

	// Whether or not the present will unlock its medal when opened
	function is_medal_unlock_enabled()
	{
		// Edge case, always award this one.
		if (day == 7 && username == "matthewlopz")
			return true;

		return day == 1 || day == Main.time.day;
	}

	public function new(X:Float, Y:Float, username:String)
	{
		super(X, Y);
		detect_range = 300;
		this.username = username;

		// trace(username, JsonData.get_all_present_names());
		def = JsonData.get_present(this.username);

		day = def.day;

		if (def == null)
			throw 'Error getting present JSON for username ${username}';

		comic = def.comicProperties != null ? true : false;

		openable = true;

		type = Interactable.InteractableType.PRESENT;

		loadAllFromAnimationSet("present-any", 'day-${def.day}-present-$username');

		PlayState.self.presents.add(this);
		thumbnail = new Thumbnail(x, y - 200, Paths.image_path(def.file));

		#if censor_presents
		thumbnail.color = FlxColor.BLACK;
		#end

		update_present_visibility();

		// trace(Main.time.day >= def.day, Main.time.day, def.day, visible);
	}

	function update_present_visibility()
	{
		visible = time_activated;
		interactable = visible;
	}

	function get_time_activated():Bool
		return Main.time.day >= def.day;

	override function kill()
	{
		PlayState.self.presents.remove(this, true);
		super.kill();
	}

	public function checkOpen()
	{
		opened = SaveManager.savedPresents.contains(username);
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
		update_present_visibility();

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
			thumbnail.show();
		else if (!mark)
			thumbnail.hide();
	}

	override function updateMotion(elapsed:Float)
	{
		super.updateMotion(elapsed);
		// TODO: thumbnail here
	}

	public function open()
	{
		var medal_was_unlocked = false;
		var first_time_opening = true;
		if (state != "OPENED")
		{
			sstate(OPENING);
			new FlxTimer().start(0.24, (tmr:FlxTimer) -> SoundPlayer.sound(Paths.get('present-open.ogg')));
			new FlxTimer().start(1.2, function(tmr:FlxTimer)
			{
				sstate(OPENED);
				thumbnail.sstate("OPEN");
				PlayState.self.openSubState(comic ? new ComicSubstate(username, true) : new ArtSubstate(username));
				opened = true;

				medal_was_unlocked = is_medal_unlock_enabled();

				SaveManager.open_present(username, def.day);
			});
		}
		else
		{
			first_time_opening = false;
			// Always try to award medals (fixes an edge case where someone encounters a crash mid-gift)
			SaveManager.open_present(username, def.day);

			SoundPlayer.sound(Paths.get('present-open.ogg'));
			PlayState.self.openSubState(comic ? new ComicSubstate(username, false) : new ArtSubstate(username));
		}

		// Post present opened event to server (it's broadcasted to every other player, and also kept for stats).
		OnlineLoop.post_present_open(day, medal_was_unlocked, first_time_opening);

		if (is_medal_unlock_enabled())
			give_opened_medal();
	}

	function give_opened_medal()
	{
		#if newgrounds
		switch (username)
		{
			case "matthewlopz":
				trace("open present unlock: the little candles");
				return Main.ng_api.medal_popup(Main.ng_api.medals.get("the-little-candles"));
			default:
				trace("open present unlock", username, day);
				return Main.ng_api.medal_popup(Main.ng_api.medals.get('day-$day'));
		}
		#end
	}
}

private enum abstract State(String) from String to String
{
	final IDLE;
	final NEARBY;
	final OPENING;
	final OPENED;
}
