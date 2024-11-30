package entities;

import data.types.TankmasEnums.PresentAnimation;
import entities.base.NGSprite;
import ui.DialogueBox;

class NPC extends Interactable
{
	var name:String;

	public function new(?X:Float, ?Y:Float, name:String)
	{
		super(X, Y);

		detect_range = 300;
		interactable = true;

		type = Interactable.InteractableType.NPC;

		this.name = name;

		PlayState.self.npcs.add(this);

		loadGraphic(Paths.get('${name}.png'));

		sstate(IDLE);
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
				sprite_anim.anim(PresentAnimation.IDLE);
			case NEARBY:
				sprite_anim.anim(PresentAnimation.NEARBY);
			case CHATTING:
				sprite_anim.anim(PresentAnimation.IDLE);
		}

	override function on_interact()
	{
		if (state == NEARBY)
			start_chat();
	}

	function start_chat()
	{
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
		PlayState.self.npcs.remove(this, true);
		super.kill();
	}
}

private enum abstract State(String) from String to String
{
	var IDLE;
	final NEARBY;
	final CHATTING;
}
