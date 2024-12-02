#if newgrounds
package ng;

import io.newgrounds.Call.CallError;
import io.newgrounds.Call.CallError;
import io.newgrounds.NG;
import io.newgrounds.NGLite;
import io.newgrounds.crypto.Cipher;
import io.newgrounds.objects.Medal;
import io.newgrounds.objects.ScoreBoard;
import io.newgrounds.objects.events.Outcome;
import io.newgrounds.objects.events.Result.MedalListData;
import io.newgrounds.swf.MedalPopup;
import io.newgrounds.swf.ScoreBrowser;
import lime.tools.GUID;

class NewgroundsHandler
{
	public var NG_LOGGED_IN:Bool = false;
	public var NG_LOGIN_ERROR:String;

	public var NG_USERNAME:String = "";
	public var NG_SESSION_ID:String = "";

	public var NG_MR_MONEYBAGS_OVER_HERE:Bool;

	public var medals:Map<String, MedalDef> = [];
	public var boards:Map<String, MedalDef> = [];

	public function new(use_medals:Bool = true, use_scoreboards:Bool = true, ?login_callback:Void->Void)
		init(use_medals, use_scoreboards, login_callback);

	public function init(use_medals:Bool = true, use_scoreboards:Bool = true, ?login_callback:Void->Void)
	{
		/*
			Make sure this file ng-secrets.json file exists, it's just a simple json that has this format
			{
				"app_id":"xxx",
				"encryption_key":"xxx"
			}
		 */

		trace("Attempting to intialize Newgrounds API...");

		try
		{
			load_medal_and_board_defs();
			login(login_callback);
		}
		catch (e)
		{
			trace(e);
		}
	}

	function login(?login_callback:Void->Void)
	{
		if(NG_LOGGED_IN) return;
		var json = haxe.Json.parse(Utils.load_file_string(Paths.get("ng-secrets.json")));

		NG.createAndCheckSession(json.app_id, false);
		NG.core.setupEncryption(json.encryption_key, AES_128, BASE_64);

		NG.core.onLogin.add(() -> onNGLogin(login_callback));

		if (!NG.core.loggedIn)
		{
			trace("Waiting on manual login...");
			NG.core.requestLogin(function(outcome:LoginOutcome):Void
			{
				switch(outcome) {
					case SUCCESS: 
						NG_LOGGED_IN = true;
						onNGLogin(login_callback);

					case FAIL(CANCELLED(_)):
						//NG.core.cancelLoginRequest();
						login_callback != null ? login_callback() : false;

					case FAIL(ERROR(error)):
						trace(error);
						NG_LOGIN_ERROR = error.toString();
						login_callback != null ? login_callback() : false;
				}
			}, );
		}
		else
		{
			NG_LOGGED_IN = true;
			login_callback != null ? login_callback() : false;
		}
	}

	function load_medal_and_board_defs()
	{
		var json:{medals:Array<MedalDef>} = haxe.Json.parse(Utils.load_file_string(Paths.get("medals.json")));
		for (medal in json.medals)
			medals.set(medal.name, medal);

		// I know they were made for medals but honestly why not just re-use instead of creating something samely different?
		var json:{boards:Array<MedalDef>} = haxe.Json.parse(Utils.load_file_string(Paths.get("boards.json")));
		for(board in json.boards)
			boards.set(board.name, board);
	}

	public function has_medal(def:MedalDef):Bool
	{
		return NG_LOGGED_IN && NG.core.medals.get(def.id).unlocked;
	}

	public function medal_popup(medal_def:MedalDef)
	{
		if (!NG_LOGGED_IN)
		{
			trace('Can\'t get a medal if not logged in $medal_def');
			return;
		}

		NG.core.verbose = true;

		var ng_medal:Medal = NG.core.medals.get(medal_def.id);

		trace('${ng_medal.name} [${ng_medal.id}] is worth ${ng_medal.value} points!');

		ng_medal.onUnlock.add(function():Void
		{
			trace('${ng_medal.name} unlocked:${ng_medal.unlocked}');
		});

		ng_medal.sendUnlock((outcome) -> switch (outcome)
		{
			case SUCCESS:
				trace("call was successful");
			case FAIL(HTTP(error)):
				trace('http error: ' + error);
			case FAIL(RESPONSE(error)):
				trace('server received but failed to parse the call, error:' + error.message);
			case FAIL(RESULT(error)):
				trace('server understood the call but failed to execute it, error:' + error.message);
		});
	}

	public function get_score(board_id:Int, ?callback:(io.newgrounds.objects.Score)->Void)
	{
		if(!validate_board(board_id)) return;

		final score:io.newgrounds.objects.Score = NG.core.scoreBoards.get(board_id).scores.filter(i -> i.user.name == NG_USERNAME)[0];
		if(callback != null) callback(score);
	}

	public function post_score(score:Int, board_id:Int)
	{
		if(!validate_board(board_id)) return;

		NG.core.scoreBoards.get(board_id).postScore(Math.floor(score));
		NG.core.scoreBoards.get(board_id).requestScores();

		//trace(NG.core.scoreBoards.get(board_id).scores);
		trace("Posted to " + NG.core.scoreBoards.get(board_id).name);
	}

	function validate_board(board_id:Int):Bool
	{
		if (!NG_LOGGED_IN)
		{
			trace('Can\'t get a score if not logged in -> $board_id');
			return false;
		}

		if (!NG.core.loggedIn)
		{
			trace("not logged in");
			return false;
		}

		if (NG.core.scoreBoards == null) {
			throw "Cannot access scoreboards until ngScoresLoaded is dispatched";
			return false;
		}

		if (NG.core.scoreBoards.getById(board_id) == null) {
			throw "Invalid boardId:" + board_id;
			return false;
		}

		return true;
	}

	/**
	 * Note: Taken from Geokurelli's Advent class
	 */
	function onNGLogin(?login_callback:Void->Void):Void
	{
		trace('mark');
		NG_LOGGED_IN = true;
		NG_USERNAME = NG.core.user.name;

		NG_MR_MONEYBAGS_OVER_HERE = NG.core.user.supporter;
		NG_SESSION_ID = NGLite.getSessionId();

		Main.username = NG_USERNAME;

		trace('logged in! user:${NG_USERNAME} session: ${NG_SESSION_ID}');

		load_api_medals_part_1();
		load_api_leaderboards();
		// NG.core.scoreBoards.loadList();
		// trace(NG.core.scoreBoards == null ? null : NG.core.scoreBoards.keys());
		NG.core.medals.loadList();

		login_callback != null ? login_callback() : false;
	}

	function outcome_handler(outcome:Outcome<CallError>, ?on_success:Void->Void, ?on_failure:Void->Void)
	{
		switch (outcome)
		{
			case SUCCESS:
				trace("call was successful");
				on_success != null ? on_success() : false;
			case FAIL(HTTP(error)):
				trace('http error: ' + error);
				on_failure != null ? on_failure() : false;
			case FAIL(RESPONSE(error)):
				trace('server received but failed to parse the call, error:' + error.message);
				on_failure != null ? on_failure() : false;
			case FAIL(RESULT(error)):
				trace('server understood the call but failed to execute it, error:' + error.message);
				on_failure != null ? on_failure() : false;
		}
	}

	function load_api_medals_part_1()
	{
		#if trace_newgrounds
		trace("REQUESTING MEDALS");
		#end
		NG.core.requestMedals((outcome) -> outcome_handler(outcome, load_api_medals_part_2));
	}

	function load_api_medals_part_2()
	{
		#if trace_newgrounds
		trace("LOADING MEDAL LIST");
		#end
		NG.core.medals.loadList((outcome) -> outcome_handler(outcome, load_api_medals_part_3));
	}

	function load_api_medals_part_3()
	{
		#if trace_newgrounds
		trace("ADDING MEDAL POP UP");
		#end
		FlxG.stage.addChild(new MedalPopup());
		medal_popup(medals.get("checked-in"));
	}

	function load_api_leaderboards()
		{
			#if trace_newgrounds
			trace("REQUESTING LEADERBOARDS");
			#end
			NG.core.scoreBoards.loadList((outcome) -> outcome_handler(outcome, load_api_medals_part_2));
		}
}
#else
package ng;

class NewgroundsHandler
{
	public function new(use_medals:Bool = true, use_scoreboards:Bool = false, ?login_callback:Void->Void)
		trace("Unable to load NG content");

	public function has_medal(def:MedalDef)
		trace("Unable to load NG content");
	
	public function medal_popup(medal_def:MedalDef)
		trace("Unable to load NG content");

	public function get_score(board_id:Int)
		trace("Unable to load NG content");

	public function post_score(score:Int, board_id:Int)
		trace("Unable to load NG content");
}
#end
typedef MedalDef =
{
	var name:String;
	var id:Int;
}
