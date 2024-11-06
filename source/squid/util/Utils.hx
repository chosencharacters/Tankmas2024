package squid.util;

import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.animation.FlxAnimation;
import flixel.effects.particles.FlxEmitter;
import flixel.effects.particles.FlxParticle;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxFilterFrames;
import flixel.graphics.frames.FlxTileFrames;
import flixel.group.FlxGroup;
import flixel.math.FlxPoint;
import flixel.math.FlxRandom;
import flixel.math.FlxRect;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.text.FlxText;
import flixel.tile.FlxTilemap;
import flixel.tweens.FlxEase;
import flixel.util.FlxAxes;
import flixel.util.FlxColor;
import haxe.ds.IntMap;
import openfl.Assets;
import openfl.display.PNGEncoderOptions;
import openfl.display.Tile;
import openfl.events.Event;
import openfl.geom.ColorTransform;
import openfl.net.SharedObject;
import openfl.net.URLLoader;
import openfl.net.URLRequest;

using Math;
using Utils.Inflect;

/**
 * Utility functions
 * @author Squidly
 */
class Utils
{
	public function new() {}

	public static function recolor(o:FlxSprite, p:Int, colorToReplace:Int = FlxColor.WHITE)
		if (colorToReplace != 0xff999999)
			o.replaceColor(colorToReplace, getColor(p));
		else
			o.replaceColor(colorToReplace, getColor2(p));

	public static function getColor(p:Int):Int
	{
		var color:Int = 0;
		switch (p)
		{
			case -4:
				color = FlxColor.CYAN;
			case -3:
				color = FlxColor.GRAY;
			case -2:
				color = FlxColor.WHITE;
			case -1:
				color = FlxColor.RED;
			case 1:
				color = FlxColor.ORANGE;
			case 2:
				color = 0xff3299FF;
			case 3:
				color = FlxColor.YELLOW;
			case 4:
				color = FlxColor.GREEN;
		}
		return color;
	}

	public static function getColor2(p:Int):Int
	{
		var color:Int = 0;
		switch (p)
		{
			case -4:
				color = FlxColor.CYAN;
			case -3:
				color = FlxColor.GRAY;
			case -2:
				color = FlxColor.WHITE;
			case -1:
				color = FlxColor.RED;
			case 1:
				color = 0xffFF6600;
			case 2:
				color = 0xff3299FF;
			case 3:
				color = FlxColor.YELLOW;
			case 4:
				color = FlxColor.GREEN;
		}
		return color;
	}

	/*returns a multiplier based on direction*/
	public static function dirMod(a:FlxSprite, b:FlxSprite):Int
		return a.getMidpoint().x < b.getMidpoint().x ? -1 : 1;

	/*returns a multiplier based on whether v is flipped*/
	public static function flipMod(sprite:FlxSprite):Int
		return sprite.flipX ? -1 : 1;

	public static function turnMod(s:FlxSprite, v:Float, mult:Float = 2):Int
	{
		if (s.velocity.x < 0 && v < 0 || s.velocity.x > 0 && v > 0)
			return 1;
		return Math.floor(mult);
	}

	/**
	 * Short hand for overlaps and then pixelPerfectOverlaps which hopefully makes things more efficient
	 * @param a 
	 * @param b 
	 * @param alpha_tolerance base alpha tolerance for consistency, set REALLY low
	 */
	public static inline function pixel_overlaps(a:FlxSprite, b:FlxSprite, alpha_tolerance:Int = 25):Bool
		return a != null && b != null && a.overlaps(b) && FlxG.pixelPerfectOverlap(a, b, alpha_tolerance);

	/**return total distance between two points**/
	public static inline function getDistance(P1:FlxPoint, P2:FlxPoint):Float // distance two points
	{
		var XX:Float = P2.x - P1.x;
		var YY:Float = P2.y - P1.y;
		return Math.sqrt(XX * XX + YY * YY);
	}

	/**return x distance between two points**/
	public static inline function getDistanceX(P1:FlxPoint, P2:FlxPoint):Float // x distance between two points
	{
		var XX:Float = P2.x - P1.x;
		return Math.sqrt(XX * XX);
	}

	/**return y distance between two points**/
	public static inline function getDistanceY(P1:FlxPoint, P2:FlxPoint):Float // x distance between two points
	{
		var XX:Float = P2.y - P1.y;
		return Math.sqrt(XX * XX);
	}

	/**distance two points using floats**/
	public static inline function getDistanceNoPoint(P1X:Float, P1Y:Float, P2X:Float, P2Y:Float):Float
	{
		var XX:Float = P2X - P1X;
		var YY:Float = P2Y - P1Y;
		return Math.sqrt(XX * XX + YY * YY);
	}

	/**does quicksort**/
	public static function quicksort(arr:Array<Int>, lo:Int, hi:Int):Array<Int>
	{
		var i:Int = lo;
		var j:Int = hi;
		var buf = arr;
		var p = buf[(lo + hi) >> 1];
		while (i <= j)
		{
			while (arr[i] > p)
				i++;
			while (arr[j] < p)
				j--;
			if (i <= j)
			{
				var t = buf[i];
				buf[i++] = buf[j];
				buf[j--] = t;
			}
		}
		if (lo < j)
			quicksort(arr, lo, j);
		if (i < hi)
			quicksort(arr, i, hi);
		return arr;
	}

	/**converts time in frames to minute, second, and frames (not nano seconds)**/
	public static inline function toTimer(time:Int):String
	{
		var minute:Int = Math.floor(time / (60 * 60));
		var second:Int = Math.floor((time / 60) % 60);
		var nano:Int = Math.floor(time % 60 / 60 * 100);
		var minutes:String = minute + "";
		var seconds:String = second + "";
		var nanos:String = nano + "";
		if (minute < 10)
			minutes = "0" + minutes;
		if (second < 10)
			seconds = "0" + seconds;
		if (nano < 10)
			nanos = "0" + nanos;
		return minutes + ":" + seconds + ":" + nanos;
	}

	// Deep copy of anything using reflection
	public static function copy<T>(v:T):T
	{
		if (!Reflect.isObject(v))
		{ // simple type
			return v;
		}
		else if (Std.isOfType(v, String))
		{ // string
			return v;
		}
		else if (Std.isOfType(v, Array))
		{ // array
			var result = Type.createInstance(Type.getClass(v), []);
			untyped
			{
				for (ii in 0...v.length)
				{
					result.push(copy(v[ii]));
				}
			}
			return result;
		}
		else if (Std.isOfType(v, List))
		{ // list
			// List would be copied just fine without this special case, but I want to avoid going recursive
			var result = Type.createInstance(Type.getClass(v), []);
			untyped
			{
				var iter:Iterator<Dynamic> = v.iterator();
				for (ii in iter)
				{
					result.add(ii);
				}
			}
			return result;
		}
		else if (Type.getClass(v) == null)
		{ // anonymous object
			var obj:Dynamic = {};
			for (ff in Reflect.fields(v))
			{
				Reflect.setField(obj, ff, copy(Reflect.field(v, ff)));
			}
			return obj;
		}
		else
		{ // class
			var obj = Type.createEmptyInstance(Type.getClass(v));
			for (ff in Reflect.fields(v))
			{
				Reflect.setField(obj, ff, copy(Reflect.field(v, ff)));
			}
			return obj;
		}
		return null;
	}

	public static function scrollMSG(txt:String)
		var e:squid.ui.ScrollingText = new squid.ui.ScrollingText(txt);

	public static function toIndex(x:Int, y:Int, w:Int = 16):Int
		return y * w + x;

	public static function shake(preset:String = "damage", force_override:Bool = false)
	{
		var intensity:Float = 0;
		var time:Float = 0;
		var force:Bool = true;

		switch (preset)
		{
			case "damage":
				intensity = 0.025;
				time = 0.1;
			case "damagelight" | "light":
				intensity = 0.01;
				time = 0.05;
				force = false;
			case "groundpound":
				intensity = 0.03;
				time = 0.2;
			case "light-long":
				intensity = 0.01;
				time = 0.2;
			case "rumble":
				intensity = 0.0025;
				time = 0.5;
			case "train-rumble":
				intensity = 0.0025;
				time = 0.15;
			case "explosion":
				intensity = 0.025;
				time = 0.225;
			case "lightest":
				intensity = 0.0025;
				time = 0.05;
				force = false;
			case "lighter":
				intensity = 0.005;
				time = 0.05;
				force = false;
			case "groundpound-2":
				FlxG.camera.shake(0.05, 0.3, true, FlxAxes.Y);
			case "airship-action":
				FlxG.camera.shake(0.01, 0.75, true);
			case "ruins-collapse":
				FlxG.camera.shake(0.0075, 0.5, true);
			case "ruins-collapse-long":
				FlxG.camera.shake(0.0075, 2, true);
			case "ruins-collapse-hard":
				FlxG.camera.shake(0.01, 0.5, true);
			case "ruins-collapse-really-hard":
				FlxG.camera.shake(0.02, 0.5, true);
		}

		if (intensity != 0 && time != 0)
			FlxG.camera.shake(intensity, time, null, force_override ? force_override : force);
	}

	public static inline function simpleHitbox(S:FlxSprite, W:Float = -1, H:Float = -1, marginX:Int = 1, marginY:Int = 1):FlxSprite
	{
		if (W == -1)
			W = S.width - 2;
		if (H == -1)
			H = S.height - 2;
		S.setSize(W, H);

		S.offset.x = marginX;
		S.offset.y = marginY;

		return S;
	}

	/**
	 * Converts an integer to a string and adds commas in the right place.
	 * 
	 * Note: Only works for english style formatting, for now.
	 * 
	 * @param num  An integer.
	 * @return Formatted number string
	 */
	public static function formatInt(num:Int):String
	{
		// TODO: Format for other languages via `Main.lang`
		var str = Std.string(num);
		var commas = Std.int((str.length - 1) / 3);
		var index = str.length % 3;
		while (commas > 0)
		{
			str = str.substr(0, index) + "," + str.substr(index);
			index += 4;
			commas--;
		}
		return str;
	}

	/*
	 * Animation int array created using string of comma seperated frames
	 * xTy = from x to y, takes r as optional form xTyRz to repeat z times
	 * xHy = hold x, y times
	 * ex: "0t2r2, 3h2" returns [0, 1, 2, 0, 1, 2, 3, 3, 3]
	 */
	public static inline function animFromString(animString:String):Array<Int>
	{
		var frames:Array<Int> = [];
		var framesGroup:Array<String> = StringTools.replace(animString, " ", "").toLowerCase().split(",");
		if (framesGroup.length <= 0)
			framesGroup = [animString];
		for (f in framesGroup)
		{
			// hold/repeat frames
			if (f.indexOf("h") > -1)
			{
				var split:Array<String> = f.split("h"); // 0 = frame, 1 = hold frame multiplier so 1h5 is 1 hold 5 i.e. repeat 5 times
				frames = frames.concat(Utils.arrayR([Std.parseInt(split[0])], Std.parseInt(split[1])));
			}
			// from x to y frames
			else if (f.indexOf("t") > -1)
			{
				var repeats:Int = 1;
				if (f.indexOf("r") != -1)
					repeats = Std.parseInt(f.substring(f.indexOf("r") + 1, f.length)); // add rInt at the end to repeat Int times
				f = StringTools.replace(f, "r", "t");
				for (i in 0...repeats)
				{
					var split:Array<String> = f.split("t"); // 0 = first frame, 1 = last frame so 1t5 is 1 to 5
					frames = frames.concat(Utils.array(Std.parseInt(split[0]), Std.parseInt(split[1])));
				}
			}
			else
			{
				frames.push(Std.parseInt(f));
			}
		}

		return frames;
	}

	public static function ms_to_frames_per_second(input:String):Int
		return input.indexOf("ms") > -1 ? Math.round(1000 / Std.parseInt(input.split("ms")[0])) : Std.parseInt(input);

	/*
	 * Alias for animFromString
	 */
	public static function anim(animString:String):Array<Int>
		return animFromString(animString);

	/*
	 * Creates FlxSprite, attaches animation, and plays it automatically if autoPlay == true
	 */
	public static function animSprite(?X:Int = 0, Y:Int = 0, graphic:FlxGraphicAsset, animString:String, fps:Int, looped:Bool = true,
			autoPlay:Bool = true):FlxSprite
	{
		var frames:Array<Int> = anim(animString);
		var maxFrame:Int = 0;

		for (f in frames)
		{
			if (f >= maxFrame)
				maxFrame = f + 1;
		}

		var sprite:FlxSprite = new FlxSprite(X, Y);
		sprite.loadGraphic(graphic);
		sprite.loadGraphic(graphic, true, Math.floor(sprite.width / maxFrame), Math.floor(sprite.height));
		sprite.animation.add("play", frames, fps, looped);

		if (autoPlay)
			sprite.animation.play("play");

		return sprite;
	}

	public static function array(start:Int, end:Int):Array<Int>
	{
		var a:Array<Int> = [];

		var array_start:Int = start < end ? start : end;
		var array_end:Int = start < end ? end : start;

		for (i in array_start...(array_end + 1))
			a.push(i);

		if (start > end)
			a.reverse();
		return a;
	}

	/*
	 * Creates repeating array that duplicates 'toRepeat', 'repeat' times
	 */
	public static function arrayR(toRepeat:Array<Int>, repeats:Int):Array<Int>
	{
		var a:Array<Int> = [];
		for (i in 0...repeats)
			for (c in toRepeat)
				a.push(c);
		return a;
	}

	public static function traceMembers(members:Array<Dynamic>, t:Int = 0):Int
	{
		for (s in members)
		{
			if (s != null && s.active)
			{
				var nname:String = Type.getClassName(Type.getClass(s));
				if (nname == "flixel.group.FlxTypedGroup")
				{
					t = traceMembers(cast(s, FlxTypedGroup<Dynamic>).members, t);
				}
				else
				{
					trace('$t - $nname - $s');
					t++;
				}
			}
		}
		return t;
	}

	public static inline function file_from_path(raw_path:String, ext:String = ""):String
		return raw_path.split("/").last().replace(ext, "") + ext;

	public static inline function file_from_path_with_extension(raw_path:String):String
		return raw_path.split("/").last();

	public static inline function file_from_path_without_extension(raw_path:String):String
		return raw_path.split("/").last().remove_extension();

	public static inline function remove_extension(file_name:String):String
		return file_name.substring(0, file_name.lastIndexOf("."));

	public static function lvlPoint(point:FlxPoint, lvl:FlxTilemap, div:Int = 16):FlxPoint
	{
		return FlxPoint.weak(Math.floor((point.x - lvl.x) / div), Math.floor((point.y - lvl.y) / div));
	}

	public static function file_to_xml(path:String):Xml
		return Assets.getText(path).string_to_xml();

	/**
	 * Cleans and formats string to xml
	 * @param string 
	 * @return Xml
	 */
	public static inline function string_to_xml(string:String):Xml
	{
		string = StringTools.replace(string, "/n", "&#xA;");
		string = StringTools.replace(string, "<&#xA;", "</n");
		return Xml.parse(string);
	}

	public static function load_file_string(file_name:String):String
		return Assets.getText(Paths.get(file_name));

	/**Mask for Std.parseInt that also handles hex*/
	inline public static function to_int_hex_safe(string:String):Int
		return string.is_hex() ? '0x$string'.to_int() : string.to_int();

	/**Mask for Std.parseInt*/
	inline public static function to_int(string:String):Int
		return Std.parseInt(string);

	/**Mask for Std.parseInt*/
	inline public static function to_float(string:String):Float
		return Std.parseFloat(string);

	/**
	 * Checks if string is hex
	 */
	public static function is_hex(string:String):Bool
	{
		var regexp:EReg = ~/(0[xX])?[0-9a-fA-F]+/;
		return regexp.match(string);
	}

	public static function newRan(seed:Int = -999):FlxRandom
	{
		if (seed == -999)
			return new FlxRandom();
		return new FlxRandom(seed);
	}

	/***moves anything! Put it in Update() code. Remember to turn on Debug to see trace outputs!***/
	public static function moveAdjust(target:FlxSpriteExt, name:String = "", addString:String = "")
	{
		if (target.moveAdjustOrg == null)
			target.moveAdjustOrg = new FlxPoint(target.x, target.y);

		if (FlxG.keys.anyJustPressed(["LEFT"]))
			target.x--;

		if (FlxG.keys.anyJustPressed(["RIGHT"]))
			target.x++;

		if (FlxG.keys.anyJustPressed(["UP"]))
			target.y--;

		if (FlxG.keys.anyJustPressed(["DOWN"]))
			target.y++;

		if (FlxG.keys.anyJustPressed(["LEFT", "RIGHT", "UP", "DOWN"]))
		{
			if (addString != "")
				addString += "\n";
			trace('${addString}${name}}\nsetPosition(${target.x}, ${target.y});\ndiff(${target.moveAdjustOrg.x - target.x}, ${target.moveAdjustOrg.y - target.y})');
		}
	}

	/***gets the line at the maximum of the flxpoint***/
	public static function getMaxLine(p1:FlxPoint, p2:FlxPoint, rect:FlxRect):FlxPoint
	{
		if (p1.x == p2.x)
			p1.x = p1.x + .1; // simple div 0 chance remover
		if (p1.y == p2.y)
			p1.y = p1.y + .1; // simple div 0 chance remover

		var slope:Float = (p2.y - p1.y) / (p2.x - p1.x);
		var yIntercept:Float = p1.y - p1.x * slope;
		var targetY:Float = 0;

		if (p1.y < p2.y)
			targetY = rect.height;
		var xx:Float = (-yIntercept + targetY) / slope;

		// debug(p1, p2, slope, yIntercept, rect.y, rect.y, xx);
		return FlxPoint.weak(xx, targetY);
	}

	/**
		Finds an object of type, make sure to have the package in the string
		@return the object found, if any
	**/
	public static function findObjectInGroup<T:FlxObject>(type:String, group:FlxTypedGroup<T>):T
	{
		// debug(group.length);
		for (sprite in group)
		{
			if (Type.getClassName(Type.getClass(sprite)) == type)
				return sprite;
		}
		return null;
	}

	/**
		Finds an object of type, make sure to have the package in the string
		@return the object found, if any
	**/
	public static function findObjectsInGroup<T:FlxObject>(type:String, group:FlxTypedGroup<T>):Array<T>
	{
		var list:Array<T> = [];
		for (sprite in group)
		{
			// debug(Type.getClassName(Type.getClass(sprite)));
			if (Type.getClassName(Type.getClass(sprite)) == type)
			{
				list.push(sprite);
			}
		}
		return list;
	}

	public static inline function formatText(text:FlxText, ?alignment:String = "left", ?color:Int = FlxColor.WHITE, ?outline:Bool = false):FlxText
	{
		if (outline)
		{
			text.setFormat(Fonts.DIALOGUE.name, Fonts.DIALOGUE.size, color, alignment, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		}
		else
		{
			text.setFormat(Fonts.DIALOGUE.name, Fonts.DIALOGUE.size, color, alignment);
		}
		#if !flash
		text.x -= 1;
		text.y -= 1;
		#end
		return text;
	}

	public static function swapItems(array, a, b)
	{
		array[a] = array.splice(b, 1)[0];
		return array;
	}

	public static inline function last<T>(a:Array<T>):T
		return a[a.length - 1];

	public static inline function concat_one(arr:Array<String>, add):Array<String>
		return arr.concat([add]);

	public static inline function mystery_text(text:String, mystery_mask_char:String = "?")
	{
		for (i in 0...text.length)
		{
			var char:String = text.charAt(i);
			if (char != " " && char != "-" && char != mystery_mask_char)
				text = text.replace(char, mystery_mask_char);
		}
		return text;
	}

	public static inline function parseIntDefault(input:String, default_val:Int):Int
	{
		var result:Int = default_val;

		if (input != null && input.length > 0)
			result = Std.parseInt(input);

		return result;
	}

	#if black_scan
	public static function scanForOffBlackPixels(threshold:FlxColor = 0xff202020)
	{
		// threshhold = 0xff010101;

		final tred = threshold.red;
		final tgreen = threshold.green;
		final tblue = threshold.blue;

		#if sys
		final encoderOptions = new PNGEncoderOptions();
		#end

		trace('~~~~ Checking all Images for Off-Black pixels with threshold color $threshold.. This may take a moment... ~~~~');

		final images = Assets.list(IMAGE);
		for (image in images)
		{
			if (image.indexOf("assets/") <= -1)
				continue;

			trace('Checking "${image}" (${images.indexOf(image)}/${images.length})...');

			var png = Assets.getBitmapData(image, false);
			if (png != null)
			{
				var count = 0;
				var clone = png.clone();
				for (x in 0...Std.int(clone.rect.width))
				{
					for (y in 0...Std.int(clone.rect.height))
					{
						final pixel:FlxColor = clone.getPixel32(x, y);
						final pred = pixel.red;
						final pgreen = pixel.green;
						final pblue = pixel.blue;
						if ((pred < tred && pgreen < tgreen && pblue < tblue) && (pred > 0 || pgreen > 0 || pblue > 0))
						{
							clone.setPixel32(x, y, 0xff000000);
							count++;
						}
					}
				}
				if (count > 0)
				{
					trace('Image "${image}" has $count Off-Black Pixels');
					#if sys
					var assets_path:String = "../../../";
					var path = '${assets_path}/${image}';

					trace('Saving fixed version to "$path"');

					sys.io.File.saveBytes(path, clone.encode(clone.rect, encoderOptions));
					#end
				}

				clone.dispose();
			}
		}

		trace('~~~~ All Images scanned ~~~~');
	}
	#end

	/**
	 * Gets a random key for a given map that's not been assigned yet
	 * @param map the map to find a new key for
	 * @param random optional flxRandom input
	 * @return the new key
	 */
	public static function getNewKey<T>(map:IntMap<T>, ?random:FlxRandom):Int
	{
		var ran:FlxRandom = random != null ? random : new FlxRandom();
		var key:Int = ran.int();
		while (map.exists(key))
			key = ran.int();
		return key;
	}

	public static function list_sprites_in_group(group:FlxTypedGroup<Dynamic>)
	{
		for (member in group.members)
			try
			{
				var alpha:Float = cast(member, FlxSprite).alpha;
				if (alpha > 0 && alpha < 1)
				{
					trace(alpha, StringTools.hex(cast(member, FlxSprite).color));
					if (alpha < 0.6 && alpha > 0.4)
					{
						trace(cast(member, FlxSpriteExt).type);

						throw "Ladies and gentleman, we got em'";
					}
				}
			}
			catch (e)
			{
				try
				{
					list_sprites_in_group(cast(member, FlxTypedGroup<Dynamic>));
				}
				catch (e)
				{
					// trace(Type.getSuperClass(Type.getClass(member)));
				}
			}
	}

	public static function tweenCamOffset(?x:Float, ?y:Float, duration:Float = 2.0, ?ease:EaseFunction)
	{
		var offset = FlxG.camera.targetOffset;
		if (x == null)
			x = offset.x;

		if (y == null)
			y = offset.y;

		if (ease == null)
			ease = FlxEase.cubeInOut;

		FlxTween.tween(offset, {x: x, y: y}, duration, {ease: ease});
	}

	static var kebab_cache:Map<String, String> = new Map<String, String>();

	public static inline function kebab(string:String):String
	{
		if (kebab_cache.get(string) != null)
			return kebab_cache.get(string);

		var post_string:String = string;
		post_string = Inflect.inflect(post_string, InflectCase.SnakeCase, InflectCase.KebabCase);
		post_string = Inflect.inflect(post_string, InflectCase.CamelCase, InflectCase.KebabCase);

		kebab_cache.set(string, post_string);
		return post_string;
	}

	public static inline function flip_towards(source:FlxSpriteExt, actor_to_flip_towards:FlxSpriteExt)
		source.flipX = Utils.dirMod(source, actor_to_flip_towards) < 0;

	/**
	 * Returns all entities in a FlxTypedGroup, usually used for locating all listeners 
	 * @param group TypedGroup to check in
	 * @param entity_ids group of entity ids
	 * @return Similarly type *Array* with iids
	 */
	inline function get_listening_entities<T:FlxSpriteExt>(group:FlxTypedGroup<T>, entity_ids:Array<String>):Array<T>
		return group.members.filter(entity -> entity_ids.contains(entity.iid));

	public static function get_listening_entities_static<T:FlxSpriteExt>(group:FlxTypedGroup<T>, entity_ids:Array<String>):Array<T>
		return group.members.filter(entity -> entity_ids.contains(entity.iid));

	public static function string_to_point(input:String):FlxPoint
	{
		var split:Array<String> = input.split(",");
		if (split.length == 1)
			return FlxPoint.get(Std.parseFloat(split[0]), 0);
		return FlxPoint.get(Std.parseFloat(split[0]), Std.parseFloat(split[1]));
	}

	/**
	 * Credits to zsolardev
	 * @param default_frames Base frame count
	 * @param minimum_frames Minimum frame count
	 * @param dist_from_target Dist from target
	 * @param max_dist Over this value, and result will be default_frames
	 * @return Int
	 */
	public static function time_adjusted_frames(default_frames:Int, minimum_frames:Int = 10, dist_from_target:Float, max_dist:Float):Int
	{
		var max_time:Int = default_frames.frames_to_ms();
		var minimum_time:Int = minimum_frames.frames_to_ms();

		var time:Int = max_time;

		if (minimum_time > max_time)
			minimum_time = max_time;

		// Is the player in range of the enemy?
		if (dist_from_target < max_dist)
		{
			time = Std.int((time / max_dist) * (max_time - minimum_time) + minimum_time);
			// linearly scaling frames into a 50-10 range
		}

		trace(max_time, minimum_time, time, (time / max_dist), (max_time - minimum_time), (time / max_dist) * (max_time - minimum_time));

		return time;
	}

	public static inline function ms_to_frames(ms:Float):Int
		return (ms / 16.6666666667).floor();

	public static inline function frames_to_ms(frames:Float):Int
		return (frames * 16.6666666667).floor();
}

// Pulled from moon lib

/**
 * https://github.com/auraphp/Aura.Framework/blob/develop/src/Aura/Framework/Inflect.php
 * @author Munir Hussin
 */
class Inflect
{
	// private static var regex:EReg = ~/([a-z])([A-Z])/g;
	#if js
	private static var regex:EReg = ~/([A-Z][^A-Z]+)/g;
	#else
	private static var regex:EReg = ~/((?<=[a-z])[A-Z]|[A-Z](?=[a-z]))/g;
	#end

	// js doesnt have lookbehind

	/*==================================================
			Operations on Entire String
		================================================== */
	/**
	 * Transform a string to upper case.
	 * "HeLlO wOrLd" ==> "HELLO WORLD"
	 */
	public static inline function upper(s:String):String
	{
		return s.toUpperCase();
	}

	/**
	 * Transform a string to lower case.
	 * "HeLlO wOrLd" ==> "hello world"
	 */
	public static inline function lower(s:String):String
	{
		return s.toLowerCase();
	}

	/**
	 * Transform the first character to upper case.
	 * "heLlO wOrLd" ==> "HeLlO wOrLd"
	 */
	public static inline function ucfirst(s:String):String
	{
		return s.substr(0, 1).toUpperCase() + s.substr(1);
	}

	/**
	 * Transform the first character to lower case
	 * "HeLlO wOrLd" ==> "heLlO wOrLd"
	 */
	public static inline function lcfirst(s:String):String
	{
		return s.substr(0, 1).toLowerCase() + s.substr(1);
	}

	/**
	 * Transform the string to lower case and change
	 * the first character to upper case
	 * "HeLlO wOrLd" ==> "Hello world"
	 */
	public static inline function proper(s:String):String
	{
		return s.lower().ucfirst();
	}

	/*==================================================
			Operations on Each Word
		================================================== */
	/**
	 * Transform the first character of each word to upper case.
	 * "HeLlO wOrLd" ==> "HeLlO WOrLd"
	 */
	public static inline function ucwords(s:String):String
	{
		return s.split(" ").map(ucfirst).join(" ");
	}

	/**
	 * Transform the first character of each word to lower case.
	 * "HeLlO wOrLd" ==> "heLlO wOrLd"
	 */
	public static inline function lcwords(s:String):String
	{
		return s.split(" ").map(lcfirst).join(" ");
	}

	/**
	 * Transform each word to proper case.
	 * "HeLlO wOrLd" ==> "Hello World"
	 */
	public static inline function title(s:String):String
	{
		return s.split(" ").map(proper).join(" ");
	}

	/*==================================================
			Service Methods
		================================================== */
	/**
	 * Splits a joined string into space seperated words.
	 * "TodayILiveInTheUSAWithSimon" ==> [Today, I, Live, In, The, USA, With, Simon]
	 * "USAToday" ==> [USA, Today]
	 * "IAmSOOOBored" ==> [I, Am, SOOO, Bored]
	 */
	public static inline function decamel(s:String):Array<String>
	{
		#if js
		return regex.split(s).filter(function(x:String) return x.length > 0);
		#else
		return regex.replace(s, " $1").trim().split(" ");
		#end
	}

	public static function convert(s:String, currSeperator:String, newSeperator:String, ?wordFn:String->String, ?phraseFn:String->String):String
	{
		var words:Array<String> = currSeperator == "" ? decamel(s) : s.split(currSeperator);

		if (wordFn != null)
			words = words.map(wordFn);

		return phraseFn == null ? words.join(newSeperator) : phraseFn(words.join(newSeperator));
	}

	public static inline function seperator(inflectCase:InflectCase):String
	{
		return switch (inflectCase)
		{
			case LowerCase | UpperCase | TitleCase:
				" ";

			case PascalCase | CamelCase:
				"";

			case KebabCase | ScreamingKebabCase | TrainCase:
				"-";

			case SnakeCase | ScreamingSnakeCase | OxfordCase:
				"_";
		}
	}

	/**
	 * lower case, UPPER CASE, Title Case
	 * PascalCase, camelCase
	 * kebab-case, SCREAMING-KEBAB-CASE, Train-Case
	 * snake_case, SCREAMING_SNAKE_CASE, Oxford_Case
	 */
	public static function inflect(s:String, currCase:InflectCase, newCase:InflectCase):String
	{
		var currSeperator:String = seperator(currCase);
		var newSeperator:String = seperator(newCase);

		return switch (newCase)
		{
			// quickBrownFox
			case CamelCase:
				s.convert(currSeperator, newSeperator, proper, lcfirst);

			// quick brown fox, quick-brown-fox, quick_brown_fox
			case LowerCase | KebabCase | SnakeCase:
				s.convert(currSeperator, newSeperator, null, lower);

			// QUICK BROWN FOX, QUICK-BROWN-FOX, QUICK_BROWN_FOX
			case UpperCase, ScreamingKebabCase | ScreamingSnakeCase:
				s.convert(currSeperator, newSeperator, null, upper);

			// Quick Brown Fox, Quick-Brown-Fox, Quick_Brown_Fox
			case TitleCase | PascalCase | TrainCase | OxfordCase:
				s.convert(currSeperator, newSeperator, proper);
		}
	}

	/**
	 * AnimSet loading for basic FlxSprites
	 * NOTE: Linking animations and such are of course not supported here
	 */
	public static inline function basic_load_from_anim_set<T:FlxSprite>(sprite:T, name:String, ?auto_play:String = "idle"):T
	{
		var anim_set:AnimSet = Lists.getAnimationSet(name);

		sprite.loadGraphic(Paths.get('${name}.png'), true, anim_set.dimensions.x.floor(), anim_set.dimensions.y.floor());

		for (anim in anim_set.animations)
			sprite.animation.add("idle", anim.frames.copy(), anim.fps, anim.looping);

		if (auto_play != "")
			sprite.animation.play(auto_play);

		/*
			var animWidth:Float = anim_set.dimensions.x;
			var animHeight:Float = anim_set.dimensions.y;

			if (animWidth == 0)
				animWidth = sprite.graphic.width / (anim_set.maxFrame + 1);
			if (animHeight == 0)
				animHeight = sprite.graphic.height;

			if (anim_set.offset.x != -999)
				sprite.offset.x = anim_set.offset.x;
			if (anim_set.offset.y != -999)
				sprite.offset.y = anim_set.offset.y;

			sprite.frames = FlxTileFrames.fromGraphic(sprite.graphic, FlxPoint.get(animWidth, animHeight));
		 */

		return sprite;
	}

	/**
	 * Tool for adjusting scrollFactor and position to any object, good for BGs and UI
	 * @param sprite 
	 * @param move_rate move rate for position, scrollFactor is a fixed 0.01
	 */
	public static inline function scroll_factor_and_position_adjust(sprite:FlxObject, move_rate:Float = 2)
	{
		if (Ctrl.use[1])
		{
			if (Ctrl.up[1])
				sprite.scrollFactor.y -= 0.01;

			if (Ctrl.down[1])
				sprite.scrollFactor.y += 0.01;

			if (Ctrl.left[1])
				sprite.scrollFactor.x -= 2;

			if (Ctrl.right[1])
				sprite.scrollFactor.x += 2;
		}

		if (Ctrl.special[1])
		{
			if (Ctrl.up[1])
				sprite.y -= move_rate;

			if (Ctrl.down[1])
				sprite.y += move_rate;

			if (Ctrl.left[1])
				sprite.x -= move_rate;

			if (Ctrl.right[1])
				sprite.x += move_rate;
		}

		if ((Ctrl.use[1] || Ctrl.special[1]) && (Ctrl.down[1] || Ctrl.up[1] || Ctrl.left[1] || Ctrl.right[1]))
			trace("position", sprite.y, "scrollFactor", sprite.scrollFactor);
	}

	public static inline function register_iid<T:FlxSpriteExt>(sprite:T, new_iid:String):T
	{
		sprite.iid = new_iid;
		return sprite;
	}

	public static inline function get_all_registered_animations(sprite:FlxSpriteExt):Map<String, Bool>
	{
		var animations:Map<String, Bool> = [];
		for (animation in sprite.animSet.animations)
		{
			var successfully_registered:Bool = false;
			for (list_animation in sprite.animation.getAnimationList())
				if (list_animation.name == animation.name)
					successfully_registered = true;
			animations.set(animation.name, successfully_registered);
		}
		return animations;
	}

	/**
	 * Copy from for positions because why not
	 * @param obj 
	 * @param new_pos 
	 * @return T
	 */
	public static inline function copy_from_position<T:FlxObject>(obj:T, new_pos:FlxPoint):T
	{
		obj.setPosition(new_pos.x, new_pos.y);
		return obj;
	}

	/**
	 * Add to positions because why not
	 * @param obj 
	 * @param new_pos 
	 * @return T
	 */
	public static inline function add_to_position<T:FlxObject>(obj:T, add:FlxPoint):T
	{
		obj.setPosition(obj.x + add.x, obj.y + add.y);
		return obj;
	}

	/**
	 * Does substring by finding first instance of start until first instance of end
	 * @param string_to_search to search
	 * @param start string to start searching from
	 * @param end strign to end searching at
	 * @return substring or null if not found
	 */
	public static inline function str_substring(string_to_search:String, start:String, end:String):String
	{
		if (end == "")
			throw "end in str_substring cannot be \"\"";

		var start_index:Int = string_to_search.indexOf(start);
		// trace('${string_to_search} search for \'${start}\' (${start_index})');

		if (start_index == -1)
			return null;

		var end_index:Int = string_to_search.indexOf(end, start_index + 1);
		// trace("found string", string_to_search, start_index, end_index, string_to_search.substring(start_index, end_index > -1 ? end_index : null));
		return string_to_search.substring(start_index, end_index > -1 ? end_index : null);
	}

	/**
	 * Does str_substring on multiple strings, first result wins, good for stuff like fps vs ms
	 * @param string_to_search to search
	 * @param starts string to start searching from
	 * @param end strign to end searching at
	 * @return substring or null if not found
	 */
	public static inline function str_substring_multiple(string_to_search:String, starts:Array<String>, end:String = ""):String
	{
		for (start in starts)
		{
			var result:String = str_substring(string_to_search, start, end);
			if (result != null)
				return result;
		}
		return null;
	}

	/**
	 * str_substring_within_brackets but with arrays
	 * @param string_to_search string to search
	 * @param contains_singular bracket contains like fps or ms
	 * @param contains_array array of possible contains like fps or ms
	 * @return text within bracket that contains text in contains_array or null if not found
	 */
	public static inline function str_substring_within_brackets(string_to_search:String, ?contains_singular:String, ?contains_array:Array<String>):String
	{
		if (contains_singular != null && contains_array != null)
			throw "contains_singular and contains_array can't be both not null, choose one >:-(";

		var brackets:Array<String> = string_to_search.replace_multiple(["(", ")", "[", "]"], "#").split("#");
		brackets.remove("");
		var found_bracket:String = null;

		if (contains_singular != null)
			contains_array = [contains_singular];

		// trace(string_to_search.replace_multiple(["(", ")", "[", "]"], "#"), brackets);
		for (bracket in brackets)
			for (contains in contains_array)
			{
				// trace(bracket, contains, bracket.indexOf(contains) > -1);
				if (bracket.indexOf(contains) > -1)
				{
					found_bracket = bracket;
					break;
				}
			}

		return found_bracket;
	}

	/**
	 * String replace, but with arrays
	 */
	public static inline function replace_multiple(string_to_replace_within:String, from:Array<String>, to:String):String
	{
		for (f in from)
			string_to_replace_within = string_to_replace_within.replace(f, to);
		return string_to_replace_within;
	}

	public static inline function iterator_to_list(iterator:Iterator<Dynamic>):Array<Dynamic>
	{
		var return_me:Array<String> = [];
		for (element in iterator)
			return_me.push(element);
		return return_me;
	}

	/**
	 * Gets animation duration (does NOT give you time remaining)
	 * @param sprite sprite to get duration of
	 * @param anim_name if null, will be the current animation, otherwise, sprite.animation.getByName(anim_name)
	 * @return Float duration
	 */
	public static inline function anim_duration(sprite:FlxSprite, ?anim_name:String):Float
	{
		var anim:FlxAnimation = anim_name == null ? sprite.animation.curAnim : sprite.animation.getByName(anim_name);
		return anim.numFrames * (1 / anim.frameRate);
	}

	// src: https://stackoverflow.com/questions/22906769/how-to-capitalise-the-first-letter-of-every-word-in-a-string
	public static inline function firstLetterUpperCase(strData:String):String
	{
		var strArray:Array<String> = strData.split(' ');
		var newArray:Array<String> = [];
		for (n in 0...strArray.length)
			newArray.push(strArray[n].charAt(0).toUpperCase() + strArray[n].substring(1));
		return newArray.join(' ');
	}

	public static inline function to_array<T>(iterator:Iterator<T>):Array<T>
	{
		var array:Array<T> = [];
		for (item in iterator)
			array.push(item);
		return array;
	}

	/**
	 * Credits Olin on Haxe Discord
	 * @param str1 string 1
	 * @param str2 string 2
	 * @return levenshtein distance between string 1 and string 2
	 */
	public static inline function levenshtein_distance(str1:String, str2:String):Int
	{
		var distance:Int = 0;
		var matrix:Array<Array<Int>> = new Array<Array<Int>>();
		for (i in 0...str1.length + 1)
		{
			matrix[i] = new Array<Int>();
			for (j in 0...str2.length + 1)
			{
				matrix[i].push((i != 0) ? 0 : j);
			}

			matrix[i][0] = i;
		}

		for (i in 1...str1.length + 1)
		{
			for (j in 1...str2.length + 1)
			{
				if (str1.charAt(i - 1) == str2.charAt(j - 1))
					distance = 0;
				else
					distance = 1;

				// todo tighten this up; min of the following 3
				// A: matrix[i - 1][j] + 1
				// B: matrix[i][j - 1] + 1)
				// C: matrix[i - 1][j - 1] + distance
				matrix[i][j] = Math.floor(Math.min(matrix[i - 1][j] + 1, matrix[i][j - 1] + 1));
				matrix[i][j] = Math.floor(Math.min(matrix[i][j], matrix[i - 1][j - 1] + distance));
			}
		}

		return matrix[str1.length][str2.length];
	}

	/**
	 * This is expensive. ONLY for debugging.
	 */
	public static inline function all_similar_strings_in(key:String, array:Array<String>, limit:Int = 6):Array<String>
	{
		var similar_strings:Array<String> = [];
		var a:String = key;
		for (b in array)
		{
			var levewhatever_distance:Int = levenshtein_distance(a, b);
			if (levewhatever_distance < limit)
				similar_strings.push(b);
		}
		return similar_strings;
	}
}

enum InflectCase
{
	// maybe change to this. more consistent
	LowerCase; // SpacedLower
	UpperCase; // SpacedUpper
	TitleCase; // SpacedProper
	PascalCase; // CamelUpper
	CamelCase; // CamelLower
	KebabCase; // DashedLower
	ScreamingKebabCase; // DashedUpper
	TrainCase; // DashedProper
	SnakeCase; // UnderLower
	ScreamingSnakeCase; // UnderUpper
	OxfordCase; // UnderProper
	// Custom(sep:String, wordFn:String->String, phraseFn:String->String)
}
