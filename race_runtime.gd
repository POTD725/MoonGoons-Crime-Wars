extends Node

const PLAYER_TEAM := "authority"
const ENEMY_TEAM := "syndicate"

var root: Node
var root_id := -1
var chosen_race := ""
var chosen_rival := ""
var passive_clock := 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_picker()

func _process(delta: float) -> void:
	var mission := _mission_root()
	if mission == null:
		return
	if mission.get_instance_id() != root_id:
		root = mission
		root_id = mission.get_instance_id()
		chosen_race = ""
		chosen_rival = ""
		passive_clock = 0.0
		_show_picker()
		return
	if chosen_race.is_empty() or bool(root.get("finished")):
		return
	passive_clock += delta
	if passive_clock >= 1.0:
		passive_clock = 0.0
		_apply_passive_income()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F1:
		_show_picker()
		get_viewport().set_input_as_handled()

func _mission_root() -> Node:
	var current := get_tree().current_scene
	if current != null and current.has_method("_spawn_unit") and current.has_method("_spawn_building"):
		return current
	return null

func _choose(race_id: String) -> void:
	chosen_race = race_id
	chosen_rival = RaceCatalog.get_rival(race_id)
	_reset_mission(race_id, chosen_rival)
	root.set_meta("race_selected", true)
	root.set_meta("race_selecting", false)
	_hide_picker()
	get_tree().paused = false
	_start_faction_briefing(race_id, chosen_rival)

func _reset_mission(race_id: String, rival_id: String) -> void:
	Engine.time_scale = 1.0
	root.get("units").clear()
	root.get("buildings").clear()
	root.get("nodes").clear()
	root.set("selected", [])
	root.set("selected_building", -1)
	root.set("next_id", 1)
	root.set("build_kind", "")
	root.set("finished", false)
	root.set("victory", false)
	root.set("credits", 520 if race_id == "lunar_cartel" else 440)
	root.set("supplies", 230 if race_id == "hollow_fang" else 180)
	root.set("intel", 40 if race_id == "null_choir" else 10)
	root.set("B", RaceSpecs.buildings_for(race_id, rival_id))
	root.set("U", RaceSpecs.units_for(race_id, rival_id))

	var map_data := PvpMaps.get_active()
	var map_id := PvpMaps.active_map_id
	root.set_meta("pvp_map_id", map_id)
	root.set_meta("pvp_map_name", str(map_data["name"]))
	for node_info in map_data.get("nodes", []):
		root.call("_spawn_node", str(node_info[0]), node_info[1], int(node_info[2]))

	var spawns: Array = map_data.get("spawns", [Vector2(-780,180), Vector2(780,-180)])
	var player_spawn: Vector2 = spawns[0]
	var enemy_spawn: Vector2 = spawns[1] if spawns.size() > 1 else Vector2(780,-180)
	root.set("cam", player_spawn + Vector2(130, -40))

	_tag(root.call("_spawn_building", "nexus", PLAYER_TEAM, player_spawn, true), race_id)
	for offset in [Vector2(94,36), Vector2(20,105), Vector2(-72,100)]:
		_tag(root.call("_spawn_unit", "drone", PLAYER_TEAM, player_spawn + offset), race_id)
	for offset in [Vector2(100,-66), Vector2(-92,-58)]:
		_tag(root.call("_spawn_unit", "deputy", PLAYER_TEAM, player_spawn + offset), race_id)
	_tag(root.call("_spawn_unit", "hero", PLAYER_TEAM, player_spawn + Vector2(0,-105)), race_id)
	if race_id == "hollow_fang":
		_tag(root.call("_spawn_unit", "shield", PLAYER_TEAM, player_spawn + Vector2(-128,30)), race_id)
	elif race_id == "null_choir":
		_tag(root.call("_spawn_unit", "deputy", PLAYER_TEAM, player_spawn + Vector2(-128,30)), race_id)

	_tag(root.call("_spawn_building", "syndicate_relay", ENEMY_TEAM, enemy_spawn, true), rival_id)
	for offset in [Vector2(-105,56), Vector2(88,74), Vector2(102,-70)]:
		_tag(root.call("_spawn_unit", "raider", ENEMY_TEAM, enemy_spawn + offset), rival_id)
	for offset in [Vector2(-55,-112), Vector2(132,-18)]:
		_tag(root.call("_spawn_unit", "hacker", ENEMY_TEAM, enemy_spawn + offset), rival_id)

	_install_visual_layer()
	_install_map_visual_layer(map_id)
	root.call("flash", "MAP // %s  •  %s  •  %s resources" % [str(map_data["name"]), str(map_data["pace"]), str(map_data["resources"])], 8.0)

func _tag(entity: Dictionary, race_id: String) -> void:
	if not entity.is_empty():
		entity["race"] = race_id

func _install_map_visual_layer(map_id: String) -> void:
	var layer := root.get_node_or_null("PvpMapVisuals")
	if layer == null:
		var visual_script := load("res://pvp_map_visuals.gd")
		layer = visual_script.new()
		layer.name = "PvpMapVisuals"
		root.add_child(layer)
	layer.call("configure", root, map_id)
