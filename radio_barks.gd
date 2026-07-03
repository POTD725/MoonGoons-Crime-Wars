extends Node
## Text-radio callouts paired with synthesized order tones.

var last_signature: String = ""
var bark_index: int = 0

const BARKS: Dictionary = {
	"authority": ["Deputy ready.", "Perimeter secured.", "Command acknowledged.", "Moving to sector."],
	"lunar_cartel": ["Cargo is moving.", "Dockside is ours.", "You pay, we play.", "No witnesses."],
	"null_choir": ["Signal received.", "Pattern expanding.", "The echo answers.", "Node aligned."],
	"hollow_fang": ["Boarding route set.", "Break the lock.", "Take their engines.", "War-rig rolling."]
}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(_delta: float) -> void:
	var scene: Node = get_tree().current_scene
	if scene == null or not scene.has_method("_entity"):
		last_signature = ""
		return
	var selection: Array = scene.get("selected") as Array
	var building_id: int = int(scene.get("selected_building"))
	var signature: String = str(scene.get_instance_id()) + ":" + str(selection) + ":" + str(building_id)
	if signature == last_signature:
		return
	last_signature = signature
	if selection.is_empty() and building_id == -1:
		return
	var race_id: String = "authority"
	if RaceMode != null and not RaceMode.chosen_race.is_empty():
		race_id = RaceMode.chosen_race
	var lines: Array = BARKS.get(race_id, BARKS["authority"]) as Array
	if lines.is_empty():
		return
	var line: String = str(lines[bark_index % lines.size()])
	bark_index += 1
	scene.call("flash", "RADIO // " + line, 1.35)
	RtsAudio.play_cue("select")
