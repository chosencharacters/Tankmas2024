package squid.sprite;

import flixel.FlxBasic;
import flixel.FlxSprite;
import flixel.addons.tile.FlxTilemapExt;
import flixel.graphics.frames.FlxTileFrames;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.tile.FlxTilemap;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import haxe.io.Float32Array;
import openfl.filters.ShaderFilter;

using Math;
using flixel.util.FlxArrayUtil;

/**
 * Extends FlxSprite
 * @author
 */
class FlxSpriteExt extends FlxSprite
{
	public var type:String = "";
	public var typeMajor:String = "";
	public var type_print(get, default):String;

	public var state:String = "";

	public var reversed:Bool = false;

	public var animation_links:Map<String, String> = new Map<String, String>();

	var tick:Float = 0;

	/***saves elapsed from this update cycle, good for making things move in paused***/
	var elapsedSave:Float = 0;

	// was the hitbox overwritten already (used for animSet overriding)
	var hitboxOverriten:Bool = false;

	/**Remain active if paused cutscene*/
	var remain_active_if_cutscene:Bool = false;

	/**Default random*/
	public var ran:FlxRandom = new FlxRandom();

	/**Sprite this is tracking*/
	public var tracking_target:FlxSpriteExt;

	public var always_on_screen:Bool = false;

	var offset_left:FlxPoint;
	var offset_right:FlxPoint;

	/**Sprite should be flipped? Only used by NPCs so far*/
	var reverse_mod:Bool = false;

	public var on(default, set):Bool = true;
	public var off(get, set):Bool;

	public var iid(get, default):String = null;

	var on_first_update:Void->Void;

	var animLoaded:Bool = false;

	/** For linking/chaining sprites **/
	public var linked_sprite:FlxSpriteExt;

	public var level_id:String = "";

	public var move_and_adjust_org:FlxPoint;

	public var on_update:Void->Void;

	public var animSet:AnimSet;

	public var frame_callbacks:Map<Int, Void->Void> = new Map<Int, Void->Void>();

	var use_animation_links:Bool = true;

	var trace_new_state:Bool = false;
	var trace_new_anim:Bool = false;
	var trace_sound_frame:Bool = false;

	public static var updated_last_frame:Array<String> = [];

	public var is_on_new_frame:Bool = true;

	var anim_history:Array<String> = [];
	var state_history:Array<String> = [];

	var quick_debug(default, set):Bool = false;

	var bottom_y(get, never):Float;
	var top_y(get, never):Float;

	var left_x(get, never):Float;
	var right_x(get, never):Float;

	var trace_on_off_flags:Bool = false;

	/**Midpoint, shorthand for getMidpoint(FlxPoint.weak())*/
	public var mp(get, default):FlxPoint;

	public function new(?X:Float = 0, ?Y:Float = 0, ?SimpleGraphic:FlxGraphicAsset)
	{
		super(X, Y, SimpleGraphic);
		type = "sprite";
	}

	function set_quick_debug(val:Bool):Bool
	{
		trace_new_state = trace_new_anim = quick_debug = val;
		return val;
	}

	override function updateMotion(elapsed:Float)
	{
		if (tracking_target != null)
		{
			setPosition(tracking_target.x - tracking_target.offset.x, tracking_target.y - tracking_target.offset.y);
			return;
		}
		super.updateMotion(elapsed);
	}

	/*
	 * Shorthand for animation
	 */
	public function anim(new_anim:String):FlxSpriteExt
	{
		var animation_switching:Bool = new_animation_check(new_anim);

		if (animation == null)
			return this;

		#if dev_trace
		if (trace_new_anim && animation.name != new_anim)
			trace('[${type}] New Animation: ${get_cur_anim_name()} -> ${new_anim} [a: $alpha] [v: $visible]');
		#end

		actually_play_the_animation(new_anim);

		if (animation_switching)
		{
			anim_history.push(new_anim);
			is_on_new_frame = true;
		}

		return this;
	}

	@:noCompletion
	function actually_play_the_animation(new_anim:String)
		animation.play(new_anim);

	/*Would this be a new animation?*/
	public function new_animation_check(new_anim:String)
		return new_anim != last_anim;

	function get_cur_anim_name():String
		return animation.name;

	public var last_anim(get, never):String;

	function get_last_anim():String
		return anim_history.last();

	function animConditionals(compare:String, array:Array<String>)
	{
		return array.indexOf(compare) != -1 && array.indexOf(last_anim) == -1;
	}

	override public function update(elapsed:Float):Void
	{
		updated_last_frame.push(type + " " + Type.getClassName(Type.getClass(this)) + " " + loaded_image);

		if (on_first_update != null)
		{
			on_first_update();
			on_first_update = null;
		}

		on_update != null ? on_update() : null;

		elapsedSave = elapsed;

		if (tracking_target != null)
			update_tracking_target();

		is_on_new_frame = false;

		super.update(elapsed);

		if (frame_callbacks.get(animation.frameIndex) != null && new_frame_check(animation.frameIndex))
			frame_callbacks.get(animation.frameIndex)();
	}

	/**
	 * Handles animation links
	 */
	function animation_link_handler(animation_name:String)
	{
		#if debug_links
		// trace("LINK ATTEMPT ", animation_name, animation_links.get(animation_name));
		#end
		if (animation_links.get(animation_name) != null)
		{
			var pre_link_frame:Int = animation.frameIndex;
			link_animation(animation_name); // used to be animation_links.get(animation_name)
			#if debug_links
			trace('ANIM LINK ${animation_name} -> ${animation_links.get(animation_name)} on FRAME: ${pre_link_frame}');
			#end
			return;
		}
	}

	function link_animation(linked_animation_name:String)
		if (animation_links.get(linked_animation_name) != null)
			anim(animation_links.get(linked_animation_name));

	/*
	 * Adds an animation using the Renaine shorthand
	 */
	public function animAdd(?def:AnimDef, animName:String, ?frames_string:String, ?frames_array:Array<Int>, ?fps:Int = 14, loopSet:Bool = true,
			flipXSet:Bool = false, flipYSet:Bool = false, animationLink:String = "", ?frame_offset:Int = 0)
	{
		#if fast_anim
		fps = fps * 3;
		#end

		if (frames_string == null && frames_array == null)
			throw "ANIM SET ERROR: You need frames_string or frames_array";

		if (animationLink.length > 0)
		{
			addAnimationLink(animName, animationLink);
			animation.finishCallback = animation_link_handler;
			#if dev_trace
			// if (loopSet)
			// trace('WARNING: looping == true in animation ${animName} with link ${animationLink}\nAutomatically setting looping to false');
			#end
			loopSet = false;
		}

		var frames:Array<Int> = frames_array == null ? Utils.anim(frames_string) : frames_array.copy();

		for (f in 0...frames.length)
			frames[f] = frames[f] + frame_offset;

		animation.add(animName, frames, fps, loopSet, flipXSet, flipYSet);
	}

	public function animAddPlay(animName:String, animString:String, fps:Int = 14, loopSet:Bool = true, flipXSet:Bool = false, flipYSet:Bool = false,
			animationLink:String = "")
	{
		animation.add(animName, Utils.anim(animString), fps, loopSet, flipXSet, flipYSet);
		animation.play(animName);
	}

	/**
		Adds a linking animation when this animation ends, "from" must not be Looped!
		@param	from a non-looped anim
		@param	to another anim, doesn't matter if it's looped or not
	**/
	public function addAnimationLink(from:String, to:String)
		animation_links.set(from, to);

	/*
	 * Changes back to stateSet, overrideName if set
	 */
	public function animProtect(overrideName:String = ""):Bool
	{
		if (overrideName == "")
		{
			if (animation != null && animation.name != state)
			{
				anim(state);
				return true;
			}
		}
		else
		{
			if (animation == null || animation.name != overrideName)
			{
				anim(overrideName);
				return true;
			}
		}
		return false;
	}

	/**
	 * Shorthand for simple animProtect states
	 * @param anim_protect_name anim to protect
	 * @param next_state_name state to swap to
	 * @param animate_on_finish sstateAnim or just sstate
	 * @return Bool if state was swapped
	 */
	public function anim_protect_then_switch_state(?anim_protect_name:String, next_state_name:String, animate_on_finish:Bool = false):Bool
	{
		if (anim_protect_name == null)
			anim_protect_name = state;

		animProtect(anim_protect_name);

		if (animation.finished)
		{
			animate_on_finish ? sstateAnim(next_state_name) : sstate(next_state_name);
			return true;
		}
		return false;
	}

	function anim_protect_then_kill(name:String)
	{
		animProtect(name);
		if (animation.finished)
		{
			kill();
			state = "";
		}
	}

	function anim_protect_then_function(name:String, on_complete:Void->Void)
	{
		animProtect(name);
		if (animation.finished)
			on_complete();
	}

	override function overlaps(objectOrGroup:FlxBasic, inScreenSpace:Bool = false, ?camera:FlxCamera):Bool
		return objectOrGroup == null ? false : super.overlaps(objectOrGroup, inScreenSpace, camera);

	/*
	 * Overlap collide, might be useful
	 */
	function ovCollide(a:FlxObject):Bool
		return overlaps(a) ? false : FlxObject.separate(a, this);

	/**
	 * Short hand for overlaps and then pixelPerfectOverlaps which hopefully makes things more efficient
	 * @param a 
	 * @param b 
	 * @param alpha_tolerance base alpha tolerance for consistency, set REALLY low
	 */
	public function pixel_overlaps(b:FlxSprite, alpha_tolerance:Int = 25):Bool
		return Utils.pixel_overlaps(this, b);

	public function loadGraphicExt(Graphic:FlxGraphicAsset, Animated:Bool = false, Width:Int = 0, Height:Int = 0, Unique:Bool = false, ?Key:String):FlxSpriteExt
		return cast(loadGraphic(Graphic, Animated, Width, Height, Unique, Key), FlxSpriteExt);

	public function makeGraphicExt(Width:Int, Height:Int, Color:FlxColor = FlxColor.WHITE, Unique:Bool = false, ?Key:String):FlxSpriteExt
		return cast(makeGraphic(Width, Height, Color, Unique, Key), FlxSpriteExt);

	override function loadGraphic(graphic:FlxGraphicAsset, animated:Bool = false, frameWidth:Int = 0, frameHeight:Int = 0, unique:Bool = false,
			?key:String):FlxSprite
	{
		try
		{
			if (loaded_image == "sprite" || loaded_image == "")
				loaded_image = Std.string(graphic);
		}
		catch (e)
		{
			trace(e);
		}

		asset_name = (loaded_image.contains(".png") ? loaded_image : '${loaded_image}.png').split("/").last();

		return super.loadGraphic(graphic, animated, frameWidth, frameHeight, unique, key);
	}

	/**
	 * Loads the Image AND Animations from an AnimationSet
	 * @param anim_set_name file name as it is in animSets
	 * @param image_override loading an animSet with another image, useful for similar things like npcs with the same animation cycles
	 * @param unique unique graphic? used in loading graphics that are going to have pixel manipulations that aren't universal
	 * @param auto_play animation to play automatically 
	 * @param unsafe suppress the throw on error
	 * @param frame_offset offset for all frame animations, good for multiple chars on same sheet
	 * @return FlxSpriteExt for chaining
	 */
	public function loadAllFromAnimationSet(anim_set_name:String, ?image_override:String, unique:Bool = false, auto_play:String = "idle", unsafe:Bool = false,
			?frame_offset:Int = 0):FlxSpriteExt
	{
		var file_path:String = Paths.get('${anim_set_name}.png');

		animSet = Lists.getAnimationSet(anim_set_name);
		loaded_image = anim_set_name;

		// "-hitbox" is ignored if it failed to load
		if (animSet == null && anim_set_name.indexOf("-hitbox") > -1)
			return loadAllFromAnimationSet(anim_set_name.replace("-hitbox", ""), anim_set_name, unique, auto_play, unsafe, frame_offset);

		if (animSet == null)
		{
			if (Paths.get('${anim_set_name}.aseprite', true) != null)
			{
				trace("running aseprite_to_xml for " + anim_set_name);
				#if sys
				data.loaders.AsepriteLoader.load_anim_set_from_xml(anim_set_name, true);
				animSet = Lists.getAnimationSet(anim_set_name);
				#end
			}
		}

		// No animSet found, check if aseprite exists
		if (animSet == null)
		{
			var file_path:String = Paths.get('${anim_set_name}.png');
			if (file_path == null)
				Paths.get('${anim_set_name}.png');

			loadGraphic(Paths.get('${anim_set_name}.png'), false, unique);
			animAdd("idle", "0");
			return this;
		}

		if (type == "sprite" || type == "")
			type = anim_set_name;

		// No animSet found, load as a basic .png
		if (animSet == null)
		{
			var file_path:String = Paths.get('${anim_set_name}.png');
			loadGraphic(Paths.get('${anim_set_name}.png'), false, unique);
			animAdd("idle", "0");
			return this;
		}

		var animWidth:Float = animSet.dimensions.x;
		var animHeight:Float = animSet.dimensions.y;

		var file_name:String = '${image_override == null ? anim_set_name : image_override}.png';

		var file_path:String = Paths.file_exists(file_name) ? Paths.get(file_name) : Paths.get('${anim_set_name}.png');

		loadGraphic(file_path, true, Math.floor(animWidth), Math.floor(animHeight), unique);

		if (graphic == null && !unsafe)
			throw '${file_path} is null!';

		if (animWidth == 0)
			animWidth = graphic.width / (animSet.maxFrame + 1);
		if (animHeight == 0)
			animHeight = graphic.height;

		if (animSet.offset.x != -999)
			offset.x = animSet.offset.x;
		if (animSet.offset.y != -999)
			offset.y = animSet.offset.y;

		if (animSet.offset_left != null)
			offset_left = animSet.offset_left;

		if (animSet.offset_right != null)
			offset_right = animSet.offset_right;

		reverse_mod = animSet.reverse_mod;

		frames = FlxTileFrames.fromGraphic(graphic, FlxPoint.get(animWidth, animHeight));

		if (animSet.hitbox.x != 0)
		{
			setSize(animSet.hitbox.x, animSet.hitbox.y);
			hitboxOverriten = true;
		}

		return loadAnimsFromAnimationSet(anim_set_name, auto_play, frame_offset);
	}

	/**
	 * Image currently loaded, gets set whenever loadAnimsFromAnimationSet is called
	 */
	public var loaded_image:String = "";

	public var asset_name:String = "";

	public function loadAnimsFromAnimationSet(anim_set_name:String, auto_play:String = "idle", ?frame_offset:Int = 0):FlxSpriteExt
	{
		animSet = Lists.getAnimationSet(anim_set_name);
		loaded_image = animSet.image;

		if (animSet == null)
			return this;

		animLoaded = true;

		for (set in animSet.animations)
		{
			animation.remove(set.name);
			animAdd(set, set.name, set.frames, set.fps, set.looping, false, false, set.linked, frame_offset);
			if (set.name == auto_play)
				anim(auto_play);
		}

		animation.callback = animation_callback;

		post_animation_set_load();

		return this;
	}

	public function post_animation_set_load()
		return;

	/**
	 * Returns all animation *names* from an animSet
	 * @param anim_set_name name
	 * @return Array<String>
	 */
	public function getAnimationNamesFromAnimSet(anim_set_name:String):Array<String>
	{
		var arr:Array<String> = [];
		for (a in Lists.getAnimationSet(anim_set_name).animations)
			arr.push(a.name);
		return arr;
	}

	/**
		Increment tick by i * timescale
		@param	add int to increment by
	**/
	public function ttick(add:Int = 1):Float
	{
		tick += add * FlxG.timeScale;
		return tick;
	}

	/**
	 * Switch state
	 * @param s new state
	 * @param reset_tick resets ticking int
	 */
	public function sstate(new_state:String, ?reset_tick:Bool = true, ?post_function:Void->Void)
	{
		var state_changing:Bool = new_state_check(new_state);

		#if dev_trace
		if (trace_new_state && state_changing)
			trace('[${type}] New State: ${state} -> ${new_state}');
		#end

		if (reset_tick)
			tick = 0;

		if (state_changing)
		{
			state = new_state;
			state_history.push(new_state);
		}

		post_function != null ? post_function() : null;
	}

	public function sstateAnim(new_state:String, reset_tick:Bool = true)
	{
		sstate(new_state, reset_tick);
		anim(new_state);
	}

	/*Would this be a new state?*/
	public function new_state_check(new_state:String)
		return new_state != state;

	public function is_state(state_to_check):Bool
		return state == state_to_check;

	/**
	 * Shorthand for getting distance to a sprite (well, object, but who uses FlxObject anyways)
	 * @param object the sprite or object
	 * @return Float the distance
	 */
	public function distance_to_sprite(object:FlxObject):Float
		return mp.distance(object.getMidpoint(FlxPoint.weak()));

	/**
	 * Shorthand for getting X distance to a sprite (well, object, but who uses FlxObject anyways)
	 * @param object the sprite or object
	 * @return Float the distance
	 */
	public function distance_to_sprite_x(object:FlxObject):Float
		return mp.distance_x(object.getMidpoint(FlxPoint.weak()));

	/**
	 * Shorthand for getting Y distance to a sprite (well, object, but who uses FlxObject anyways)
	 * @param object the sprite or object
	 * @return Float the distance
	 */
	public function distance_to_sprite_y(object:FlxObject):Float
		return mp.distance_y(object.getMidpoint(FlxPoint.weak()));

	/**return total distance between this sprite's midpoint and another point**/
	public function distance(P2:FlxPoint):Float // distance two points
		return mp.distance(P2);

	public function get_mp():FlxPoint
		return getMidpoint(FlxPoint.weak());

	var track_sprite_options:TrackSpriteOptions;

	/**
	 * Start following a sprite *exactly*
	 * @param new_sprite the sprite to follow
	 */
	public function track_sprite(target_sprite:FlxSpriteExt, ?options:TrackSpriteOptions)
	{
		tracking_target = target_sprite;
		track_sprite_options = options;
		update_tracking_target();
	}

	public function update_tracking_target()
	{
		if (tracking_target == null || tracking_target.velocity == null)
			return;
		try
		{
			flipX = tracking_target.flipX;
			velocity.copyFrom(tracking_target.velocity);
			drag.copyFrom(tracking_target.drag);
			acceleration.copyFrom(tracking_target.acceleration);
			flipX = tracking_target.flipX;
			x = tracking_target.x - tracking_target.offset.x;
			y = tracking_target.y - tracking_target.offset.y;

			if (track_sprite_options != null)
			{
				if (track_sprite_options.track_offset)
					offset.copyFrom(tracking_target.offset);

				if (track_sprite_options.reverse_flip)
					flipX = !tracking_target.flipX;
			}
		}
		catch (e)
		{
			#if dev_trace
			trace(e);
			trace(tracking_target.type, velocity);
			#end
		}
	}

	/**Shorthand for FlxPoint.weak(x, y)**/
	function point_weak(?X:Float = 0, ?Y:Float = 0)
		return FlxPoint.weak(X, Y);

	public function extLoadSet(?image:String, ?image_as:String, unique:Bool = false):FlxSpriteExt
	{
		loadAllFromAnimationSet(image, image_as, unique);
		return this;
	}

	public function one_line(?image:String, ?image_as:String, unique:Bool = false)
	{
		extLoadSet(image, image_as, unique);
		return this;
	}

	public function new_frame_check(frame:Int, verboise:Bool = false):Bool
		return is_on_new_frame && animation != null && animation.frameIndex == frame;

	public function animCheck(?anim_name:String, ?anim_name_array:Array<String>):Bool
	{
		if (anim_name == null)
		{
			for (anim_name in anim_name_array)
				if (animation.name == anim_name)
					return true;
		}
		else
		{
			return anim_name == animation.name;
		}
		return false;
	}


	public function get_iid():String
	{
		if (iid == null)
			return 'Trying to access Sprite ${type} without iid';
		return iid;
	}

	public function center_on_spawn()
		setPosition(x - width * .5, y + 16 - height);

	public function addPosition(position:FlxPoint)
	{
		x += position.x;
		y += position.y;
	}

	public function subtractPosition(position:FlxPoint)
	{
		x -= position.x;
		y -= position.y;
	}

	public function turnOn(source:FlxSpriteExt = null)
	{
		on = true;
		#if dev_trace
		if (trace_on_off_flags)
			trace('TURNING ON ${type} (${iid})');
		#end
	}

	public function turnOff(source:FlxSpriteExt = null)
	{
		on = false;
		#if dev_trace
		if (trace_on_off_flags)
			trace('TURNING OFF ${type} (${iid})');
		#end
	}

	public function turnOnInstantly(source:FlxSpriteExt = null)
		turnOn(source);

	public function turnOffInstantly(source:FlxSpriteExt = null)
		turnOff(source);

	/**
	 * Special kill from entity killer
	 * @param damage_kill whether to do it by damage or call kill()/special kill directly, no effect on base FlxSpriteExt
	 */
	public function entity_killer_kill(damage_kill:Bool)
		kill();

	override function kill()
	{
		tracking_target = null;
		super.kill();
	}

	public function get_tile_coords(?lvl:FlxTilemap):FlxPoint
	{
		if (lvl != null)
			return FlxPoint.get(get_tile_x(lvl), get_tile_y(lvl));
		throw "need lvl set on on base FlxSpriteExt";
	}

	public function get_tile_x(?lvl:FlxTilemap):Int
	{
		if (lvl != null)
			return Math.floor((x - lvl.x) / 16);
		throw "need lvl set on on base FlxSpriteExt";
	}

	public function get_tile_y(?lvl:FlxTilemap):Int
	{
		if (lvl != null)
			return Math.floor((y - lvl.y) / 16);
		throw "need lvl set on on base FlxSpriteExt";
	}

	override function toString():String
		try
		{
			return
				'{${type} (${Type.getClassName(Type.getClass(this)).split(".").last()}) - state: [${state}] ${toStringAnim()} - [ex:${exists}][vis:${visible}][immv:${immovable}][a:${alpha}] - pos: (${x.floor()}, ${y.floor()}) ${toStringVelocity()}';
		}
		catch (e)
		{
			return 'FlxSpriteExt to string error: ${e}';
		}

	public function toStringAnim():String
		return animation == null ? "anim: [NONE]" : 'anim: ${animation.name} (${animation.frameIndex})(${animation.finished})';

	public function toStringVelocity():String
		return velocity == null ? "vel: [NONE]" : 'vel (${velocity.x.floor()}, ${velocity.y.floor()})}';

	/**
	 * Debug tool for offsets, call on update
	 */
	public function offset_adjust(?rate:Int = 1, addString:String = "")
	{
		if (FlxG.keys.anyJustPressed(["UP"]))
			offset.y -= rate;
		if (FlxG.keys.anyJustPressed(["DOWN"]))
			offset.y += rate;
		if (FlxG.keys.anyJustPressed(["LEFT"]))
			offset.x -= rate;
		if (FlxG.keys.anyJustPressed(["RIGHT"]))
			offset.x += rate;

		if (FlxG.keys.anyJustPressed(["F"]))
			flipX = !flipX;

		if (FlxG.keys.anyJustPressed(["LEFT", "RIGHT", "UP", "DOWN"]))
		{
			if (addString == "")
				addString = type;
			trace(addString + "\n" + "offset.set(" + offset.x + ", " + offset.y + ");");
		}
	}

	var position_adjust_point:FlxPoint = new FlxPoint(0, 0);

	/**
	 * Debug tool for offsets, call on update
	 */
	public function position_adjust(?rate:Int = 1, addString:String = "")
	{
		if (FlxG.keys.anyJustPressed(["UP"]))
		{
			y -= rate;
			position_adjust_point.y -= rate;
		}

		if (FlxG.keys.anyJustPressed(["DOWN"]))
		{
			y += rate;
			position_adjust_point.y += rate;
		}

		if (FlxG.keys.anyJustPressed(["LEFT"]))
		{
			x -= rate;
			position_adjust_point.x -= rate;
		}

		if (FlxG.keys.anyJustPressed(["RIGHT"]))
		{
			x += rate;
			position_adjust_point.x += rate;
		}

		if (FlxG.keys.anyJustPressed(["F"]))
			flipX = !flipX;

		if (FlxG.keys.anyJustPressed(["LEFT", "RIGHT", "UP", "DOWN"]))
		{
			if (addString == "")
				addString = type;

			trace(addString + '\nsetPosition(x + ${position_adjust_point.x}, y + ${(position_adjust_point.y)})');
		}
	}

	/**
	 * Returns all entities in a FlxTypedGroup, usually used for locating all listeners 
	 * @param group TypedGroup to check in
	 * @param entity_ids group of entity ids
	 * @return Similarly type *Array* with iids
	 */
	inline function get_listening_entities<T:FlxSpriteExt>(group:FlxTypedGroup<T>, entity_ids:Array<String>):Array<T>
		return group.members.filter(entity -> entity_ids.contains(entity.iid));

	public inline function add_xy(X:Float, Y:Float):FlxSpriteExt
		return add_x(X).add_y(Y);

	public inline function add_x(X:Float):FlxSpriteExt
	{
		x = x + X;
		return this;
	}

	public inline function add_y(Y:Float):FlxSpriteExt
	{
		y = y + Y;
		return this;
	}

	public function set_offset(?X:Float = 0, ?Y:Float = 0)
		offset.set(X, Y);

	function set_on(val:Bool):Bool
		return on = val;

	function get_off():Bool
		return !on;

	function set_off(val:Bool):Bool
		throw "don't set off directly >:(";

	var tasc_animation_name:String = "";
	var tasc_animation_loose:Bool = false;

	/**Do a tasc anim, can be overwritten for complex actors like the Player*/
	public function tasc_anim(new_anim:String, ?loose:Bool = false)
	{
		#if tasc_debug
		trace('///////DOING A TASC ANIMATION: "${new_anim}"///////');
		#end
		tasc_animation_name = new_anim;
		tasc_animation_loose = loose;
		anim(new_anim);
	}

	public function clear_tasc_anim()
	{
		tasc_animation_name = "";
		tasc_animation_loose = false;
	}

	/**Do a tasc state, can be overwritten for complex actors like Bullwhip Bones*/
	public function tasc_state(new_state:String)
	{
		#if tasc_debug
		trace('///////SWITCHING STATE THROUGH TASC: "${new_state}"///////');
		#end
		sstate(new_state);
	}

	/**
	 * Level collide callback, must be called in an actual FlxG.overlap or FlxG.collide function
	 */
	public function post_collide_level(level:FlxTilemap) {}

	public function post_collide_actor(actor:FlxSpriteExt) {}

	public function get_type_print():String
		return '\'${iid}\' ($type)';

	public function sound(name:String, ?vol_multiplier:Float = 1):FlxSound
	{
		#if trace_sound
		trace("FlxSpriteExt sound " + name);
		#end
		return SoundPlayer.sound(name, vol_multiplier);
	}

	public function animation_callback(animation_name:String, frame_number:Int, frame_index:Int)
	{
		is_on_new_frame = true;
		animation_sound_callback(animation_name, frame_index);
	}

	var sound_frame_animations:Map<String, Map<Int, AnimationSoundFrame>> = new Map<String, Map<Int, AnimationSoundFrame>>();

	function animation_sound_callback(animation_name:String, frame_index:Int)
	{
		if (!new_frame_check(frame_index))
			return;

		if (sound_frame_animations.get(animation_name) != null && sound_frame_animations.get(animation_name).get(frame_index) != null)
		{
			var sound_frame:AnimationSoundFrame = sound_frame_animations.get(animation_name).get(frame_index);
			sound(sound_frame.sound_name);
			sound_frame.plays++;
			#if trace_sounds
			trace('ANIMATION SOUND ${sound_frame.sound_name} PLAYED ON $animation_name [frame: $frame_index]');
			#end
			if (sound_frame.loops != null)
			{
				sound_frame.loops--;
				if (sound_frame.loops <= 0)
					sound_frame_animations.get(animation_name).remove(frame_index);
			}
		}
	}

	public function add_sound_frame(sound_name:String, frame_index:Int, ?animation_name:String = "all", ?loops:Int = -1)
	{
		#if sound_test
		trace(animation_name, frame_index, sound_name);
		#end

		if (animation_name == "all")
		{
			for (a_name in animation.getNameList())
				if (animation.getByName(a_name).frames.indexOf(frame_index) > -1)
					add_sound_frame(sound_name, frame_index, a_name, loops);
			return;
		}

		if (sound_frame_animations.get(animation_name) == null)
			sound_frame_animations.set(animation_name, new Map<Int, AnimationSoundFrame>());

		sound_frame_animations.get(animation_name).set(frame_index, {sound_name: sound_name, plays: 0, loops: loops == -1 ? null : loops});
	}

	public function get_anim_linked_emote():String
		return null;

	public function variable_frame_check(variable_name:String, only_on_new_frame:Bool = false)
		return animSet.variable_frame_check(animation.frameIndex, variable_name)
			&& (only_on_new_frame ? new_frame_check(animation.frameIndex) : true);

	function get_bottom_y():Float
		return y + height;

	function get_top_y():Float
		return y;

	function get_left_x():Float
		return x;

	function get_right_x():Float
		return x + width;
}

typedef TrackSpriteOptions =
{
	/**Use the offset from the tracking sprite?*/
	var ?track_offset:Bool;

	/**Reverse the flip (useful for some enemies)*/
	var ?reverse_flip:Bool;

}

typedef AnimationSoundFrame =
{
	sound_name:String,
	plays:Int,
	?loops:Int
}
