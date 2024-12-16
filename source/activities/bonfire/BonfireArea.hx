package activities.bonfire;

import entities.base.BaseUser;
import net.tankmas.NetDefs.NetEventDef;
import net.tankmas.NetDefs.NetEventType;
import net.tankmas.OnlineLoop;

class BonfireArea extends ActivityAreaInstance
{
	var stick:BonfireStick;
	var local:Bool;

	var bonfire_graphic:FlxSpriteExt;

	var txt:FlxText;

	public function new(player:BaseUser, area:ActivityArea)
	{
		super(player, area);
		local = player == PlayState.self.player;

		stick = new BonfireStick(player, this);
		stick.activate();

		PlayState.self.objects.add(this);
		visible = false;

		txt = new FlxText(x, y, 0, "", 32);
		txt.color = FlxColor.PURPLE;
		txt.setFormat(Paths.get('CharlieType-Heavy.otf'), 40, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		PlayState.self.objects.add(txt);
		update_text();

		if (player.data.marshmallow_streak == null)
			player.data.marshmallow_streak = 0;
	}

	function reset_streak()
	{
		player.data.marshmallow_streak = 0;
	}

	function update_text()
	{
		if (txt == null)
			return;
		txt.text = '${player.data.marshmallow_streak}';
		txt.visible = player.data.marshmallow_streak > 0;
		txt.x = player.x + 90;
		txt.y = player.y - 30;
	}

	override function on_leave()
	{
		super.on_leave();
		stick.hide();
		kill();
		txt.kill();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		update_text();
	}

	override function on_interact()
	{
		var marshmallow = stick.marshmallow;
		if (marshmallow != null)
		{
			if (marshmallow.current_level == Marshmallow.GOLDEN_MARSHMALLOW_LEVEL)
			{
				Marshmallow.on_cooked_perfect();
				player.data.marshmallow_streak++;
			}
			else
			{
				player.data.marshmallow_streak = 0;
			}

			update_text();

			#if !offline OnlineLoop.post_marshmallow_discard(marshmallow.current_level); #end
		}
		stick.shake_off();
	}

	override function on_event(event:NetEventDef)
	{
		super.on_event(event);
		if (local)
			return;

		if (event.type == NetEventType.DROP_MARSHMALLOW)
		{
			var level:Int = cast(event.data.level, Int);
			if (stick.marshmallow != null)
			{
				stick.marshmallow.set_level(level);
			}
			stick.shake_off();
		}
	}
}
