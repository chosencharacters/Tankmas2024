package data.types;

import data.types.TankmasDefs.CostumeDef;
import data.types.TankmasDefs.SpriteAnimationDef;

enum abstract UnlockCondition(String) from String to String
{
	/**On a specific date, data contains the unix timestamp, see: https://www.unixtimestamp.com/index.php**/
	final DATE;

	/**Checks if you have an achievement, by achievement name*/
	final ACHIEVEMENT;

	/**Always true, because you're always a special little boy. This is the same as no unlock condition at all (i.e. null)*/
	final YOUR_A_SPECIAL_LITTLE_BOY;

	/**Always false >:(*/
	final ANGRY_FAIC;

	/**Checks on flag, data is a String representing flag(s)*/
	final FLAG;

	public static inline function get_unlocked(condition:UnlockCondition, data:Dynamic):Bool
		switch (cast(condition, UnlockCondition))
		{
			default:
				return true;
			case UnlockCondition.YOUR_A_SPECIAL_LITTLE_BOY:
				return true;
			case UnlockCondition.ANGRY_FAIC:
				return false;
			case UnlockCondition.DATE:
				return Date.now().getTime() >= data; // where data is a unix timestamp, see above
			case UnlockCondition.ACHIEVEMENT:
				#if newgrounds return Main.ng_api.has_medal(Main.ng_api.medals.get(data)) #else return false #end; // where data is the name of a medal
			case UnlockCondition.FLAG:
				return Flags.get(data);
		}
}

/**
 * Enum of fixed player animations, probably will be moved
 */
enum abstract PlayerAnimation(SpriteAnimationDef) from SpriteAnimationDef to SpriteAnimationDef
{
	public static final IDLE:SpriteAnimationDef = {
		name: "idle",
		fps: Utils.ms_to_frames_per_second("40ms"),
		looping: true,
		frames: [
			{
				duration: 1,
				x: 0,
				y: 0,
				angle: 0,
				height: 1.0,
				width: 1.0
			}
		]
	};

	public static final MOVING:SpriteAnimationDef = {
		name: "moving",
		fps: Utils.ms_to_frames_per_second("40ms"),
		looping: true,
		frames: [
			{
				duration: 2,
				x: -5,
				y: -16,
				angle: 7
			},
			{
				duration: 2,
				y: -20,
			},
			{
				duration: 3,
				x: 0,
				y: 0,
				angle: 0
			},
			{
				duration: 2,
				x: 5,
				y: -16,
				angle: -7
			},
			{
				duration: 2,
				y: -20,
			},
			{
				duration: 3,
				x: 0,
				y: 0,
				angle: 0
			},
		]
	};

	public static final START_STOP:SpriteAnimationDef = {
		name: "start-stop",
		fps: Utils.ms_to_frames_per_second("40ms"),
		looping: false,
		frames: [
			{
				duration: 3,
				x: 0,
				y: 0,
				angle: 0,
				height: 1.0,
				width: 1.0
			},
			{
				duration: 5,
				x: 0,
				y: -10,
				angle: -10,
			},
			{
				duration: 5,
				x: 0,
				y: -5,
				angle: 5,
			},
		]
	};
}

/**
 * Enum of fixed player animations, probably will be moved
 */
enum abstract PresentAnimation(SpriteAnimationDef) from SpriteAnimationDef to SpriteAnimationDef
{
	public static final IDLE:SpriteAnimationDef = {
		name: "idle",
		fps: Utils.ms_to_frames_per_second("40ms"),
		looping: true,
		frames: [
			{
				duration: 1,
				x: 0,
				y: 0,
				angle: 0,
				height: 1.0,
				width: 1.0
			}
		]
	};

	public static final NEARBY:SpriteAnimationDef = {
		name: "nearby",
		fps: Utils.ms_to_frames_per_second("40ms"),
		looping: true,
		frames: [
			{
				duration: 2,
				x: 0,
				y: 0,
				angle: 0,
				height: 1.0,
				width: 1.0,
				frameNum: 0
			}, // frame 1
			{
				duration: 2,
				height: 1.2,
			}, // frame 4
			{
				duration: 2,
				y: -36,
				height: 0.9,
				angle: -15
			}, // frame 6
			{
				duration: 2,
				height: 1.2,
				angle: 15,
				y: -46
			}, // frame 8
			{
				duration: 2,
				height: 1,
				angle: -15
			}, // frame 10
			{
				duration: 2,
				angle: 15,
				y: -50
			}, // frame 12
			{
				duration: 2,
				angle: -15,
				y: -53
			}, // frame 13
			{
				duration: 2,
				angle: 15,
				y: -56
			}, // frame 15
			{
				duration: 3,
				height: 1.2,
				angle: -12,
				y: -40
			}, // frame 18
			{
				duration: 1,
				height: 1.5,
				angle: 0,
				y: -40,
			}, // frame 19
			{
				duration: 2,
				y: -20,
			}, // frame 21
			{
				duration: 1,
				height: 0.7,
				y: 10,
			}, // frame 22 + extra bounce not in anim
			{
				duration: 1,
				height: 1,
				y: -10,
			},
			{
				duration: 1,
				y: -6,
			},
			{
				duration: 5,
				height: 1,
				y: 0
			},
		]
	};

	public static final OPENING:SpriteAnimationDef = {
		name: "opening",
		fps: Utils.ms_to_frames_per_second("40ms"),
		looping: true,
		frames: [
			{
				duration: 2,
				x: 0,
				y: 0,
				angle: 0,
				height: 0.8,
				width: 1.0,
				frameNum: 0
			},
			{
				duration: 2,
				height: 0.7,
			},
			{
				duration: 2,
				y: -36,
				height: 1.4,
			}, // frame 6
			{
				duration: 2,
				height: 1.3,
				y: -46,
				frameNum: 1
			}, // frame 8
			{
				duration: 2,
				height: 1.1,
			}, // frame 10
			{
				duration: 2,
				y: -50
			}, // frame 12
			{
				duration: 2,
				y: -53
			}, // frame 13
			{
				duration: 2,
				y: -56
			}, // frame 15
			{
				duration: 3,
				height: 1.2,
				y: -40
			}, // frame 18
			{
				duration: 1,
				height: 1.5,
				y: -40,
			}, // frame 19
			{
				duration: 2,
				y: -20,
			}, // frame 21
			{
				duration: 1,
				height: 0.7,
				y: 10,
			}, // frame 22 + extra bounce not in anim
			{
				duration: 1,
				height: 1,
				y: -10,
			},
			{
				duration: 1,
				y: -6,
			},
			{
				duration: 5,
				height: 1,
				y: 0
			},
		]
	};

	public static final OPENED:SpriteAnimationDef = {
		name: "opened",
		fps: Utils.ms_to_frames_per_second("40ms"),
		looping: true,
		frames: [
			{
				duration: 1,
				x: 0,
				y: 0,
				angle: 0,
				height: 1.0,
				width: 1.0,
				frameNum: 1
			}
		]
	};
}
