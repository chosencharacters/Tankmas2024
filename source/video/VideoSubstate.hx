package video;

import flixel.tweens.FlxEase;
import flixel.graphics.FlxGraphic;
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
	var closed = false;

	public var on_close:() -> Void = null;
	// Called if video was watched completely
	public var on_completed:() -> Void = null;

	var bg:FlxSprite;

	public function new(path:String)
	{
		super();

		ui = new VideoUi(path, false);
		bg = new FlxSprite(0, 0);
		bg = bg.makeGraphic(FlxG.width, FlxG.height, FlxColor.fromRGB(4, 4, 5));
		bg.y = FlxG.height;
		bg.alpha = 0.0;
		bg.scrollFactor.set(0, 0);
		bg.origin.set(0, 0);
		add(bg);

		trace('tweenin');

		FlxTween.tween(bg, {alpha: 1, y: 0}, 0.4, {ease: FlxEase.smootherStepInOut, onComplete: on_fade_in});
	}

	function on_fade_in(t)
	{
		ui.play();
	}

	override function create()
	{
		super.create();

		if (FlxG.sound.music != null)
			FlxG.sound.music.pause();

		FlxG.stage.addChild(ui);

		ui.onComplete = video_completed;
	}

	function video_completed()
	{
		if (on_completed != null)
			on_completed();
		close_video();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (ui.requestedExit)
			close_video();

		ui.update(elapsed);

		if (Ctrl.pause[1])
			ui.togglePause();

		if (Ctrl.emote[1])
			close_video();
	}

	public function close_video()
	{
		if (closed)
			return;

		closed = true;
		FlxG.mouse.useSystemCursor = true;
		FlxG.mouse.visible = true;

		haxe.Timer.delay(() -> FlxTween.tween(bg, {alpha: 0}, 0.4, {
			ease: FlxEase.smootherStepInOut,
			onComplete: (t) ->
			{
				FlxG.stage.removeChild(ui);
				ui.destroy();

				if (FlxG.sound.music != null)
					FlxG.sound.music.resume();

				if (on_close != null)
					on_close();

				close();
			}
		}), 500);
	}
}

class VideoUi extends openfl.display.Sprite
{
	public var isPaused = false;
	public var requestedExit = false;
	public var onComplete:() -> Void;

	var netStream:NetStream;
	var video:Video;
	var path:String;
	var backBtn:OpenFlBackButton;
	var moveTimer = 2.0;

	public function new(path:String, auto_play = true)
	{
		this.path = path;
		super();

		FlxG.mouse.useSystemCursor = true;
		addChild(video = new Video());
		backBtn = new OpenFlBackButton(close_video);
		backBtn.x = 20;
		backBtn.y = 20;
		addChild(backBtn);

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
				onVideoComplete();
		});

		if (auto_play)
			play();
	}

	var closed = false;

	function close_video()
	{
		if (closed)
			return;
		closed = true;
		FlxTween.tween(video, {y: FlxG.stage.window.height * 0.5, scaleY: 0.0, alpha: 0}, 0.2, {
			ease: FlxEase.smootherStepInOut,
			onComplete: (t) ->
			{
				requestedExit = true;
			}
		});
	}

	public function play()
	{
		netStream.play(path);
		isPaused = false;
	}

	public function update(elapsed:Float)
	{
		backBtn.update(elapsed);
		if (moveTimer > 0)
		{
			moveTimer -= elapsed;
			if (moveTimer <= 0)
				backBtn.visible = false;
		}

		if (FlxG.mouse.justMoved || FlxG.mouse.pressed || isPaused)
		{
			backBtn.visible = true;
			moveTimer = 2.0;
		}
	}

	function onMetaData(data:MetaData)
	{
		final stage = FlxG.stage;
		video.attachNetStream(netStream);
		video.width = video.videoWidth;
		video.height = video.videoHeight;

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

		video.scaleY = 0;

		// netStream.pause();

		haxe.Timer.delay(() ->
		{
			video.y = FlxG.stage.window.height * 0.5;
			video.scaleY = 0.5;
			FlxTween.tween(video, {y: 0, scaleY: 1.0}, 0.5, {
				ease: FlxEase.elasticOut,
				// onComplete: (t) -> netStream.resume()
			});
		}, 400);
	}

	function onPlayStatus(data:PlayStatusData) {}

	function onVideoComplete()
	{
		trace('Video complete!');
		if (onComplete != null)
			onComplete();
		close_video();
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

	public function destroy()
	{
		netStream.dispose();
	}
}
