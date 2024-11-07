package data;

import flixel.addons.text.FlxTextField;
import flixel.system.FlxAssets;
import flixel.system.FlxLinkedList;
import flixel.text.FlxText;
import haxe.Json;
import haxe.xml.Access;
import json2object.JsonParser;
import json2object.reader.BaseParser;
import openfl.Assets;
import openfl.display3D.textures.Texture;
import states.PlayState;
#if sys
import sys.FileSystem;
#end

/**
 * Global lists and list functions for instance saves and data
 * @author Squidly
 */
class Lists
{
	public static var animSets:Map<String, AnimSet> = new Map<String, AnimSet>();
	public static var textStorage:Map<String, String> = new Map<String, String>();

	public static var generated:Bool = false;

	public static var dlg_files:Map<String, Array<String>> = [];

	#if ldtk
	public static var ldtk_project:LdtkProject = new LdtkProject();
	#end

	static var assets_path(get, never):String;

	static function get_assets_path():String
		return Paths.asset_folder_alias;

	public static function init()
	{
		var start = Date.now().getTime();

		Fonts.init();

		Flags.generate();

		/*
			var xml:String = "";

			for (file in Utils.get_every_file_of_type(".json", "${assets_path}images/npcs/beach"))
			{
				var clean_file:String = StringTools.replace(file.split("/").pop(), ".json", "");
				xml = xml + json_to_aseprite(clean_file);
		}*/

		animSets.clear();
		textStorage.clear();

		if (!animSets.keys().hasNext())
			loadAnimationSets();

		#if word_count
		xml_word_count(true, "count-en");
		#end

		generated = true;

		#if find_missing_portraits
		data.tools.MissingPortraitsFinder.find_missing_portraits();
		#end

		// data.tests.AssetTests.all_tests();

		// trace(word_count());
	}

	public static function xml_word_count(write:Bool = false, save_file_name:String = "count-en")
	{
		var skip:Array<String> = ["anims", "exceptions", "moves", "unlocks", "-jp"];
		var required:Array<String> = [];

		var files:Array<String> = Paths.get_every_file_of_type(".xml");
		var file_counts:Array<{file:String, count:{words:Int, chars:Int}}> = [];

		files = files.filter(function(file:String):Bool
		{
			for (skippy in skip)
				if (file.contains(skippy))
					return false;
			return true;
		});

		if (required.length > 0)
			files = files.filter(function(file:String):Bool
			{
				for (req in required)
					if (file.contains(req))
						return true;
				return false;
			});

		for (file in files)
		{
			var xml:Xml = Utils.file_to_xml(Paths.get('${file}'));
			file_counts.push({file: file, count: count_inner(xml, false)});
		}

		var total:{file:String, count:{words:Int, chars:Int}} = {file: "total", count: {words: 0, chars: 0}};

		for (fc in file_counts)
		{
			total.count.words += fc.count.words;
			total.count.chars += fc.count.chars;
		}

		file_counts.push(total);

		file_counts.sort(((a, b) -> a.count.words < b.count.words ? 1 : -1));

		var content:String = "";

		for (fc in file_counts)
			content = content + 'FILE: ${fc.file}\nWORDS: ${fc.count.words}\t\tCHAR: ${fc.count.chars}\n\n';

		trace("\n" + content);

		#if sys
		if (write)
		{
			trace('writing... to ../../../${save_file_name}.txt');
			sys.io.File.saveContent('../../../${save_file_name}.txt', content);
		}
		#end
	}

	static function count_inner(xml:Xml, verbose:Bool = false):{words:Int, chars:Int}
	{
		var count:{words:Int, chars:Int} = {words: 0, chars: 0};
		var elements:Array<Xml> = [xml];

		while (elements.length > 0)
		{
			var current_element:Xml = elements.pop();

			for (element in current_element.elements())
				elements.push(element);

			if (current_element.firstChild() != null)
			{
				count.chars += current_element.firstChild().toString().length;
				count.words += count_words(current_element.firstChild().toString(), verbose);
			}
		}

		return count;
	}

	static function count_words(line:String, verbose:Bool = false):Int
	{
		var count:Int = 0;
		for (replace_me in ["\n", "\t", "<?xml", "version=\"1.0\"", "encoding=\"utf-8\"", "?>"])
			line = line.replace(replace_me, " ");

		for (word in line.split(" "))
		{
			if (word != " " && word != "")
			{
				if (verbose)
					trace(word, word.length);
				count++;
			}
		}
		return count;
	}

	public static function recursive_file_operation(?verboise:Bool = false, path:String, ext:String, file_operation:String->Void)
		for (file_path in find_all_files_by_name(verboise, path, ext))
			try
			{
				file_operation(file_path);
			}
			catch (e)
			{
				#if !demo_assets
				throw e;
				#end
			}

	public static function find_all_files_by_name(?verboise:Bool = false, path:String, ext:String):Array<String>
	{
		var found_files:Array<String> = [];
		for (file in Paths.path_cache.keys())
		{
			var file_path:String = Paths.path_cache.get(file);
			if (verboise)
				if (file_path.indexOf(path) > -1)
					trace(file_path, ext, file_path.indexOf(path) == 0, file, ext, file.indexOf(ext) > -1);
			if (file_path != null && file_path.indexOf(path) == 0 && file.contains(ext))
				found_files.push('${file_path}/${file}');
		}
		return found_files;
	}

	/***
	 * Animation Set Loading and Usage
	***/
	/**Loads all the animations from several xml files**/
	public static function loadAnimationSets()
		recursive_file_operation(false, '${assets_path}', "anims.xml", loadAnimationSet);

	public static function loadAnimationSet(path:String)
	{
		var xml:Xml = Utils.file_to_xml(path);
		for (set_xml in xml.elementsNamed("root").next().elementsNamed("animSet"))
			for (image in set_xml.get("image").split("||"))
				load_anim_set_from_xml(set_xml, image);
	}

	public static function load_anim_set_from_xml(xml:Xml, image:String)
	{
		var allFrames:String = "";
		var data:AnimSet = new AnimSet(image);

		var default_FPS:Int = xml.get("fps") == null ? 14 : Utils.ms_to_frames_per_second(xml.get("fps"));

		for (variable in xml.elementsNamed("variable"))
		{
			var frames_str:Array<String> = variable.get("frames").split(",");
			var frames:Array<Int> = [];
			for (frame in frames_str)
				frames.push(Std.parseInt(frame));

			data.variable_frames.set(variable.get("name"), frames);
		}

		for (anim in xml.elementsNamed("anim"))
		{
			function create_anim_def_with_name(anim:Xml, alias:String)
			{
				var animDef:AnimDef = {
					name: alias,
					frames: [],
					frames_string: "",
					fps: default_FPS,
					looping: true,
				};

				if (anim.get("fps") != null)
					animDef.fps = Utils.ms_to_frames_per_second(anim.get("fps"));
				if (anim.get("looping") != null)
					animDef.looping = anim.get("looping") == "true";
				if (anim.get("loops") != null)
					animDef.looping = anim.get("loops") == "true";
				if (anim.get("linked") != null)
					animDef.linked = anim.get("linked");
				if (anim.get("link") != null)
					animDef.linked = anim.get("link");
				if (anim.get("emote") != null)
					animDef.emote = anim.get("emote");

				animDef.frames_string = anim.firstChild().toString();

				allFrames = allFrames + animDef.frames_string + ",";

				data.animations.set(animDef.name, animDef);
			}

			for (anim_alias in anim.get("name").split("||"))
				create_anim_def_with_name(anim, anim_alias);
		}

		// if no anim data, add an idle
		if (!data.animations.keys().hasNext())
			data.animations.set("idle", {
				name: "idle",
				frames: [],
				frames_string: "0",
				fps: default_FPS,
				looping: true,
			});

		// xml.get("path") != null ? StringTools.replace(xml.get("path"), "\\", "/") : "";

		if (xml.get("x") != null)
			data.offset.x = Std.parseFloat(xml.get("x"));

		if (xml.get("y") != null)
			data.offset.y = Std.parseFloat(xml.get("y"));

		if (xml.get("offset") != null)
		{
			var off:Array<String> = xml.get("offset").split(",");
			data.offset = new FlxPoint(Std.parseFloat(off[0]), Std.parseFloat(off[1]));
		}

		if (xml.get("offset_left") != null)
		{
			var off:Array<String> = xml.get("offset_left").split(",");
			data.offset_left = new FlxPoint(Std.parseFloat(off[0]), Std.parseFloat(off[1]));
		}

		if (xml.get("offset_right") != null)
		{
			var off:Array<String> = xml.get("offset_right").split(",");
			data.offset_right = new FlxPoint(Std.parseFloat(off[0]), Std.parseFloat(off[1]));
		}

		if (xml.get("reverse") != null)
			data.reverse_mod = xml.get("reverse") == "true";

		if (xml.get("width") != null)
			data.dimensions.x = Std.parseFloat(xml.get("width"));

		if (xml.get("height") != null)
			data.dimensions.y = Std.parseFloat(xml.get("height"));

		if (xml.get("size") != null)
		{
			var size:Array<String> = xml.get("size").split(",");
			data.dimensions.set(Std.parseInt(size[0]), Std.parseInt(size[1]));
		}

		if (xml.get("frame_size") != null)
		{
			var size:Array<String> = xml.get("frame_size").split(",");
			data.dimensions.set(Std.parseInt(size[0]), Std.parseInt(size[1]));
		}

		if (xml.get("hitbox") != null)
		{
			var hitbox:Array<String> = xml.get("hitbox").split(",");
			data.hitbox.set(Std.parseFloat(hitbox[0]), Std.parseFloat(hitbox[1]));
		}

		if (xml.get("flipOffset") != null)
		{
			var flipOffset:Array<String> = xml.get("flipOffset").split(",");
			data.flipOffset.set(Std.parseFloat(flipOffset[0]), Std.parseFloat(flipOffset[1]));
		}

		if (xml.get("bg") != null)
			data.default_bg = xml.get("bg");

		if (xml.get("main_color") != null)
			data.main_color = xml.get("main_color").hex_safe_int() + 0xFF000000;

		if (xml.get("sub_color") != null)
			data.sub_color = '0xff${xml.get("sub_color")}'.hex_safe_int() + 0xFF000000;

		var maxFrame:Int = 0;

		for (anim in data.animations)
			anim.frames = Utils.animFromString(anim.frames_string);

		allFrames = StringTools.replace(allFrames, "t", ",");

		for (frame in allFrames.split(","))
		{
			if (frame.indexOf("h") > -1)
				frame = frame.substring(0, frame.indexOf("h"));

			var compFrame:Int = Std.parseInt(frame);

			if (compFrame > maxFrame)
				maxFrame = compFrame;
		}

		data.maxFrame = maxFrame;
		animSets.set(data.image, data);
	}

	public static function getAnimationSet(image:String):AnimSet
		return animSets.get(image);

	/***Helps with preloading or retrieving text, useful for TASC stuff like the SquidMechs***/
	public static function textStorageLoad(path:String):String
	{
		if (textStorage.get(path) == null)
			textStorage.set(path, Assets.getText(path));
		return textStorage.get(path);
	}

	static function writeToJSON<T>(source:Map<String, T>, filePath:String)
	{
		#if sys
		var holder:{array:Array<T>} = {array: []};

		for (src in source)
		{
			holder.array.push(src);
		}

		sys.io.File.saveContent(filePath, haxe.Json.stringify(holder));
		#end
	}

	static function santize_text(text:Null<String>):Null<String>
		return text == null ? text : text.replace("&lt;", "<");

	@:noCompletion
	static var generated_text_ids:Array<Int> = [];

	static function generatePsuedoFixedTextID(text:UnicodeString, fixedID:Int)
	{
		var id:Int = 0;
		if (fixedID != 0)
			return fixedID;
		if (text == "")
			return -999;
		for (char in 0...text.length)
			id += text.charCodeAt(char);

		return generated_text_ids.indexOf(id) <= -1 ? id : generatePsuedoFixedTextID(text, fixedID);
	}

	public static function get_xml_atr(xml:Xml, element:String, attribute:String):String
	{
		if (xml.elementsNamed(element).hasNext())
			return xml.elementsNamed(element).next().get(attribute);
		return "";
	}
}
