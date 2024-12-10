package ui;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxBitmapText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;

/**
 * UI that describes the currently playing song
 * Stolen from Tankmas 2021
 */
class MusicPopup extends FlxTypedSpriteGroup<FlxSprite>
{
    static var instance(default, null):MusicPopup;
    
    inline static var SCALE = 4.0;

    inline static var DURATION = 5.0;
    inline static var MAIN_PATH = "assets/images/ui/jukebox/main.png";
    inline static var BAR_PATH = "assets/images/ui/jukebox/bar.png";
    
    var tweener:FlxTweenManager = new FlxTweenManager();
    var main:FlxSprite;
    var bar:FlxSprite;
    var text:FlxBitmapText;

    static var info:MusicInfo;
    
    public function new()
    {
        super();
        
        FlxG.signals.preStateSwitch.remove(tweener.clear);
        
        add(bar = new FlxSprite(BAR_PATH));
        add(main = new FlxSprite());
        add(text = new FlxBitmapText());
        
        main.scale.set(SCALE, SCALE);
        bar.scale.set(SCALE, SCALE);
        text.scale.set(SCALE, SCALE);

        #if FLX_DEBUG
        ignoreDrawDebug = true;
        bar.ignoreDrawDebug = true;
        main.ignoreDrawDebug = true;
        text.ignoreDrawDebug = true;
        #end
        
        main.loadGraphic(MAIN_PATH, true, 56, 72);
        main.animation.add("idle", [for (i in 0...main.animation.numFrames) i], 10);
        main.animation.play("idle");

        main.x = 0;

        bar.x = main.x + main.width;
        bar.y = main.y + main.height + 52;
        
        text.x = main.x + 8;
        text.y = main.y + main.height + 72;
        
        // visible = false;
        x = 0;
        y = FlxG.height - main.height - 104;
        scrollFactor.set(0,0);
        
        if (info != null) {
            play_anim();
        } else {
            trace('Jukebox loaded! Waiting for info (${info})');
        }
        
    }
    
    override function update(elapsed:Float)
    {
        super.update(elapsed);
        tweener.update(elapsed);
    }
    
    override function destroy()
    {
        // super.destroy();
    }
    
    function play_anim():Void
    {
        visible = true;
        
        tweener.cancelTweensOf(this);
        var tweenOutro:(?_:FlxTween)->Void = null;
        final duration = 0.5;
        
        trace('Displaying jukebox: ${info}');

        switch (info)
        {
            case Playing(data):
            {
                text.text = '${data}';
                
                tweenOutro = function (?_)
                {
                    var outroTween = tweener.tween(this, { y:FlxG.height }, duration,
                        { startDelay:DURATION, ease:FlxEase.circInOut, onComplete:(_)->visible = false });
                }
            }
            case Loading(data):
                text.text = 'Loading ${data}';        }
        
        // if (y > FlxG.height - bar.height)
        //     bar.x = text.x + text.width - bar.width + 6;
        // else
        // {
        //     FlxTween.tween(bar, { x:text.x + text.width - bar.width + 6 }, 0.25,
        //         { ease:FlxEase.circInOut });
        // }
        
        
        if (y > FlxG.height - main.height)
        {
            final introTime = (y - (FlxG.height - main.height)) / main.height * duration;
            tweener.tween(this, { y:FlxG.height - main.height }, introTime,
                { ease:FlxEase.circInOut, onComplete:tweenOutro });
        }
        else if (tweenOutro != null)
            tweenOutro();
        
        info = null;
    }
    
    /**
     * Call this to indicate the track is playing.
     */
    public static function show_info(info:String)
    {
        MusicPopup.info = Playing(info);
        if (instance != null) {
            instance.play_anim();
        } else {
            trace('Jukebox not loaded yet! Waiting to display info (${info})');
        }
    }
    
    /**
     * Call this to indicate the track is loading.
     */
    public static function show_loading(info:String)
    {
        MusicPopup.info = Loading(info);
        if (instance != null) {
            instance.play_anim();
        } else {
            trace('Jukebox not loaded yet! Waiting to display info (${info})');
        }
    }
    
    static public function get_instance()
    {
        if (instance == null)
            instance = new MusicPopup();
        return instance;
    }
}

enum MusicInfo
{
    Playing(data:String);
    Loading(data:String);
}