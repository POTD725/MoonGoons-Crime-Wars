extends Node
## Enforces the CW-001 Armory objective before the Relay victory can finalize.

var mission: Node
var mission_id := -1
var relay_position := Vector2(780, -250)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(_delta: float) -> void:
	var current: Node = get_tree().current_scene
	if current == null or not current.has_method("_spawn_building"):
		mission = null
		return
	if current.get_instance_id() != mission_id:
		mission = current
		mission_id = current.get_instance_id()
		relay_position = Vector2(780, -250)
	if bool(mission.get_meta("custom_match", false)):
		return
	var armory_online := false
	for building in mission.get("buildings"):
		if building.get("team", "") == "syndicate" and building.get("kind", "") == "syndicate_relay":
			relay_position = building["pos"]
		if building.get("team", "") == "authority" and building.get("kind", "") == "armory" and bool(building.get("done", false)):
			armory_online = true
	if bool(mission.get("finished")) and bool(mission.get("victory")) and not armory_online:
		mission.set("finished", false)
		mission.set("victory", false)
		mission.call("_spawn_building", "syndicate_relay", "syndicate", relay_position, true)
		mission.call("flash", "Operation protocol requires a completed Tactical Armory before the Relay can be secured.", 5.0)
