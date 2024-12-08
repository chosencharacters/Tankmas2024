package ui.button;

class ActionStamp extends HoverButton
{
	public function new()
	{
		super();

		update_visual(ActionStampType.INSPECT);

		setPosition(16, FlxG.height - height - 16);

		on_release = interact;
	}

	public function update_visual(stamp_type:ActionStampType)
	{
		loadAllFromAnimationSet('action-stamp-$stamp_type');
	}

	function interact(button:HoverButton)
	{
		trace("you're doing it !!!");
	}
}

enum abstract ActionStampType(String) from String to String
{
	final TALK = "talk";
	final PRESENT_NEW = "present-new";
	final PRESENT_OPENED = "present-opened";
	final INSPECT = "inspect";
	final MARSHMALLOW = "marshmallow";
}
