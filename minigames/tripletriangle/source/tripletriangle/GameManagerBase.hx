package tripletriangle;

// import PickupCircle.PickupType;
import coroutine.CoroutineRunner;
import coroutine.Routine;
import flixel.FlxObject;

// TOEDIT (Circle): Need to edit this every time I add a new circle type.
/*enum CircleType
{
    Inexistent;  // = -1
    Basic;
    Torpedo;
    Big;
    Bloon;
    Mole;
}*/

abstract class GameManagerBase extends FlxObject
{
    public static var _main:GameManagerBase;
    @:isVar public static var Main(get, set):GameManagerBase;
    static function get_Main(){
        return _main;
    }
    static function set_Main(newMain){
        return _main = newMain;
    }

	public var topSpike:Spike;
	public var rightSpike:Spike;
	public var leftSpike:Spike;
    public var pauseMenu:FlxObject;
    public var settingsMenu:FlxObject;

    //private var coStartRoutine:Routine;
    private var coStartRoutine:CoroutineRunner;
    public var _damage(default, default):Int = 1;


    /*virtual*/ function new()
    {
        super();
        
        if (Main == null) Main = this;

        //CameraShake.Main._isCameraShakeEnabled = SettingsManager.Main._isCameraShakeEnabled;

        coStartRoutine = new CoroutineRunner();
        coStartRoutine.startCoroutine(StartGame());
        //coStartRoutine = StartCoroutine(StartGame());
        new haxe.Timer(16).run = function() {
            // Customize how/when to update your coroutines
            // Set this at your convenience in your project
            var processor = CoroutineProcessor.of(coStartRoutine);
            processor.updateEnterFrame();
            processor.updateTimer(haxe.Timer.stamp());
            processor.updateExitFrame();
        }
    }

    //abstract IEnumerator StartGame();
    //public var StartGame:Void->Routine;
    public abstract function StartGame():Routine;

    // abstract function StartGame(): Routine;

    // Originally, circle was GameObject (AKA FlxObject).
    public function OnCirclePopped(circle: GenericCircle)
    {
        var errorMessage = "BASE: Unimplemented (OnCirclePopped of GameManagerBase)";
        trace(errorMessage);
        //ErrorScreenManager.Main.ShowError(errorMessage);
    }

    public function OnCircleEscaped(circle: GenericCircle)
    {
        var errorMessage = "BASE: Unimplemented (OnCircleEscaped of GameManagerBase)";
        trace(errorMessage);
        //ErrorScreenManager.Main.ShowError(errorMessage);
    }

    public function OnPickupPopped(circle: GenericCircle, pickupType: PickupCircle.PickupType)
    {
        var errorMessage = "BASE: Unimplemented (OnPickupPopped of GameManagerBase)";
        trace(errorMessage);
        //ErrorScreenManager.Main.ShowError(errorMessage);
    }

    public function OnPickupEscaped(circle: GenericCircle)
    {
        var errorMessage = "BASE: Unimplemented (OnPickupEscaped of GameManagerBase)";
        trace(errorMessage);
        //ErrorScreenManager.Main.ShowError(errorMessage);
    }

    function SetStopwatchesRun(value: Bool)
    {
        var errorMessage = "BASE: Unimplemented (SetStopwatchesRun of GameManagerBase)";
        trace(errorMessage);
        //ErrorScreenManager.Main.ShowError(errorMessage);
    }

    function Restart()
    {
        var errorMessage = "BASE: Unimplemented (Restart of GameManagerBase)";
        trace(errorMessage);
        //ErrorScreenManager.Main.ShowError(errorMessage);
    }

    public function OnCombo(combo: Int)
    {
        var errorMessage = "BASE: Unimplemented (OnCombo of GameManagerBase)";
        trace(errorMessage);
        //ErrorScreenManager.Main.ShowError(errorMessage);
    }

    public function OnFinishCombo()
    {
        var errorMessage = "BASE: Unimplemented (OnFinishCombo of GameManagerBase)";
        trace(errorMessage);
        //ErrorScreenManager.Main.ShowError(errorMessage);
    }

    public function AddToScore(amount: Int)
    {
        var errorMessage = "BASE: Unimplemented (AddToScore of GameManagerBase)";
        trace(errorMessage);
        //ErrorScreenManager.Main.ShowError(errorMessage);
    }

    /*#region Menu functions
    public void OnBtnSettings()
    {
        InputManager.Main.OnBtnSettings();
    }

    public void OnBtnSettingsBack()
    {
        InputManager.Main.OnBtnSettingsBack();
    }

    public void ClosePauseMenu()
    {
        InputManager.Main.ClosePauseMenu();
    }

    public void OnPressRestart()
    {
        Restart();
    }

    public void OnPressMainMenu()
    {
        if (IngameCoinManager.Main != null)
        {
            // In game, naturally. But a normal game!
            GameManager.Main.CheckIfHighScore();
            IngameCoinManager.Main.CashInCoins();
        }
        TransitionScreenManager.Main.LoadScene("Main Menu Scene");
    }
    #endregion*/
}
