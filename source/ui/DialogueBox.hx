package ui;

import data.loaders.NPCLoader;
import data.types.TankmasFontTypes;
import flixel.tweens.FlxEase;
import squid.ext.FlxTypedGroupExt;
import squid.ui.FlxTextBMP;
import ui.sheets.buttons.DialogueOptionBox;

class DialogueBox extends FlxTypedGroupExt<FlxSprite>
{
	#if ttf
	var text:FlxText;
	#else
	var text:FlxTextBMP;
	#end

	public var bg:FlxSpriteExt;

	var dlgs:Array<NPCDLG>;

	var dlg(get, never):NPCDLG;

	var line_number:Int = 0;

	var char_index:Int;
	var typing_rate:Int = 2;

	public function get_dlg():NPCDLG
		return dlgs[line_number];

	var defines:DialogueBoxDefines;

	var line_finished(get, default):Bool;

	var text_position:FlxPoint;

	public function get_line_finished()
		return char_index >= dlg.text.str.length;

	/**
	 * Prevents this from closing
	 */
	var hold_for_dialogue_options(get, default):Bool;

	var option_boxes:Array<DialogueOptionBox> = [];

	public function new(dlgs:Array<NPCDLG>, ?defines:DialogueBoxDefines)
	{
		super();

		this.dlgs = dlgs;
		this.defines = defines == null ? {} : defines;

		PlayState.self.dialogues.add(this);

		/*
			text = new FlxTextBMP(200, 159, 1208);
			text.set_format(TextFormatPreset.DEFAULT_WHITE);
			text.fieldWidthSet((FlxG.width / 2).floor());
		 */

		Ctrl.mode = Ctrl.ControlModes.TALKING;

		#if ttf
		text = Utils.formatText(new FlxText(0, 0, 1216), TextFormatPresets.DIALOGUE);
		#else
		text = new FlxTextBMP(0, 0, 1216, TextFormatPresets.DIALOGUE);
		text.fieldWidthSet(1216);
		#end

		bg = new FlxSpriteExt().one_line("dialogue-box");

		bg.setPosition(FlxG.width / 2 - bg.width / 2, 0);

		#if ttf
		// temp
		text.setPosition(bg.x + 194, bg.y + 130);
		switch (TextFormatPresets.DIALOGUE.font.name.split(".")[0])
		{
			case "crappy-handwriting":
				text.y += 42;
		}
		#else
		text.setPosition(bg.x + 194, bg.y + 150);
		text.lineSpacing = -28;
		#end

		sstate(SWIPE_IN);

		bg.scrollFactor.set(0, 0);
		text.scrollFactor.set(0, 0);

		text_position = new FlxPoint(text.x - bg.x, text.y - bg.y);

		add(bg);
		add(text);
		load_dlg(dlgs[line_number]);
	}

	public function load_dlg(dlg:NPCDLG)
	{
		text.text = "";
		char_index = 0;
		sstate(SWIPE_IN);
	}

	public function next_dlg()
	{
		if (hold_for_dialogue_options)
		{
			return;
		}
		line_number = line_number + 1;
		if (line_number < dlgs.length)
		{
			load_dlg(dlgs[line_number]);
			if (hold_for_dialogue_options)
				spawn_dlg_options();
		}
		else
			close_dlg();
	}

	public function close_dlg()
	{
		kill();
	}

	public function type_char()
	{
		char_index = char_index + 1;
		text.text = dlg.text.str.substr(0, char_index);
		if (line_finished)
			sstate(IDLE);
	}

	override function update(elapsed:Float)
	{
		bg.anim(line_number < dlgs.length - 1 ? "has-next" : "idle");
		text.setPosition(bg.x + text_position.x, bg.y + text_position.y);
		// text.offset_adjust();
		fsm();
		super.update(elapsed);
	}

	function fsm()
		switch (cast(state, State))
		{
			default:
			case SWIPE_IN:
				bg.y = -bg.height;
				FlxTween.tween(bg, {y: 0}, 0.15, {ease: FlxEase.quadIn, onComplete: (t:FlxTween) -> sstate(TYPING)});
				sstate(WAIT);
			case SWIPE_OUT:
				bg.y = 0;
				FlxTween.tween(bg, {y: -bg.height}, 0.15, {ease: FlxEase.quadIn, onComplete: (t:FlxTween) -> next_dlg()});
				sstate(WAIT);
			case TYPING:
				if (Ctrl.jinteract[1] || FlxG.mouse.justPressed)
					char_index = dlg.text.str.length - 1;
				if (ttick() % typing_rate == 0)
					type_char();
			case IDLE:
				if (line_finished)
				{
					if (Ctrl.jinteract[1] || FlxG.mouse.justPressed)
						if (!hold_for_dialogue_options)
							swipe_out();
				}
		}

	override function kill()
	{
		Ctrl.mode = Ctrl.ControlModes.OVERWORLD;
		defines.on_complete != null ? defines.on_complete() : false;
		PlayState.self.dialogues.remove(this, true);
		super.kill();
	}

	function get_hold_for_dialogue_options():Bool
		return dlg.options != null && dlg.options.length > 0;

	public function spawn_dlg_options()
	{
		for (n in 0...dlg.options.length)
			option_boxes.push(new DialogueOptionBox(n, dlg.options[n], this));
	}

	public function swipe_out()
	{
		sstate(SWIPE_OUT);
	}
}

private enum abstract State(String) from String to String
{
	var IDLE;
	var TYPING;
	var SWIPE_IN;
	var SWIPE_OUT;
	var WAIT;
}

typedef DialogueBoxDefines =
{
	var ?on_complete:Void->Void;
	var ?dialogue_options:Array<NPCDLGOption>;
}
