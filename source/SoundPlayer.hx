import data.types.TankmasDefs.TrackDef;
import flixel.math.FlxRandom;
import flixel.sound.FlxSound;
import flixel.system.FlxAssets.FlxSoundAsset;
import lime.app.Future;
import lime.app.Promise;
import lime.media.AudioBuffer;
import lime.utils.AssetLibrary;
import lime.utils.Assets;
import openfl.media.Sound;
import ui.MusicPopup;

class SoundPlayer
{
	public static var CURRENT_TRACK:Null<TrackDef> = null;
	public static var MUSIC_VOLUME:Float = 1;
	public static var SOUND_VOLUME:Float = 1;

	static var ran:FlxRandom;

	#if html5
	public static final SOUND_EXT:String = ".mp3";
	#else
	public static final SOUND_EXT:String = ".ogg";
	#end

	public static function init() {}

	public static function sound(sound_asset:String, vol:Float = 1):FlxSound
	{
		sound_asset = sound_asset.replace(".ogg", "");

		// Query the asset before trying to play it.
		// Don't play the sound if it doesn't exist
		var sound_path:Null<String> = Paths.get('${sound_asset}${SOUND_EXT}', true);
		if (sound_path == null) return null;

		var return_sound:FlxSound = FlxG.sound.play(sound_path, SOUND_VOLUME * vol);
		return return_sound;
	}

	public static function music(track:TrackDef, vol:Float = 1, force = false):Future<FlxSound>
	{
		var music_path = Paths.get('assets/music/${track.id}${SOUND_EXT}', true);

		// Don't restart same song if it's already playing,
		// unless force is set to true.
		if (music_path == null) {
			var expected = 'assets/music/${track.id}${SOUND_EXT}';

			var message = 'SoundPlayer: Tried to play invalid music track \"${expected}\"';

			if (SOUND_EXT == ".mp3") {
				message += " (Did you remember to convert to MP3 for web?)";
			}

			// Don't throw in production! Just fail silently.
			#if dev
			throw message;
			#else
			trace(message);
			#end

			var future:Future<FlxSound> = cast Future.withError(message);
			return future;
		}

		if (!force && track == CURRENT_TRACK) {
			trace('SoundPlayer: Music is already playing "${track.name}"');
			return Future.withValue(FlxG.sound.music);
		}

		CURRENT_TRACK = track;

		var is_local = Assets.isLocal(music_path);

		// If music is local (embedded, it's already ready to play. Do it.)
		if (is_local)
		{
			var music = Assets.getAudioBuffer(music_path);
			return Future.withValue(start_music(music, track, vol));
		}

		var music_started_promise = new Promise<FlxSound>();
		// If music is not embedded, we need to first load it,
		// and then start it once it's ready.
		set_music_loading(track);
		var sound_buffer = Assets.loadAudioBuffer(music_path).onComplete((buffer) ->
		{
			var res = start_music(buffer, track, vol);
			music_started_promise.complete(res);
		}).onError((error) ->
		{
			trace('Error loading music ${music_path}');
			trace(error);
		});

		return music_started_promise.future;
	}

	static function start_music(buffer:AudioBuffer, track:TrackDef, volume:Float)
	{
		// Music was already changed, so skip starting this.
		if (track != CURRENT_TRACK)
			return FlxG.sound.music;

		set_music_playing(track);

		var music = Sound.fromAudioBuffer(buffer);
		FlxG.sound.playMusic(music, MUSIC_VOLUME * volume);
		if (FlxG.sound.music != null) {
			FlxG.sound.music.persist = true;
		}

		return FlxG.sound.music;
	}

	static function build_song_name(track:TrackDef):String {
		if (track == null) return 'Unknown Song';

		return '${track.name} by ${track.artist}';
	}

	static function set_music_playing(track:TrackDef):Void {
		trace('SoundPlayer: Playing music ${track.name}');
		MusicPopup.show_info(build_song_name(track));
	}

	static function set_music_loading(track:TrackDef):Void {
		trace('SoundPlayer: Loading music ${track.name}');
		MusicPopup.show_loading(build_song_name(track));
	}

	static var slots:Array<Array<String>> = [];

	static var alt_sounds:Map<String, Array<String>> = [];

	public static var prev_alt_sounds:Map<String, FlxSound> = [];

	public static function alt_sound(slot:String, shuffle:Bool, sounds:Array<String>, ?wait_for_prev_sound:Bool = false)
	{
		ran = ran != null ? ran : new FlxRandom();

		#if nosound
		return;
		#end

		if (wait_for_prev_sound)
			if (prev_alt_sounds.get(slot) != null)
				return;

		if (alt_sounds.get(slot) == null || alt_sounds.get(slot).length <= 0)
		{
			if (shuffle)
				ran.shuffle(sounds);
			alt_sounds.set(slot, sounds);
		}

		var soundToPlay:String = alt_sounds.get(slot).pop();
		var sound_played:FlxSound = sound(soundToPlay);

		if (wait_for_prev_sound)
		{
			prev_alt_sounds.set(slot, sound_played);
			sound_played.onComplete = function()
			{
				prev_alt_sounds.set(slot, null);
			}
		}

		alt_sounds.get(slot).remove(soundToPlay);
	}
}
