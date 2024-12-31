package data.loaders;

using squid.util.XmlUtils;

typedef TankmasChroniclesPassage =
{
	var passage_name:String;
	var image_name:String;
	var sound_name:String;
	var ?next_passage:String;
	var ?choices:Array<TankmasChroniclesChoice>;
	var ?victory_royale:String;
	var ?game_over:String;
}

typedef TankmasChroniclesChoice =
{
	var choice_name:String;
	var link_passage:String;
}

class TankmasChroniclesLoader
{
	public static function load_tankmas_chronicles_from_file(passages:Map<String, TankmasChroniclesPassage>, file_path:String)
	{
		var xml:Xml = Utils.file_to_xml(file_path);
		var choices:Map<String, TankmasChroniclesChoice> = new Map<String, TankmasChroniclesChoice>();

		for (choice_xml in xml.tags("choice"))
			choices.set(choice_xml.get("name"), xml_to_tankmas_chronicles_choice(choice_xml));

		for (passage_xml in xml.tags("passage"))
			passages.set(passage_xml.get("name"), xml_to_tankmas_chronicles_passage(passage_xml, choices));
	}

	static function xml_to_tankmas_chronicles_passage(passage_xml:Xml, choices:Map<String, TankmasChroniclesChoice>):TankmasChroniclesPassage
	{
		var passage_name:String = passage_xml.get("name");
		var image_name:String = passage_xml.exists("image") ? passage_xml.get("image") : passage_name;
		var sound_name:String = passage_xml.exists("sound") ? passage_xml.get("sound") : passage_name;

		var passage:TankmasChroniclesPassage = {
			passage_name: passage_name,
			image_name: sound_name,
			sound_name: image_name,
			choices: [],
		};

		if (passage_xml.exists("next"))
			passage.next_passage = passage_xml.get("next");

		if (passage_xml.exists("victory"))
			passage.victory_royale = passage_xml.get("victory");

		if (passage_xml.exists("game_over"))
			passage.game_over = passage_xml.get("game_over");

		if (passage_xml.exists("choices"))
			for (choice_name in passage_xml.get("choices").split(","))
				passage.choices.push(choices.get(choice_name));

		passage.victory_royale = passage_xml.get("victory");

		// trace(haxe.Json.stringify(def, "\t"));
		return passage;
	}

	static function xml_to_tankmas_chronicles_choice(choice_xml:Xml):TankmasChroniclesChoice
	{
		var choice_name:String = choice_xml.get("name");
		var link_passage:String = choice_xml.get("link");

		var choice:TankmasChroniclesChoice = {
			choice_name: choice_name,
			link_passage: link_passage
		};

		return choice;
	}

	public static inline function get_linked_passage(choice:TankmasChroniclesChoice, passages:Map<String, TankmasChroniclesPassage>):TankmasChroniclesPassage
		return passages.get(choice.link_passage);
}
