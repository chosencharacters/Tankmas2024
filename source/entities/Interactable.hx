package entities;

import entities.base.NGSprite;

class Interactable extends NGSprite
{
	public var detect_range:Int;
	public var interactable:Bool;

	public var marked(default, set):Bool = false;

	function set_marked(m)
	{
		if (m != marked)
			mark_target(m);
		return marked = m;
	}

	public function new(?X:Float, ?Y:Float)
	{
		super(X, Y);
		PlayState.self.interactables.add(this);
	}

	public static function find_in_detect_range<T:Interactable>(player:Player, interactables:FlxTypedGroup<T>):Array<T>
		return interactables.members.filter((interactable:T) -> interactable.interactable
			&& interactable.mp.distance(player.mp) < interactable.detect_range);

	public static function find_closest_in_array<T:Interactable>(player:Player, interactables:Array<T>):T
	{
		var interactables_with_distance:Array<{interactable:T, distance:Float}> = [];

		for (interactable in interactables)
			interactables_with_distance.push({interactable: interactable, distance: interactable.mp.distance(player.mp)});

		if (interactables_with_distance.length > 0)
		{
			interactables_with_distance.sort((a, b) -> a.distance > b.distance ? -1 : 1); // might be other way around
			return interactables_with_distance.pop().interactable; // or this might be shift
		}

		return null;
	}

	// Called when in range and player presses interact button
	public function on_interact() {}

	function mark_target(mark:Bool) {}

	public static function unmark_all<T:Interactable>(interactables:FlxTypedGroup<T>)
		for (interactable in interactables)
			interactable.marked = false;

	override function kill()
	{
		PlayState.self.interactables.remove(this, true);
		super.kill();
	}
}

enum abstract InteractableType(String) from String to String
{
	final NPC = "npc";
	final PRESENT = "present";
	final MINIGAME = "minigame";
}
