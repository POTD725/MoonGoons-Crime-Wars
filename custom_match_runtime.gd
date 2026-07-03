extends Node
## Builds a two-team custom battle from CustomMatchConfig.
## The current RTS controller uses Authority and Syndicate teams internally.

const TEAM_A := "authority"
const TEAM_B := "syndicate"

func launch(root: Node) -> void:
	var config := CustomMatchConfig
	var scenario: Dictionary = config.scenario()
	PvpMaps.choose(config.map_id)
	var map_data := PvpMaps.get_active()
	var rival := RaceCatalog.get_rival(config.local_race)

	root.get("units").clear()
	root.get("buildings").clear()
	root.get("nodes").clear()
	root.set("selected", [])
	root.set("selected_building", -1)
	root.set("next_id", 1)
	root.set("build_kind", "")
	root.set("finished", false)
	root.set("victory", false)
	root.set("wave_clock", 0.0)
	root.set("credits", int(scenario["credits"]))
	root.set("supplies", int(scenario["supplies"]))
	root.set("intel", int(scenario["intel"]))
	root.set("B", RaceSpecs.buildings_for(config.local_race, rival))
	root.set("U", RaceSpecs.units_for(config.local_race, rival))
	root.set_meta("custom_match", true)
	root.set_meta("custom_team_size", config.team_size)
	root.set_meta("custom_scenario", config.scenario_id)
	root.set_meta("custom_slots", config.slots)
	root.set_meta("pvp_map_id", config.map_id)
	root.set_meta("pvp_map_name", str(map_data["name"]))

	for node_info in map_data.get("nodes", []):
		var multiplier := 1.35 if config.scenario_id == "resource_rush" else 1.0
		root.call("_spawn_node", str(node_info[0]), node_info[1], int(int(node_info[2]) * multiplier))
	if config.scenario_id == "king_of_relay":
		root.call("_spawn_node", "evidence", Vector2.ZERO, 1400)
	if config.scenario_id == "last_convoy":
		root.call("_spawn_node", "ore", Vector2(0, 360), 1200)
		root.call("_spawn_node", "ore", Vector2(0, -360), 1200)

	var positions := _team_spawns(map_data, config.team_size)
	var slot_index := 0
	for slot in config.slots:
		if str(slot.get("controller", "closed")) == "closed":
			slot_index += 1
			continue
		if slot_index >= positions.size():
			break
		var team := TEAM_A if str(slot.get("team", "A")) == "A" else TEAM_B
		_spawn_slot_force(root, slot, positions[slot_index], team, slot_index, config.scenario_id)
		slot_index += 1

	if positions.size() > 0:
		root.set("cam", positions[0] + Vector2(150, -45))
	_install_map_visual(root, config.map_id)
	CustomMatchAI.begin_match(root)
	root.call("flash", "CUSTOM %dv%d // %s // %s // %s" % [config.team_size, config.team_size, map_data["name"], scenario["name"], config.ai_difficulty], 8.0)

func spawn_reinforcement(root: Node, slot: Dictionary, position: Vector2, kind: String) -> Dictionary:
	var saved_units: Dictionary = root.get("U")
	root.set("U", RaceSpecs.unit_set(str(slot.get("race", "authority"))))
	var team := TEAM_A if str(slot.get("team", "A")) == "A" else TEAM_B
	var unit: Dictionary = root.call("_spawn_unit", kind, team, position)
	unit["race"] = str(slot.get("race", "authority"))
	unit["cpu"] = str(slot.get("controller", "cpu")) == "cpu"
	unit["slot_id"] = int(slot.get("runtime_slot", -1))
	root.set("U", saved_units)
	return unit

func _spawn_slot_force(root: Node, slot: Dictionary, position: Vector2, team: String, slot_index: int, scenario_id: String) -> void:
	var race_id := str(slot.get("race", "authority"))
	var saved_buildings: Dictionary = root.get("B")
	var saved_units: Dictionary = root.get("U")
	root.set("B", RaceSpecs.building_set(race_id))
	root.set("U", RaceSpecs.unit_set(race_id))
	var base: Dictionary = root.call("_spawn_building", "nexus", team, position, true)
	if team == TEAM_B:
		base["kind"] = "syndicate_relay"
	base["race"] = race_id
	base["cpu"] = str(slot.get("controller", "cpu")) == "cpu"
	base["slot_id"] = slot_index

	var unit_specs := [
		["drone", Vector2(82, 34)],
		["drone", Vector2(-40, 92)],
		["deputy", Vector2(88, -62)],
		["deputy", Vector2(-85, -56)],
		["hero", Vector2(0, -108)]
	]
	if scenario_id == "sudden_death":
		unit_specs += [["deputy", Vector2(115, 92)], ["deputy", Vector2(-116, 56)], ["shield", Vector2(0, 116)]]
	elif race_id == "hollow_fang":
		unit_specs.append(["shield", Vector2(-118, 26)])
	for item in unit_specs:
		var unit: Dictionary = root.call("_spawn_unit", str(item[0]), team, position + item[1])
		unit["race"] = race_id
		unit["cpu"] = str(slot.get("controller", "cpu")) == "cpu"
		unit["slot_id"] = slot_index
	root.set("B", saved_buildings)
	root.set("U", saved_units)

func _team_spawns(map_data: Dictionary, team_size: int) -> Array[Vector2]:
	var left: Array[Vector2] = []
	var right: Array[Vector2] = []
	for point in map_data.get("spawns", []):
		if point.x < 0.0:
			left.append(point)
		else:
			right.append(point)
	left.sort_custom(func(a: Vector2, b: Vector2): return a.y < b.y)
	right.sort_custom(func(a: Vector2, b: Vector2): return a.y < b.y)
	while left.size() < team_size:
		left.append(_generated_spawn(-930.0, left.size(), team_size))
	while right.size() < team_size:
		right.append(_generated_spawn(930.0, right.size(), team_size))
	left = left.slice(0, team_size)
	right = right.slice(0, team_size)
	return left + right

func _generated_spawn(x: float, index: int, count: int) -> Vector2:
	var fraction := 0.5 if count <= 1 else float(index) / float(count - 1)
	return Vector2(x, lerpf(-570.0, 570.0, fraction))

func _install_map_visual(root: Node, map_id: String) -> void:
	var layer := root.get_node_or_null("PvpMapVisuals")
	if layer == null:
		var script := load("res://pvp_map_visuals.gd")
		layer = script.new()
		layer.name = "PvpMapVisuals"
		root.add_child(layer)
	layer.call("configure", root, map_id)
