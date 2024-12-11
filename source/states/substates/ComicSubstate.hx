package states.substates;

#if hl
import hl.I64;
#end
import data.JsonData;
import entities.Present;
import flixel.util.FlxTimer;
import sound.RadioManager;
import squid.ext.FlxSubstateExt;

class ComicSubstate extends FlxSubstateExt
{
	var art:FlxSprite;
	var backButton:FlxSprite;
	var forwardButton:FlxSprite;
	var exitButton:FlxSprite;

	var data:data.types.TankmasDefs.PresentDef;
	var theText:FlxText;
	var timings:Array<Float>;
	var page(default, set):Int = -1;
	var totalPages:Int = 0;
	var keepButtonsOff:Bool = false;
	var audio:FlxSound;
	var hasCover:Bool = false;
	var seenCover:Bool = false;

	override public function new(content:String, firstTime:Bool = false)
	{
		super();

		// sprite loading
		art = new FlxSprite(0, 0);
		add(art);

		backButton = new FlxSprite(20, 470).loadGraphic(Paths.get('left-arrow.png'));
		add(backButton);
		backButton.kill();

		forwardButton = new FlxSprite(1755, 470).loadGraphic(Paths.get('right-arrow.png'));
		add(forwardButton);

		exitButton = new FlxSprite(20, 20).loadGraphic(Paths.get('back-arrow.png'));
		add(exitButton);

		members.for_all_members((member:flixel.FlxBasic) -> cast(member, FlxObject).scrollFactor.set(0, 0));

		// getting present data
		data = JsonData.get_present(content);

		totalPages = data.comicProperties.pages;

		// preloading pages, just in case
		// for (i in 0...totalPages)
		// Paths.get(content + '-$i' + '.png');

		// checking for audio/automation and for cover
		if (data.comicProperties.audio != null)
		{
			RadioManager.volume = 0.0;
			keepButtonsOff = firstTime;
			if (keepButtonsOff)
				exitButton.kill();
		}

		if (data.comicProperties.cover)
		{
			hasCover = true;
			page = 0;
		}
		if (data.comicProperties.audio != null)
		{
			timings = data.comicProperties.timing;
			// the illusion of loading
			new FlxTimer().start(3, function(tmr:FlxTimer)
			{
				audio = SoundPlayer.sound(Paths.get(data.comicProperties.audio + '.ogg'));
				audio.onComplete = close;
				page += 1;
			});
		}
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		Ctrl.update();

		// auto page turning if audio is on
		if (audio != null && timings.length > (page - (hasCover ? 1 : 0)) && audio.time >= (timings[page - (hasCover ? 1 : 0)] * 1000))
			page = (page + 1);

		// button hovering logic
		if (FlxG.mouse.overlaps(backButton) && !FlxG.mouse.pressed && backButton.scale.x == 1)
			backButton.scale.set(1.1, 1.1)
		else if (!FlxG.mouse.overlaps(backButton) && backButton.scale.x != 1)
			backButton.scale.set(1, 1);
		if (FlxG.mouse.overlaps(forwardButton) && !FlxG.mouse.pressed && forwardButton.scale.x == 1)
			forwardButton.scale.set(1.1, 1.1)
		else if (!FlxG.mouse.overlaps(forwardButton) && forwardButton.scale.x != 1)
			forwardButton.scale.set(1, 1);
		if (FlxG.mouse.overlaps(exitButton) && !FlxG.mouse.pressed && exitButton.scale.x == 1)
			exitButton.scale.set(1.1, 1.1)
		else if (!FlxG.mouse.overlaps(exitButton) && exitButton.scale.x != 1)
			exitButton.scale.set(1, 1);

		// button/key press logic
		if ((Ctrl.left[1] || (FlxG.mouse.justPressed && FlxG.mouse.overlaps(backButton))) && !keepButtonsOff)
			forceChangePage(-1);
		if ((Ctrl.right[1] || (FlxG.mouse.justPressed && FlxG.mouse.overlaps(forwardButton))) && !keepButtonsOff)
			forceChangePage(1);
		if (Ctrl.menuConfirm[1] || (FlxG.mouse.justPressed && FlxG.mouse.overlaps(exitButton)))
			close();
	}

	function forceChangePage(int:Int)
	{
		page = (page + int);
		if (audio != null)
			audio.time = (timings[page - (hasCover ? 1 : 0)] * 1000);
	}

	function set_page(num:Int):Int
	{
		// making sure the number's legit
		if ((num <= 0 && seenCover) || num <= -1)
			return page = (hasCover ? 1 : 0);
		if (num > totalPages - (hasCover ? 0 : 1))
			return page = (hasCover ? totalPages : (totalPages - 1));

		// if it's the cover, we don't want players going back to the cover
		if (num == 0 && hasCover)
			seenCover = true;

		// reviving/killing buttons as needed
		if (((num == 1 && hasCover) || (num == 0)) && backButton.alive)
			backButton.kill()
		else if (!backButton.alive && !keepButtonsOff && (num != 1 && hasCover) && num != 0)
			backButton.revive();
		if ((num == (totalPages - 1) || keepButtonsOff) && forwardButton.alive)
			forwardButton.kill()
		else if (!forwardButton.alive && !keepButtonsOff)
			forwardButton.revive();

		// creating the page of art
		art.loadGraphic(Paths.get('${data.file}-$num' + '.png'));
		art.setGraphicSize(art.width > art.height ? 1920 : 0, art.height >= art.width ? 1080 : 0);
		art.updateHitbox();
		art.screenCenter();

		return page = num;
	}

	override function close()
	{
		art.kill();
		if (audio != null)
		{
			audio.stop();
			RadioManager.volume = 1.0;
		}
		super.close();
	}
}
