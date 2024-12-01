package states.substates;

import ui.settings.BaseSettings;

class SettingsSubstate extends squid.ext.FlxSubstateExt.FlxSubStateExt
{
	var setting_ui:BaseSettings;

	public static var self:SettingsSubstate;

	public function new(setting_ui:BaseSettings)
	{
		super();

		self = this;

		add(this.setting_ui = setting_ui);

		sstate(ACTIVE);
	}

	override function update(elapsed:Float)
	{
		fsm();

		super.update(elapsed);
	}

	function fsm()
		switch (cast(state, State))
		{
			default:
			case ACTIVE:
				Ctrl.update();
				if (Ctrl.jinteract[1])
					start_closing();
			case CLOSING:
				return;
		}

	public function start_closing()
	{
		setting_ui.start_closing(() -> close_and_close_substate());
		sstate(CLOSING);
	}

	public function close_and_close_substate()
	{
		close();
		FlxG.state.closeSubState();
	}

	override function close()
	{
		setting_ui.kill();
		self = null;
		PlayState.self.ui_overlay.reveal_top_ui();
		super.close();
	}
}

private enum abstract State(String) from String to String
{
	var ACTIVE;
	var CLOSING;
}
