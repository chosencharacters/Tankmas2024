package squid.ui;

import flixel.graphics.frames.FlxBitmapFont;
import flixel.text.FlxBitmapText;
import squid.types.FontTypes;

/**
 * ...
 * @author 
 */
class FlxTextBMP extends FlxBitmapText
{
	var scroll_rate:Int = 0;

	public function new(?x:Float = 0, ?y:Float = 0, ?fieldWidth:Int, ?scroll_rate:Int = 0, ?text:String, format:TextFormatDef)
	{
		var bmp_graphic:String = Paths.get('${format.font.name}_0.png');
		var bmp_defines:String = Paths.get('${format.font.name}.fnt');

		wrap = WORD(WordSplitConditions.LINE_WIDTH);

		var bmpFont:FlxBitmapFont = FlxBitmapFont.fromAngelCode(bmp_graphic, bmp_defines);

		if (fieldWidth != null)
		{
			this.fieldWidth = fieldWidth;
			set_fieldWidth(fieldWidth);
		}

		super(x, y, bmpFont);

		this.multiLine = true;
		this.autoSize = false;

		this.alignment = format.alignment;

		this.text = text;
	}

	public function fieldWidthSet(newWidth:Int)
		set_fieldWidth(newWidth);

	public static inline function set_format(text:FlxTextBMP, format:TextFormatDef):FlxTextBMP
	{
		text.color = format.color;
		if (format.outline != null)
			text.setBorderStyle(OUTLINE, format.outline.color);

		text.alignment = format.alignment;

		return text;

		// TODO: implement bitmap fonts?
		// lineSpacing = 2;
		// switch (format)
		// {
		// 	case DEFAULT_BLACK:
		// 		color = FlxColor.BLACK;
		// 	case DEFAULT_WHITE:
		// 		color = FlxColor.WHITE;
		// 		setBorderStyle(OUTLINE, FlxColor.BLACK);
		// 	case PAUSE_BODY_CENTERED:
		// 		set_format(PAUSE_BODY);
		// 		alignment = FlxTextAlign.CENTER;
		// 	case PAUSE_BODY:
		// 		color = FlxColor.BLACK;
		// }
	}
}
