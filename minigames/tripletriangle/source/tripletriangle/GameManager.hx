package tripletriangle;

import tripletriangle.PickupCircle.PickupType;
import tripletriangle.BasicCircle.CircleType;
import coroutine.CoroutineRunner;
import coroutine.Routine;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxBitmapText;
import haxe.Exception;

private class Animator{}
private class CameraShake{}
private class HeartBar{}
private class Stopwatch{}
private class TextMeshProUGUI{}

class GameManager extends GameManagerBase
{
	@:isVar public static var Main(get, set):GameManager;
    static function get_Main(){
        return cast(GameManagerBase._main, GameManager);
    }
    static function set_Main(newMain){
		GameManagerBase._main = cast(newMain, GameManagerBase);
        return Main = newMain;  // Redundant-ish, but I couldn't get the set to work otherwise.
    }

	private var textShopMoney:FlxBitmapText;

    private var circleGroup:FlxTypedGroup<BasicCircle>;

    public var circlePrefabArr: Array<FlxObject>;  // Must have at least one circle.
    public var pickupCirclePrefabArr: Array<FlxObject>;  // Must have at least one circle.

    public var scoreText:TextMeshProUGUI;
    public var newRecordText:Animator;
    public var heartBar:HeartBar;
    public var countdownText:FlxObject;
    public var restartScreen:Animator;
    public var highScoreText:TextMeshProUGUI;

    public var alert:FlxObject;
    public var painScreenAnimator:Animator;
    public var cameraShake:CameraShake;

    public var PopZone:FlxObject;  // Transform

    public var _powerupScore:Int = 25;

    public var _tripleSpikeTime:Float = 10;

    public var _baseDamage:Int = 1;
    public var _scorchingDamage:Int = 3;
    //#endregion
    
    //#region Non-Serialized properties
    var score:Int;

    var circleCountArr:Array<UInt>;

    var circleList:Array<FlxObject>;  // List
    var pickupCircleList:Array<FlxObject>;  // List

    //var prefabToSpawn:FlxObject;
    //var pickupPrefabToSpawn:FlxObject;
    var typeToSpawn:CircleType;  // circleTypeToSpawn
    var pickupTypeToSpawn:PickupType;
    
    var isSpawning:Bool = false;
    final startCircleCount:UInt = 3;
    var currentCircleCount:UInt;
    var currentAliveCircleCount:UInt;

    var currentPickupCircleCount:UInt = 1;
    var currentAlivePickupCircleCount:UInt;

    final startLives:UInt = 5;
    var currentLives:UInt;

    
	private var swCircleSpawn_lastOccurrenceTimeInSeconds:Float; // System.Diagnostics.Stopwatch
	private final swtCircleSpawn_cooldownInSeconds:Float = 0.15; // const
    //var swCircleSpawn:Stopwatch;
    final swtCircleSpawnMin:Float = 0.5;  // Never-changing, at the moment. Might remove the const if I want to balance the game.
    var swtCircleSpawnMax:Float = 2.5;
    //var swtCircleSpawnCurr:Float = 2.5;

    var swPickupCircleSpawn:Stopwatch;
    var swtPickupCircleSpawnCurr:Float = 25;
    var _pickupsUnlocked:Bool = false;

    // #region Circle choice values
    // The weights measure how likely is a circle to be spawned
    // TOEDIT (Circle): Need to edit this every time I add a new circle type.
    final BASIC_WEIGHT:Float = 1.2;
    final TORPEDO_WEIGHT:Float = 0.4;
    final BLOON_WEIGHT:Float = 0.25;
    final BIG_WEIGHT:Float = 0.2;
    final MOLE_WEIGHT:Float = 0.2;

    final TORPEDO_SCORE_TARGET:Int = 20;
    final BLOON_SCORE_TARGET:Int = 40;
    final BIG_SCORE_TARGET:Int = 60;
    final MOLE_SCORE_TARGET:Int = 80;
	// #endregion

    var circleToChance:Map<CircleType, Float>;
    var circleChoicePool:Array<CircleType>;  // List
	// #endregion

	// #endregion

	public override function new(p_circlePrefabArr: Array<FlxObject>, p_pickupCirclePrefabArr: Array<FlxObject>, p_circleGroup: FlxTypedGroup<BasicCircle>)
    {
        circlePrefabArr = p_circlePrefabArr;
        pickupCirclePrefabArr = p_pickupCirclePrefabArr;
        circleGroup = p_circleGroup;
        if (circlePrefabArr == null || circlePrefabArr.length == 0) throw new Exception("circlePrefabArr's length must be at least one!");
        if (pickupCirclePrefabArr == null || pickupCirclePrefabArr.length == 0) throw new Exception("pickupCirclePrefabArr's length must be at least one!");
        //super().new();
        super();
        if (Main == null) Main = this;

        //swCircleSpawn = new Stopwatch();
		swCircleSpawn_lastOccurrenceTimeInSeconds = -999;
        //swPickupCircleSpawn = new Stopwatch();
        circleList = new Array<FlxObject>();
        pickupCircleList = new Array<FlxObject>();

        var circleTypeCount: Int = circlePrefabArr.length;
        circleCountArr = [for(i in 0...circleTypeCount) 0];  // new uint[circleTypeCount]
        
        //InitializeCircleToChance();
        circleChoicePool = new Array<CircleType>();
        //SkinManager.Main.SetupSkins(circlePrefabArr);

        //CameraShake.Main._isCameraShakeEnabled = SettingsManager.Main._isCameraShakeEnabled;

		coStartRoutine = new CoroutineRunner();
        coStartRoutine.startCoroutine(StartGame());
        new haxe.Timer(16).run = function() {
            // Customize how/when to update your coroutines
            // Set this at your convenience in your project
            var processor = CoroutineProcessor.of(coStartRoutine);
            processor.updateEnterFrame();
            processor.updateTimer(haxe.Timer.stamp());
            processor.updateExitFrame();
        }
		textShopMoney = PlayState.textShopMoney;
    }

	public function StartGame():Routine {
        @yield return WaitEndOfFrame;  // Wait for the InputManager.hx to initialize itself (If it even going to be implemented.)

		currentLives = startLives;

        currentCircleCount = startCircleCount;
        currentAliveCircleCount = 0;
        currentAlivePickupCircleCount = 0;
		score = 0;
        
        //SoundManager.Main.PlaySound("Countdown");
        trace("TODO: Properly start a countdown.");
        var i = 3;
		while(i > 0) {
			trace(i--);
			@yield return WaitDelay(1);
		}
		trace("GO!");
        

        isSpawning = true;
        typeToSpawn = CircleType.Basic;
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);
		var currentTimeInSeconds = haxe.Timer.stamp();

		if (isSpawning)
		{
			/*if (swCircleSpawn.Elapsed.TotalSeconds >= swtCircleSpawnCurr)
			{
				if (currentAliveCircleCount < currentCircleCount)
				{
					SpawnCircle();
                    //swCircleSpawn.Restart();
                    //swtCircleSpawnCurr = UnityEngine.Random.Range(swtCircleSpawnMin, swtCircleSpawnMax);
				}
			}*/

			if (currentTimeInSeconds > swCircleSpawn_lastOccurrenceTimeInSeconds + swtCircleSpawn_cooldownInSeconds)
			{
				if (currentAliveCircleCount < currentCircleCount)
				{
					SpawnCircle();
                    //swCircleSpawn.Restart();
                    //swtCircleSpawnCurr = UnityEngine.Random.Range(swtCircleSpawnMin, swtCircleSpawnMax);
				    swCircleSpawn_lastOccurrenceTimeInSeconds = currentTimeInSeconds;
				}
			}

			/*if (_pickupsUnlocked && swPickupCircleSpawn.Elapsed.TotalSeconds >= swtPickupCircleSpawnCurr)
				{
				if (currentAlivePickupCircleCount < currentPickupCircleCount)
				{
					SpawnPickupCircle();
				}
			}*/
		}
	}

    // TOEDIT (Circle): Need to edit this every time I add a new circle type.
    private function SpawnCircle()
    {
        IncrementCircleCount(typeToSpawn);

        var spawnedCircleInstance = CircleTypeToCircleInstance(typeToSpawn);
		circleGroup.add(spawnedCircleInstance);
        circleList.push(spawnedCircleInstance);

        // What's the next circle going to be?

        circleChoicePool = [ CircleType.Basic ];  // Reset to initial pool state

        if (score >= BLOON_SCORE_TARGET && circleCountArr[cast CircleType.Bloon] <= 1 && typeToSpawn != CircleType.Bloon)
        {
            circleChoicePool.push(CircleType.Bloon);
        }
        if (score >= BIG_SCORE_TARGET && circleCountArr[cast CircleType.Big] <= 1 && typeToSpawn != CircleType.Big)
        {
            circleChoicePool.push(CircleType.Big);
        }
        if (score >= TORPEDO_SCORE_TARGET && circleCountArr[cast CircleType.Torpedo] <= 1 && typeToSpawn != CircleType.Torpedo)
        {
            circleChoicePool.push(CircleType.Torpedo);
        }
        if (score >= MOLE_SCORE_TARGET && circleCountArr[cast CircleType.Mole] <= 1 && typeToSpawn != CircleType.Mole)
        {
            circleChoicePool.push(CircleType.Mole);
        }
        ChooseCircle();
    }

    private function CircleTypeToCircleInstance(circleType: CircleType): BasicCircle{
        switch (circleType) {
            case CircleType.Basic:
                return new BasicCircle();  // TODO: Be able to spawn without parameters.
            case CircleType.Torpedo:
                trace("Torpedo? Not yet");
                //return new EnemyB(x, y);
                return null;
            default:
                trace("What how");
                return null;
        }
    }
    
    /*private void SpawnPickupCircle()
    {
        currentAlivePickupCircleCount++;

        // Make sure a full HP player doesn't get an HP bonus, IF there's an option.
        if (currentLives == startLives)
        {
            while (pickupPrefabToSpawn.GetComponent<PickupCircle>().pickupType == PickupCircle.PickupType.HP)
            {
                if (pickupCirclePrefabArr.Length == 1) break;  // No choice, you gotta have the HP.
                pickupPrefabToSpawn = pickupCirclePrefabArr[UnityEngine.Random.Range(0, pickupCirclePrefabArr.Length)];
            }
        }

        pickupCircleList.Add(Instantiate(pickupPrefabToSpawn, null));

        // What's the next pickup going to be?

        pickupPrefabToSpawn = pickupCirclePrefabArr[UnityEngine.Random.Range(0, pickupCirclePrefabArr.Length)];
    }

    // TOEDIT (Circle): Need to edit this every time I add a new circle type.
    private void InitializeCircleToChance()
    {
        circleToChance = new Dictionary<CircleType, float>
        {
            { CircleType.Basic, BASIC_WEIGHT },
            { CircleType.Torpedo, TORPEDO_WEIGHT },
            { CircleType.Big, BIG_WEIGHT },
            { CircleType.Bloon, BLOON_WEIGHT },
            { CircleType.Mole, MOLE_WEIGHT },
        };
    }*/

    private function ChooseCircle(){trace("TODO: ChooseCircle()");}

    private function IncrementCircleCount(circleType: CircleType)
    {
        currentAliveCircleCount++;
        circleCountArr[cast circleType]++;
    }

    // TOEDIT (Circle): Need to edit this every time I add a new circle type.
    public override function OnCirclePopped(circle: BasicCircle)
    {
        /*if(GlobalMasterManager.Main.GameState != EGameState.RestartScreen)
        {*/
            try
            {
                AddToScore(1);
                // ComboManager.Main.AddToCombo(1);
                // IngameCoinManager.Main.AddCoins(1);

                // Originally in Unity, I converted the circle (GameObject)'s name to a circle name "Torpedo Clone (1) -> Torpedo" via GameObjectNameToPrefabName.
                currentAliveCircleCount--;
                switch (circle.type)
                {
                    case CircleType.Basic:
                        circleCountArr[cast CircleType.Basic]--;
                    case CircleType.Torpedo:
                        circleCountArr[cast CircleType.Torpedo]--;
                    case CircleType.Big:
                        circleCountArr[cast CircleType.Big]--;
                    case CircleType.Bloon:
                        circleCountArr[cast CircleType.Bloon]--;
                    case CircleType.Mole:
                        circleCountArr[cast CircleType.Mole]--;
                    default:
                        throw new Exception("Invalid circle name!!");
                }
                circleList.remove(circle);
            }
            catch (e: Exception)
            {
                // ErrorScreenManager.Main.ShowError(e.ToString());
                trace(e.message);
            }
        /*}*/
        // Else, do nothing.
    }

    //    public override void OnCombo(int combo)

    // public override OnFinishCombo(){ /* Nada */ }

    // public override void OnPickupPopped(GameObject pickupCircle, PickupCircle.PickupType pickupType)

	public override function AddToScore(toAdd:Int)
	{
		score += toAdd;
		textShopMoney.text = StringTools.lpad(Std.string(score > 999 ? 999 : score), "0", 3);
		textShopMoney.x = 278 - (textShopMoney.width / 2);

		if (score % 20 == 0)
		{
			// Every 20 points, the game gets harder.
			currentCircleCount++;
		}

		if (score % 15 == 0 && score <= 300)
		{
			// Will happen only 20 times.
			if (swtCircleSpawnMax >= 1.5)
				swtCircleSpawnMax -= 0.25;
			else
				swtCircleSpawnMax -= 0.05;
		}

		if (!_pickupsUnlocked && score >= _powerupScore)
		{
			_pickupsUnlocked = true;
			// SpawnPickupCircle();
		}
	}

    public override function OnCircleEscaped(circle: BasicCircle)
    {
        /*if(GlobalMasterManager.Main.GameState != EGameState.RestartScreen)
            {*/
                currentLives--;
                // heartBar.DecreaseHearts();
                // FlashPainScreen();
                // CameraShake.Main.TriggerShake(0.5);
                // GlobalMasterManager.Vibrate();
    
                currentAliveCircleCount--;
                switch (circle.type)
                {
                    case CircleType.Basic:
                        circleCountArr[cast CircleType.Basic]--;
                    case CircleType.Torpedo:
                        circleCountArr[cast CircleType.Torpedo]--;
                    case CircleType.Big:
                        circleCountArr[cast CircleType.Big]--;
                    case CircleType.Bloon:
                        circleCountArr[cast CircleType.Bloon]--;
                    case CircleType.Mole:
                        circleCountArr[cast CircleType.Mole]--;
                    default:
                        throw new Exception("Not a circle!!");
                }
    
                circleList.remove(circle);
    
                if (currentLives == 0)
                {
                    trace("DEATH");
                    // SoundManager.Main.PlaySound("Death");
                    // OnLose();
                }
                else
                {
                    trace("HP LOSS");
                    // SoundManager.Main.PlaySound("HP Loss");
                }
            /*}*/
    }

    // public override void OnPickupEscaped(GameObject pickupCircle)

    // private void FlashPainScreen()

    // private void RestartTripleSpikes()

    // private IEnumerator IRestartTripleSpikes()

    // private void RestartScorchingSpikes()

    // private IEnumerator IRestartSchorchingSpikes()

    // private void OnLose()

    // private IEnumerator ShowRestartScreen()

    // public void CheckIfHighScore(bool allowClaps = false)

    // private void ClearCircles()

    // private void ClearParticles()

    // protected override void Restart()

    // public void Revive()

    // private void PlayAlert(CircleType type)

    // #region Helper Functions
    // private CircleType PrefabNameToCircleType(string prefabName)

    // public override void SetStopwatchesRun(bool toRun)
    // #endregion
}
