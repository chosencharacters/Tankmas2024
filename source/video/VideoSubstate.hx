package video;

import flixel.tweens.FlxEase;
import openfl.display.Sprite;
import flixel.FlxG;
import openfl.display.Bitmap;
import openfl.display.MovieClip;
import openfl.events.AsyncErrorEvent;
import openfl.events.NetStatusEvent;
import openfl.geom.Rectangle;
import openfl.media.Video;
import openfl.net.NetConnection;
import openfl.net.NetStream;
import openfl.utils.Assets;
import ui.OpenFlButton;

private typedef PlayStatusData =
{
	code:String,
	duration:Float,
	position:Float,
	speed:Float
}

private typedef MetaData =
{
	width:Int,
	height:Int,
	duration:Float
}

class VideoSubstate extends flixel.FlxSubState
{
	var ui:VideoUi;
	var aReleased = false;

	public function new(path:String)
	{
		super();

		ui = new VideoUi(path);
	}

	override function create()
	{
		super.create();

		if (FlxG.sound.music != null)
			FlxG.sound.music.pause();

		// FlxG.stage.addChild(ui);

		ui.onComplete = close;
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		ui.update(elapsed);

		/*
			if (Ctrl.pause[1])
				ui.togglePause();

			if (Ctrl.emote[1])
				close();
		 */

		if (ui.requestedExit)
			close();
	}

	override function close()
	{
		FlxG.mouse.useSystemCursor = true;
		FlxG.mouse.visible = true;
		// FlxG.stage.removeChild(ui);
		ui.destroy();

		super.close();

		if (FlxG.sound.music != null)
			FlxG.sound.music.resume();
	}
}

class VideoUi extends FlxSprite
{
	public var isPaused = false;
	public var requestedExit = false;
	public var onComplete:() -> Void;

	public var on_close_request:() -> Void;

	var netStream:NetStream;
	var video:Video;
	var video_url:String;
	// var backBtn:OpenFlBackButton;
	var moveTimer = 2.0;

	var video_container:openfl.display.Sprite;

	var video_aspect_ratio = 1.0;

	var screen_width = 100.0;
	var screen_height = 100.0;

	public var on_enter_area:() -> Void = null;
	public var on_leave_area:() -> Void = null;

	var start_time:Float = 0.0;

	public function new(video_url:String, x:Float = 0, y:Float = 0, width:Float = 100, height:Float = 50, start_time:Float = 0.0)
	{
		this.video_url = video_url;
		super();

		this.start_time = Math.max(0.0, start_time);

		this.x = x;
		this.y = y;
		this.screen_height = height;
		this.screen_width = width;
		this.origin.set(0, 0);

		video_container = new Sprite();
		FlxG.stage.addChild(video_container);

		if (FlxG.sound.music != null)
			FlxG.sound.music.pause();

		FlxG.mouse.useSystemCursor = true;

		video_container.addChild(video = new Video());

		// backBtn = new OpenFlBackButton(close);
		// video_container.addChild(backBtn);

		var netConnection = new NetConnection();
		netConnection.connect(null);

		netStream = new NetStream(netConnection);
		netStream.client = {
			onMetaData: onMetaData,
			onPlayStatus: onPlayStatus
		};
		netStream.addEventListener(AsyncErrorEvent.ASYNC_ERROR, (e) -> trace("error loading video"));
		netConnection.addEventListener(NetStatusEvent.NET_STATUS, function onNetStatus(event)
		{
			trace("net status:" + haxe.Json.stringify(event.info));
			if (event.info.code == "NetStream.Play.Complete")
			{
				close();
				onVideoComplete();
			}
		});

		netStream.play(video_url);
		isPaused = false;
	}

	override function draw()
	{
		super.draw();

		var scl_x = (FlxG.stage.window.width / FlxG.width) * FlxG.camera.zoom;
		var scl_y = FlxG.stage.window.height / FlxG.height * FlxG.camera.zoom;

		var dy = y - FlxG.camera.viewTop;
		var dx = x - FlxG.camera.viewLeft;

		var pos = getScreenPosition();
		video.x = dx * scl_x;
		video.y = dy * scl_y;

		var video_aspect_ratio = video.videoHeight / video.videoWidth;

		video.width = screen_width * scl_x;
		video.height = video.width * video_aspect_ratio;
	}

	var entered = false;
	var camera_tween:FlxTween;

	function on_enter_video_area()
	{
		if (entered)
			return;
		entered = true;
		if (camera_tween != null)
			camera_tween.cancel();
		camera_tween = FlxTween.tween(FlxG.camera, {"targetOffset.y": -590, zoom: 0.6}, 1.0, {ease: FlxEase.smoothStepInOut});

		if (on_enter_area != null)
			on_enter_area();
	}

	function on_leave_video_area()
	{
		if (!entered)
			return;
		entered = false;
		if (camera_tween != null)
			camera_tween.cancel();
		camera_tween = FlxTween.tween(FlxG.camera, {"targetOffset.y": 0, zoom: 1.0}, 1.0, {ease: FlxEase.smoothStepInOut});
		if (on_leave_area != null)
			on_leave_area();
	}

	public override function update(elapsed:Float)
	{
		super.update(elapsed);
		// backBtn.update(elapsed);
		if (moveTimer > 0)
		{
			moveTimer -= elapsed;
			// if (moveTimer <= 0)
			// backBtn.visible = false;
		}

		if (FlxG.mouse.justMoved || FlxG.mouse.pressed || isPaused)
		{
			// backBtn.visible = true;
			moveTimer = 2.0;
		}

		if (PlayState.self.player.y < y + screen_height + 900)
		{
			on_enter_video_area();
		}
		else
		{
			on_leave_video_area();
		}
	}

	function close()
	{
		requestedExit = true;
		if (on_close_request != null)
			on_close_request();
	}

	function onMetaData(data:MetaData)
	{
		final stage = FlxG.stage;
		video.attachNetStream(netStream);
		video.width = video.videoWidth;
		video.height = video.videoHeight;

		if (start_time > 2.0)
		{
			var position = start_time % data.duration;
			trace('seeking to $position');
			netStream.seek(position);
		}

		if (video.videoWidth / stage.stageWidth > video.videoHeight / stage.stageHeight)
		{
			video.width = stage.stageWidth;
			video.height = stage.stageWidth * video.videoHeight / video.videoWidth;
		}
		else
		{
			video.height = stage.stageHeight;
			video.width = stage.stageHeight * video.videoWidth / video.videoHeight;
		}

		if (video.width < stage.stageWidth)
			video.x = (stage.stageWidth - video.width) / 2;

		if (video.height < stage.stageHeight)
			video.y = (stage.stageHeight - video.height) / 2;
	}

	function onPlayStatus(data:PlayStatusData) {}

	function onVideoComplete()
	{
		trace('Video complete!');
		if (onComplete != null)
			onComplete();

		close();
	}

	public function pause()
	{
		netStream.pause();
		isPaused = true;
	}

	public function resume()
	{
		netStream.resume();
		isPaused = false;
	}

	public function togglePause()
	{
		isPaused ? resume() : pause();
	}

	public override function destroy()
	{
		on_leave_video_area();
		FlxG.stage.removeChild(video_container);

		if (FlxG.sound.music != null)
			FlxG.sound.music.resume();

		super.destroy();
		netStream.dispose();
	}
}
