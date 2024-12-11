package states.substates;

import squid.ext.FlxSubstateExt;

class VideoSubstate extends FlxSubstateExt
{
	var video_name:String;

	public function new(video_name:String)
	{
		super();
		this.video_name = video_name;
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		var info = PlayState.self.premieres.get_premiere_info(video_name);
		if (info == null)
			return;

		if (info.released)
		{
			// Video is playable;
			var video_url = info.url;
		}

		var until_release = info.until_release;
		trace('video releases in ${until_release} seconds');
	}
}
