#if newgrounds
package ng;

import io.newgrounds.Call.CallError;
import io.newgrounds.Call.CallOutcome;
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

	public var NG_USERNAME:String = "";
	public var NG_SESSION_ID:String = null;

	public var NG_MR_MONEYBAGS_OVER_HERE:Bool;

	public var medals:Map<String, MedalDef> = [];

	public function new() {}

	public function init(login_callback:Void->Void, on_ng_passport_requested:Void->Void)
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
			load_medal_defs();
			login(login_callback, on_ng_passport_requested);
		}
		catch (e)
		{
			#if dev
			throw e;
			#else
			trace(e);
			#end
		}
	}

	function login(login_callback:Void->Void, on_ng_passport_required:Void->Void)
	{
		var json = haxe.Json.parse(Utils.load_file_string(Paths.get("ng-secrets.json")));

		var app_id = json.app_id;
		var encryption_key = json.encryption_key;

		var session_id = NGLite.getSessionId();
		if (session_id != null && session_id != "")
		{
			NG_SESSION_ID = session_id;
		}

		NG.create(app_id, NG_SESSION_ID);

		NG.core.setupEncryption(encryption_key, AES_128, BASE_64);
		NG.core.onLogin.add(() -> onNGLogin(login_callback), true);

		if (NG_SESSION_ID != null)
		{
			// If we have a session ID (either directly from the newgrounds URL, or one saved locally),
			// check if it's still valid.
			NG.core.calls.app.checkSession().addOutcomeHandler(outcome ->
			{
				switch (outcome)
				{
					case FAIL(error):
						// If session is invalid/expired,
						create_new_session(on_ng_passport_required);
					default:
				}
			}).send();

			return;
		}

		// No session found, gotta use newgrounds passport.
		create_new_session(on_ng_passport_required);
	}

	var ng_passport_url:String = null;

	function create_new_session(on_ng_passport_required:Void->Void)
	{
		NG.core.requestLogin(null, (passport_url) ->
		{
			this.ng_passport_url = passport_url;
			on_ng_passport_required();
		});
	}

	public function launch_newgrounds_passport()
	{
		FlxG.openURL(ng_passport_url);
		NG.core.onPassportUrlOpen();
	}

	function load_medal_defs()
	{
		var json:{medals:Array<MedalDef>} = haxe.Json.parse(Utils.load_file_string(Paths.get("medals.json")));
		if (json?.medals == null)
			return;

		for (medal in json.medals)
			medals.set(medal.name, medal);
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

		if (medal_def == null)
		{
			var message = "No medal definition provided. Can't unlock it.";
			#if debug
			throw message;
			#else
			trace(message);
			#end
			return;
		}

		NG.core.verbose = true;

		var ng_medal:Medal = NG.core.medals.get(medal_def.id);

		if (ng_medal == null)
		{
			var message = 'Could not find medal with ID ${medal_def}.';
			#if debug
			throw message;
			#else
			trace(message);
			#end
			return;
		}

		trace('${ng_medal.name} [${ng_medal.id}] is worth ${ng_medal.value} points!');

		if (ng_medal.unlocked)
		{
			trace('${ng_medal.name} is already unlocked!');
			return;
		}

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

	public function post_score(score:Int, board_id:Int)
	{
		if (!NG_LOGGED_IN)
		{
			trace('Can\'t get a score if not logged in $score -> $board_id');
			return;
		}

		if (!NG.core.loggedIn)
		{
			trace("not logged in");
			return;
		}

		if (NG.core.scoreBoards == null)
			throw "Cannot access scoreboards until ngScoresLoaded is dispatched";
		if (NG.core.scoreBoards.getById(board_id) == null)
		{
			trace("Invalid boardId:" + board_id);
			return;
		}

		NG.core.scoreBoards.get(board_id).postScore(Math.floor(score));
		NG.core.scoreBoards.get(board_id).requestScores();

		trace(NG.core.scoreBoards.get(board_id).scores);
		trace("Posted to " + NG.core.scoreBoards.get(board_id));
	}

	/**
	 * Note: Taken from Geokurelli's Advent class
	 */
	function onNGLogin(?login_callback:Void->Void):Void
	{
		NG_LOGGED_IN = true;
		NG_USERNAME = NG.core.user.name;
		NG_LOGGED_IN = true;

		NG_MR_MONEYBAGS_OVER_HERE = NG.core.user.supporter;
		NG_SESSION_ID = NG.core.sessionId;

		Main.username = NG_USERNAME;
		Main.session_id = NG_SESSION_ID;

		trace('logged in! user:${NG_USERNAME} session: ${NG_SESSION_ID}');

		load_api_medals_part_1();
		NG.core.scoreBoards.loadList();
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
		// medal_popup(medals.get("test-medal"));
	}
}

typedef MedalDef =
{
	var name:String;
	var id:Int;
}
#end
