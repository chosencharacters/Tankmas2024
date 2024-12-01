package ui.settings;

import flixel.tweens.FlxEase;
import flixel.FlxBasic;
import flixel.util.FlxTimer;
import states.substates.SettingsSubstate;
import ui.button.HoverButton;

class BaseSettings extends FlxTypedGroupExt<FlxSprite>
{
    var point:FlxPoint;
    var substate:SettingsSubstate;
    public function new()
    {
        super();

        FlxG.state.openSubState(substate = new SettingsSubstate(this));

        sstate(OPENING);

        point = FlxPoint.weak(960, 540);

        add(new FlxSpriteExt(point.x - 723, point.y - 436).makeGraphicExt(1446, 872));
        add(new FlxSpriteExt(point.x - 703, point.y - 416, Paths.get('emotes-back-red.png')));
        add(new HoverButton(point.x - 683, point.y - 396, null, (b) -> substate.start_closing()).loadAllFromAnimationSet("back-arrow"));
        add(new HoverButton(point.x - 424, point.y - 120, Paths.get('show-name-single.png'), (b) -> {PlayState.showUsers = !PlayState.showUsers;}));
        add(new HoverButton(point.x - 108, point.y - 120, Paths.get('fullscreen-single.png'), (b) -> {FlxG.fullscreen = !FlxG.fullscreen;}));
        add(new HoverButton(point.x + 208, point.y - 120, Paths.get('sound-single.png'), (b) -> FlxG.sound.toggleMuted()));

        members.for_all_members((member:FlxBasic) ->
		{
			final daMem:FlxObject = cast(member, FlxObject);
			daMem.y += 1300;
			daMem.scrollFactor.set(0, 0);
			FlxTween.tween(daMem, {y: daMem.y - 1300}, 0.8, {ease: FlxEase.cubeInOut});
		});
		new FlxTimer().start(0.8, (tmr:FlxTimer) -> sstate(ACTIVE));
    }

    function fsm()
		switch (cast(state, State))
		{
			default:
            case ACTIVE: for(i in 2...members.length) cast (members[i], HoverButton).enable();
            case OPENING | CLOSING:
                for(i in 2...members.length) cast (members[i], HoverButton).disable();
		}

	override function update(elapsed:Float)
	{
		fsm();
		super.update(elapsed);
	}
        

    public function start_closing(?on_complete:Void->Void)
        {
            var dumb_on_complete_bool:Bool = true;
            sstate(CLOSING);
            new FlxTimer().start(0.3, function(tmr:FlxTimer)
            {
                members.for_all_members((member:FlxBasic) ->
                {
                    final daMem:FlxObject = cast(member, FlxObject);
                    var tween:FlxTween = FlxTween.tween(daMem, {y: daMem.y + 1300}, 1, {ease: FlxEase.cubeInOut});
                    if (dumb_on_complete_bool)
                        tween.onComplete = (t) -> on_complete();
                    dumb_on_complete_bool = false;
                });
            });
        }
}

private enum abstract State(String) from String to String
{
	var OPENING;
	var ACTIVE;
	var CLOSING;
}