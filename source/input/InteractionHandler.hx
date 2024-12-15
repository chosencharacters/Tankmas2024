package input;

import flixel.tweens.FlxEase;
import entities.Interactable;

enum MouseInteractionState
{
	// Nothing happening, can interact with UI
	Idle;
	// Just pressed in game,
	// leads to either tap (try interacting with game, or drag = auto move)
	// can't interact with UI
	Down;
	// Dragging, can't interact with UI
	Dragging;
}

class InteractionHandler extends FlxObject
{
	var play_state:PlayState;

	public var mouse_state:MouseInteractionState = Idle;

	public var ui_interaction_enabled(get, null):Bool;

	var interaction_arrow:FlxSprite;
	var interaction_arrow_offset_y = .0;

	// Potential interactables
	var hovered_interactable:Interactable = null;
	// When tapped, it will be triggered once in player range
	var active_interactable:Interactable = null;

	function get_ui_interaction_enabled()
		return mouse_state == Idle;

	public function new(play_state:PlayState)
	{
		super();
		this.play_state = play_state;

		interaction_arrow = new FlxSprite(0, 0, AssetPaths.interact_arrow__png);
		play_state.in_world_ui_overlay.add(interaction_arrow);
	}

	var time:Float = 0.0;

	var scale_x_tween:FlxTween = null;
	var scale_y_tween:FlxTween = null;

	function mark_interactable(i:Interactable)
	{
		interaction_arrow.x = i.x;
		interaction_arrow.y = i.y - interaction_arrow.height;
		interaction_arrow.visible = true;

		interaction_arrow.alpha = 0.4;
		interaction_arrow.scale.x = 0.0;
		interaction_arrow.scale.y = 0.0;

		if (scale_x_tween != null)
			scale_x_tween.cancel();
		if (scale_y_tween != null)
			scale_y_tween.cancel();

		scale_x_tween = FlxTween.tween(interaction_arrow, {"scale.x": 1.0, alpha: 1.0}, 0.2, {ease: FlxEase.elasticOut});
		scale_y_tween = FlxTween.tween(interaction_arrow, {"scale.y": 1.0}, 0.4, {ease: FlxEase.elasticOut});

		i.marked = true;
	}

	function unmark_interactable()
	{
		var i = hovered_interactable;
		if (i == null)
			return;

		i.marked = false;

		if (active_interactable != null)
			return;

		hovered_interactable = null;

		if (scale_x_tween != null)
			scale_x_tween.cancel();
		if (scale_y_tween != null)
			scale_y_tween.cancel();
		scale_x_tween = FlxTween.tween(interaction_arrow, {alpha: 0}, 0.1);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		time += elapsed;

		var input_mode = play_state.input_manager.mode;

		var player = play_state.player;

		var hovered_over_ui = play_state.ui_overlay.mouse_is_over_ui();
		var can_interact = Ctrl.mode.can_interact && Ctrl.mode.can_move;

		var untargeted_interact_tapped = Ctrl.mode.can_move && (Ctrl.jinteract[1] || play_state.touch.interact_just_released);
		var interact_tapped = Ctrl.mode.can_move && (Ctrl.jinteract[1] || play_state.touch.tap_just_released);

		if (active_interactable != null)
		{
			var dist = active_interactable.distance(player.get_feet_position());
			if (dist <= active_interactable.detect_range)
			{
				active_interactable.on_interact();
				active_interactable = null;
				unmark_interactable();
				return;
			}

			var movement_cancelled = !player.auto_moving;
			if (movement_cancelled)
			{
				active_interactable = null;
				unmark_interactable();
				return;
			}
		}

		if (hovered_over_ui || play_state.touch.press_type == Hold || !can_interact)
		{
			unmark_interactable();
			return;
		}

		interaction_arrow.offset.y = Math.sin(time * 1.5) * 8 + interaction_arrow_offset_y;

		var mouse_pos = FlxG.mouse.getWorldPosition();
		var player_pos = player.get_feet_position();

		var interact_position = input_mode == Keyboard ? player_pos : mouse_pos;
		var extra_distance = input_mode == MouseOrTouch ? -100. : 0;

		var interactables = Interactable.find_in_detect_range(interact_position, play_state.interactables, extra_distance);
		var i = Interactable.find_closest_in_array(interact_position, interactables);

		if (player.active_activity_area != null)
		{
			if (untargeted_interact_tapped)
			{
				player.active_activity_area.on_interact(player);
			}
			if (input_mode == Keyboard)
			{
				unmark_interactable();
				return;
			}
		}

		if (i != null)
		{
			// Only change arrow if switching active interactable
			if (i != hovered_interactable)
			{
				unmark_interactable();

				hovered_interactable = i;
				mark_interactable(hovered_interactable);
			}
		}
		else
		{
			unmark_interactable();
		}

		if (hovered_interactable != null && interact_tapped)
		{
			interaction_arrow.scale.y = 0.6;
			interaction_arrow.scale.x = 0.9;
			interaction_arrow_offset_y = 60.0;
			FlxTween.tween(this, {interaction_arrow_offset_y: 0.0}, 0.45, {ease: FlxEase.elasticOut});

			scale_y_tween = FlxTween.tween(interaction_arrow, {"scale.y": 1.0}, 0.4, {ease: FlxEase.elasticOut});
			scale_x_tween = FlxTween.tween(interaction_arrow, {"scale.x": 1.0}, 0.3, {ease: FlxEase.elasticOut});

			active_interactable = hovered_interactable;
		}
	}
}
