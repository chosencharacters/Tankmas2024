package entities;

import data.types.TankmasDefs.CostumeDef;
import data.types.TankmasEnums.Costumes;
import entities.base.BaseUser;

class NetUser extends BaseUser
{
	public function new(?X:Float, ?Y:Float, username:String, ?costume:CostumeDef)
	{
		super(X, Y, username);
		new_costume(costume);
		trace("NEW USER " + username);
	}

}