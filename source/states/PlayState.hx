package states;

import entities.Player;
import entities.Present;
import flixel.FlxState;
import flixel.text.FlxText;

class PlayState extends BaseState
{
	public static var self:PlayState;

	var bg:FlxSpriteExt;

	public var players:FlxTypedGroup<Player> = new FlxTypedGroup<Player>();
	public var presents:FlxTypedGroup<Present> = new FlxTypedGroup<Present>();
	public var player_shadows:FlxTypedGroup<FlxSpriteExt> = new FlxTypedGroup<FlxSpriteExt>();

	override public function create()
	{
		super.create();
		self = this;
		
		bgColor = FlxColor.GRAY;

		add(bg = new FlxSpriteExt(Paths.get("bg-outside-hotel.png")));

		add(player_shadows);
		add(presents);
		add(players);

		new Player();
		new Present();
		players.getFirstAlive().center_on(bg);

		FlxG.camera.target = players.getFirstAlive();

		FlxG.camera.setScrollBounds(bg.x, bg.width, bg.y, bg.height);
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		if (FlxG.keys.anyJustPressed(["R"]))
			FlxG.switchState(new PlayState());
	}

	override function destroy()
	{
		self = null;
		super.destroy();
	}
}
