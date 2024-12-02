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

	public static function music(music_asset:String, vol:Float = 1)
	{
		music_asset = music_asset.replace(".ogg", "");
		FlxG.sound.playMusic(Paths.get('$music_asset.ogg', "assets/music"), MUSIC_VOLUME * vol);
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
