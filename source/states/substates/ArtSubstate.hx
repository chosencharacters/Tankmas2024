package states.substates;

import data.JsonData;
import entities.Present;

class ArtSubstate extends flixel.FlxSubState
{
	var art:FlxSprite;
	var data:data.types.TankmasDefs.PresentDef;
	var theText:FlxText;

	override public function new(content:String)
	{
		super();
		art = new FlxSprite(0, 0).loadGraphic(Paths.get('$content.png'));

		#if censor_presents
		art = new FlxSprite(0, 0).loadGraphic(Paths.get('present-censored.png'));
		#end

		art.setGraphicSize(art.width > art.height ? 1920 : 0, art.height >= art.width ? 1080 : 0);
		art.updateHitbox();
		art.screenCenter();
		add(art);

		final backBox:FlxSprite = new FlxSprite(0, 960).makeGraphic(1920, 120, FlxColor.BLACK);
		backBox.alpha = 0.3;
		add(backBox);

		data = JsonData.get_present(content);

		theText = new FlxText(0, 980, 1920,
			((data.name != null && data.name != "") ? ('"' + data.name + '"') : "Untitled")
			+ " by "
			+ ((data.artist != null && data.artist != "") ? data.artist : "Unknown")
			+ '\nClick here to view this ${data.link != null ? 'piece' : 'artist'} on NG!');
		theText.setFormat(null, 32, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		add(theText);

		members.for_all_members((member:flixel.FlxBasic) -> cast(member, FlxObject).scrollFactor.set(0, 0));
	}

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
		if (FlxG.mouse.justPressed && FlxG.mouse.overlaps(theText))
			FlxG.openURL(data.link != null ? data.link : 'https://${data.artist.toLowerCase()}.newgrounds.com');
	}
}
