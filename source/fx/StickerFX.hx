package fx;

import data.types.TankmasDefs.SpriteAnimationDef;
import entities.base.NGSprite;
import squid.util.Utils;
import states.PlayState;

class StickerFX extends NGSprite
{
	var idle_time:Int = 60;
	var parent:NGSprite;
	var cover:NGSprite;

	/*since offset is actually used by animations*/
	var base_emote_offset_y:Int = -16;

	var on_complete:Void->Void;

	public function new(parent:NGSprite, name:String, on_complete:Void->Void)
	{
		super(Paths.get(name + ".png"));
		cover = new NGSprite(Paths.get("sticker-cover.png"));

		this.on_complete = on_complete;

		this.parent = parent;

		PlayState.self.stickers.add(this);
		PlayState.self.sticker_fx.add(cover);

		sstate(IN);

		trace_new_state = true;
	}

	override function updateMotion(elapsed:Float)
	{
		this.center_on_top(parent);
		this.y = y + base_emote_offset_y;

		cover.center_on(this);

		super.updateMotion(elapsed);
	}

	override function update(elapsed:Float)
	{
		fsm();
		super.update(elapsed);
	}

	function fsm()
		switch (cast(state, State))
		{
			case IN:
				cover.sprite_anim.anim(StickerAnimations.IN);
				sprite_anim.anim(StickerAnimations.IN);
				switch (sprite_anim.frame_num)
				{
					case 0:
						cover.alpha = 1;
					case 1:
						cover.alpha = 0.5;
					case 2:
						cover.alpha = 0;
				}
				if (sprite_anim.finished)
					sstate(IDLE);
			case IDLE:
				cover.sprite_anim.anim(StickerAnimations.IDLE);
				sprite_anim.anim(StickerAnimations.IDLE);
				if (ttick() > idle_time)
					sstate(OUT);
			case OUT:
				cover.sprite_anim.anim(StickerAnimations.OUT);
				sprite_anim.anim(StickerAnimations.OUT);
				switch (sprite_anim.frame_num)
				{
					case 0:
						cover.alpha = 0;
					case 1:
						cover.alpha = 0.5;
					case 2:
						cover.alpha = 1;
				}
				if (sprite_anim.finished)
					kill();
		}

	override function kill()
	{
		super.kill();
		cover.kill();
		on_complete != null ? on_complete() : null;
	}
}

private enum abstract State(String) from String to String
{
	var IN;
	var IDLE;
	var OUT;
}

enum abstract StickerAnimations(SpriteAnimationDef) from SpriteAnimationDef to SpriteAnimationDef
{
	public static final IN:SpriteAnimationDef = {
		name: "in",
		fps: Utils.ms_to_frames_per_second("40ms"),
		looping: false,
		frames: [
			{
				duration: 1,
				y: 20,
				height: 0.3
			},
			{
				duration: 1,
				// x: 5,
				y: -10,
				height: 0.5
			},
			{
				duration: 2,
				// x: -5,
				y: 20,
				height: 0.75,
			},
			{
				duration: 2,
				y: -40,
				height: 0.75,
			}
		]
	};

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

	public static final OUT:SpriteAnimationDef = {
		name: "out",
		fps: Utils.ms_to_frames_per_second("40ms"),
		looping: false,
		frames: [
			{
				duration: 2,
				x: 0,
				y: -10,
				angle: 0,
				height: 1,
				width: 1.0
			},
			{
				duration: 2,
				y: 10,
				angle: 0,
				height: 0.5,
			},
			{
				duration: 2,
				y: -10,
				height: 0.15,
			}
		]
	};
}
