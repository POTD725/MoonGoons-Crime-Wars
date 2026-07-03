extends Node

var last_signature: String = ""
var line_index: int = 0

const LINES: Dictionary = {
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
	var entries: Array = LINES.get(race_id, LINES["authority"]) as Array
	if entries.is_empty():
		return
	var response: String = str(entries[line_index % entries.size()])
	line_index += 1
	scene.call("flash", "RADIO // " + response, 1.35)
	RtsAudio.play_cue("select")
