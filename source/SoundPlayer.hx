import lime.app.Promise;
import lime.app.Future;
import openfl.media.Sound;
import lime.utils.AssetLibrary;
import lime.media.AudioBuffer;
import lime.utils.Assets;
import flixel.math.FlxRandom;
import flixel.sound.FlxSound;
import flixel.system.FlxAssets.FlxSoundAsset;

class SoundPlayer
{
	public static var MUSIC_ALREADY_PLAYING:String = "";
	public static var MUSIC_VOLUME:Float = 1;
	public static var SOUND_VOLUME:Float = 1;

	static var ran:FlxRandom;

	public static function init() {}

	public static function sound(sound_asset:String, vol:Float = 1):FlxSound
	{
		sound_asset = sound_asset.replace(".ogg", "");
		var return_sound:FlxSound = FlxG.sound.play(Paths.get('${sound_asset}.ogg'), SOUND_VOLUME * vol);
		return return_sound;
	}

	public static function music(music_asset:String, vol:Float = 1, force = false):Future<FlxSound>
	{
		music_asset = music_asset.replace(".ogg", "");

		var music_path = Paths.get('${music_asset}.ogg');

		// Don't restart same song if it's already playing,
		// unless force is set to true.
		if (!force && music_path == MUSIC_ALREADY_PLAYING)
			return Future.withValue(FlxG.sound.music);

		MUSIC_ALREADY_PLAYING = music_path;

		var is_local = Assets.isLocal(music_path);

		// If music is local (embedded, it's already ready to play. Do it.)
		if (is_local)
		{
			var music = Assets.getAudioBuffer(music_path);
			return Future.withValue(start_music(music, music_path, vol));
		}

		var music_started_promise = new Promise<FlxSound>();
		// If music is not embedded, we need to first load it,
		// and then start it once it's ready.
		var sound_buffer = Assets.loadAudioBuffer(music_path);
		Assets.loadAudioBuffer(music_path).onComplete((buffer) ->
		{
			var res = start_music(buffer, music_path, vol);
			music_started_promise.complete(res);
		});

		return music_started_promise.future;
	}

	static function start_music(buffer:AudioBuffer, music_path:String, volume:Float)
	{
		// Music was already changed, so skip starting this.
		if (music_path != MUSIC_ALREADY_PLAYING)
			return FlxG.sound.music;

		var music = Sound.fromAudioBuffer(buffer);
		FlxG.sound.playMusic(music, MUSIC_VOLUME * volume);
		FlxG.sound.music.persist = true;

		return FlxG.sound.music;
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
