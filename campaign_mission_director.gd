extends Node
## Campaign-only mission dressing implemented by composition, not another scene inheritance layer.

var prepared_scene_id: int = -1

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(_delta: float) -> void:
	var scene: Node = get_tree().current_scene
	if scene == null or bool(scene.get_meta("custom_match", false)) or not scene.has_meta("campaign_mission_id"):
		prepared_scene_id = -1
		return
	if scene.get_instance_id() == prepared_scene_id:
		return
	prepared_scene_id = scene.get_instance_id()
	_prepare_mission(scene, str(scene.get_meta("campaign_mission_id", "CW-001")))

func _prepare_mission(scene: Node, mission_id: String) -> void:
	match mission_id:
		"CW-002":
			_prepare_quiet_cargo(scene)
		"CW-003":
			_prepare_cinder_row(scene)
		_:
			scene.call("flash", "OPERATION BREAKWATER // Destroy the Syndicate Relay and secure the district.", 4.0)

func _prepare_quiet_cargo(scene: Node) -> void:
	var player_spawn: Vector2 = scene.get("active_map").get("player_spawn", Vector2(-1750.0, 720.0)) as Vector2
	var relay_spawn: Vector2 = scene.get("active_map").get("relay_spawn", Vector2(1950.0, -980.0)) as Vector2
	var middle: Vector2 = player_spawn.lerp(relay_spawn, 0.52)
	_spawn_resource(scene, "evidence", middle + Vector2(-420.0, 260.0), 600)
	_spawn_resource(scene, "evidence", middle + Vector2(160.0, -230.0), 680)
	_spawn_resource(scene, "evidence", relay_spawn + Vector2(-520.0, 350.0), 540)
	_spawn_guard(scene, "raider", middle + Vector2(-320.0, 220.0))
	_spawn_guard(scene, "hacker", middle + Vector2(200.0, -170.0))
	scene.call("flash", "THE QUIET CARGO // Recover 80 Intel from secured Evidence Caches in the Underhive.", 5.0)

func _prepare_cinder_row(scene: Node) -> void:
	var player_spawn: Vector2 = scene.get("active_map").get("player_spawn", Vector2(-1750.0, 720.0)) as Vector2
	var relay_spawn: Vector2 = scene.get("active_map").get("relay_spawn", Vector2(1950.0, -980.0)) as Vector2
	var middle: Vector2 = player_spawn.lerp(relay_spawn, 0.5)
	_spawn_resource(scene, "alloy", player_spawn + Vector2(420.0, -240.0), 520)
	_spawn_resource(scene, "ore", middle + Vector2(-100.0, 260.0), 900)
	_spawn_resource(scene, "evidence", middle + Vector2(280.0, -220.0), 500)
	_spawn_guard(scene, "raider", middle + Vector2(250.0, 120.0))
	_spawn_guard(scene, "raider", middle + Vector2(-220.0, -160.0))
	scene.call("flash", "BLACKOUT AT CINDER ROW // Build three Communications Relays, then hold the district for 120 seconds.", 5.0)

func _spawn_resource(scene: Node, kind: String, preferred: Vector2, amount: int) -> void:
	if not scene.has_method("_spawn_node"):
		return
	var location: Vector2 = preferred
	if scene.has_method("_find_open_resource_location"):
		location = scene.call("_find_open_resource_location", preferred) as Vector2
	if location == Vector2.INF:
		return
	scene.call("_spawn_node", kind, location, amount)

func _spawn_guard(scene: Node, kind: String, preferred: Vector2) -> void:
	if not scene.has_method("_spawn_unit"):
		return
	var location: Vector2 = preferred
	if scene.has_method("_find_open_resource_location"):
		var safe_location: Vector2 = scene.call("_find_open_resource_location", preferred) as Vector2
		if safe_location != Vector2.INF:
			location = safe_location
	var unit: Dictionary = scene.call("_spawn_unit", kind, "syndicate", location) as Dictionary
	if not unit.is_empty():
		unit["order"] = "attack_move"
