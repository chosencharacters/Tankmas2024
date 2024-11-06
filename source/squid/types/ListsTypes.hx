package squid.types;

/**
 * This is default animation sets associated with a particular spritesheet
 */
typedef AnimSetData =
{
	var ?image:String;
	var ?animations:Map<String, AnimDef>;
	var ?variable_frames:Map<String, Array<Int>>;
	var ?dimensions:FlxPoint;
	var ?offset:FlxPoint;
	var ?offset_left:FlxPoint;
	var ?offset_right:FlxPoint;
	var ?flipOffset:FlxPoint;
	var ?hitbox:FlxPoint;
	var ?maxFrame:Int;
	var ?reverse_mod:Bool;
	var ?default_bg:String;
	var ?main_color:Int;
	var ?sub_color:Int;
}

/**
 * This an animation definition to be used with AnimSet 
 */
typedef AnimDef =
{
	var name:String;
	var frames:Array<Int>;
	var frames_string:String;
	var fps:Int;
	var looping:Bool;
	var ?linked:String;
	var ?emote:String;
}

/**
 * A dialogue text from an NPC
 */
typedef DialogueText =
{
	var text:UnicodeString;
	var animation:String;
	var source:FlxSpriteExt;
	var id:Int;
	var cutscene:String;
	var portrait:String;
	var ?emote:String;
	var ?facing:String;
	var ?if_flag:String;
}

/**
 * Saved info about a font
 */
typedef FontSave =
{
	var name:String;
	var size:Int;
}

typedef PointDef =
{
	x:Float,
	y:Float
}

@:forward
abstract AnimSet(AnimSetData) from AnimSetData
{
	public function new(image_name:String)
	{
		var set:AnimSetData = {
			image: image_name,
			animations: [],
			variable_frames: [],
			dimensions: new FlxPoint(),
			offset: new FlxPoint(-999, -999), // offset is now redundent
			offset_right: null,
			offset_left: null,
			flipOffset: new FlxPoint(-999, -999),
			hitbox: new FlxPoint(),
			maxFrame: 0,
			reverse_mod: false,
			default_bg: "",
		};

		this = set;
	}

	public function variable_frame_check(current_frame:Int, variable_frame_name:String)
	{
		if (this.variable_frames.get(variable_frame_name) == null)
			return false;
		return this.variable_frames.get(variable_frame_name).indexOf(current_frame) > -1;
	}
}

/**
 * An key in an action with whether it's charged/hold
 */
typedef AttackInputDef =
{
	var key:String;
	var key_release:String;
	var charge_time:Int;
}

@:structInit
class AttackInputResult
{
	public var valid_input:Bool;
	public var all_results:Array<Bool>;

	public function new(valid_input:Bool, all_results:Array<Bool>):Void
	{
		this.valid_input = valid_input;
		this.all_results = all_results;
	}
}

@:forward
abstract AttackInput(AttackInputDef) from AttackInputDef
{
	public function new(key:String, key_release:String, charge_time:Int = 0)
	{
		var def:AttackInputDef = {
			key: key,
			key_release: key_release,
			charge_time: charge_time
		};
		this = def;
	}

	public function valid_input(sprite:FlxSpriteExt, buffer:ButtonBuffer, ?key_substitution:String):Bool
	{
		var flipX:Bool = sprite.flipX;
		var team:Int = buffer.team;
		var key:String = key_substitution == null ? this.key : key_substitution;

		var opposite:Bool = key.charAt(0) == "!";

		if (opposite)
			return !valid_input(sprite, buffer, key.substring(1, key.length - 1));

		switch (key)
		{
			case "down":
				return Ctrl.down[team];
			case "up":
				return Ctrl.up[team];
			case "forwards":
				return (Ctrl.right[team] && !flipX || Ctrl.left[team] && flipX);
			case "backwards":
				return (Ctrl.left[team] && !flipX || Ctrl.right[team] && flipX);
			case "sideways":
				return (Ctrl.right[team] || Ctrl.left[team]);
		}

		// trace('What is the value of \'${key}\' in Map? The value is \'${buffer.get(key)}\'', buffer);

		// this handles charge actions and non charge actions
		return buffer.get_int(key) >= this.charge_time && (this.key_release == "" || buffer.exists(this.key_release));
	}

	function toString():String
		return this.key;

	public static function valid_inputs(inputs:Array<AttackInput>, sprite:FlxSpriteExt, buffer:ButtonBuffer):AttackInputResult
	{
		var all_results:Array<Bool> = [for (i in 0...inputs.length) false];

		for (n in 0...inputs.length)
			all_results[n] = inputs[n].valid_input(sprite, buffer);

		for (i in 0...all_results.length)
			if (!all_results[i])
				return new AttackInputResult(false, all_results);

		return new AttackInputResult(true, all_results);
	}
}
