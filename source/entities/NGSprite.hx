package entities;

import data.types.TankmasDefs.CostumeDef;
import data.types.TankmasDefs.SpriteAnimationDef;
import data.types.TankmasDefs.SpriteAnimationFrameDef;
import data.types.TankmasEnums.Costumes;
import data.types.TankmasEnums.PlayerAnimation;
import data.types.TankmasEnums.UnlockCondition;

class NGSprite extends FlxSpriteExt
{
	public var original_size:FlxPoint = new FlxPoint();

	var sprite_anim:SpriteAnimationController;

	public function new(?X:Float, ?Y:Float)
	{
		super(X, Y);
		sprite_anim = new SpriteAnimationController(this);
	}

	override function update(elapsed:Float)
	{
		sprite_anim.iterate();
		super.update(elapsed);
	}
}

class SpriteAnimationController
{
	var animation:SpriteAnimationDef;
	var index:Int = 0;
	var tick:Int = 0;

	var sprite:NGSprite;

	public var finished(get, never):Bool;
	public var name(get, never):String;

	var max_index(get, never):Int;
	var frame(get, never):SpriteAnimationFrameDef;

	var on_complete:Void->Void;

	public function new(sprite:NGSprite)
		this.sprite = sprite;

	public function anim(animation:SpriteAnimationDef, ?on_complete:Void->Void)
	{
		if (this.animation != null && this.animation.name == animation.name)
			return;

		#if trace_animation
		trace('${sprite.type}: $name -> ${animation.name}');
		#end

		this.on_complete = on_complete;
		this.animation = animation;
		tick = 0;
		index = 0;

		reset_sprite();
		update_sprite();
	}

	public function iterate()
	{
		if (animation == null)
			return;

		tick++;

		var frame_length:Float = 60 / animation.fps;
		var duration:Float = tick / frame_length;
		var duration_elapsed:Bool = duration >= frame.duration;

		if (!duration_elapsed)
			return;

		tick = 0;

		index++;

		if (finished)
		{
			trace('${animation.name} finished');
			animation = null;
			on_complete == null ? false : on_complete();
			return;
		}

		if (index > max_index)
			index = 0;

		update_sprite();
	}

	function update_sprite()
	{
		sprite.offset.x = frame.x == null ? sprite.offset.x : -frame.x;
		sprite.offset.y = frame.y == null ? sprite.offset.y : -frame.y;
		sprite.scale.x = frame.width == null ? sprite.scale.x : frame.width;
		sprite.scale.y = frame.height == null ? sprite.scale.y : frame.height;

		sprite.angle = frame.angle == null ? sprite.angle : frame.angle;
	}

	public function reset_sprite()
	{
		sprite.offset.set(0, 0);
		sprite.scale.set(1, 1);
		sprite.angle = 0;
	}

	public function get_name():String
		return animation == null ? null : animation.name;

	public function get_frame():SpriteAnimationFrameDef
		return animation == null ? null : animation.frames[index];

	public function get_finished():Bool
		return animation == null || !animation.looping && index >= max_index;

	public function get_max_index():Int
		return animation == null ? 0 : animation.frames.length - 1;
}
