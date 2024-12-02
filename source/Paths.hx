package;

import flixel.system.FlxAssets;
import lime.utils.AssetManifest;
import openfl.utils.AssetType;
import openfl.utils.Assets;
#if deprecated
import sys.FileSystem;
#end

class Paths
{
	public static var path_cache:Map<String, String> = new Map<String, String>();
	public static var asset_folder_alias:String;

	public static var allowed_extensions:Array<String> = [
		".json", ".png", ".xml", ".txt", ".ogg", ".ttf", ".world", ".tasc", ".ldtkl", ".aseprite", ".fnt"
	];

	public static function get(name:String, starting_path:String = "assets", safe:Bool = false):String
	{
		starting_path = starting_path.replace("assets", asset_folder_alias);

		var clean_name:String = name.file_from_path();

		if (path_cache.exists(clean_name))
		{
			#if demo_asset_record PathsDemo.add_asset_to_demo_assets_folder(name); #end
			return '${path_cache.get(clean_name)}/$clean_name';
		}

		if (!safe)
		{
			#if dev_trace
			trace(name.all_similar_strings_in(path_cache.keys().to_array()));
			#end
			throw 'could not find ${name} from starting path ${starting_path}';
		}

		return null;
	}

	/**
	 * Unsafe, do not generally use
	 */
	public static function unsafe_get(name:String):String
	{
		var clean_name:String = name.file_from_path();
		return '${path_cache.get(clean_name)}/$clean_name';
	}

	public static function get_every_file_of_type(extension:String, starting_path:String = "assets", ?file_must_contain:String = ""):Array<String>
	{
		starting_path = starting_path.replace("assets", asset_folder_alias);

		var return_files:Array<String> = [];

		for (file in Paths.path_cache.keys())
		{
			var file_must_contain_req:Bool = file_must_contain == "" || file.contains(file_must_contain);

			if (path_cache.get(file).contains(starting_path) && file.contains(extension) && file_must_contain_req)
				return_files.push(file);
		}

		return return_files;
	}

	public static function file_exists(name:String):Bool
		return path_cache.get(name.split("/").last()) != null;

	public static function ldtk_filepath(path:String, extension:String):String
		return path.replace(extension, "").split("/").last();

	public static function find_nearest(name:String, extension:String, safe:Bool = false):String
	{
		var name_segments:Array<String> = name.split("-");

		for (n in 0...name_segments.length)
		{
			var test_name:String = name_segments.slice(0, n).join("-");
			var success:Bool = Paths.get(test_name + extension, true) != null;

			if (success)
				return test_name;
		}

		if (!safe)
			throw "no nearest for " + name;

		return null;
	}

	public static function get_cache_path(file_name:String):String
		return '${path_cache.get(file_name)}/$file_name';

	/**
	 * credits to https://ashes999.github.io/learnhaxe/recursively-delete-a-directory-in-haxe.html
	 */
	public static function delete_dir_recursively(path:String):Void
	{
		#if sys
		if (sys.FileSystem.exists(path) && sys.FileSystem.isDirectory(path))
		{
			var entries = sys.FileSystem.readDirectory(path);
			for (entry in entries)
				if (sys.FileSystem.isDirectory(path + '/' + entry))
				{
					delete_dir_recursively(path + '/' + entry);
					sys.FileSystem.deleteDirectory(path + '/' + entry);
				}
				else
					sys.FileSystem.deleteFile(path + '/' + entry);
		}
		#end
	}

	public static function recurse_rmdir(dir_path:String)
	{
		#if sys
		while (sys.FileSystem.exists(dir_path))
			command('rmdir "${dir_path}" /s /q', false);
		#end
	}

	static function command(cmd:String, verboise:Bool = true)
	{
		#if sys
		if (verboise)
			trace(cmd);
		Sys.command(cmd);
		#end
	}
}

class Manifest
{
	// functionality has been mostly removed
	static public function init(asset_folder_alias:String = "assets", onComplete:() -> Void):Void
	{
		Paths.asset_folder_alias = asset_folder_alias;

		#if demo_assets
		PathsDemo.add_dummy_files_to_paths();
		#end

		for (asset_path in AssetPaths.allFiles)
		{
			var real_path:String = asset_path.replace("assets", Paths.asset_folder_alias);
			for (extension in Paths.allowed_extensions)
				if (real_path.indexOf(extension) == -1)
				{
					#if trace_assets
					trace(real_path);
					#end

					var asset_name:String = real_path.split("/").last();

					Paths.path_cache.set(asset_name, real_path.substr(0, real_path.length - asset_name.length - 1));

					break;
				}
		}
		onComplete();
	}
}
