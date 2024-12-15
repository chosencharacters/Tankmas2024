package tripletriangle;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.graphics.frames.FlxBitmapFont;
import flixel.group.FlxGroup;
import flixel.text.FlxBitmapText;
import flixel.text.FlxText;
import flixel.ui.FlxButton;

#if ADVENT
import utils.OverlayGlobal as Global;
#else
import utils.Global;
#end

class PlayState extends FlxState
{
	var _walls:FlxGroup;

	var _circleList:FlxTypedGroup<BasicCircle>;  // Originally it's a List<GameObject>
	public static var _spikeList:FlxTypedGroup<Spike>; // New to this Haxe version
	public static var _spikeSpriteList:FlxTypedGroup<FlxSprite>; // For collisions. New to this Haxe version

	public static var textShopMoney:FlxBitmapText;
	
	var fontAngelCode:FlxBitmapFont;
	var fontAngelCode_x4:FlxBitmapFont;

	override public function create()
	{
		bgColor = 0xffcbdbfc;
		FlxG.camera.antialiasing = false;
		super.create();
		fontAngelCode = FlxBitmapFont.fromAngelCode(Global.asset("assets/slkscrb_0.png"), Global.asset("assets/slkscrb.fnt"));
		fontAngelCode_x4 = FlxBitmapFont.fromAngelCode(Global.asset("assets/slkscrb_x4_0.png"), Global.asset("assets/slkscrb_x4.fnt"));

		var circle:BasicCircle = new BasicCircle(120, 160, Global.asset("assets/images/Circle Basic.png"));
		var errorCauser:BasicCircle = new BasicCircle(5, 5, Global.asset("assets/images/Logo Triangles.png"));  // TODO: No. Initialize actual pick up circles.
		var circlePrefabArr: Array<FlxObject> = [circle];  // Must have at least one circle.
		var pickupCirclePrefabArr: Array<FlxObject> = [errorCauser];  // Must have at least one circle.

		

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
		_walls.add(_bottomWall);*/
		
		add(_walls);



		initializeUI();

		_circleList = new FlxTypedGroup();
		add(_circleList);

		_spikeList = new FlxTypedGroup();
		add(_spikeList);
		_spikeSpriteList = new FlxTypedGroup();
		add(_spikeSpriteList);

		var spikesController = new SpikesController(this);
		add(spikesController);

		FlxG.sound.playMusic(Global.asset("assets/music/Rob0ne - Press Start.ogg"), 1, true);

		GameManagerBase.Main = new GameManager(circlePrefabArr, pickupCirclePrefabArr, _circleList);
		add(GameManagerBase.Main);
		var global = new GlobalMasterManager();
		add(global);
	}

	function initializeUI(){
		var creditsText = new FlxBitmapText(fontAngelCode);
		creditsText.font = fontAngelCode;
		creditsText.text = "Dev:\n Blawnode";
		creditsText.setPosition(8, 54);
		add(creditsText);
		/*var creditsText = new FlxText(8, 54, 0, "Dev:\n Blawnode", 8);
		creditsText.font = "assets/slkscrb.ttf";
		creditsText.antialiasing = false;
		creditsText.pixelPerfectRender = true;
		add(creditsText);*/
		// creditsText.setFormat(null, 8);
		// creditsText.scrollFactor.set(0, 0); // Keeps the text fixed in place
		//creditsText.x = Math.floor(creditsText.x / FlxG.camera.scaleX) * FlxG.camera.scaleX;
		//creditsText.y = Math.floor(creditsText.y / FlxG.camera.scaleY) * FlxG.camera.scaleY;

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
		
		/*flixel.util.FlxTimer.wait(2, () ->
		{
			textShopMoney.text = "999";
			textShopMoney.x = 244 - (textShopMoney.width / 2);
			textShopMoney.y = 42 - (textShopMoney.height / 2);
		});*/

		initializeShopButtons();
	}

	function initializeShopButtons(){
		var buttonDatas = [
			// (Already unlocked)
			{
				x: 250,
				y: 100,
				callback: btnToBeImplementedCallback,
				image: "assets/images/Shop Circle Madness Grunt.png",
				unlockableName: "Grunt Circle",
				// image: "assets/images/Shop Circle Angry Faic.png"
			},
			{
				x: 270,
				y: 100,
				callback: btnToBeImplementedCallback,
				image: "assets/images/Shop Locked Unimplemented.png"
				// image: "assets/images/Shop Circle Nene.png"
			},
			{
				x: 290,
				y: 100,
				callback: btnToBeImplementedCallback,
				image: "assets/images/Shop Locked Unimplemented.png"
				// image: "assets/images/Shop Circle Nene.png"
			},
			{
				x: 250,
				y: 130,
				callback: btnToBeImplementedCallback,
				image: "assets/images/Shop Locked Unimplemented.png"
				// image: "assets/images/Shop Circle Nene.png"
			},
			{
				x: 270,
				y: 130,
				callback: btnToBeImplementedCallback,
				image: "assets/images/Shop Locked Unimplemented.png"
				// image: "assets/images/Shop Circle Nene.png"
			},
			{
				x: 290,
				y: 130,
				callback: btnToBeImplementedCallback,
				image: "assets/images/Shop Locked Unimplemented.png"
				// image: "assets/images/Shop Circle Nene.png"
			},
			

			// Spike Skin Buttons
			
			/*{
				x: 270,
				y: 100,
				callback: btnToBeImplementedCallback,
				image: "assets/images/Shop Locked Unimplemented.png"
				// image: "assets/images/Shop Circle Nene.png"
			},
			{
				x: 270,
				y: 100,
				callback: btnToBeImplementedCallback,
				image: "assets/images/Shop Locked Unimplemented.png"
				// image: "assets/images/Shop Circle Nene.png"
			},
			{
				x: 270,
				y: 100,
				callback: btnToBeImplementedCallback,
				image: "assets/images/Shop Locked Unimplemented.png"
				// image: "assets/images/Shop Circle Nene.png"
			},*/
			
			
			// BG Skin Buttons
			
			/*{
				x: 270,
				y: 100,
				callback: btnToBeImplementedCallback,
				image: "assets/images/Shop Locked Unimplemented.png"
				// image: "assets/images/Shop Circle Nene.png"
			},
			{
				x: 270,
				y: 100,
				callback: btnToBeImplementedCallback,
				image: "assets/images/Shop Locked Unimplemented.png"
				// image: "assets/images/Shop Circle Nene.png"
			},
			{
				x: 270,
				y: 100,
				callback: btnToBeImplementedCallback,
				image: "assets/images/Shop Locked Unimplemented.png"
				// image: "assets/images/Shop Circle Nene.png"
			},*/
		];

		var btnGroup:FlxTypedGroup<FlxButton> = new FlxTypedGroup<FlxButton>();
		
		var btn:FlxButton;
		
		for(buttonData in buttonDatas){
			btn = new FlxButton(buttonData.x, buttonData.y, "", buttonData.callback);
			// btn.loadGraphic("assets/images/Shop Circle Angry Faic.png");
			btn.loadGraphic(Global.asset(buttonData.image));
			btnGroup.add(btn);
		}
		
		add(btnGroup);
	}

	function btnToBeImplementedCallback(){
		trace("A locked button. (To be implemented!)");
	}
}
