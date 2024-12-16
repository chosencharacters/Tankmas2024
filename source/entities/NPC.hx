package entities;

import data.loaders.NPCLoader.NPCDef;
import data.types.TankmasEnums.NPCAnimation;
import data.types.TankmasEnums.PresentAnimation;
import entities.base.NGSprite;
import ui.DialogueBox;

class NPC extends Interactable
{
	var name:String;
	var timelock:Int = 0;

	var def:NPCDef;

	public function new(?X:Float, ?Y:Float, name:String, timelock:Int)
	{
		super(X, Y);

		def = Lists.npcs.get(name);

		this.timelock = timelock * 1000;

		detect_range = 300;
		interactable = true;

		type = Interactable.InteractableType.NPC;

		this.name = name;

		PlayState.self.world_objects.add(this);

		loadAllFromAnimationSet(name);

		sstate(IDLE, fsm);
	}

	override function update(elapsed:Float)
	{
		fsm();
		super.update(elapsed);
	}

	function fsm()
		switch (cast(state, State))
		{
			default:
			case IDLE:
				conditional_animation("idle");
				visible = interactable = spawn_condition_check();
			case NEARBY:
				conditional_animation("nearby", "idle");
			case CHATTING:
				sprite_anim.anim(PresentAnimation.IDLE);
		}

	function conditional_animation(animation:String, ?fallback:String)
	{
		if (def.animations.exists(animation))
		{
			if (def.animations.get(animation).sprite_anim != null)
				switch (def.animations.get(animation).sprite_anim)
				{
					case "float-slow":
						sprite_anim.anim(NPCAnimation.FLOAT_SLOW);
					case "float-normal" | "float":
						sprite_anim.anim(NPCAnimation.FLOAT_NORMAL);
					case "float-fast":
						sprite_anim.anim(NPCAnimation.FLOAT_FAST);
					case "float-hyper":
						sprite_anim.anim(NPCAnimation.FLOAT_HYPER);
				}
		}
		else
		{
			if (fallback != null)
				conditional_animation(animation);
		}
	}

	function spawn_condition_check():Bool
	{
		if (timelock > 0 && Main.time.utc < timelock)
			return false;
		return true;
	}

	override function on_interact()
	{
		if (state == NEARBY)
			start_chat();
	}

	function start_chat()
	{
		PlayState.self.player.velocity.scale(0.25, 0.25);
		Ctrl.allFalse();
		new DialogueBox(Lists.npcs.get(name).get_state_dlg("default"), {on_complete: () -> interactable = true});
		sstate(CHATTING, fsm);
		interactable = false;
	}

	override public function mark_target(mark:Bool)
	{
		if (mark && interactable)
			sstate(NEARBY);
		if (!mark && interactable)
			sstate(IDLE);
	}

	override function kill()
	{
		PlayState.self.world_objects.remove(this, true);
		super.kill();
	}
}

private enum abstract State(String) from String to String
{
	var IDLE;
	final NEARBY;
	final CHATTING;
}
