package entities;

import minigames.MinigameHandler;

/**
 * The minigame cabinet entity, which displays a given minigame when interacted with.
 */
class Minigame extends Interactable
{
	var minigame_id:String;

	var ready_to_play:Bool = false;

	public function new(?X:Float, ?Y:Float, width:Int, height:Int, minigame_id:String)
	{
		super(X, Y);

		this.minigame_id = minigame_id;

		// Make this interactable to start the minigame.
		interactable = true;
		detect_range = 300;
		type = Interactable.InteractableType.MINIGAME;

		PlayState.self.minigames.add(this);

		// TODO: Make this look better.
		makeGraphic(width, height, FlxColor.BLUE);
		alpha = 0.5;
	}

	public override function mark_target(mark:Bool):Void
	{
		ready_to_play = mark;
	}

	public override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (ready_to_play && Ctrl.jjump[1])
		{
			start_minigame();
		}
	}

	function start_minigame()
	{
		trace('Starting minigame ${minigame_id}!');

		MinigameHandler.instance.playMinigame(minigame_id);
	}
}
