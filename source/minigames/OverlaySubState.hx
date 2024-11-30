package minigames;

import flixel.FlxCamera;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.FlxState;
import flixel.FlxSubState;
import flixel.graphics.frames.FlxBitmapFont;
import flixel.group.FlxGroup;
import flixel.math.FlxRect;
import flixel.text.FlxBitmapText;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxTween;
import flixel.util.FlxAxes;
import flixel.util.FlxTimer;
import flixel.util.typeLimit.NextState;
import minigames.CrtShader;
import minigames.MinigameHandler.MinigameEntry;
import openfl.filters.ShaderFilter;
import openfl.utils.Assets;
import ui.Font;
import utils.OverlayGlobal;

/**
 * Hastily stolen from Tankmas 2022!
 */
class OverlaySubState extends flixel.FlxSubState
{
	public var data:MinigameEntry;
	public var state(default, null):FlxState = null;

	var requestedState:NextState = null;
	var timers = new FlxTimerManager();
	var oldTimers:FlxTimerManager;
	var tweens = new FlxTweenManager();
	var oldTweens:FlxTweenManager;
	var oldCamera:FlxCamera;
	var oldBounds:FlxRect;
	var bg:FlxSprite;

	public function new(minigame_id:String, data:MinigameEntry, initialState:NextState)
	{
		super();

		this.data = data;
		OverlayGlobal.container = this;
		requestedState = new LoadingState(initialState, minigame_id);
		var cameraData = data.camera ?? {width: FlxG.width, height: FlxG.height, zoom: 1};

		final scale = Std.int(Math.min(FlxG.width / cameraData.width, FlxG.height / cameraData.height));
		final zoom = cameraData.zoom ?? 1;
		trace('${minigame_id} ${scale}x${zoom} (${cameraData.width}x${cameraData.height})');
		camera = new FlxCamera(0, 0, cameraData.width, cameraData.height, zoom * scale);

		if (data.crtShader ?? false)
			camera.filters = [new ShaderFilter(new CrtShader())];
		camera.bgColor = 0x00000000;
		camera.x = (FlxG.width - camera.width * (scale * zoom)) / 2;
		camera.y = (FlxG.height - camera.height * (scale * zoom)) / 2;
	}

	override function create()
	{
		trace('OverlaySubState.create');
		super.create();

		bg = new FlxSprite();
		bg.makeGraphic(1, 1);
		bg.color = 0x0;
		bg.setGraphicSize(FlxG.width << 1, FlxG.height << 1);
		bg.scrollFactor.set(0, 0);
		bg.camera = camera;
		add(bg);

		var instructions = new FlxText(0, 0, 0, "Press C to exit");
		instructions.color = 0xFFFFFF;
		instructions.camera = camera;
		add(instructions);
		instructions.y = 20;
		instructions.x = 20; // FlxG.width - instructions.width - 20;

		oldCamera = FlxG.camera;
		FlxG.camera = camera;
		FlxG.cameras.add(camera);
		oldTimers = FlxTimer.globalManager;
		FlxTimer.globalManager = timers;
		oldTweens = FlxTween.globalManager;
		FlxTween.globalManager = tweens;
		oldBounds = FlxRect.get().copyFrom(FlxG.worldBounds);

		switchStateActual();
	}

	override function update(elapsed:Float)
	{
		// trace('OverlaySubState.update');

		// Propagate camera background color.
		if (camera.bgColor != 0x0)
		{
			bg.color = camera.bgColor;
			camera.bgColor = 0x0;
		}

		super.update(elapsed);
		
		Ctrl.update();
		timers.update(elapsed);
		tweens.update(elapsed);

		if (state != requestedState && requestedState != null)
			switchStateActual();

		if (Ctrl.menuBack[1]) {
			trace('Closing overlay');
			close();

			// TODO: Is there a better way to do this?
			Ctrl.jemote[1] = false;
		}
	}

	public function cancelTweensOf(object, ?fieldPaths)
	{
		tweens.cancelTweensOf(object, fieldPaths);
	}

	public function switchState(nextState:NextState)
	{
		requestedState = nextState;
	}

	public function switchStateActual()
	{
		if (state != null)
		{
			remove(state);
			state.destroy();
		}

		timers.clear();
		tweens.clear();
		FlxG.worldBounds.set(-10, -10, camera.width + 20, camera.height + 20);
		camera.scroll.set(0, 0);
		camera.setScrollBounds(null, null, null, null);
		camera.follow(null);
		@:privateAccess
		camera._scrollTarget.set(0, 0);
		camera.deadzone = null;
		// camera.update(0);
		state = requestedState.createInstance();
		requestedState = null;
		add(state);

		state.camera = camera;
		state.create();
	}

	override function close()
	{
		FlxG.cameras.remove(camera);
		OverlayGlobal.container = null;
		timers.clear();
		tweens.clear();
		FlxTimer.globalManager = oldTimers;
		FlxTween.globalManager = oldTweens;
		FlxG.camera = oldCamera;
		FlxG.worldBounds.copyFrom(oldBounds);
		oldTimers = null;
		oldTweens = null;
		oldCamera = null;
		oldBounds.put();
		cameras = null;
		super.close();
	}
}

class LoadingState extends FlxState
{
	var nextState:NextState;
	var libraryName:String;

	public function new(nextState:NextState, libraryName:String)
	{
		super();
		this.nextState = nextState;
		this.libraryName = libraryName;
	}

	override function create()
	{
		var text = new FlxBitmapText(new NokiaFont16());
		text.text = "Loading...";
		text.x = (OverlayGlobal.width - text.width) / 2;
		text.y = (OverlayGlobal.height - text.height) / 2;
		add(text);

		super.create();

		if (Assets.getLibrary(libraryName) == null)
			Assets.loadLibrary(libraryName).onComplete((_) -> loadComplete());
		else
			loadComplete();
	}

	function loadComplete()
	{
		OverlayGlobal.switchState(nextState);
	}

	override function destroy()
	{
		super.destroy();

		nextState = null;
	}
}
