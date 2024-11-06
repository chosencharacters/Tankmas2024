package entities;

import data.types.TankmasDefs.CostumeDef;
import data.types.TankmasEnums.Costumes;
import entities.base.BaseUser;

class NetUser extends BaseUser
{
	public function new(?X:Float, ?Y:Float, ?costume:CostumeDef)
	{
		super(X, Y);
		new_costume(costume);
	}
}