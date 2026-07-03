extends Node
## Expands the local War Room configuration into a stronger CPU skirmish.

var configured_scene_id: int = -1

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(_delta: float) -> void:
	var scene: Node = get_tree().current_scene
	if scene == null or not scene.has_method("_spawn_unit") or not scene.has_method("_relay"):
		return
	if scene.get_instance_id() == configured_scene_id:
		return
	if not bool(scene.get_meta("custom_match", false)):
		return
	configured_scene_id = scene.get_instance_id()
	_configure_skirmish(scene)

func _configure_skirmish(scene: Node) -> void:
	var relay: Dictionary = scene.call("_relay") as Dictionary
	if relay.is_empty():
		return
	var cpu_count: int = clampi(MatchState.bots, 1, 7)
	var relay_position: Vector2 = relay["pos"] as Vector2
	for index: int in cpu_count * 2:
		var angle: float = float(index) * TAU / float(maxi(1, cpu_count * 2))
		var distance_value: float = 155.0 + float(index % 3) * 42.0
		var kind: String = "hacker" if index % 4 == 3 else "raider"
		var unit: Dictionary = scene.call("_spawn_unit", kind, "syndicate", relay_position + Vector2.from_angle(angle) * distance_value) as Dictionary
		unit["race"] = MatchState.opposing_race
	var scenario: String = MatchState.selected_mode
	if scenario == "Resource Rush":
		scene.call("_spawn_node", "ore", Vector2(-20.0, -340.0), 1100)
		scene.call("_spawn_node", "ore", Vector2(375.0, 325.0), 1100)
		scene.set("credits", int(scene.get("credits")) + 180)
	elif scenario == "King of the Relay":
		scene.call("_spawn_node", "evidence", Vector2(88.0, -10.0), 1400)
		scene.set("intel", int(scene.get("intel")) + 50)
	elif scenario == "Sudden Death":
		scene.set("credits", maxi(220, int(scene.get("credits")) - 170))
		for index: int in 4:
			var angle: float = float(index) * TAU / 4.0
			scene.call("_spawn_unit", "raider", "syndicate", relay_position + Vector2.from_angle(angle) * 240.0)
	scene.set_meta("skirmish_map", MatchState.selected_map)
	scene.call("flash", "CUSTOM SKIRMISH // " + MatchState.selected_map + " // " + MatchState.selected_mode + " // " + str(cpu_count) + " CPU COMMANDERS", 5.0)
