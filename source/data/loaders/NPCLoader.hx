package data.loaders;

using squid.util.XmlUtils;

typedef NPCDefJSON =
{
	var name:String;
	var image:String;
	var states:Map<String, NPCState>;
	var ?animations:Map<String, NPCAnimDef>;
}

typedef NPCAnimDef =
{
	var type:String;
	var sprite_anim:String;
	var png_anim:String;
}

typedef NPCState =
{
	var name:String;
	var dlg:Array<NPCDLG>;
	var ?if_flag:String;
	var ?unless_flag:String;
	var ?options:Array<NPCDLGOption>;
}

typedef NPCDLG =
{
	var text:NPCText;
	var ?if_flag:String;
	var ?unless_flag:String;
	var ?options:Array<NPCDLGOption>;
}

typedef NPCDLGOption =
{
	var label:String;
	var state:String;
}

/**Seems excessive until we start fucking with cutscenes just sayin*/
typedef NPCText =
{
	var str:String;
}

@:forward
abstract NPCDef(NPCDefJSON) from NPCDefJSON
{
	public function new(def:NPCDefJSON)
		this = def;

	public function get_current_state_dlg(default_ok:Bool = false):Array<NPCDLG>
	{
		for (state in this.states)
		{
			var if_exists:Bool = state.if_flag != null;
			var unless_exists:Bool = state.unless_flag != null;

			if (state.name != "default" && !if_exists && !unless_exists)
				continue;

			var if_check:Bool = !if_exists || Flags.get_bool(state.if_flag);
			var unless_check:Bool = !unless_exists || !Flags.get_bool(state.unless_flag);

			if (if_check && unless_check)
				if (state.name != "default" || default_ok)
					return process_dlg(state);
		}
		// run it again with default on if default ok is false
		// default ok == false is the most common starting point for NPC loading states
		return default_ok ? null : get_current_state_dlg(true);
	}

	public function get_state_dlg(state_name:String = null):Array<NPCDLG>
	{
		for (state in this.states)
			if (state.name == state_name)
				return process_dlg(state);
		return null;
	}

	function process_dlg(npc_state:NPCState):Array<NPCDLG>
	{
		var return_dlgs:Array<NPCDLG> = [];

		for (dlg in npc_state.dlg)
		{
			var if_check:Bool = dlg.if_flag == null || Flags.get_bool(dlg.if_flag);
			var unless_check:Bool = dlg.unless_flag == null || !Flags.get_bool(dlg.unless_flag);

			if (if_check && unless_check)
				return_dlgs.push(dlg);
		}

		if (npc_state.options != null)
			return_dlgs.last().options = npc_state.options;

		return return_dlgs;
	}
}

class NPCLoader
{
	public static function load_npc_defs_from_file(map:Map<String, NPCDef>, file_path:String)
	{
		var xml:Xml = Utils.file_to_xml(file_path);
		for (npc_xml in xml.tags("npc"))
			map.set(npc_xml.get("name"), xml_to_npc_def(npc_xml));
		for (element in map.get("thomas").states)
			trace(element);
	}

	static function xml_to_npc_def(npc_xml:Xml):NPCDef
	{
		var name:String = npc_xml.get("name");
		var image:String = npc_xml.get("image") != null ? npc_xml.get("image") : name;

		var def:NPCDefJSON = {
			name: name,
			image: image,
			states: parse_npc_states(npc_xml.tags("state")),
			animations: parse_npc_anims(npc_xml.tags("animation"))
		};

		// trace(haxe.Json.stringify(def, "\t"));

		return new NPCDef(def);
	}

	static function parse_npc_states(state_xmls:Array<Xml>):Map<String, NPCState>
	{
		var npc_states:Map<String, NPCState> = [];

		for (state_xml in state_xmls)
			parse_npc_state(npc_states, state_xml);

		return npc_states;
	}

	static function parse_npc_state(npc_states:Map<String, NPCState>, state_xml:Xml):NPCState
	{
		var name:String = state_xml.get("name");

		// probably an option xml
		if (name == null)
			name = state_xml.exists("state") ? state_xml.get("state") : state_xml.get("label");

		var if_flag:String = state_xml.get("if");
		var unless_flag:String = state_xml.get("unless");
		var options:String = state_xml.get("unless");

		var npc_state:NPCState = {
			name: name,
			dlg: parse_npc_dlgs(state_xml.tags("dlg"))
		};

		if (if_flag != null)
			npc_state.if_flag = if_flag;

		if (unless_flag != null)
			npc_state.unless_flag = unless_flag;

		if (state_xml.has_tags("option"))
		{
			npc_state.options = [];
			for (option_xml in state_xml.tags("option"))
			{
				npc_state.options.push({label: option_xml.get("label"), state: option_xml.exists("state") ? option_xml.get("state") : option_xml.get("label")});
				if (!npc_states.exists(npc_state.options.last().state))
					parse_npc_state(npc_states, option_xml);
			}
		}

		npc_states.set(npc_state.name, npc_state);

		return npc_state;
	}

	static function parse_npc_anims(npc_anims_xml:Array<Xml>):Map<String, NPCAnimDef>
	{
		var map:Map<String, NPCAnimDef> = new Map<String, NPCAnimDef>();
		for (npc_anim in npc_anims_xml.map((npc_anim_xml) -> parse_npc_anim(npc_anim_xml)))
			map.set(npc_anim.type, npc_anim);
		return map;
	}

	static function parse_npc_anim(npc_anim_xml:Xml):NPCAnimDef
		return {
			type: npc_anim_xml.get("type"),
			sprite_anim: npc_anim_xml.get("sprite_anim"),
			png_anim: npc_anim_xml.get("png_anim")
		};

	static function parse_npc_dlgs(dlg_xmls:Array<Xml>):Array<NPCDLG>
		return dlg_xmls.map((dlg_xml) -> parse_npc_dlg(dlg_xml));

	static function parse_npc_dlg(dlg_xml:Xml):NPCDLG
	{
		var if_flag:String = dlg_xml.get("if");
		var unless_flag:String = dlg_xml.get("unless");
		var text:NPCText = {str: dlg_xml.firstChild().toString()};

		var npc_dlg:NPCDLG = {text: text};

		if (if_flag != null)
			npc_dlg.if_flag = if_flag;

		if (unless_flag != null)
			npc_dlg.unless_flag = unless_flag;

		return npc_dlg;
	}
}
