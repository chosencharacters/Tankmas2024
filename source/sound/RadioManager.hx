package sound;

import ui.MusicPopup;

typedef RadioSegment =
{
	var type:RadioSegmentType;
	var parts:Array<String>;
	var ?follow_up:RadioSegmentType;
}

enum abstract RadioSegmentType(String) from String to String
{
	var AD = 'ad';
	var NEWS = 'news';
	var MUSIC = 'music';
	var SHOTGUN = 'shotgun';
}

class RadioManager
{
	var current_segment:RadioSegment;
	var sounds:Map<String, Array<String>> = [];
	var next_music_followup:RadioSegmentType = AD;
	var current_sound:FlxSound;

	public static var volume:Float = 1.0;

	var next_music_track:Map<Int, Array<String>> = [1 => ["christmasohyeah", "stixdevs"], 3 => ["christmasjoy", "realtin3sn"]];

	final sound_categories:Array<String> = [
		'ad-intro-',
		'ad-main-',
		'ad-outro-',
		'music-chaoz-fantasy-intro-',
		'music-chaoz-fantasy-main-',
		'music-chaoz-fantasy-outro-',
		'news-intro-',
		'news-outro-',
		'news-A-main-',
		'news-A-followup-',
		'shotgun-'
	];

	var ran:FlxRandom;

	public function new()
	{
		#if no_radio return; #end
		ran = new FlxRandom();
		current_segment = make_segment(NEWS);
		update();
	}

	public function update()
	{
		if (current_sound == null)
		{
			if (current_segment == null || current_segment.parts.length == 0)
				current_segment = make_segment(current_segment.follow_up);
			var next_sound:String = current_segment.parts.shift();
			#if trace_radio trace("PLAYING ", next_sound); #end
			current_sound = SoundPlayer.sound(next_sound, volume);
			if (current_sound != null)
			{
				current_sound.persist = true;
				current_sound.onComplete = end_sound;
			}
		}
		else if (current_sound.volume != volume)
			current_sound.volume = volume;
	}

	public function end_sound()
	{
		current_sound = null;
		update();
	}

	public function manage_sounds_array()
		for (category in sound_categories)
			if (!sounds.exists(category) || sounds.get(category).length == 0)
			{
				sounds.set(category, Paths.get_every_file_of_type('.ogg', 'assets', category));
				ran.shuffle(sounds.get(category));
			}

	function get_part(part_name:String)
	{
		#if trace_radio trace(part_name, sounds.get(part_name)); #end
		var sound = sounds.get(part_name);
		if (sound == null)
			return '';
		return sound.pop();
	}

	function make_segment(type:RadioSegmentType):RadioSegment
	{
		manage_sounds_array();
		var segment:RadioSegment = {type: type, parts: []};
		switch (segment.type)
		{
			case SHOTGUN:
				segment = make_shotgun(segment);
			case AD:
				segment = make_ad(segment);
			case NEWS:
				segment = make_news(segment);
			case MUSIC:
				segment = make_music(segment);
		}

		return segment;
	}

	function make_shotgun(segment:RadioSegment):RadioSegment
	{
		segment.parts = [get_part("shotgun-")];
		segment.follow_up = MUSIC;
		MusicPopup.show_info("You're listening to Tankmas Radio!");
		return segment;
	}

	function make_music(segment:RadioSegment):RadioSegment
	{
		final n:Array<String> = get_random_track();
		segment.parts = [
			get_part('music-${n[0]}-intro-'),
			get_part('music-${n[0]}-main-'),
			n.join("_"),
			get_part('music-${n[0]}-outro-')
		];
		segment.follow_up = next_music_followup;
		next_music_followup == AD ? NEWS : AD;
		return segment;
	}

	function make_news(segment:RadioSegment):RadioSegment
	{
		var n:String = 'A';
		segment.parts = [get_part('news-intro-'), get_part('news-$n-main-'), get_part('news-outro-')];
		segment.follow_up = SHOTGUN;
		MusicPopup.show_info("You're listening to Tankmas Radio!");
		return segment;
	}

	function make_ad(segment:RadioSegment):RadioSegment
	{
		segment.parts = [get_part('ad-intro-'), get_part('ad-main-'), get_part('ad-outro-')];
		segment.follow_up = SHOTGUN;
		MusicPopup.show_info("You're listening to Tankmas Radio!");
		return segment;
	}

	function get_random_track():Array<String>
	{
		final currentOps:Array<Array<String>> = [];
		for (key in next_music_track.keys())
			if (key <= 1)
				currentOps.push(next_music_track.get(key));
		return currentOps[FlxG.random.int(0, currentOps.length - 1)];
	}
}
