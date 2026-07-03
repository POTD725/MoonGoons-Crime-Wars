extends Node
## Applies GameDifficulty to every playable mode without duplicating rules in each scene.

var watched_scene_id := -1
var last_completed_recon := 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(delta: float) -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return
	if scene.get_instance_id() != watched_scene_id:
		watched_scene_id = scene.get_instance_id()
		last_completed_recon = 0
	if scene.has_method("_spawn_unit") and scene.has_method("_spawn_building"):
		_apply_rts_difficulty(scene)
	elif scene.has_method("_complete_recon") and scene.has_method("_nearest_site"):
		_apply_free_roam_difficulty(scene, delta)

func _apply_rts_difficulty(root: Node) -> void:
	var ready_for_scaling := bool(root.get_meta("race_selected", false)) or bool(root.get_meta("custom_match", false))
	if not ready_for_scaling or bool(root.get_meta("difficulty_applied", false)):
		return
	var player_health := GameDifficulty.multiplier("player_health")
	var player_damage := GameDifficulty.multiplier("player_damage")
	var ai_health := GameDifficulty.multiplier("ai_health")
	var ai_damage := GameDifficulty.multiplier("ai_damage")
	for unit in root.get("units"):
		var is_cpu := bool(unit.get("cpu", false)) or unit.get("team", "") == "syndicate"
		var health_scale := ai_health if is_cpu else player_health
		var damage_scale := ai_damage if is_cpu else player_damage
		unit["hp"] = float(unit["hp"]) * health_scale
		unit["max"] = float(unit["max"]) * health_scale
		unit["damage"] = max(0, int(round(float(unit["damage"]) * damage_scale)))
	for building in root.get("buildings"):
		var is_cpu := bool(building.get("cpu", false)) or building.get("team", "") == "syndicate"
		var health_scale := ai_health if is_cpu else player_health
		building["hp"] = float(building["hp"]) * health_scale
		building["max"] = float(building["max"]) * health_scale
	var resource_scale := GameDifficulty.multiplier("start_multiplier")
	root.set("credits", int(round(float(root.get("credits")) * resource_scale)))
	root.set("supplies", int(round(float(root.get("supplies")) * resource_scale)))
	root.set("intel", int(round(float(root.get("intel")) * resource_scale)))
	root.set_meta("difficulty_applied", true)
	root.call("flash", "DIFFICULTY // " + GameDifficulty.get_name(), 3.0)

func _apply_free_roam_difficulty(scene: Node, delta: float) -> void:
	var patrol_speed := GameDifficulty.multiplier("patrol_speed")
	if patrol_speed != 1.0:
		for patrol in scene.get("patrols"):
			var phase: float = patrol.get("phase", 0.0)
			patrol["pos"] += Vector2(cos(phase * 0.8), sin(phase * 0.53)) * delta * 22.0 * (patrol_speed - 1.0)
	var complete := 0
	for site in scene.get("recon_sites"):
		if bool(site.get("complete", false)):
			complete += 1
	if complete > last_completed_recon:
		var multiplier := GameDifficulty.multiplier("recon_reward")
		var gained := complete - last_completed_recon
		var intel_delta := int(round(12.0 * multiplier)) - 12
		var credit_delta := int(round(80.0 * multiplier)) - 80
		scene.set("intel", max(0, int(scene.get("intel")) + intel_delta * gained))
		scene.set("credits", max(0, int(scene.get("credits")) + credit_delta * gained))
		scene.call("flash", "Difficulty reward modifier applied: " + GameDifficulty.get_name(), 2.5)
	last_completed_recon = complete
