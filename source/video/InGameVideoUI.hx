package video;

import flixel.FlxG;
import flixel.tweens.FlxEase;
import openfl.display.Sprite;
import openfl.events.AsyncErrorEvent;
import openfl.events.NetStatusEvent;
import openfl.media.Video;
import openfl.net.NetConnection;
import openfl.net.NetStream;
import openfl.utils.Assets;
import states.PlayState;
import video.PremiereHandler.PremiereData;

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

class InGameVideoUI extends FlxSprite
{
	var premieres:PremiereHandler;

	public var isPaused = false;
	public var on_complete:() -> Void;
	public var on_close_request:() -> Void;

	var netStream:NetStream;
	var video:Video;
	var video_url:String;

	var video_container:openfl.display.Sprite;

	var video_aspect_ratio = 1.0;

	var screen_width = 100.0;
	var screen_height = 100.0;

	public var on_enter_area:() -> Void = null;
	public var on_leave_area:() -> Void = null;

	var start_time:Float = 0.0;

	var countdown_text:FlxText;

	public function new(screen:levels.LdtkProject.Entity_Misc) // video_url:String, x:Float = 0, y:Float = 0, width:Float = 100, height:Float = 50, start_time:Float = 0.0)
	{
		super();

		premieres = new PremiereHandler();
		premieres.on_premiere_release = on_premiere_release;
		premieres.on_loaded = on_loaded;
		premieres.refresh();

		countdown_text = new FlxText();
		PlayState.self.objects.add(countdown_text);
		countdown_text.color = FlxColor.RED;
		countdown_text.setFormat(Paths.get('CharlieType-Heavy.otf'), 64, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		countdown_text.visible = false;

		PlayState.self.objects.add(this);

		this.start_time = Math.max(0.0, start_time);

		this.x = screen.worldPixelX;
		this.y = screen.worldPixelY;
		this.screen_height = screen.height;
		this.screen_width = screen.width;
		this.origin.set(0, 0);
		makeGraphic(1, 1, FlxColor.TRANSPARENT);
		this.width = screen.width;
		this.height = screen.height;

		video_container = new Sprite();
		FlxG.stage.addChild(video_container);

		FlxG.mouse.useSystemCursor = true;

		video_container.addChild(video = new Video());

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

				premieres.refresh();
			}
		});
	}

	function on_premiere_release(premiere:PremiereData)
	{
		trace('premiere release!!');
	}

	function stop_video()
	{
		netStream.pause();
		video.visible = false;
	}

	function start_premiere_countdown()
	{
		countdown_text.visible = true;
	}

	function on_loaded()
	{
		var time_until_premiere = premieres.get_time_until_next_premiere();
		if (time_until_premiere != null && time_until_premiere < 3600 && time_until_premiere > 0) // Start premiere countdown on an hour before premiere
		{
			start_premiere_countdown();
			return;
		}

		var currently_playing = premieres.get_currently_playing_premiere();
		if (currently_playing != null)
		{
			trace('resuming at ${currently_playing.resume_time}');
			start_time = (Main.time.utc / 1000.0 - currently_playing.timestamp);
			if (currently_playing.resume_time != null)
				start_time = currently_playing.resume_time;
			play_video(currently_playing.url);
		}
	}

	function play_video(url:String)
	{
		if (FlxG.sound.music != null)
			FlxG.sound.music.pause();
		netStream.play(url);
		video.visible = true;
		isPaused = false;
		countdown_text.visible = false;
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
		camera_tween = FlxTween.tween(FlxG.camera, {"targetOffset.y": -590, zoom: 0.65}, 1.0, {ease: FlxEase.smoothStepInOut});

		if (on_enter_area != null)
			on_enter_area();
		PlayState.self.ui_overlay.visible = false;
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

		if (PlayState.self != null && PlayState.self.ui_overlay != null)
			PlayState.self.ui_overlay.visible = true;
	}

	public override function update(elapsed:Float)
	{
		super.update(elapsed);

		premieres.update(elapsed);

		if (PlayState.self.player.y < y + screen_height + 900)
		{
			on_enter_video_area();
		}
		else
		{
			on_leave_video_area();
		}

		if (countdown_text.visible)
		{
			var t = Math.ceil(premieres.get_time_until_next_premiere());
			var hours = Math.floor(t / 3600);
			var minutes = Math.floor(t / 60) - hours * 60;
			var seconds = t - minutes * 60 - hours * 3600;
			var hours_str = hours > 0 ? '$hours:' : '';
			if (hours < 10 && hours > 0)
				hours_str = '0$hours_str';

			countdown_text.text = '$hours_str${minutes < 10 ? '0' : ''}${minutes}:${seconds < 10 ? '0' : ''}${seconds}';
			countdown_text.x = x + (width - countdown_text.width) * 0.5;
			countdown_text.y = y + height * 0.5 - countdown_text.height * 0.5;
		}
	}

	function close()
	{
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
			trace('seeking to $position (start time : $start_time)');
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
		if (on_complete != null)
			on_complete();

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

		netStream.dispose();
		super.destroy();
	}
}
