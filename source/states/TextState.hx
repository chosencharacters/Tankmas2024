package states;

class TextState extends flixel.FlxState
{
    public static var text_to_write:String = '';

    override function create()
    {
        add(new FlxText(0,0,FlxG.width,text_to_write.toUpperCase() + '\n\nPRESS ANY KEY TO CONTINUE.').setFormat(Paths.get('CharlieType-Heavy.otf'), 48, FlxColor.WHITE, CENTER).screenCenter());
    }

    override function update(elapsed:Float)
    {
        super.update(elapsed);
        Ctrl.update();
        if(FlxG.mouse.justPressed || Ctrl.anyB[1]) {
            text_to_write = '';
            FlxG.switchState(new PlayState());
        }
    }
}