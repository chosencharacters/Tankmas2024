package states.substates;

import data.JsonData;
import entities.Present;
import flixel.tweens.FlxEase;
import openfl.Assets;
import openfl.display.BitmapData;
import squid.ext.FlxSubstateExt;
import ui.button.HoverButton;

class ArtSubstate extends FlxSubstateExt
{
	var art:FlxSpriteExt;
	var data:data.types.TankmasDefs.PresentDef;
	var display_text:FlxText;

	var back_button:HoverButton;

	var has_link:Bool = true;

	override public function new(present_name:String)
	{
		super();
		data = JsonData.get_present(present_name);
		trace(present_name);
		trace(data);

		art = new FlxSpriteExt(0, 0);

		var image_name:String = #if censor_presents 'art-censored' #else data.file #end;
		var image_url:String = Paths.image_path(image_name);

		Assets.loadBitmapData(image_url).onComplete((bitmap) -> on_image_loaded(bitmap, image_name));

		add(art);

		final backBox:FlxSpriteExt = new FlxSpriteExt(0, 960).makeGraphicExt(1920, 120, FlxColor.BLACK);
		backBox.alpha = 0.3;
		add(backBox);

		var title:String = data.title != null && data.title != "" ? data.title : "Untitled";
		var artist:String = data.artist != null && data.artist != "" ? data.artist : "Unknown";
		var link:String = 'Click here to view this ${data.link != null ? 'piece' : 'artist'} on NG!';

		if (present_name == "ng-tv")
		{
			link = "";
			has_link = false;
		}

		display_text = new FlxText(0, 980, 1920, '$title by $artist\n$link');

		display_text.setFormat(Paths.get('CharlieType-Heavy.otf'), 32, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		add(display_text);

		add(back_button = new HoverButton((b) -> back_button_activated()));

		back_button.scrollFactor.set(0, 0);

		back_button.loadAllFromAnimationSet("back-arrow-but-smaller-for-present-art");
		back_button.setPosition(FlxG.width - back_button.width - 16, FlxG.height - back_button.height - 16);
		back_button.offset.y = -back_button.height;
		back_button.tween = FlxTween.tween(back_button.offset, {y: 0}, 0.25, {ease: FlxEase.cubeInOut});

		back_button.on_neutral = (b) -> b.alpha = 0.35;
		back_button.on_hover = (b) -> b.alpha = 0.75;

		members.for_all_members((member:flixel.FlxBasic) -> cast(member, FlxObject).scrollFactor.set(0, 0));
	}

	function on_image_loaded(bitmap:BitmapData, image_name:String)
	{
		art.loadAllFromAnimationSet(image_name);
		art.setGraphicSize(art.width > art.height ? 1920 : 0, art.height >= art.width ? 1080 : 0);
		art.updateHitbox();
		art.screenCenter();
	}

	function back_button_activated()
		close();

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		Ctrl.update();
		if (Ctrl.up[1])
			art.y -= 5;
		if (Ctrl.down[1])
			art.y += 5;
		if (Ctrl.left[1])
			art.x -= 5;
		if (Ctrl.right[1])
			art.x += 5;
		if (Ctrl.menuConfirm[1])
			close();
		if (has_link)
			if (FlxG.mouse.justPressed && FlxG.mouse.overlaps(display_text) && !FlxG.mouse.overlaps(back_button) && FlxG.mouse.x < FlxG.width * .9)
				FlxG.openURL(data.link != null ? data.link : 'https://${data.artist.toLowerCase()}.newgrounds.com');
	}
}
