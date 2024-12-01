package data.types;

import flixel.text.FlxText.FlxTextAlign;
import squid.types.FontTypes;

/**Note: Currently this is divided between defs here and in Fonts.hx 
	*This is becauseI want to eventually make squid lib its own repo
	*We'll deal with it all later... Maybe
**/
/**
 * Pls only use fonts from this, add new ones if needed
 */
enum abstract TankmasFonts(FontDef) from FontDef to FontDef
{
	public static final HANDWRITTEN:FontDef = {name: "crappy-handwriting", size: 96};
}

/**
 * Pls only use formats from this, add new ones if needed
 */
enum abstract TextFormatPresets(TextFormatDef) from TextFormatDef to TextFormatDef
{
	public static final BLACK:TextFormatDef = {font: TankmasFonts.HANDWRITTEN, color: FlxColor.BLACK};
	public static final WHITE:TextFormatDef = {font: TankmasFonts.HANDWRITTEN, color: FlxColor.WHITE};

	public static final BLACK_OUTLINED:TextFormatDef = {font: TankmasFonts.HANDWRITTEN, color: FlxColor.BLACK, outline: {color: FlxColor.WHITE, thickness: 2}};
	public static final WHITE_OUTLINED:TextFormatDef = {font: TankmasFonts.HANDWRITTEN, color: FlxColor.WHITE, outline: {color: FlxColor.BLACK, thickness: 2}};

	public static final DIALOGUE:TextFormatDef = {font: TankmasFonts.HANDWRITTEN, color: FlxColor.BLACK};
	public static final TITLE:TextFormatDef = {font: TankmasFonts.HANDWRITTEN, color: FlxColor.BLACK, alignment: FlxTextAlign.CENTER};
}
