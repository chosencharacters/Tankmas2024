package entities.misc;

import video.PremiereHandler;
import flixel.FlxBasic;

class PremiereCountdown extends FlxText
{
	var premieres:PremiereHandler;

	public function new(p:PremiereHandler)
	{
		super();
		premieres = p;
		color = FlxColor.RED;
		setFormat(Paths.get('CharlieType-Heavy.otf'), 64, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		PlayState.self.add(this);
	}

	override function kill()
	{
		super.kill();
		PlayState.self.remove(this);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		if (premieres.get_active_premiere() == null)
			return;

		var ps = PlayState.self;
		var t = Math.ceil(premieres.get_time_until_next_premiere());
		var minutes = Math.floor(t / 60);
		var seconds = t - minutes * 60;
		text = '${minutes < 10 ? '0' : ''}${minutes}:${seconds < 10 ? '0' : ''}${seconds}';
		x = ps.player.x + (ps.player.width - width) * 0.5;
		y = ps.player.y - 130.0;

		if (t <= 0)
			kill();
	}
}
