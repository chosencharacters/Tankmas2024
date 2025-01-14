package entities;

import data.JsonData;
import data.SaveManager;
import data.types.TankmasDefs.PresentDef;
import data.types.TankmasEnums.PresentAnimation;
import entities.base.NGSprite;
import flixel.util.FlxTimer;
import fx.Thumbnail;
import net.tankmas.OnlineLoop;
import states.substates.ArtSubstate;
import states.substates.ComicSubstate;
import states.substates.TankmasChroniclesSubstate;

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

	var timelock:Int = 0;

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

	public static var num_25_opened:Int = 0;
	public static final req_num_25_opened:Int = 14;
	public static var num_28_opened:Int = 0;
	public static final req_num_28_opened:Int = 2;
	public static var num_32_opened:Int = 0;
	public static final req_num_32_opened:Int = 6;

	public var final_gift:Bool = false;

	public function new(X:Float, Y:Float, username:String, timelock:Int)
	{
		super(X, Y);
		detect_range = 300;
		this.username = username;

		final_gift = username == "kingcrowned-2";

		// trace(username, JsonData.get_present_names());
		def = JsonData.get_present(this.username);

		if (def == null)
			throw 'Error getting present JSON for username ${username}';

		day = def.day;

		comic = def.comicProperties != null ? true : false;

		if ([
			"dragonmiracles",
			"guri",
			"marbardan82",
			"oscarlors",
			"midgetsausage-2",
			"tankmas-chronicles"
		].contains(username))
			comic = true;

		openable = true;

		type = Interactable.InteractableType.PRESENT;

		loadAllFromAnimationSet("present-default", 'day-${def.day}-present-$username');

		PlayState.self.world_objects.add(this);
		thumbnail = new Thumbnail(x, y - 200, Paths.image_path(def.file), def.file);

		#if censor_presents
		thumbnail.color = FlxColor.BLACK;
		#end

		this.timelock = timelock * 1000;

		update_present_visibility();

		checkOpen();
		this.y_bottom_offset = 16;

		var count:Int = 0;
		for (present in SaveManager.savedPresents)
		{
			if (JsonData.get_present(present).day == 25)
				count++;
			num_25_opened = count;
		}
		count = 0;
		for (present in SaveManager.savedPresents)
		{
			if (JsonData.get_present(present).day == 28)
				count++;
			num_28_opened = count;
		}
		count = 0;
		for (present in SaveManager.savedPresents)
		{
			if (JsonData.get_present(present).day == 32)
				count++;
			num_32_opened = count;
		}

		// trace(Main.time.day >= def.day, Main.time.day, def.day, visible);
	}

	function update_present_visibility()
	{
		var enabled = time_activated;
		if (def.requires_flag != null)
		{
			enabled = enabled && Flags.get_bool(def.requires_flag);
		}

		#if all_presents
		enabled = true;
		#end

		visible = enabled;
		interactable = visible;
	}

	function get_time_activated():Bool
	{
		if (timelock > 0)
			return Main.time.utc >= timelock;
		return Main.time.day >= def.day;
	}

	override function kill()
	{
		PlayState.self.world_objects.remove(this, true);
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

		if (def.unlocks_flag != null)
		{
			Flags.set_bool(def.unlocks_flag);
		}

		if (state != "OPENED")
		{
			if (first_time_opening && day == 25)
				num_25_opened++;

			if (first_time_opening && day == 28)
				num_28_opened++;

			if (first_time_opening && day == 32 && !def.artist.contains("kingcrowned"))
				num_32_opened++;

			sstate(OPENING);
			new FlxTimer().start(0.24, (tmr:FlxTimer) -> SoundPlayer.sound(Paths.get('present-open.ogg')));
			new FlxTimer().start(1.2, function(tmr:FlxTimer)
			{
				sstate(OPENED);
				thumbnail.sstate("OPEN");
				if (username == "tankmas-chronicles")
					PlayState.self.openSubState(new TankmasChroniclesSubstate("intro-page-1"));
				else
					PlayState.self.openSubState(comic ? new ComicSubstate(username) : new ArtSubstate(username));
				opened = true;

				medal_was_unlocked = is_medal_unlock_enabled();

				SaveManager.open_present(username, def.day, medal_was_unlocked);
			});
		}
		else
		{
			first_time_opening = false;
			// Always try to award medals (fixes an edge case where someone encounters a crash mid-gift)
			SaveManager.open_present(username, def.day, is_medal_unlock_enabled());

			SoundPlayer.sound(Paths.get('present-open.ogg'));
			PlayState.self.openSubState(comic ? new ComicSubstate(username) : new ArtSubstate(username));

			SaveManager.save();
		}

		// Post present opened event to server (it's broadcasted to every other player, and also kept for stats).
		OnlineLoop.post_present_open(day, medal_was_unlocked, first_time_opening);

		#if newgrounds
		if (day != 25 && day != 28 && day != 32)
		{
			if (is_medal_unlock_enabled())
				give_opened_medal();
		}
		else
		{
			if (num_25_opened >= req_num_25_opened)
				Main.ng_api.medal_popup(Main.ng_api.medals.get('day-25'));
			if (num_28_opened >= req_num_28_opened)
				Main.ng_api.medal_popup(Main.ng_api.medals.get('day-28'));
			if (num_32_opened >= req_num_32_opened)
				Main.ng_api.medal_popup(Main.ng_api.medals.get('day-32'));

			trace(num_25_opened + "/" + req_num_25_opened);
			trace(num_28_opened + "/" + req_num_28_opened);
			trace(num_32_opened + "/" + req_num_32_opened);
		}
		if (comic && ["guri", "dragonmiracles", "oscarlors", "midgetsausage-2"].contains(username))
			Main.ng_api.medal_popup(Main.ng_api.medals.get('comic-${username}'));
		#end
		if (comic && username == "marbardan82")
			Flags.set_bool("GOT_SHMIGGED");

		if (username.contains("kingcrowned") && day == 32)
			Flags.set_bool("FINAL_PRESENT_OPENED");
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
