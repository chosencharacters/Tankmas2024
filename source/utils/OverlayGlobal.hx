package utils;

import flixel.FlxState;
import flixel.util.FlxAxes;
import flixel.util.typeLimit.NextState;
import minigames.OverlaySubState;

class OverlayGlobal
{
	public static var width(get, never):Int;

	inline static function get_width()
	{
		return container == null ? FlxG.width : container.camera.width;
	}

	public static var height(get, never):Int;

	inline static function get_height()
	{
		return container == null ? FlxG.height : container.camera.height;
	}

	public static var camera(get, never):FlxCamera;

	inline static function get_camera()
	{
		return container == null ? FlxG.camera : container.camera;
	}

	public static var state(get, never):FlxState;

	inline static function get_state()
	{
		return container == null ? FlxG.state : container.state;
	}

	@:allow(minigames.OverlaySubState)
	static var container:OverlaySubState;

	static public function switchState(state:NextState)
	{
		if (container != null)
			container.switchState(state);
		else
			FlxG.switchState(state);
	}

	static public function resetState()
	{
		switchState(Type.createInstance(Type.getClass(container.state), []));
	}

	static public function cancelTweensOf(object, ?fieldPaths)
	{
		if (container != null)
			container.cancelTweensOf(object, fieldPaths);

		FlxTween.cancelTweensOf(object, fieldPaths);
	}

	static public function asset(path:String):String
	{
		var library:String = minigames.MinigameHandler.instance.active_minigame_id;

		var id:String = path.split('assets/').join('assets/minigames/$library/');

		return '$library:$id';
	}

	inline static public function screenCenterX(obj:FlxObject)
	{
		obj.x = (width - obj.width) / 2;
	}

	inline static public function screenCenterY(obj:FlxObject)
	{
		obj.y = (height - obj.height) / 2;
	}

	inline static public function screenCenter(obj:FlxObject, axes = FlxAxes.XY)
	{
		switch (axes)
		{
			case NONE:
			case FlxAxes.XY:
				screenCenterX(obj);
				screenCenterY(obj);
			case FlxAxes.X:
				screenCenterX(obj);
			case FlxAxes.Y:
				screenCenterY(obj);
		}
	}

	static public function exit()
	{
		if (container != null)
			container.close();
		// else
		//     ArcadeGame.exitActiveGameState();
	}
}
