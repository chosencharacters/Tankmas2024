package tripletriangle;

import tripletriangle.PickupCircle.PickupType;
import tripletriangle.GenericCircle.CircleType;
import coroutine.CoroutineRunner;
import coroutine.Routine;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxBitmapText;
import haxe.Exception;

#if ADVENT
import utils.OverlayGlobal as Global;
#else
import utils.Global;
#end

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

    private var circleGroup:FlxTypedGroup<GenericCircle>;

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
    var money:Int;

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
    var circleToPurchased:Map<CircleType, Bool>;
    var circleChoicePool:Array<CircleType>;  // List
	// #endregion

	// #endregion

	public override function new(p_circlePrefabArr: Array<FlxObject>, p_pickupCirclePrefabArr: Array<FlxObject>, p_circleGroup: FlxTypedGroup<GenericCircle>)
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
        
        InitializeCircleToChance();
        circleToPurchased = [
            CircleType.Basic => true,
            CircleType.Torpedo => false,
            CircleType.Big => false,
            CircleType.Bloon => false,
            CircleType.Mole => false
        ];
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
		money = 0;
        
        //SoundManager.Main.PlaySound("Countdown");
        
		FlxG.sound.play(Global.asset("assets/sounds/Threeangle SFX.ftm/Threeangle SFX - Track 01 (Countdown).ogg"), 0.9);
        trace("TODO: Visually start a countdown.");
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
			if (currentTimeInSeconds > swCircleSpawn_lastOccurrenceTimeInSeconds + swtCircleSpawn_cooldownInSeconds)
			{
				if (currentAliveCircleCount < currentCircleCount)
				{
                    // trace("Spawning circle at time: " + currentTimeInSeconds + " (" + currentAliveCircleCount + ")");  // Useful for debugging.
                    //swCircleSpawn.Restart();
                    //swtCircleSpawnCurr = UnityEngine.Random.Range(swtCircleSpawnMin, swtCircleSpawnMax);
					SpawnCircle();
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

        if (circleToPurchased[CircleType.Torpedo] && circleCountArr[cast CircleType.Torpedo] <= 1 && typeToSpawn != CircleType.Torpedo)
        {
            circleChoicePool.push(CircleType.Torpedo);
        }
        if (circleToPurchased[CircleType.Bloon] && circleCountArr[cast CircleType.Bloon] <= 1 && typeToSpawn != CircleType.Bloon)
        {
            circleChoicePool.push(CircleType.Bloon);
        }
        if (circleToPurchased[CircleType.Big] && circleCountArr[cast CircleType.Big] <= 1 && typeToSpawn != CircleType.Big)
        {
            circleChoicePool.push(CircleType.Big);
        }
        if (circleToPurchased[CircleType.Mole] && circleCountArr[cast CircleType.Mole] <= 1 && typeToSpawn != CircleType.Mole)
        {
            circleChoicePool.push(CircleType.Mole);
        }
        ChooseCircle();
    }

    private function CircleTypeToCircleInstance(circleType: CircleType): GenericCircle{
        switch (circleType) {
            case CircleType.Basic:
                return new BasicCircle();  // TODO: Be able to spawn without parameters.
            case CircleType.Torpedo:
                return new TorpedoCircle();
            case CircleType.Bloon:
                return new BloonCircle();
            case CircleType.Big:
                return new BigCircle();
            case CircleType.Mole:
                return new MoleCircle();
            default:
                trace("Unimplemented/impossible circle type: " + circleType);
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
    }*/

    // TOEDIT (Circle): Need to edit this every time I add a new circle type.
    private function InitializeCircleToChance()
    {
        circleToChance = 
        [
            CircleType.Basic => BASIC_WEIGHT,
            CircleType.Torpedo => TORPEDO_WEIGHT,
            CircleType.Big => BIG_WEIGHT,
            CircleType.Bloon => BLOON_WEIGHT,
            CircleType.Mole => MOLE_WEIGHT
        ];
    }

    // Chooses the next circle to be spawned based on whether they're possible and on their weights
    private function ChooseCircle(){

        var choice: CircleType = CircleType.Basic;  // Initialization to prevent error.
        var weightSum: Float = 0;
        var randomNum: Float;
        var currentFloorWeight: Float = 0;

        for(type in circleChoicePool)
        {
            weightSum += circleToChance[type];
        }
        randomNum = FlxG.random.float(0, weightSum);

        // Issue: The last circle type will be favored. Start the loop from a different circle each time!

        for(type in circleChoicePool)
        {
            if(currentFloorWeight <= randomNum && randomNum <= currentFloorWeight + circleToChance[type])
            {
                // This condition should 100% be fulfilled.
                // This is the chosen one!!
                choice = type;
                break;
            }
            currentFloorWeight += circleToChance[type];
        }

        // prefabToSpawn = circlePrefabArr[cast choice];  // Unneeded in Haxe version.
        typeToSpawn = choice;
        if (choice != CircleType.Basic)
        {
            trace("TODO: PlayAlert(" + choice + ")");
            // PlayAlert(choice);
        }
    }

    private function IncrementCircleCount(circleType: CircleType)
    {
        currentAliveCircleCount++;
        circleCountArr[cast circleType]++;
    }

    // TOEDIT (Circle): Need to edit this every time I add a new circle type.
    public override function OnCirclePopped(circle: GenericCircle)
    {
        // trace("KILLL: " + circle.ID);  // Useful for debugging.

        /*if(GlobalMasterManager.Main.GameState != EGameState.RestartScreen)
        {*/
            try
            {
                AddToScore(circle.deathScore);
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
		money += toAdd;
		textShopMoney.text = StringTools.lpad(Std.string(money > 999 ? 999 : money), "0", 3);
		textShopMoney.x = 278 - (textShopMoney.width / 2);

		UpdateMaxCircleCount();

        // TODO: IMPERFECT PROGRAMMING. What about getting 3 points, F.E?
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

    public function CanPurchase(price:Int):Bool{
        return money > price;
    }

    public function Purchase(price:Int){
        money -= price;
		textShopMoney.text = StringTools.lpad(Std.string(money > 999 ? 999 : money), "0", 3);
		textShopMoney.x = 278 - (textShopMoney.width / 2);

        UpdateMaxCircleCount();
    }

    private function UpdateMaxCircleCount(){
		// Every 20 points, the game gets harder - Up to a limit.
        final MAX_CIRCLE_COUNT = 20;
        var newCircleCount = (3 + Std.int(score / 20));
        if(newCircleCount > MAX_CIRCLE_COUNT) newCircleCount = MAX_CIRCLE_COUNT;
        if(newCircleCount != currentCircleCount)
        {
            currentCircleCount = newCircleCount;
            trace("Max circle count set to " + currentCircleCount + "!");
        }
    }

    public override function OnCircleEscaped(circle: GenericCircle)
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

    public function UnlockCircle(circleType: CircleType){
        circleToPurchased[circleType] = true;
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

    // TOEDIT (Circle): Need to edit this every time I add a new circle type.
    private function PlayAlert(type:CircleType)
    {
        try
        {
            switch (type)
            {
                case CircleType.Torpedo:
                    // alert.GetComponent<Animator>().Play("Torpedo");
                    // var flxSound = FlxG.sound.play(Global.asset("assets/sounds/.ogg"), 0.9);
				    // flxSound.pitch = FlxG.random.float(0.95, 1.05);
                    // SoundManager.Main.PlaySound("Torpedo Alert");
                case CircleType.Big:
                    // alert.GetComponent<Animator>().Play("Big");
                    // var flxSound = FlxG.sound.play(Global.asset("assets/sounds/.ogg"), 0.9);
				    // flxSound.pitch = FlxG.random.float(0.95, 1.05);
                    // SoundManager.Main.PlaySound("Big Alert");
                case CircleType.Bloon:
                    // var flxSound = FlxG.sound.play(Global.asset("assets/sounds/.ogg"), 0.9);
				    // flxSound.pitch = FlxG.random.float(0.95, 1.05);
                    // SoundManager.Main.PlaySound("Bloon Inflation");
                case CircleType.Mole:
                    // Called later, in MoleCircle.cs.
                default:
                    throw new Exception("Circle doesn't have an alert!!");
            }
        }
        catch (e:Exception)
        {
            trace(e.toString());
            // ErrorScreenManager.Main.ShowError(e.ToString());
        }
    }

    // #region Helper Functions
    // private CircleType PrefabNameToCircleType(string prefabName)

    // public override void SetStopwatchesRun(bool toRun)
    // #endregion
}
