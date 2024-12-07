package states.substates;

import openfl.Assets;
import data.JsonData;
import entities.Present;
import flixel.tweens.FlxEase;
import ui.button.HoverButton;

class ArtSubstate extends flixel.FlxSubState
{
	var art:FlxSprite;
	var data:data.types.TankmasDefs.PresentDef;
	var theText:FlxText;

	var back_button:HoverButton;

	override public function new(content:String)
	{
		super();
		data = JsonData.get_present(content);
		trace(content);
		trace(data);

		art = new FlxSprite(0, 0);

		var image_url = #if censor_presents Paths.image_path('art-censored') #else Paths.image_path(data.file) #end;
		Assets.loadBitmapData(image_url).onComplete(on_image_loaded);

		add(art);

		final backBox:FlxSprite = new FlxSprite(0, 960).makeGraphic(1920, 120, FlxColor.BLACK);
		backBox.alpha = 0.3;
		add(backBox);

		theText = new FlxText(0, 980, 1920,
			((data.name != null && data.name != "") ? ('"' + data.name + '"') : "Untitled")
			+ " by "
			+ ((data.artist != null && data.artist != "") ? data.artist : "Unknown")
			+ '\nClick here to view this ${data.link != null ? 'piece' : 'artist'} on NG!');

		theText.setFormat(Paths.get('CharlieType-Heavy.otf'), 32, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		add(theText);

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

	function on_image_loaded(image)
	{
		art.loadGraphic(image);
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
		if (FlxG.mouse.justPressed && FlxG.mouse.overlaps(theText) && !FlxG.mouse.overlaps(back_button))
			FlxG.openURL(data.link != null ? data.link : 'https://${data.artist.toLowerCase()}.newgrounds.com');
	}
}
