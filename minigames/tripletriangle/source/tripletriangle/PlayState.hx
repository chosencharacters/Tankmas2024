package tripletriangle;

import coroutine.CoroutineRunner;
import coroutine.Routine;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.FlxSubState;
import flixel.graphics.frames.FlxBitmapFont;
import flixel.group.FlxGroup;
import flixel.text.FlxBitmapText;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import tripletriangle.GenericCircle.CircleType;
import ui.Cursor;
#if ADVENT
import utils.OverlayGlobal as Global;
#else
import utils.Global;
#end

enum UIUnlockableType
{
	circle; // With "active" status.
	spikeSkin; // With "locked" and "chosen" status.
	backgroundSkin; // With "locked" and "chosen" status.
	achievement; // With optional tooltip.
}

enum AchievementID
{
	combo3;
	combo5;
	combo10;
	shopper;
}

// Needs to be flexible, and preferably possible to initiate via anonymous JSON objects like {type: 1}

/*class UIUnlockableButtonData {
	public var type:UIUnlockableType;
	public var x:Int;
	public var y:Int;
	public var callback:(btn:FlxButton) -> Void;
	public var image:String;
	public var unlockableName:String;
	//public var active:Bool;
}*/
class PlayState extends FlxSubState
{
	var _walls:FlxGroup;

	var _circleList:FlxTypedGroup<GenericCircle>; // Originally it's a List<GameObject>

	public static var _spikeList:FlxTypedGroup<Spike>; // New to this Haxe version
	public static var _spikeSpriteList:FlxTypedGroup<FlxSprite>; // For collisions. New to this Haxe version

	public static var countdownText:FlxBitmapText;
	public static var textShopMoney:FlxBitmapText;

	var fontAngelCode:FlxBitmapFont;
	var fontAngelCode_x4:FlxBitmapFont;

	var achievementGroup:FlxTypedGroup<FlxSprite>;
	var achievementSpriteDatas:Array<Dynamic>;
	var purchaseCounter = 0;
	final MAX_PURCHASE_AMOUNT = 4; // 4 circles + 0 spike skins + 0 background skins.

	public static var comboText:FlxBitmapText;
	public static var coinComboText:FlxBitmapText;

	public static var initiatedRoutinesToStopOnClose:List<CoroutineRunner>;

	var cursor:Cursor; // Debugging
	var cursorPosition:FlxBitmapText; // Debugging

	override public function create()
	{
		bgColor = 0xffcbdbfc;
		FlxG.camera.antialiasing = false;
		cursor = new Cursor(this);
		cursor.scale.x = 0.125;
		cursor.scale.y = 0.125;
		cursor.offset.set(58, 72); // Some magic numbers manually selected until it looked currect.
		states.PlayState.self.input_manager.mode = input.InputManager.InputMode.MouseOrTouch;

		super.create();
		initiatedRoutinesToStopOnClose = new List<CoroutineRunner>();
		fontAngelCode = FlxBitmapFont.fromAngelCode(Global.asset("assets/slkscrb_0.png"), Global.asset("assets/slkscrb.fnt"));
		fontAngelCode_x4 = FlxBitmapFont.fromAngelCode(Global.asset("assets/slkscrb_x4_0.png"), Global.asset("assets/slkscrb_x4.fnt"));

		var circle:BasicCircle = new BasicCircle(120, 160, Global.asset("assets/images/Circle Basic.png"));
		var errorCauser:BasicCircle = new BasicCircle(5, 5, Global.asset("assets/images/Logo Triangles.png")); // TODO: No. Initialize actual pick up circles.
		var circlePrefabArr:Array<FlxObject> = [circle]; // Must have at least one circle.
		var pickupCirclePrefabArr:Array<FlxObject> = [errorCauser]; // Must have at least one circle.

		_walls = new FlxGroup();
		var wallColor = 0xff847e87;

		var _leftWall = new FlxSprite(0, 0);
		_leftWall.makeGraphic(80, 240, wallColor);
		_leftWall.immovable = true;
		_walls.add(_leftWall);

		var _rightWall = new FlxSprite(240, 0);
		_rightWall.makeGraphic(80, 240, wallColor);
		_rightWall.immovable = true;
		_walls.add(_rightWall);

		/*var _bottomWall = new FlxSprite(0, 239);
			_bottomWall.makeGraphic(320, 10, FlxColor.TRANSPARENT);
			_bottomWall.immovable = true;
			_walls.add(_bottomWall); */

		_circleList = new FlxTypedGroup();
		add(_circleList);

		_spikeList = new FlxTypedGroup();
		add(_spikeList);
		_spikeSpriteList = new FlxTypedGroup();
		add(_spikeSpriteList);

		var spikesController = new SpikesController(this);
		add(spikesController);

		add(_walls);

		initializeUI();

		FlxG.sound.playMusic(Global.asset("assets/music/Rob0ne - Press Start.ogg"), 1, true);
		ComboManager.Main = new ComboManager(this);
		add(ComboManager.Main);
		GameManagerBase.Main = new GameManager(circlePrefabArr, pickupCirclePrefabArr, _circleList);
		add(GameManagerBase.Main);
		var global = new GlobalMasterManager();
		add(global);
	}

	override function update(elapsed:Float)
	{
		// cursorPosition.text = cursor.getPosition().toString();
		super.update(elapsed);
	}

	override function close()
	{
		for (routine in initiatedRoutinesToStopOnClose)
		{
			routine.stopAllCoroutines(); // IN THE PERFECT PROJECT, there's likely only one CoroutineRunner. Not important rn.
		}
		super.close();
	}

	function initializeUI()
	{
		countdownText = new FlxBitmapText(fontAngelCode);
		countdownText.font = fontAngelCode_x4;
		countdownText.setPosition(160, 104);
		add(countdownText);

		var creditsText = new FlxBitmapText(fontAngelCode);
		creditsText.font = fontAngelCode;
		creditsText.text = "Dev:\n Blawnode";
		creditsText.setPosition(8, 54);
		add(creditsText);

		var exitText = new FlxBitmapText(fontAngelCode);
		exitText.font = fontAngelCode;
		exitText.text = "C - Exit";
		exitText.setPosition(8, 200);
		add(exitText);

		comboText = new FlxBitmapText(fontAngelCode);
		comboText.font = fontAngelCode;
		comboText.setPosition(160, 120);
		comboText.visible = false;
		add(comboText);

		coinComboText = new FlxBitmapText(fontAngelCode);
		coinComboText.font = fontAngelCode;
		coinComboText.setPosition(160, 140);
		coinComboText.visible = false;
		coinComboText.color = 0xffe551;
		add(coinComboText);

		// CURSOR POSITION DEBUGGING
		/*cursorPosition = new FlxBitmapText(fontAngelCode);
			cursorPosition.font = fontAngelCode;
			cursorPosition.text = "-";
			cursorPosition.setPosition(8, 74);
			add(cursorPosition); */
		/*var creditsText = new FlxText(8, 54, 0, "Dev:\n Blawnode", 8);
			creditsText.font = "assets/slkscrb.ttf";
			creditsText.antialiasing = false;
			creditsText.pixelPerfectRender = true;
			add(creditsText); */
		// creditsText.setFormat(null, 8);
		// creditsText.scrollFactor.set(0, 0); // Keeps the text fixed in place
		// creditsText.x = Math.floor(creditsText.x / FlxG.camera.scaleX) * FlxG.camera.scaleX;
		// creditsText.y = Math.floor(creditsText.y / FlxG.camera.scaleY) * FlxG.camera.scaleY;

		var logoTriangles:FlxSprite = new FlxSprite(0, 0, Global.asset("assets/images/Logo Triangles.png"));
		add(logoTriangles);

		var logoShop:FlxSprite = new FlxSprite(240, 16, Global.asset("assets/images/Shop Money Icon.png"));
		add(logoShop);

		final INITIAL_MONEY = 0;
		textShopMoney = new FlxBitmapText(fontAngelCode_x4);
		textShopMoney.font = fontAngelCode_x4;
		textShopMoney.text = StringTools.lpad(Std.string(INITIAL_MONEY), "0", 3);
		textShopMoney.setPosition(278 - (textShopMoney.width / 2), 57 - (textShopMoney.height / 2));
		textShopMoney.alignment = FlxTextAlign.CENTER;
		add(textShopMoney);

		var mouseOnlyText = new FlxBitmapText(fontAngelCode);
		mouseOnlyText.font = fontAngelCode;
		mouseOnlyText.text = "Warning:\n This is a\n Mouse-only\n Game!";
		mouseOnlyText.setPosition(242, 160);
		add(mouseOnlyText);

		/*flixel.util.FlxTimer.wait(2, () ->
			{
				textShopMoney.text = "999";
				textShopMoney.x = 244 - (textShopMoney.width / 2);
				textShopMoney.y = 42 - (textShopMoney.height / 2);
		});*/

		initializeShopButtons();
	}

	function initializeShopButtons()
	{
		var buttonDatas:Array<Dynamic> = [
			// (Already unlocked)
			{
				type: UIUnlockableType.circle,
				x: 250,
				y: 100,
				callback: btnShopItemCallback,
				image: "assets/images/Shop Circle Madness Grunt.png",
				imageLocked: "assets/images/Shop Locked Unimplemented.png",
				unlockableName: "Grunt Circle",
				price: 999,
				unlocked: true,
				circleType: CircleType.Basic,
			},
			/*{
				type: UIUnlockableType.circle,
				x: 290,
				y: 130,
				callback: btnToBeImplementedCallback,
				image: "assets/images/Shop Locked Unimplemented.png",
				imageLocked: "assets/images/Shop Locked Unimplemented.png",
				unlockableName: "6th Circle",
				price: 50,
				unlocked: true,
			},*/
			{
				type: UIUnlockableType.circle,
				x: 270,
				y: 100,
				callback: btnShopItemCallback,
				image: "assets/images/Shop Circle Nene.png",
				imageLocked: "assets/images/Shop Locked 50.png",
				unlockableName: "Nene Circle",
				price: 50,
				unlocked: false,
				circleType: CircleType.Torpedo,
			},
			{
				type: UIUnlockableType.circle,
				x: 290,
				y: 100,
				callback: btnShopItemCallback,
				image: "assets/images/Shop Circle Moony.png",
				imageLocked: "assets/images/Shop Locked 50.png",
				unlockableName: "Moony Circle",
				price: 50,
				unlocked: false,
				circleType: CircleType.Bloon,
			},
			{
				type: UIUnlockableType.circle,
				x: 250,
				y: 130,
				callback: btnShopItemCallback,
				image: "assets/images/Shop Circle P-Bot.png",
				imageLocked: "assets/images/Shop Locked 100.png",
				unlockableName: "P-Bot Circle",
				price: 100,
				unlocked: false,
				circleType: CircleType.Big,
			},
			{
				type: UIUnlockableType.circle,
				x: 270,
				y: 130,
				callback: btnShopItemCallback,
				image: "assets/images/Shop Circle Angry Faic.png",
				imageLocked: "assets/images/Shop Locked 100.png",
				unlockableName: "Angry Faic Circle",
				price: 100,
				unlocked: false,
				circleType: CircleType.Mole,
			},
			/*{
				type: UIUnlockableType.circle,
				x: 290,
				y: 130,
				callback: btnShopItemCallback,
				image: "assets/images/Shop Locked Unimplemented.png",
				imageLocked: "assets/images/Shop Locked 100.png",
				// image: "assets/images/Shop Circle Nene.png"
				unlockableName: "6th Circle",
				price: 100,
				unlocked: false,
			},*/

			// Spike Skin Buttons

			/*{
					type: UIUnlockableType.spikeSkin,
					x: 270,
					y: 100,
					callback: btnToBeImplementedCallback,
					image: "assets/images/Shop Locked Unimplemented.png"
					// image: "assets/images/Shop Circle Nene.png"
				},
				{
					type: UIUnlockableType.spikeSkin,
					x: 270,
					y: 100,
					callback: btnToBeImplementedCallback,
					image: "assets/images/Shop Locked Unimplemented.png"
					// image: "assets/images/Shop Circle Nene.png"
				},
				{
					type: UIUnlockableType.spikeSkin,
					x: 270,
					y: 100,
					callback: btnToBeImplementedCallback,
					image: "assets/images/Shop Locked Unimplemented.png"
					// image: "assets/images/Shop Circle Nene.png"
			},*/

			// BG Skin Buttons

			/*{
					type: UIUnlockableType.backgroundSkin,,
					x: 270,
					y: 100,
					callback: btnToBeImplementedCallback,
					image: "assets/images/Shop Locked Unimplemented.png"
					// image: "assets/images/Shop Circle Nene.png"
				},
				{
					type: UIUnlockableType.backgroundSkin,
					x: 270,
					y: 100,
					callback: btnToBeImplementedCallback,
					image: "assets/images/Shop Locked Unimplemented.png"
					// image: "assets/images/Shop Circle Nene.png"
				},
				{
					type: UIUnlockableType.backgroundSkin,
					x: 270,
					y: 100,
					callback: btnToBeImplementedCallback,
					image: "assets/images/Shop Locked Unimplemented.png"
					// image: "assets/images/Shop Circle Nene.png"
			},*/
		];

		achievementSpriteDatas = [
			// (Already unlocked)
			{
				type: UIUnlockableType.achievement,
				x: 10,
				y: 100,
				image: "assets/images/Achievement Combo 3.png",
				imageLocked: "assets/images/Achievement Locked.png",
				unlockableName: "Combo 3 Achievement",
				unlocked: false,
				achievement: AchievementID.combo3,
			},
			{
				type: UIUnlockableType.achievement,
				x: 30,
				y: 100,
				image: "assets/images/Achievement Combo 5.png",
				imageLocked: "assets/images/Achievement Locked.png",
				unlockableName: "Combo 5 Achievement",
				unlocked: false,
				achievement: AchievementID.combo5,
			},
			{
				type: UIUnlockableType.achievement,
				x: 50,
				y: 100,
				image: "assets/images/Achievement Combo 10.png",
				imageLocked: "assets/images/Achievement Locked.png",
				unlockableName: "Combo 10 Achievement",
				unlocked: false,
				achievement: AchievementID.combo10,
			},
			{
				type: UIUnlockableType.achievement,
				x: 10,
				y: 150,
				image: "assets/images/Achievement Shopper.png",
				imageLocked: "assets/images/Achievement Locked.png",
				unlockableName: "Shopper Achievement",
				unlocked: false,
				achievement: AchievementID.shopper,
			},
		];

		var btnGroup:FlxTypedGroup<FlxButton> = new FlxTypedGroup<FlxButton>();
		achievementGroup = new FlxTypedGroup<FlxSprite>();

		for (buttonData in buttonDatas)
		{
			var btn:FlxButton = new FlxButton(buttonData.x, buttonData.y, "");
			btn.loadGraphic(Global.asset(buttonData.unlocked ? buttonData.image : buttonData.imageLocked));
			btn.centerOrigin();
			btn.onUp.callback = () ->
			{
				buttonData.callback(btn, buttonData);
			};
			btnGroup.add(btn);
		}

		add(btnGroup);

		for (achievementSpriteData in achievementSpriteDatas)
		{
			var achievementSprite:FlxSprite = new FlxSprite(achievementSpriteData.x, achievementSpriteData.y);
			achievementSprite.loadGraphic(Global.asset(achievementSpriteData.imageLocked));
			// achievementSprite.loadGraphic(Global.asset(achievementSpriteData.unlocked ? achievementSpriteData.image : achievementSpriteData.imageLocked));
			achievementSprite.centerOrigin();
			achievementGroup.add(achievementSprite);
		}

		add(achievementGroup);
	}

	function btnShopItemCallback(btn:FlxButton, shopButtonData:Dynamic)
	{
		trace("Clicked shop item: " + shopButtonData.unlockableName);
		if (shopButtonData.unlocked)
		{
			trace("But it is already unlocked!");
			trace("TEST: " + btn.toString());
			return;
		}

		// ASSUMPTION: There is only GameManager inheriting form GameManagerBase.
		if (!GameManager.Main.CanPurchase(shopButtonData.price))
		{
			trace("Insufficient funds.");
			trace("TEST: " + btn.toString());
			return;
		}

		shopButtonData.unlocked = true;
		GameManager.Main.Purchase(shopButtonData.price);
		FlxG.sound.play(Global.asset("assets/sounds/JSFXR Buy Thing.ogg"), 0.9);
		// btn.active = false;  // More efficient when the button is disabled. Better debugging when the button is enabled + Items can be re-enabled or re-disabled, like skins.
		switch (shopButtonData.type)
		{
			case UIUnlockableType.circle:
				trace("TODO: UNLOCK CIRCLE");
				GameManager.Main.UnlockCircle(shopButtonData.circleType);
			case UIUnlockableType.spikeSkin:
				trace("TODO: UNLOCK SPIKE SKIN");
			case UIUnlockableType.backgroundSkin:
				trace("TODO: UNLOCK BACKGROUND SKIN");
			default:
				trace("UNSUPPORTED PURCHASE TYPE. MISTAKE IN PROGRAMMING EXPECTED.");
		}
		btn.loadGraphic(Global.asset(shopButtonData.image));

		// Handle purchase achievement.
		purchaseCounter++;
		if (purchaseCounter == MAX_PURCHASE_AMOUNT)
			UnlockAchievement(AchievementID.shopper);
	}

	public function UnlockAchievement(achievement:AchievementID)
	{
		trace("Attempting to unlock achievement with ID: " + achievement);

		var achievementIndexInArrays:Int = -1;
		for (i in 0...achievementSpriteDatas.length)
		{
			if (achievementSpriteDatas[i].achievement == achievement)
			{
				achievementIndexInArrays = i;
				break;
			}
		}
		if (achievementIndexInArrays == -1)
		{
			trace("Couldn't find achievement: " + achievement);
			return;
		}

		trace("Unlocked achievement: " + achievementSpriteDatas[achievementIndexInArrays].unlockableName);
		achievementGroup.members[achievementIndexInArrays].loadGraphic(Global.asset(achievementSpriteDatas[achievementIndexInArrays].image));
		achievementSpriteDatas[achievementIndexInArrays].unlocked = true;
		FlxG.sound.play(Global.asset("assets/sounds/Echoes of the Void.ftm (Threeangle version)/Mixed SFX T17 - Note Pick Up.ogg"), 1);
	}

	function btnToBeImplementedCallback(btn:FlxButton, shopButtonData:Dynamic)
	{
		trace("A locked button. (To be implemented!) " + btn.toString());
	}
}
