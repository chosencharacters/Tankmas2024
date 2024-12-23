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

	var if_flag:String;
	var unless_flag:String;

	public function new(?X:Float, ?Y:Float, name:String, timelock:Int, ?if_flag:String, ?unless_flag:String)
	{
		super(X, Y);

		this.if_flag = if_flag;
		this.unless_flag = unless_flag;

		def = Lists.npcs.get(name);

		if (def == null || def.animations == null)
			def = Lists.npcs.get("default-npc");

		this.timelock = timelock * 1000;

		detect_range = 300;
		interactable = true;

		type = Interactable.InteractableType.NPC;

		this.name = name;

		PlayState.self.world_objects.add(this);

		var anim_set_name:String = Lists.animSets.exists(name) ? name : "npc-default";

		loadAllFromAnimationSet(anim_set_name, name);

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
		if (def == null || def.animations == null)
			return;
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
		var TIMELOCKED:Bool = timelock > 0 && Main.time.utc < timelock;
		var IF_FLAG_CHECK:Bool = if_flag == null || Flags.get_bool(if_flag);
		var UNLESS_FLAG_BLOCKED:Bool = unless_flag != null && Flags.get_bool(unless_flag);

		return !TIMELOCKED && IF_FLAG_CHECK && !UNLESS_FLAG_BLOCKED;
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
		new DialogueBox(Lists.npcs.get(name).get_current_state_dlg());
		sstate(CHATTING, fsm);
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
