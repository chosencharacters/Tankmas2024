package input;

enum InputMode
{
	Keyboard;
	MouseOrTouch;
}

// Switches between keyboard only and mouse controls depending on if mouse is moved
// or keys being pressed
class InputManager extends FlxObject
{
	var last_cursor_pos:FlxPoint = new FlxPoint();

	public var mode(default, set):InputMode = MouseOrTouch;

	var play_state:PlayState;

	public function new(play_state:PlayState)
	{
		super();
		this.play_state = play_state;
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		var UP:Bool = Ctrl.up[1];
		var DOWN:Bool = Ctrl.down[1];
		var LEFT:Bool = Ctrl.left[1];
		var RIGHT:Bool = Ctrl.right[1];
		if (UP || DOWN || LEFT || RIGHT || Ctrl.jinteract[1])
		{
			mode = Keyboard;
		}
		else if (FlxG.mouse.justPressed || last_cursor_pos.distance(FlxG.mouse.getScreenPosition()) > 20)
		{
			mode = MouseOrTouch;
		}
	}

	function set_mode(m)
	{
		if (this.mode == m)
			return m;
		if (m == Keyboard || last_cursor_pos == null)
		{
			last_cursor_pos = FlxG.mouse.getScreenPosition();
		}

		return this.mode = m;
	}
}
