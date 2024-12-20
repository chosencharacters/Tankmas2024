package ui.sheets.buttons;

import data.JsonData;
import data.SaveManager;
import data.types.TankmasDefs.CostumeDef;
import data.types.TankmasDefs.EmoteDef;
import data.types.TankmasDefs.PetDef;
import data.types.TankmasEnums.UnlockCondition;
import ui.button.HoverButton;
import ui.sheets.BaseSelectSheet.SheetType;
import ui.sheets.defs.SheetDefs.SheetItemDef;

class SheetButton extends HoverButton
{
	var sheet_type:SheetType;

	public var empty:Bool;
	public var unlocked:Bool;

	public var def:SheetItemDef;

	public var lock_condition:UnlockCondition;

	public function new(X:Float, Y:Float, def:SheetItemDef, sheet_type:SheetType, ?on_pressed:HoverButton->Void)
	{
		super(X, Y, on_pressed);
		this.sheet_type = sheet_type;

		this.def = def;

		if (sheet_type != COSTUMES || def == null || def.name == null)
		{
			empty = def.name == null || def.name == "";
			loadAllFromAnimationSet(!empty ? def.name : "thomas");
		}
		else
		{
			var costume_name:String = def.name;
			var anim_set_name:String = 'costume-${Lists.animSets.exists('costume-${costume_name}') ? costume_name : "default"}';

			loadAllFromAnimationSet(anim_set_name, costume_name);
			animation.frameIndex = 0;
		}

		update_unlocked();
	}

	public function update_unlocked()
	{
		unlocked = eval_unlocked();

		color = unlocked ? FlxColor.WHITE : FlxColor.BLACK;
		if (empty)
			visible = false;
	}

	public function eval_unlocked():Bool
	{
		if (empty)
			return false;
		switch (sheet_type)
		{
			case SheetType.COSTUMES:
				var costume:CostumeDef = JsonData.get_costume(def.name);
				lock_condition = costume.unlock != null ? costume.unlock : UnlockCondition.YOUR_A_SPECIAL_LITTLE_BOY;
				if (costume.unlock != null)
					return data.types.TankmasEnums.UnlockCondition.get_unlocked(costume.unlock, costume.data);
			case SheetType.EMOTES:
				#if sticker_whatevey
				return true;
				#else
				return SaveManager.saved_emote_collection.contains(def.name);
				#end
			case SheetType.PETS:
				var pet:PetDef = JsonData.get_pet(def.name);
				lock_condition = pet.unlock != null ? pet.unlock : UnlockCondition.YOUR_A_SPECIAL_LITTLE_BOY;
				if (pet.unlock != null)
					return data.types.TankmasEnums.UnlockCondition.get_unlocked(pet.unlock, pet.data);
		}
		return true;
	}
}
