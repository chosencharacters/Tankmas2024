package ui.sheets.buttons;

import data.JsonData;
import data.SaveManager;
import data.loaders.NPCLoader.NPCDLGOption;
import data.types.TankmasDefs.CostumeDef;
import data.types.TankmasDefs.EmoteDef;
import data.types.TankmasDefs.PetDef;
import data.types.TankmasFontTypes.TextFormatPresets;
import squid.ui.FlxTextBMP;
import ui.button.HoverButton;
import ui.sheets.BaseSelectSheet.SheetType;
import ui.sheets.defs.SheetDefs.SheetItemDef;

class DialogueOptionBox extends FlxTypedGroupExt<FlxSprite>
{
	var button:HoverButton;
	var text:FlxTextBMP;

	var option_number:Int = 0;

	var def:NPCDLGOption;

	var dlg_box:DialogueBox;

	public function new(option_number:Int, def:NPCDLGOption, dlg_box:DialogueBox)
	{
		super();

		this.option_number = option_number;
		this.def = def;
		this.dlg_box = dlg_box;

		button = new HoverButton(0, 0, Paths.image_path("dialogue-option"), dialogue_pressed);

		button.center_on_x(dlg_box.bg);

		text = new FlxTextBMP(0, 0, 1216, 0, def.label, TextFormatPresets.DIALOGUE_OPTION);
		text.fieldWidthSet(button.width.floor());
		text.lineSpacing = -28;

		text.scrollFactor.set(0, 0);
		button.scrollFactor.set(0, 0);

		add(button);
		add(text);

		update_positions();

		PlayState.self.dialogue_options.add(this);
	}

	function update_positions()
	{
		button.center_on_x(dlg_box.bg);
		button.y = dlg_box.bg.bottom_y + dlg_box.bg.offset.y + button.height * option_number;

		text.center_on(button);
	}

	override function update(elapsed:Float)
	{
		update_positions();
		text.scale.set(button.scale.x, button.scale.y);
		super.update(elapsed);
	}

	public function dialogue_pressed(b:HoverButton)
	{
		dlg_box.swipe_out(true);
		dlg_box.defines.on_complete = () -> new DialogueBox(Lists.npcs.get(def.npc_name).get_state_dlg(def.state));
		trace(def);
	}

	override function kill()
	{
		killMembers();
		clear();
		PlayState.self.dialogue_options.remove(this, true);
		super.kill();
	}
}
