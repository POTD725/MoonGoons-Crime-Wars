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

	root.call("_spawn_node", "ore", Vector2(-550, 210), 980)
	root.call("_spawn_node", "ore", Vector2(-420, -95), 720)
	root.call("_spawn_node", "evidence", Vector2(90, 280), 480)
	root.call("_spawn_node", "ore", Vector2(210, -155), 930)
	root.call("_spawn_node", "evidence", Vector2(480, 150), 520)

	_tag(root.call("_spawn_building", "nexus", PLAYER_TEAM, Vector2(-260, 145), true), race_id)
	for position in [Vector2(-166,180), Vector2(-215,245), Vector2(-310,255)]:
		_tag(root.call("_spawn_unit", "drone", PLAYER_TEAM, position), race_id)
	for position in [Vector2(-145,92), Vector2(-332,78)]:
		_tag(root.call("_spawn_unit", "deputy", PLAYER_TEAM, position), race_id)
	_tag(root.call("_spawn_unit", "hero", PLAYER_TEAM, Vector2(-250, 55)), race_id)
	if race_id == "hollow_fang":
		_tag(root.call("_spawn_unit", "shield", PLAYER_TEAM, Vector2(-370, 170)), race_id)
	elif race_id == "null_choir":
		_tag(root.call("_spawn_unit", "deputy", PLAYER_TEAM, Vector2(-365, 170)), race_id)

	_tag(root.call("_spawn_building", "syndicate_relay", ENEMY_TEAM, Vector2(780, -250), true), rival_id)
	for position in [Vector2(675,-180), Vector2(845,-145), Vector2(895,-330)]:
		_tag(root.call("_spawn_unit", "raider", ENEMY_TEAM, position), rival_id)
	for position in [Vector2(740,-385), Vector2(990,-250)]:
		_tag(root.call("_spawn_unit", "hacker", ENEMY_TEAM, position), rival_id)

	_install_visual_layer()
	root.call("flash", "%s deployed. %s" % [RaceCatalog.get_name(race_id), RaceCatalog.get_construction(race_id)], 8.0)

func _tag(entity: Dictionary, race_id: String) -> void:
	if not entity.is_empty():
		entity["race"] = race_id
