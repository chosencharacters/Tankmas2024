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

	public function new(player:BaseUser, area:ActivityArea)
	{
		super(player, area);
		local = player == PlayState.self.player;
		stick = new BonfireStick(player, this);
		stick.activate();
	}

	override function on_leave()
	{
		super.on_leave();
		stick.hide();
		destroy();
	}

	override function on_interact()
	{
		var marshmallow = stick.marshmallow;
		if (marshmallow != null)
		{
			OnlineLoop.post_marshmallow_discard(Main.current_room_id, marshmallow.current_level);
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
