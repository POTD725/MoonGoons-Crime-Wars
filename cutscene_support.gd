extends Node
## Small support layer for CutsceneDirector.
## Keeps dialogue UI hidden outside scenes and plays mission-specific stingers
## independently from the looping cutscene ambience.

var cue_player: AudioStreamPlayer
var previous_active := false
var previous_line := -1

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	cue_player = AudioStreamPlayer.new()
	cue_player.volume_db = -8.0
	add_child(cue_player)

func _process(_delta: float) -> void:
	var director := get_node_or_null("/root/CutsceneDirector")
	if director == null:
		return
	var active: bool = bool(director.get("is_playing"))
	for node_name in ["name_label", "faction_label", "dialogue_label", "continue_label"]:
		var node: CanvasItem = director.get(node_name)
		if node != null:
			node.visible = active
	if active and not previous_active:
		previous_line = int(director.get("sequence_index"))
		_play_stinger(director)
	elif active and int(director.get("sequence_index")) != previous_line:
		previous_line = int(director.get("sequence_index"))
	previous_active = active

func _play_stinger(director: Node) -> void:
	var lines: Array = director.get("sequence")
	if lines.is_empty():
		return
	var text := str(lines[0].get("text", ""))
	var path := ""
	if "Breakwater is not a raid" in text:
		path = "res://audio/mission_deploy.wav"
	elif "Authority comms are bright" in text:
		path = "res://audio/mission_alert.wav"
	elif "Relay destroyed" in text:
		path = "res://audio/mission_victory.wav"
	elif "Their Nexus went dark" in text:
		path = "res://audio/mission_failure.wav"
	if not path.is_empty() and ResourceLoader.exists(path):
		cue_player.stream = load(path)
		cue_player.play()
