package;

import flixel.FlxG;
import flixel.input.gamepad.FlxGamepad;
import flixel.input.gamepad.FlxGamepadInputID;
import openfl.Assets;

/**
 * Main control loop
 * @author Squidly
 */
class Ctrl
{
	// for switch, mainly
	static var REVERSE_MENU_CONTROLS:Bool = false;

	// controls are handled as an array of bools
	public static var anyB:Array<Bool> = [false];

	// action
	public static var interact:Array<Bool> = [false];
	public static var menu:Array<Bool> = [false];
	public static var emote:Array<Bool> = [false];

	// just pressed
	public static var jinteract:Array<Bool> = [false];
	public static var jmenu:Array<Bool> = [false];
	public static var jemote:Array<Bool> = [false];

	// just released
	public static var rinteract:Array<Bool> = [false];
	public static var rmenu:Array<Bool> = [false];
	public static var remote:Array<Bool> = [false];

	// directions
	public static var up:Array<Bool> = [false];
	public static var down:Array<Bool> = [false];
	public static var left:Array<Bool> = [false];
	public static var right:Array<Bool> = [false];

	// constant directions (for menus)
	public static var cleft:Array<Bool> = [false];
	public static var cright:Array<Bool> = [false];
	public static var cup:Array<Bool> = [false];
	public static var cdown:Array<Bool> = [false];
	public static var cTicks:Array<Int> = [0, 0, 0, 0];

	// menu
	public static var menuConfirm:Array<Bool> = [false];
	public static var menuBack:Array<Bool> = [false];
	public static var menuLeft:Array<Bool> = [false];
	public static var menuRight:Array<Bool> = [false];

	// miscFront
	public static var pause:Array<Bool> = [false];
	public static var map:Array<Bool> = [false];

	public static var reset:Array<Bool> = [false];

	public static var releaseHolds:Array<Bool> = [false];

	public static var p1controller:FlxGamepad;
	public static var p2controller:FlxGamepad;

	public static var model:String = "keyboard";

	public static var scrollRate:Int = 10;

	/*whether allFalse was called, set to false every update()*/
	public static var allCleared:Bool = false;

	static var controlLock:Int = 0;

	public static var mode:ControlMode = ControlModes.INITIAL;

	public function new()
	{
		// Nothing
	}

	public static var controls:Array<Array<String>> = null;

	public static function set()
	{
		controls = [[""]];
		for (c in 1...2)
		{
			controls.push(Assets.getText("assets/data/config/controls/plyrc" + c + ".txt").split("\n"));
			for (f in 0...controls[c].length)
			{
				controls[c][f] = controls[c][f].trim();
			}
		}
		// ProgressManager("keys_load");
		#if switch
		model = "switch";
		REVERSE_MENU_CONTROLS = true;
		#end
	}

	public static function update()
	{
		if (controls == null)
		{
			set();
		}
		if (controlLock > 0)
		{
			controlLock--;
			return;
		}
		allCleared = false;
		for (c in 1...2)
		{
			up[c] = FlxG.keys.anyPressed(["W", "UP", controls[c][0]]);
			down[c] = FlxG.keys.anyPressed(["S", "DOWN", controls[c][1]]);
			left[c] = FlxG.keys.anyPressed(["A", "LEFT", controls[c][2]]);
			right[c] = FlxG.keys.anyPressed(["D", "RIGHT", controls[c][3]]);

			interact[c] = FlxG.keys.anyPressed([controls[c][4], "SPACE"]);
			jinteract[c] = FlxG.keys.anyJustPressed([controls[c][4], "SPACE"]);
			rinteract[c] = FlxG.keys.anyJustReleased([controls[c][4], "SPACE"]);

			menu[c] = FlxG.keys.anyPressed([controls[c][5]]);
			jmenu[c] = FlxG.keys.anyJustPressed([controls[c][5]]);
			rmenu[c] = FlxG.keys.anyJustReleased([controls[c][5]]);

			emote[c] = FlxG.keys.anyPressed([controls[c][6]]);
			jemote[c] = FlxG.keys.anyJustPressed([controls[c][6]]);
			remote[c] = FlxG.keys.anyJustReleased([controls[c][6]]);

			pause[c] = FlxG.keys.anyJustPressed(["V", "P", "ENTER"]);
			map[c] = FlxG.keys.anyJustPressed(["TAB"]);
			reset[c] = FlxG.keys.anyJustPressed(["R"]);

			menuLeft[c] = left[c];
			menuRight[c] = right[c];
			menuConfirm[c] = jinteract[c] && !REVERSE_MENU_CONTROLS || jemote[c] && REVERSE_MENU_CONTROLS;
			menuBack[c] = jinteract[c] && REVERSE_MENU_CONTROLS || jemote[c] && !REVERSE_MENU_CONTROLS || pause[c];

			anyB[c] = up[c] || down[c] || left[c] || right[c] || interact[c] || menu[c] || emote[c] || pause[c] || map[c] || reset[c];

			if (anyB[c])
				model = "keyboard";
		}
		altcontrol();
		menuControl();
	}

	public static function altcontrol()
	{ // gamepad controls
		// var gp:Array<FlxGamepad> = FlxG.gamepads.getByID

		for (p in 1...3)
		{
			var gp:FlxGamepad = null;

			if (p == 1)
				gp = p1controller;

			if (p == 2)
				gp = p2controller;

			if (p1controller == null && p2controller == null && p == 1)
				gp = FlxG.gamepads.getFirstActiveGamepad();

			if (gp != null && FlxG.gamepads.getByID(gp.id) != null)
			{
				gp.deadZone = .5;
				right[p] = right[p] || gp.analog.value.LEFT_STICK_X > 0 || gp.anyPressed([FlxGamepadInputID.DPAD_RIGHT]);
				up[p] = up[p] || gp.analog.value.LEFT_STICK_Y < 0 || gp.anyPressed([FlxGamepadInputID.DPAD_UP]);
				left[p] = left[p] || gp.analog.value.LEFT_STICK_X < 0 || gp.anyPressed([FlxGamepadInputID.DPAD_LEFT]);
				down[p] = down[p] || gp.analog.value.LEFT_STICK_Y > 0 || gp.anyPressed([FlxGamepadInputID.DPAD_DOWN]);
				pause[p] = pause[p] || gp.anyJustPressed([FlxGamepadInputID.START]);
				map[p] = map[p] || gp.anyJustPressed([FlxGamepadInputID.BACK]);

				interact[p] = interact[p] || gp.anyPressed([FlxGamepadInputID.A]);
				jinteract[p] = jinteract[p] || gp.anyJustPressed([FlxGamepadInputID.A]);
				jinteract[p] = rinteract[p] || gp.anyJustReleased([FlxGamepadInputID.A]);

				menu[p] = menu[p] || gp.anyPressed([FlxGamepadInputID.B]);
				jmenu[p] = jmenu[p] || gp.anyJustPressed([FlxGamepadInputID.B]);
				rmenu[p] = rmenu[p] || gp.anyJustReleased([FlxGamepadInputID.B]);

				emote[p] = emote[p] || gp.anyPressed([FlxGamepadInputID.X]);
				jemote[p] = jemote[p] || gp.anyJustPressed([FlxGamepadInputID.X]);
				remote[p] = remote[p] || gp.anyJustReleased([FlxGamepadInputID.X]);

				reset[p] = reset[p] || gp.anyJustReleased([FlxGamepadInputID.BACK]);

				menuConfirm[p] = jinteract[p] && !REVERSE_MENU_CONTROLS || jemote[p] && REVERSE_MENU_CONTROLS;
				menuBack[p] = jinteract[p] && REVERSE_MENU_CONTROLS || jemote[p] && !REVERSE_MENU_CONTROLS;

				menuLeft[p] = menuLeft[p] || gp.anyJustPressed([FlxGamepadInputID.LEFT_SHOULDER]);
				menuRight[p] = menuRight[p] || gp.anyJustPressed([FlxGamepadInputID.RIGHT_SHOULDER]);

				anyB[p] = up[p] || down[p] || left[p] || right[p] || interact[p] || menu[p] || emote[p] || pause[p] || map[p] || reset[p];

				if (gp.anyInput())
				{
					model = "xbox";
					if (gp.model == FlxGamepadModel.PS4)
					{
						model = "psx";
					}
					#if switch
					model = "switch";
					#end
				}
			}

			if (gp != null && FlxG.gamepads.getByID(gp.id) == null)
			{
				if (gp == p1controller)
					for (g in FlxG.gamepads.getActiveGamepads())
						if (g != p2controller)
							p1controller = g;
				if (gp == p2controller)
					for (g in FlxG.gamepads.getActiveGamepads())
						if (g != p1controller)
							p2controller = g;
			}
		}
	}

	static function menuControl()
	{
		for (c in 1...3)
		{ // for all players
			cup[c] = cdown[c] = cleft[c] = cright[c] = false;
			if (up[c] || down[c] || left[c] || right[c])
			{
				if (cTicks[c] % scrollRate == 0)
				{
					cup[c] = up[c];
					cdown[c] = down[c];
					cleft[c] = left[c];
					cright[c] = right[c];
				}
				cTicks[c]++;
				// debug(cTicks[c]);
			}
			else
			{
				cTicks[c] = 0;
			}
		}
	}

	public static function allFalse()
	{
		// for all players
		for (c in 1...3)
		{
			setFalse(c);
		}
		allCleared = true;
	}

	public static function setFalse(c:Int)
	{
		/*
			if (PlayState.players != null && PlayState.players.members != null)
			{
				if (c <= PlayState.players.members.length && PlayState.players.members.length > 0)
					PlayState.players.members[c - 1].clearBuffer();
			}
		 */
		up[c] = false;
		down[c] = false;
		left[c] = false;
		right[c] = false;

		interact[c] = false;
		jinteract[c] = false;
		rinteract[c] = false;

		menu[c] = false;
		jmenu[c] = false;
		rmenu[c] = false;

		emote[c] = false;
		jemote[c] = false;
		remote[c] = false;

		menuLeft[c] = false;
		menuRight[c] = false;

		pause[c] = false;
		map[c] = false;
		reset[c] = false;
		menuConfirm[c] = false;
		menuBack[c] = false;
		cup[c] = false;
		cdown[c] = false;
		cleft[c] = false;
		cright[c] = false;
		cTicks[c] = 0;

		anyB[c] = false;
	}

	public static function any(l:Array<Bool>):Bool
	{
		for (r in l)
		{
			if (r)
			{
				return true;
			}
		}
		return false;
	}

	public static function setControlLock(setLock:Int)
	{
		controlLock = setLock;
		allFalse();
	}
	/*
		function anyJustPressed(keys:Array<String>):Bool {
			return FlxG.keys.anyJustPressed(keys);
		}

		function anyJustReleased(keys:Array<String>):Bool {
			if (keys == ["-"]) return false;
			return FlxG.keys.anyJustReleased(keys);
		}

		function anyPressed(keys:Array<String>):Bool {
			if (keys == ["-"]) return false;
			return FlxG.keys.anyJustReleased(keys);
		}
	 */
}

typedef ControlMode =
{
	var can_move:Bool;
	var can_emote:Bool;
	var can_open_menus:Bool;
}

enum abstract ControlModes(ControlMode) from ControlMode to ControlMode
{
	public static final INITIAL:ControlMode = {can_move: false, can_emote: false, can_open_menus: false};
	public static final OVERWORLD:ControlMode = {can_move: true, can_emote: true, can_open_menus: true};
	public static final TALKING:ControlMode = {can_move: false, can_emote: false, can_open_menus: false};
	public static final MINIGAME:ControlMode = {can_move: false, can_emote: false, can_open_menus: false};
	public static final NONE:ControlMode = {can_move: false, can_emote: false, can_open_menus: false};

	public function restrict_controls(mode:ControlMode)
	{
		// not implemented
		switch (mode)
		{
			default:
		}
	}
}
