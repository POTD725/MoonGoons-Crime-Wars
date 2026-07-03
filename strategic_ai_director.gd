extends Node
## Adds escalating CPU pressure to normal RTS missions.

var mission: Node
var mission_id := -1
var clock := 0.0
var phase := 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(delta: float) -> void:
	var current: Node = get_tree().current_scene
	if current == null or not current.has_method("_spawn_unit"):
		mission = null
		return
	if current.get_instance_id() != mission_id:
		mission = current
		mission_id = current.get_instance_id()
		clock = 0.0
		phase = 0
	if mission == null or bool(mission.get("finished")):
		return
	if not bool(mission.get_meta("race_selected", false)):
		return
	if bool(mission.get_meta("custom_match", false)):
		return
	clock += delta
	var interval := 26.0 * GameDifficulty.multiplier("ai_interval", 1.0)
	if clock < interval:
		return
	clock = 0.0
	phase += 1
	_deploy_response()

func _deploy_response() -> void:
	var relay: Dictionary = {}
	for building in mission.get("buildings"):
		if building.get("team", "") == "syndicate" and building.get("kind", "") == "syndicate_relay":
			relay = building
			break
	if relay.is_empty():
		return
	var wave_size := 2 + mini(4, phase / 2)
	if GameDifficulty.active_id == "hard":
		wave_size += 1
	elif GameDifficulty.active_id == "nightmare":
		wave_size += 2
	for index in wave_size:
		var kind := "hacker" if index % 3 == 2 else "raider"
		var angle := float(index) * TAU / float(maxi(1, wave_size))
		var unit: Dictionary = mission.call("_spawn_unit", kind, "syndicate", relay["pos"] + Vector2.from_angle(angle) * 125.0)
		unit["cpu"] = true
		unit["race"] = RaceMode.chosen_rival if not RaceMode.chosen_rival.is_empty() else "lunar_cartel"
	if phase % 2 == 0:
		mission.call("flash", "Syndicate tactical response incoming. Threat level %d." % phase, 3.5)
