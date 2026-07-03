extends Node2D
## MoonGoons: Crime Wars — polished playable RTS vertical slice.
## Original visuals are drawn in-engine so the demo has no third-party asset dependency.

const WORLD: Rect2 = Rect2(-1150.0, -760.0, 2500.0, 1500.0)
const AUTHORITY: String = "authority"
const SYNDICATE: String = "syndicate"
const CAMERA_EDGE: float = 42.0

var camera_position: Vector2 = Vector2(-70.0, 75.0)
var camera_goal: Vector2 = Vector2(-70.0, 75.0)
var zoom: float = 0.82
var zoom_goal: float = 0.82
var middle_dragging: bool = false
var selection_dragging: bool = false
var drag_start_screen: Vector2 = Vector2.ZERO
var build_kind: String = ""
var attack_move_pending: bool = false
var patrol_pending: bool = false

var credits: int = 420
var supplies: int = 180
var intel: int = 0
var units: Array[Dictionary] = []
var buildings: Array[Dictionary] = []
var nodes: Array[Dictionary] = []
var props: Array[Dictionary] = []
var projectiles: Array[Dictionary] = []
var effects: Array[Dictionary] = []
var selected: Array[int] = []
var selected_building: int = -1
var next_id: int = 1
var mission_clock: float = 0.0
var enemy_wave_clock: float = 0.0
var finished: bool = false
var victory: bool = false
var note: String = ""
var note_time: float = 0.0
var font: Font

var building_specs: Dictionary = {
	"nexus": {"name":"Command Nexus", "cost":0, "size":Vector2(126.0, 92.0), "hp":1400.0, "time":0.0, "accent":Color("74c9ff")},
	"armory": {"name":"Tactical Armory", "cost":160, "size":Vector2(104.0, 76.0), "hp":900.0, "time":8.0, "accent":Color("b58aff")},
	"relay": {"name":"Power Relay", "cost":60, "size":Vector2(58.0, 58.0), "hp":440.0, "time":4.0, "accent":Color("66efd2")},
	"medbay": {"name":"Field Medbay", "cost":120, "size":Vector2(88.0, 66.0), "hp":680.0, "time":6.0, "accent":Color("5ff0ac")},
	"bay": {"name":"Drone Bay", "cost":110, "size":Vector2(92.0, 68.0), "hp":640.0, "time":6.0, "accent":Color("7aa8ff")},
	"cells": {"name":"Containment Block", "cost":170, "size":Vector2(112.0, 80.0), "hp":980.0, "time":8.0, "accent":Color("f3b85e")},
	"syndicate_relay": {"name":"Syndicate Relay", "cost":0, "size":Vector2(146.0, 108.0), "hp":1750.0, "time":0.0, "accent":Color("ff5f93")}
}

var unit_specs: Dictionary = {
	"drone": {"name":"Builder Drone", "hp":95.0, "speed":155.0, "range":0.0, "damage":0.0, "cool":0.0, "radius":15.0, "accent":Color("8deaff"), "cost":65, "time":4.0},
	"deputy": {"name":"Patrol Deputy", "hp":165.0, "speed":128.0, "range":170.0, "damage":14.0, "cool":0.62, "radius":18.0, "accent":Color("9cb6ff"), "cost":85, "time":5.0},
	"shield": {"name":"Shield Deputy", "hp":300.0, "speed":94.0, "range":110.0, "damage":22.0, "cool":0.82, "radius":23.0, "accent":Color("d9a2ff"), "cost":145, "time":8.0},
	"hero": {"name":"Chief Nova", "hp":460.0, "speed":120.0, "range":205.0, "damage":31.0, "cool":0.72, "radius":25.0, "accent":Color("ffd270"), "cost":0, "time":0.0},
	"raider": {"name":"Cartel Raider", "hp":135.0, "speed":116.0, "range":142.0, "damage":12.0, "cool":0.76, "radius":18.0, "accent":Color("ff6f9d"), "cost":0, "time":0.0},
	"hacker": {"name":"Cartel Hacker", "hp":95.0, "speed":108.0, "range":198.0, "damage":9.0, "cool":0.50, "radius":16.0, "accent":Color("ffbf68"), "cost":0, "time":0.0}
}

func _ready() -> void:
	font = ThemeDB.fallback_font
	_setup_operation_breakwater()
	flash("OPERATION BREAKWATER // Build a Tactical Armory, train a force, and silence the Syndicate Relay.", 8.0)

func _setup_operation_breakwater() -> void:
	props = [
		{"kind":"rail", "pos":Vector2(-1070.0, -220.0), "length":2110.0},
		{"kind":"crane", "pos":Vector2(-620.0, -315.0)},
		{"kind":"wreck", "pos":Vector2(155.0, 80.0)},
		{"kind":"cargo", "pos":Vector2(-470.0, 310.0)},
		{"kind":"cargo", "pos":Vector2(-95.0, 215.0)},
		{"kind":"cargo", "pos":Vector2(530.0, 250.0)},
		{"kind":"pipe", "pos":Vector2(285.0, -340.0)},
		{"kind":"barricade", "pos":Vector2(390.0, -40.0)},
		{"kind":"lamp", "pos":Vector2(-760.0, 105.0)},
		{"kind":"lamp", "pos":Vector2(610.0, -120.0)},
		{"kind":"sign", "pos":Vector2(775.0, -60.0)}
	]
	_spawn_building("nexus", AUTHORITY, Vector2(-280.0, 145.0), true)
	_spawn_unit("hero", AUTHORITY, Vector2(-280.0, 40.0))
	for position: Vector2 in [Vector2(-180.0, 185.0), Vector2(-245.0, 252.0), Vector2(-342.0, 246.0)]:
		_spawn_unit("drone", AUTHORITY, position)
	for position: Vector2 in [Vector2(-160.0, 88.0), Vector2(-365.0, 76.0)]:
		_spawn_unit("deputy", AUTHORITY, position)
	_spawn_node("ore", Vector2(-560.0, 210.0), 980)
	_spawn_node("ore", Vector2(-430.0, -88.0), 720)
	_spawn_node("evidence", Vector2(62.0, 275.0), 500)
	_spawn_node("ore", Vector2(235.0, -150.0), 930)
	_spawn_node("evidence", Vector2(488.0, 145.0), 540)
	_spawn_building("syndicate_relay", SYNDICATE, Vector2(790.0, -250.0), true)
	for position: Vector2 in [Vector2(675.0, -180.0), Vector2(850.0, -145.0), Vector2(912.0, -332.0)]:
		_spawn_unit("raider", SYNDICATE, position)
	for position: Vector2 in [Vector2(740.0, -390.0), Vector2(1000.0, -250.0)]:
		_spawn_unit("hacker", SYNDICATE, position)

func _process(delta: float) -> void:
	_movement_camera(delta)
	zoom = lerpf(zoom, zoom_goal, minf(1.0, delta * 10.0))
	note_time = maxf(0.0, note_time - delta)
	mission_clock += delta
	if not finished:
		_update_buildings(delta)
		_update_units(delta)
		_update_projectiles(delta)
		enemy_wave_clock += delta
		if enemy_wave_clock >= _enemy_wave_interval():
			enemy_wave_clock = 0.0
			_spawn_enemy_wave()
		_cleanup_dead_entities()
		_check_mission_end()
	_update_effects(delta)
	queue_redraw()

func _movement_camera(delta: float) -> void:
	var direction: Vector2 = Vector2.ZERO
	if Input.is_key_pressed(KEY_W):
		direction.y -= 1.0
	if Input.is_key_pressed(KEY_S):
		direction.y += 1.0
	if Input.is_key_pressed(KEY_A) and not attack_move_pending:
		direction.x -= 1.0
	if Input.is_key_pressed(KEY_D):
		direction.x += 1.0
	var mouse: Vector2 = get_viewport().get_mouse_position()
	var viewport_size: Vector2 = get_viewport_rect().size
	if not middle_dragging:
		if mouse.x <= CAMERA_EDGE:
			direction.x -= 1.0
		elif mouse.x >= viewport_size.x - CAMERA_EDGE:
			direction.x += 1.0
		if mouse.y <= CAMERA_EDGE:
			direction.y -= 1.0
		elif mouse.y >= viewport_size.y - CAMERA_EDGE:
			direction.y += 1.0
	if direction.length_squared() > 0.0:
		camera_goal += direction.normalized() * 760.0 * delta / maxf(zoom, 0.1)
	camera_goal.x = clampf(camera_goal.x, WORLD.position.x + 340.0, WORLD.end.x - 340.0)
	camera_goal.y = clampf(camera_goal.y, WORLD.position.y + 250.0, WORLD.end.y - 250.0)
	camera_position = camera_position.lerp(camera_goal, minf(1.0, delta * 8.5))

func _enemy_wave_interval() -> float:
	var difficulty: String = GameDifficulty.active_id
	if difficulty == "easy":
		return 43.0
	if difficulty == "hard":
		return 28.0
	if difficulty == "nightmare":
		return 21.0
	return 35.0

func _update_buildings(delta: float) -> void:
	for building: Dictionary in buildings:
		if not bool(building.get("done", false)):
			building["progress"] = minf(float(building.get("progress", 0.0)) + delta, float(building.get("build_time", 1.0)))
			if float(building.get("progress", 0.0)) >= float(building.get("build_time", 1.0)):
				building["done"] = true
				_spawn_effect("construct", building["pos"] as Vector2, Color("8fe9ff"), 0.95)
				flash(str(building.get("name", "Structure")) + " online.", 2.0)
				_sound("complete")

func _update_units(delta: float) -> void:
	for unit: Dictionary in units:
		if not bool(unit.get("ready", true)):
			unit["progress"] = float(unit.get("progress", 0.0)) + delta
			if float(unit.get("progress", 0.0)) >= float(unit.get("train_time", 0.0)):
				unit["ready"] = true
				_spawn_effect("construct", unit["pos"] as Vector2, _unit_color(unit), 0.55)
				_sound("complete")
			continue
		unit["walk_phase"] = float(unit.get("walk_phase", 0.0)) + delta * 7.0
		unit["hit_flash"] = maxf(0.0, float(unit.get("hit_flash", 0.0)) - delta)
		if str(unit.get("team", AUTHORITY)) == AUTHORITY:
			_update_authority_unit(unit, delta)
		else:
			_update_enemy_unit(unit, delta)

func _update_authority_unit(unit: Dictionary, delta: float) -> void:
	var order: String = str(unit.get("order", "idle"))
	if order == "move":
		_move_unit(unit, unit.get("target", unit["pos"]) as Vector2, delta)
		if (unit["pos"] as Vector2).distance_to(unit.get("target", unit["pos"]) as Vector2) < 5.0:
			unit["order"] = "idle"
	elif order == "attack":
		var target: Dictionary = _entity(int(unit.get("target_id", -1)))
		if target.is_empty():
			unit["order"] = "idle"
		else:
			_combat_step(unit, target, delta)
	elif order == "attack_move":
		var nearby_enemy: Dictionary = _nearest_enemy(unit, 250.0)
		if not nearby_enemy.is_empty():
			_combat_step(unit, nearby_enemy, delta)
		else:
			_move_unit(unit, unit.get("target", unit["pos"]) as Vector2, delta)
	elif order == "harvest":
		_update_harvest(unit, delta)
	elif order == "patrol":
		_update_patrol(unit, delta)
	elif order == "hold":
		var hold_enemy: Dictionary = _nearest_enemy(unit, float(unit.get("range", 0.0)))
		if not hold_enemy.is_empty():
			_combat_step(unit, hold_enemy, delta)
	else:
		var enemy: Dictionary = _nearest_enemy(unit, float(unit.get("range", 0.0)))
		if not enemy.is_empty():
			_combat_step(unit, enemy, delta)

func _update_enemy_unit(unit: Dictionary, delta: float) -> void:
	var target: Dictionary = _nearest_authority(unit)
	if target.is_empty():
		return
	_combat_step(unit, target, delta)

func _update_patrol(unit: Dictionary, delta: float) -> void:
	var a: Vector2 = unit.get("patrol_a", unit["pos"]) as Vector2
	var b: Vector2 = unit.get("patrol_b", unit["pos"]) as Vector2
	var leg: int = int(unit.get("patrol_leg", 0))
	var target: Vector2 = b if leg == 0 else a
	var enemy: Dictionary = _nearest_enemy(unit, float(unit.get("range", 0.0)))
	if not enemy.is_empty():
		_combat_step(unit, enemy, delta)
		return
	_move_unit(unit, target, delta)
	if (unit["pos"] as Vector2).distance_to(target) < 5.0:
		unit["patrol_leg"] = 1 - leg

func _update_harvest(unit: Dictionary, delta: float) -> void:
	var node_index: int = int(unit.get("target_id", -1))
	if node_index < 0 or node_index >= nodes.size():
		unit["order"] = "idle"
		return
	var resource: Dictionary = nodes[node_index]
	if int(resource.get("amount", 0)) <= 0:
		unit["order"] = "idle"
		flash("Deposit exhausted.", 1.8)
		return
	var carrying: int = int(unit.get("carrying", 0))
	if carrying >= 20:
		var nexus: Dictionary = _home_nexus()
		if nexus.is_empty():
			return
		_move_unit(unit, nexus["pos"] as Vector2 + Vector2(65.0, 46.0), delta)
		if (unit["pos"] as Vector2).distance_to(nexus["pos"] as Vector2) < 82.0:
			credits += carrying
			supplies += maxi(1, carrying / 5)
			unit["carrying"] = 0
			_spawn_effect("deposit", nexus["pos"] as Vector2, Color("8deaff"), 0.45)
		return
	var target_pos: Vector2 = resource["pos"] as Vector2
	if (unit["pos"] as Vector2).distance_to(target_pos) > 48.0:
		_move_unit(unit, target_pos, delta)
		return
	unit["harvest_clock"] = float(unit.get("harvest_clock", 0.0)) + delta
	if float(unit.get("harvest_clock", 0.0)) >= 0.82:
		unit["harvest_clock"] = 0.0
		var gathered: int = mini(20, int(resource.get("amount", 0)))
		resource["amount"] = int(resource.get("amount", 0)) - gathered
		unit["carrying"] = carrying + gathered
		_spawn_effect("spark", target_pos, Color("66e8ff") if str(resource.get("type", "ore")) == "ore" else Color("ffc46b"), 0.35)

func _combat_step(attacker: Dictionary, target: Dictionary, delta: float) -> void:
	var target_pos: Vector2 = target["pos"] as Vector2
	var attacker_pos: Vector2 = attacker["pos"] as Vector2
	var range_value: float = float(attacker.get("range", 0.0))
	if range_value <= 0.0:
		return
	if attacker_pos.distance_to(target_pos) > range_value:
		_move_unit(attacker, target_pos, delta)
		return
	attacker["attack_clock"] = float(attacker.get("attack_clock", 0.0)) + delta
	if float(attacker.get("attack_clock", 0.0)) < float(attacker.get("cool", 1.0)):
		return
	attacker["attack_clock"] = 0.0
	attacker["facing"] = attacker_pos.direction_to(target_pos)
	_spawn_projectile(attacker, target)

func _move_unit(unit: Dictionary, target: Vector2, delta: float) -> void:
	var position: Vector2 = unit["pos"] as Vector2
	var direction: Vector2 = position.direction_to(target)
	if direction.length_squared() > 0.0:
		unit["facing"] = direction
	unit["pos"] = position.move_toward(target, float(unit.get("speed", 0.0)) * delta)

func _spawn_projectile(attacker: Dictionary, target: Dictionary) -> void:
	var team: String = str(attacker.get("team", AUTHORITY))
	var color: Color = _unit_color(attacker)
	if team == SYNDICATE:
		color = Color("ff7199") if str(attacker.get("kind", "")) == "raider" else Color("ffbf68")
	projectiles.append({
		"pos":attacker["pos"], "target_id":int(target.get("id", -1)), "target_pos":target["pos"], "damage":float(attacker.get("damage", 0.0)),
		"team":team, "color":color, "speed":520.0 if team == AUTHORITY else 470.0, "life":1.35
	})
	_spawn_effect("muzzle", attacker["pos"] as Vector2, color, 0.20)
	_sound("fire")

func _update_projectiles(delta: float) -> void:
	var next_projectiles: Array[Dictionary] = []
	for projectile: Dictionary in projectiles:
		projectile["life"] = float(projectile.get("life", 0.0)) - delta
		var target: Dictionary = _entity(int(projectile.get("target_id", -1)))
		var target_pos: Vector2 = projectile.get("target_pos", Vector2.ZERO) as Vector2
		if not target.is_empty():
			target_pos = target["pos"] as Vector2
		var position: Vector2 = projectile["pos"] as Vector2
		var moved: Vector2 = position.move_toward(target_pos, float(projectile.get("speed", 0.0)) * delta)
		projectile["pos"] = moved
		if moved.distance_to(target_pos) < 13.0 or float(projectile.get("life", 0.0)) <= 0.0:
			if not target.is_empty():
				target["hp"] = float(target.get("hp", 0.0)) - float(projectile.get("damage", 0.0))
				target["hit_flash"] = 0.16
				_spawn_effect("impact", target_pos, projectile["color"] as Color, 0.44)
				if float(target.get("hp", 0.0)) <= 0.0:
					_spawn_effect("explosion", target_pos, projectile["color"] as Color, 1.0)
					if str(target.get("team", "")) == SYNDICATE:
						credits += 18
						intel += 3
				_sound("impact")
		else:
			next_projectiles.append(projectile)
	projectiles = next_projectiles

func _spawn_enemy_wave() -> void:
	var relay: Dictionary = _relay()
	if relay.is_empty() or finished:
		return
	var count: int = 3
	if GameDifficulty.active_id == "hard":
		count = 4
	elif GameDifficulty.active_id == "nightmare":
		count = 5
	for index: int in count:
		var angle: float = float(index) * TAU / float(maxi(1, count))
		var offset: Vector2 = Vector2.from_angle(angle) * 135.0
		var kind: String = "hacker" if index % 3 == 2 else "raider"
		_spawn_unit(kind, SYNDICATE, relay["pos"] as Vector2 + offset)
	flash("Syndicate response team inbound.", 3.0)
	_sound("alert")

func _cleanup_dead_entities() -> void:
	var surviving_units: Array[Dictionary] = []
	for unit: Dictionary in units:
		if float(unit.get("hp", 0.0)) > 0.0:
			surviving_units.append(unit)
	units = surviving_units
	var surviving_buildings: Array[Dictionary] = []
	for building: Dictionary in buildings:
		if float(building.get("hp", 0.0)) > 0.0:
			surviving_buildings.append(building)
	buildings = surviving_buildings
	var valid_selection: Array[int] = []
	for entity_id: int in selected:
		if not _entity(entity_id).is_empty():
			valid_selection.append(entity_id)
	selected = valid_selection
	if selected_building != -1 and _entity(selected_building).is_empty():
		selected_building = -1

func _check_mission_end() -> void:
	if _relay().is_empty():
		finished = true
		victory = true
		flash("MISSION COMPLETE // Breakwater is secured. Press F2 for the war room after this test.", 999.0)
		_sound("victory")
		return
	if _home_nexus().is_empty():
		finished = true
		victory = false
		flash("MISSION FAILED // The Command Nexus has fallen. Press R to restart.", 999.0)
		_sound("defeat")

func _update_effects(delta: float) -> void:
	var live_effects: Array[Dictionary] = []
	for effect: Dictionary in effects:
		effect["age"] = float(effect.get("age", 0.0)) + delta
		if float(effect.get("age", 0.0)) < float(effect.get("duration", 0.5)):
			live_effects.append(effect)
	effects = live_effects

func _spawn_effect(kind: String, position: Vector2, color: Color, duration: float) -> void:
	effects.append({"kind":kind, "pos":position, "color":color, "age":0.0, "duration":duration})

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event
		if mouse_event.button_index == MOUSE_BUTTON_WHEEL_UP and mouse_event.pressed:
			zoom_goal = clampf(zoom_goal * 1.12, 0.52, 1.34)
		elif mouse_event.button_index == MOUSE_BUTTON_WHEEL_DOWN and mouse_event.pressed:
			zoom_goal = clampf(zoom_goal / 1.12, 0.52, 1.34)
		elif mouse_event.button_index == MOUSE_BUTTON_MIDDLE:
			middle_dragging = mouse_event.pressed
		elif mouse_event.button_index == MOUSE_BUTTON_LEFT:
			if mouse_event.pressed:
				drag_start_screen = mouse_event.position
				selection_dragging = true
				if not build_kind.is_empty():
					_place_building(_screen_to_world(mouse_event.position))
					selection_dragging = false
			else:
				if selection_dragging:
					_select_at(_screen_to_world(mouse_event.position))
				selection_dragging = false
		elif mouse_event.button_index == MOUSE_BUTTON_RIGHT and mouse_event.pressed:
			_order_selected(_screen_to_world(mouse_event.position))
	elif event is InputEventMouseMotion and middle_dragging:
		var motion: InputEventMouseMotion = event
		camera_goal -= motion.relative / maxf(zoom, 0.1)
	elif event is InputEventKey and event.pressed and not event.echo:
		var key_event: InputEventKey = event
		match key_event.keycode:
			KEY_ESCAPE:
				build_kind = ""
				attack_move_pending = false
				patrol_pending = false
				flash("Command cancelled.", 1.5)
			KEY_SPACE:
				var nexus: Dictionary = _home_nexus()
				if not nexus.is_empty():
					camera_goal = nexus["pos"] as Vector2
			KEY_A:
				attack_move_pending = true
				patrol_pending = false
				flash("Attack-move armed. Right-click a destination.", 2.0)
			KEY_H:
				_set_hold_position()
			KEY_P:
				patrol_pending = true
				attack_move_pending = false
				flash("Patrol armed. Right-click a destination.", 2.0)
			KEY_R:
				if finished:
					get_tree().reload_current_scene()
				else:
					_train("shield")
			KEY_1:
				_begin_build("armory")
			KEY_2:
				_begin_build("relay")
			KEY_3:
				_begin_build("medbay")
			KEY_4:
				_begin_build("bay")
			KEY_5:
				_begin_build("cells")
			KEY_Q:
				_train("deputy")
			KEY_E:
				_train("drone")

func _select_at(world_point: Vector2) -> void:
	if finished:
		return
	selected.clear()
	selected_building = -1
	var world_start: Vector2 = _screen_to_world(drag_start_screen)
	var select_box: Rect2 = Rect2(world_start, world_point - world_start).abs()
	if select_box.size.length() < 18.0:
		var unit: Dictionary = _friendly_unit_at(world_point)
		if not unit.is_empty():
			selected.append(int(unit.get("id", -1)))
			_sound("select")
			return
		var building: Dictionary = _friendly_building_at(world_point)
		if not building.is_empty():
			selected_building = int(building.get("id", -1))
			_sound("select")
			return
	for unit: Dictionary in units:
		if str(unit.get("team", "")) == AUTHORITY and bool(unit.get("ready", true)) and select_box.has_point(unit["pos"] as Vector2):
			selected.append(int(unit.get("id", -1)))
	if not selected.is_empty():
		_sound("select")

func _order_selected(world_point: Vector2) -> void:
	if selected.is_empty() or finished:
		return
	var enemy: Dictionary = _enemy_at(world_point)
	var resource_index: int = _resource_at(world_point)
	var formation_index: int = 0
	for entity_id: int in selected:
		var unit: Dictionary = _entity(entity_id)
		if unit.is_empty():
			continue
		if not enemy.is_empty():
			unit["order"] = "attack"
			unit["target_id"] = int(enemy.get("id", -1))
		elif str(unit.get("kind", "")) == "drone" and resource_index >= 0 and not attack_move_pending and not patrol_pending:
			unit["order"] = "harvest"
			unit["target_id"] = resource_index
		elif patrol_pending:
			unit["order"] = "patrol"
			unit["patrol_a"] = unit["pos"]
			unit["patrol_b"] = world_point + _formation_offset(formation_index)
			unit["patrol_leg"] = 0
		elif attack_move_pending:
			unit["order"] = "attack_move"
			unit["target"] = world_point + _formation_offset(formation_index)
		else:
			unit["order"] = "move"
			unit["target"] = world_point + _formation_offset(formation_index)
		formation_index += 1
	attack_move_pending = false
	patrol_pending = false
	_sound("order")

func _formation_offset(index: int) -> Vector2:
	var column: int = index % 3 - 1
	var row: int = index / 3 - 1
	return Vector2(float(column) * 30.0, float(row) * 28.0)

func _set_hold_position() -> void:
	for entity_id: int in selected:
		var unit: Dictionary = _entity(entity_id)
		if not unit.is_empty():
			unit["order"] = "hold"
	flash("Selected squad holding position.", 1.5)
	_sound("order")

func _begin_build(kind: String) -> void:
	if not building_specs.has(kind):
		return
	if not _selected_has_drone():
		flash("Select a Builder Drone before placing a structure.", 2.5)
		return
	build_kind = kind
	var spec: Dictionary = building_specs[kind]
	flash("Blueprint active // " + str(spec.get("name", "Structure")) + ". Left-click terrain to place.", 3.0)

func _place_building(world_point: Vector2) -> void:
	if build_kind.is_empty() or not building_specs.has(build_kind):
		return
	var spec: Dictionary = building_specs[build_kind]
	var cost: int = int(spec.get("cost", 0))
	var size: Vector2 = spec.get("size", Vector2(80.0, 60.0)) as Vector2
	if credits < cost:
		flash("Insufficient Credits.", 2.0)
		_sound("error")
		return
	if not _valid_build_site(world_point, size):
		flash("Construction zone blocked.", 2.0)
		_sound("error")
		return
	credits -= cost
	_spawn_building(build_kind, AUTHORITY, world_point, false)
	build_kind = ""
	_sound("build")

func _train(kind: String) -> void:
	if not unit_specs.has(kind):
		return
	var producer: Dictionary = _selected_producer(kind)
	if producer.is_empty():
		flash("Select a Command Nexus, or a Tactical Armory for Shield Deputies.", 2.5)
		_sound("error")
		return
	var spec: Dictionary = unit_specs[kind]
	var cost: int = int(spec.get("cost", 0))
	if credits < cost:
		flash("Insufficient Credits.", 2.0)
		_sound("error")
		return
	credits -= cost
	var spawn_position: Vector2 = producer["pos"] as Vector2 + Vector2(82.0, 55.0)
	var unit: Dictionary = _spawn_unit(kind, AUTHORITY, spawn_position)
	unit["ready"] = false
	unit["progress"] = 0.0
	unit["train_time"] = float(spec.get("time", 0.0))
	flash(str(spec.get("name", "Unit")) + " queued.", 1.8)
	_sound("build")

func _selected_has_drone() -> bool:
	for entity_id: int in selected:
		var unit: Dictionary = _entity(entity_id)
		if not unit.is_empty() and str(unit.get("kind", "")) == "drone":
			return true
	return false

func _selected_producer(kind: String) -> Dictionary:
	var building: Dictionary = _entity(selected_building)
	if building.is_empty() or not bool(building.get("done", false)):
		return {}
	if kind == "shield" and str(building.get("kind", "")) == "armory":
		return building
	if kind != "shield" and str(building.get("kind", "")) == "nexus":
		return building
	return {}

func _spawn_unit(kind: String, team: String, position: Vector2) -> Dictionary:
	var spec: Dictionary = unit_specs.get(kind, unit_specs["deputy"])
	var hp: float = float(spec.get("hp", 100.0))
	var unit: Dictionary = {
		"id":next_id, "kind":kind, "name":str(spec.get("name", kind)), "team":team, "pos":position, "target":position,
		"target_id":-1, "order":"idle", "hp":hp, "max":hp, "speed":float(spec.get("speed", 100.0)), "range":float(spec.get("range", 0.0)),
		"damage":float(spec.get("damage", 0.0)), "cool":float(spec.get("cool", 1.0)), "radius":float(spec.get("radius", 16.0)),
		"accent":spec.get("accent", Color.WHITE), "attack_clock":0.0, "harvest_clock":0.0, "carrying":0, "ready":true,
		"progress":0.0, "train_time":0.0, "walk_phase":0.0, "facing":Vector2.RIGHT, "hit_flash":0.0, "race":"authority" if team == AUTHORITY else "lunar_cartel"
	}
	next_id += 1
	units.append(unit)
	return unit

func _spawn_building(kind: String, team: String, position: Vector2, done: bool) -> Dictionary:
	var spec: Dictionary = building_specs.get(kind, building_specs["nexus"])
	var hp: float = float(spec.get("hp", 500.0))
	var build_time: float = float(spec.get("time", 0.0))
	var building: Dictionary = {
		"id":next_id, "kind":kind, "name":str(spec.get("name", kind)), "team":team, "pos":position, "hp":hp, "max":hp,
		"size":spec.get("size", Vector2(70.0, 50.0)), "accent":spec.get("accent", Color.WHITE), "done":done,
		"build_time":build_time, "progress":build_time if done else 0.0, "hit_flash":0.0, "race":"authority" if team == AUTHORITY else "lunar_cartel"
	}
	next_id += 1
	buildings.append(building)
	return building

func _spawn_node(kind: String, position: Vector2, amount: int) -> void:
	nodes.append({"type":kind, "pos":position, "amount":amount, "max":amount})

func _entity(entity_id: int) -> Dictionary:
	for unit: Dictionary in units:
		if int(unit.get("id", -1)) == entity_id:
			return unit
	for building: Dictionary in buildings:
		if int(building.get("id", -1)) == entity_id:
			return building
	return {}

func _home_nexus() -> Dictionary:
	for building: Dictionary in buildings:
		if str(building.get("team", "")) == AUTHORITY and str(building.get("kind", "")) == "nexus":
			return building
	return {}

func _relay() -> Dictionary:
	for building: Dictionary in buildings:
		if str(building.get("kind", "")) == "syndicate_relay":
			return building
	return {}

func _nearest_enemy(unit: Dictionary, maximum_distance: float) -> Dictionary:
	if maximum_distance <= 0.0:
		return {}
	var best: Dictionary = {}
	var best_distance: float = maximum_distance
	var position: Vector2 = unit["pos"] as Vector2
	for entity: Dictionary in units:
		if str(entity.get("team", "")) == SYNDICATE:
			var distance_value: float = position.distance_to(entity["pos"] as Vector2)
			if distance_value < best_distance:
				best = entity
				best_distance = distance_value
	for entity: Dictionary in buildings:
		if str(entity.get("team", "")) == SYNDICATE:
			var distance_value: float = position.distance_to(entity["pos"] as Vector2)
			if distance_value < best_distance:
				best = entity
				best_distance = distance_value
	return best

func _nearest_authority(unit: Dictionary) -> Dictionary:
	var best: Dictionary = {}
	var best_distance: float = INF
	var position: Vector2 = unit["pos"] as Vector2
	for entity: Dictionary in units:
		if str(entity.get("team", "")) == AUTHORITY:
			var distance_value: float = position.distance_to(entity["pos"] as Vector2)
			if distance_value < best_distance:
				best = entity
				best_distance = distance_value
	for entity: Dictionary in buildings:
		if str(entity.get("team", "")) == AUTHORITY:
			var distance_value: float = position.distance_to(entity["pos"] as Vector2)
			if distance_value < best_distance:
				best = entity
				best_distance = distance_value
	return best

func _friendly_unit_at(world_point: Vector2) -> Dictionary:
	var closest: Dictionary = {}
	var closest_distance: float = 38.0
	for unit: Dictionary in units:
		if str(unit.get("team", "")) == AUTHORITY and bool(unit.get("ready", true)):
			var distance_value: float = world_point.distance_to(unit["pos"] as Vector2)
			if distance_value < closest_distance:
				closest = unit
				closest_distance = distance_value
	return closest

func _friendly_building_at(world_point: Vector2) -> Dictionary:
	for building: Dictionary in buildings:
		if str(building.get("team", "")) == AUTHORITY:
			var size: Vector2 = building.get("size", Vector2(70.0, 50.0)) as Vector2
			var rect: Rect2 = Rect2(building["pos"] as Vector2 - size * 0.5, size)
			if rect.has_point(world_point):
				return building
	return {}

func _enemy_at(world_point: Vector2) -> Dictionary:
	var closest: Dictionary = {}
	var closest_distance: float = 48.0
	for unit: Dictionary in units:
		if str(unit.get("team", "")) == SYNDICATE and _revealed(unit["pos"] as Vector2):
			var distance_value: float = world_point.distance_to(unit["pos"] as Vector2)
			if distance_value < closest_distance:
				closest = unit
				closest_distance = distance_value
	for building: Dictionary in buildings:
		if str(building.get("team", "")) == SYNDICATE and _revealed(building["pos"] as Vector2):
			var size: Vector2 = building.get("size", Vector2(70.0, 50.0)) as Vector2
			var rect: Rect2 = Rect2(building["pos"] as Vector2 - size * 0.5, size).grow(22.0)
			if rect.has_point(world_point):
				return building
	return closest

func _resource_at(world_point: Vector2) -> int:
	var result: int = -1
	var closest_distance: float = 55.0
	for index: int in nodes.size():
		var resource: Dictionary = nodes[index]
		if int(resource.get("amount", 0)) > 0:
			var distance_value: float = world_point.distance_to(resource["pos"] as Vector2)
			if distance_value < closest_distance:
				result = index
				closest_distance = distance_value
	return result

func _valid_build_site(world_point: Vector2, size: Vector2) -> bool:
	var candidate: Rect2 = Rect2(world_point - size * 0.5, size)
	if not WORLD.grow(-82.0).encloses(candidate):
		return false
	for building: Dictionary in buildings:
		var other_size: Vector2 = building.get("size", Vector2(70.0, 50.0)) as Vector2
		var other: Rect2 = Rect2(building["pos"] as Vector2 - other_size * 0.5, other_size)
		if candidate.grow(26.0).intersects(other):
			return false
	for resource: Dictionary in nodes:
		if candidate.grow(25.0).has_point(resource["pos"] as Vector2):
			return false
	return true

func _screen_to_world(screen_position: Vector2) -> Vector2:
	return camera_position + (screen_position - get_viewport_rect().size * 0.5) / maxf(zoom, 0.1)

func _revealed(world_point: Vector2) -> bool:
	for entity: Dictionary in units:
		if str(entity.get("team", "")) == AUTHORITY and (entity["pos"] as Vector2).distance_to(world_point) < 360.0:
			return true
	for entity: Dictionary in buildings:
		if str(entity.get("team", "")) == AUTHORITY and (entity["pos"] as Vector2).distance_to(world_point) < 330.0:
			return true
	return false

func _unit_color(unit: Dictionary) -> Color:
	var accent: Color = unit.get("accent", Color.WHITE) as Color
	if float(unit.get("hit_flash", 0.0)) > 0.0:
		return Color.WHITE
	return accent

func flash(message: String, duration: float = 3.0) -> void:
	note = message
	note_time = duration

func _sound(cue: String) -> void:
	var service: Node = get_node_or_null("/root/RtsAudio")
	if service != null:
		service.call("play_cue", cue)

func _draw() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, viewport_size), Color("040916"), true)
	_draw_space_backdrop(viewport_size)
	draw_set_transform(viewport_size * 0.5 - camera_position * zoom, 0.0, Vector2.ONE * zoom)
	_draw_lunar_dockyard()
	_draw_props()
	_draw_resources()
	_draw_building_blueprint()
	_draw_buildings()
	_draw_units()
	_draw_projectiles()
	_draw_effects()
	_draw_fog()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if selection_dragging and build_kind.is_empty():
		var current_mouse: Vector2 = get_viewport().get_mouse_position()
		draw_rect(Rect2(drag_start_screen, current_mouse - drag_start_screen).abs(), Color(0.45, 0.82, 1.0, 0.12), true)
		draw_rect(Rect2(drag_start_screen, current_mouse - drag_start_screen).abs(), Color("8fe9ff"), false, 1.5)
	if finished:
		_draw_result_banner(viewport_size)

func _draw_space_backdrop(viewport_size: Vector2) -> void:
	for index: int in 46:
		var x: float = fposmod(float(index * 197 + 41), viewport_size.x)
		var y: float = fposmod(float(index * 79 + 23), viewport_size.y)
		var alpha: float = 0.12 + float(index % 4) * 0.10
		draw_circle(Vector2(x, y), 0.8 + float(index % 3) * 0.45, Color(0.66, 0.80, 1.0, alpha))

func _draw_lunar_dockyard() -> void:
	draw_rect(WORLD, Color("18233a"), true)
	for x: int in range(int(WORLD.position.x), int(WORLD.end.x), 80):
		draw_line(Vector2(float(x), WORLD.position.y), Vector2(float(x), WORLD.end.y), Color(0.27, 0.36, 0.54, 0.24), 1.2)
	for y: int in range(int(WORLD.position.y), int(WORLD.end.y), 80):
		draw_line(Vector2(WORLD.position.x, float(y)), Vector2(WORLD.end.x, float(y)), Color(0.27, 0.36, 0.54, 0.24), 1.2)
	var zone_a: Rect2 = Rect2(-1040.0, 35.0, 670.0, 440.0)
	var zone_b: Rect2 = Rect2(525.0, -510.0, 470.0, 360.0)
	draw_rect(zone_a, Color("25456e"), true)
	draw_rect(zone_a, Color("65c7f5"), false, 3.0)
	draw_rect(zone_b, Color("54243d"), true)
	draw_rect(zone_b, Color("ff74aa"), false, 3.0)
	for index: int in 20:
		var angle: float = float(index) * 1.78
		var crater_center: Vector2 = Vector2(-970.0 + fposmod(float(index * 137), 2100.0), -610.0 + fposmod(float(index * 71), 1270.0))
		var crater_radius: float = 16.0 + float(index % 4) * 7.0
		draw_circle(crater_center, crater_radius, Color(0.04, 0.07, 0.13, 0.34))
		draw_arc(crater_center, crater_radius, 0.0, TAU, 12, Color(0.40, 0.48, 0.62, 0.24), 1.0)
		angle += 0.0
	draw_rect(WORLD, Color("8aa6cf"), false, 5.0)

func _draw_props() -> void:
	for prop: Dictionary in props:
		var kind: String = str(prop.get("kind", "cargo"))
		var position: Vector2 = prop.get("pos", Vector2.ZERO) as Vector2
		if kind == "rail":
			var length: float = float(prop.get("length", 1200.0))
			draw_line(position, position + Vector2(length, 0.0), Color("586b83"), 8.0)
			draw_line(position + Vector2(0.0, 14.0), position + Vector2(length, 14.0), Color("33455d"), 8.0)
			for x: float in range(0, int(length), 52):
				draw_line(position + Vector2(x, -7.0), position + Vector2(x, 23.0), Color("a2b3c8"), 3.0)
		elif kind == "cargo":
			for index: int in 3:
				var crate: Rect2 = Rect2(position + Vector2(float(index % 2) * 38.0, float(index / 2) * -28.0), Vector2(48.0, 26.0))
				draw_rect(crate, Color("795971"), true)
				draw_rect(crate, Color("ff93c4"), false, 2.0)
		elif kind == "crane":
			draw_rect(Rect2(position, Vector2(20.0, 240.0)), Color("5d7590"), true)
			draw_line(position + Vector2(10.0, 18.0), position + Vector2(210.0, 18.0), Color("9ec7e8"), 10.0)
			draw_line(position + Vector2(185.0, 18.0), position + Vector2(185.0, 104.0), Color("ffd46f"), 3.0)
			draw_circle(position + Vector2(185.0, 110.0), 8.0, Color("ffd46f"))
		elif kind == "wreck":
			var hull: PackedVector2Array = PackedVector2Array([position + Vector2(-74.0, 10.0), position + Vector2(-20.0, -36.0), position + Vector2(76.0, -8.0), position + Vector2(48.0, 32.0), position + Vector2(-48.0, 28.0)])
			draw_colored_polygon(hull, Color("4d536c"))
			draw_polyline(hull, Color("b8756c"), 3.0, true)
			draw_line(position + Vector2(-16.0, 0.0), position + Vector2(52.0, -8.0), Color("ffbd5c"), 3.0)
		elif kind == "pipe":
			draw_line(position + Vector2(-120.0, 0.0), position + Vector2(120.0, 0.0), Color("576a82"), 18.0)
			draw_line(position + Vector2(-120.0, 0.0), position + Vector2(120.0, 0.0), Color("9eb5cc"), 4.0)
		elif kind == "barricade":
			for index: int in 4:
				draw_rect(Rect2(position + Vector2(float(index) * 28.0, 0.0), Vector2(22.0, 14.0)), Color("b56d42"), true)
				draw_rect(Rect2(position + Vector2(float(index) * 28.0, 0.0), Vector2(22.0, 14.0)), Color("ffd178"), false, 1.5)
		elif kind == "lamp":
			draw_line(position, position + Vector2(0.0, -68.0), Color("7e94ad"), 4.0)
			draw_circle(position + Vector2(0.0, -72.0), 11.0 + sin(mission_clock * 3.0) * 1.5, Color(0.45, 0.9, 1.0, 0.34))
			draw_circle(position + Vector2(0.0, -72.0), 4.0, Color("e7fbff"))
		elif kind == "sign":
			draw_rect(Rect2(position, Vector2(105.0, 44.0)), Color("4d2039"), true)
			draw_rect(Rect2(position, Vector2(105.0, 44.0)), Color("ff70ac"), false, 2.0)
			draw_string(font, position + Vector2(10.0, 28.0), "NO LAW", HORIZONTAL_ALIGNMENT_LEFT, 90, 14, Color("ffb3d4"))

func _draw_resources() -> void:
	for resource: Dictionary in nodes:
		if int(resource.get("amount", 0)) <= 0:
			continue
		var position: Vector2 = resource["pos"] as Vector2
		var evidence: bool = str(resource.get("type", "ore")) == "evidence"
		var color: Color = Color("ffca69") if evidence else Color("65eaff")
		draw_circle(position, 34.0, Color(color.r, color.g, color.b, 0.15))
		for index: int in 5:
			var angle: float = float(index) * TAU / 5.0 + mission_clock * 0.12
			var outer: Vector2 = position + Vector2.from_angle(angle) * (25.0 + float(index % 2) * 7.0)
			var shard: PackedVector2Array = PackedVector2Array([position, outer + Vector2(-5.0, 4.0), outer + Vector2(6.0, -4.0)])
			draw_colored_polygon(shard, Color(color.r, color.g, color.b, 0.75))
		draw_arc(position, 35.0, 0.0, TAU, 16, Color(color.r, color.g, color.b, 0.55), 1.5)

func _draw_building_blueprint() -> void:
	if build_kind.is_empty() or not building_specs.has(build_kind):
		return
	var position: Vector2 = _screen_to_world(get_viewport().get_mouse_position())
	var spec: Dictionary = building_specs[build_kind]
	var size: Vector2 = spec.get("size", Vector2(80.0, 60.0)) as Vector2
	var valid: bool = _valid_build_site(position, size)
	var color: Color = Color("72f2bd") if valid else Color("ff7187")
	var rect: Rect2 = Rect2(position - size * 0.5, size)
	draw_rect(rect, Color(color.r, color.g, color.b, 0.17), true)
	draw_rect(rect, color, false, 2.0)
	draw_string(font, position + Vector2(-size.x * 0.46, -size.y * 0.62), str(spec.get("name", "Blueprint")), HORIZONTAL_ALIGNMENT_LEFT, int(size.x), 13, color)

func _draw_buildings() -> void:
	for building: Dictionary in buildings:
		var position: Vector2 = building["pos"] as Vector2
		if str(building.get("team", "")) == SYNDICATE and not _revealed(position):
			continue
		var size: Vector2 = building.get("size", Vector2(70.0, 50.0)) as Vector2
		var accent: Color = _building_color(building)
		var rect: Rect2 = Rect2(position - size * 0.5, size)
		_draw_building_shadow(rect)
		match str(building.get("kind", "")):
			"nexus": _draw_nexus(position, size, accent, building)
			"armory": _draw_armory(position, size, accent, building)
			"relay": _draw_relay(position, size, accent, building)
			"medbay": _draw_medbay(position, size, accent, building)
			"bay": _draw_bay(position, size, accent, building)
			"cells": _draw_cells(position, size, accent, building)
			"syndicate_relay": _draw_syndicate_relay(position, size, accent, building)
			_: _draw_generic_building(position, size, accent)
		if not bool(building.get("done", false)):
			_draw_construction_scaffold(position, size, accent, building)
		_draw_health_bar(position + Vector2(-size.x * 0.44, -size.y * 0.66), size.x * 0.88, float(building.get("hp", 0.0)) / maxf(1.0, float(building.get("max", 1.0))))
		if int(building.get("id", -1)) == selected_building:
			draw_rect(rect.grow(8.0), Color("ffffff"), false, 2.5)

func _draw_building_shadow(rect: Rect2) -> void:
	draw_rect(Rect2(rect.position + Vector2(10.0, 12.0), rect.size), Color(0.01, 0.02, 0.05, 0.42), true)

func _draw_nexus(position: Vector2, size: Vector2, accent: Color, _building: Dictionary) -> void:
	var rect: Rect2 = Rect2(position - size * 0.5, size)
	draw_rect(rect, Color("1d3659"), true)
	draw_rect(rect, accent, false, 3.0)
	draw_rect(Rect2(position + Vector2(-size.x * 0.25, -size.y * 0.16), Vector2(size.x * 0.5, size.y * 0.33)), Color("31527e"), true)
	var hub: Vector2 = position + Vector2(0.0, -size.y * 0.23)
	draw_circle(hub, 20.0, Color(accent.r, accent.g, accent.b, 0.28))
	draw_circle(hub, 9.0 + sin(mission_clock * 3.0) * 1.5, Color("e8faff"))
	for angle_index: int in 4:
		var angle: float = mission_clock * 0.8 + float(angle_index) * TAU / 4.0
		var end_point: Vector2 = hub + Vector2.from_angle(angle) * 31.0
		draw_line(hub, end_point, accent, 2.0)
	for x: float in [-size.x * 0.34, size.x * 0.34]:
		draw_rect(Rect2(position + Vector2(x - 8.0, size.y * 0.12), Vector2(16.0, 28.0)), Color("5a7296"), true)

func _draw_armory(position: Vector2, size: Vector2, accent: Color, _building: Dictionary) -> void:
	var rect: Rect2 = Rect2(position - size * 0.5, size)
	draw_rect(rect, Color("37234f"), true)
	draw_rect(rect, accent, false, 3.0)
	draw_rect(Rect2(position + Vector2(-size.x * 0.34, -size.y * 0.05), Vector2(size.x * 0.68, size.y * 0.42)), Color("171126"), true)
	draw_arc(position + Vector2(0.0, size.y * 0.16), size.x * 0.28, PI, TAU, 16, accent, 2.0)
	for x: float in [-size.x * 0.32, size.x * 0.32]:
		draw_line(position + Vector2(x, -size.y * 0.42), position + Vector2(x, -size.y * 0.15), Color("d8bcff"), 3.0)
		draw_circle(position + Vector2(x, -size.y * 0.44), 4.5, accent)

func _draw_relay(position: Vector2, size: Vector2, accent: Color, _building: Dictionary) -> void:
	var base: PackedVector2Array = PackedVector2Array([position + Vector2(-size.x * 0.46, size.y * 0.37), position + Vector2(0.0, -size.y * 0.42), position + Vector2(size.x * 0.46, size.y * 0.37)])
	draw_colored_polygon(base, Color("183a40"))
	draw_polyline(base, accent, 3.0, true)
	var orb: Vector2 = position + Vector2(0.0, -size.y * 0.27)
	draw_circle(orb, 13.0 + sin(mission_clock * 4.0) * 2.0, Color(accent.r, accent.g, accent.b, 0.36))
	draw_circle(orb, 7.0, Color("eaffff"))

func _draw_medbay(position: Vector2, size: Vector2, accent: Color, _building: Dictionary) -> void:
	var rect: Rect2 = Rect2(position - size * 0.5, size)
	draw_rect(rect, Color("1d4d47"), true)
	draw_rect(rect, accent, false, 3.0)
	draw_rect(Rect2(position + Vector2(-8.0, -size.y * 0.30), Vector2(16.0, size.y * 0.60)), Color("e8fff6"), true)
	draw_rect(Rect2(position + Vector2(-size.x * 0.30, -8.0), Vector2(size.x * 0.60, 16.0)), Color("e8fff6"), true)
	draw_circle(position + Vector2(size.x * 0.28, -size.y * 0.22), 8.0, Color(accent.r, accent.g, accent.b, 0.55))

func _draw_bay(position: Vector2, size: Vector2, accent: Color, _building: Dictionary) -> void:
	var rect: Rect2 = Rect2(position - size * 0.5, size)
	draw_rect(rect, Color("20345e"), true)
	draw_rect(rect, accent, false, 3.0)
	draw_line(position + Vector2(-size.x * 0.42, size.y * 0.22), position + Vector2(size.x * 0.42, size.y * 0.22), Color("d9edff"), 3.0)
	for x: float in [-size.x * 0.24, 0.0, size.x * 0.24]:
		draw_circle(position + Vector2(x, -size.y * 0.15), 7.0, Color(accent.r, accent.g, accent.b, 0.75))

func _draw_cells(position: Vector2, size: Vector2, accent: Color, _building: Dictionary) -> void:
	var rect: Rect2 = Rect2(position - size * 0.5, size)
	draw_rect(rect, Color("57442d"), true)
	draw_rect(rect, accent, false, 3.0)
	for x: float in range(-size.x * 0.32, size.x * 0.34, 14.0):
		draw_line(position + Vector2(x, -size.y * 0.28), position + Vector2(x, size.y * 0.31), Color("f9dd9c"), 2.0)

func _draw_syndicate_relay(position: Vector2, size: Vector2, accent: Color, _building: Dictionary) -> void:
	var rect: Rect2 = Rect2(position - size * 0.5, size)
	draw_rect(rect, Color("4d1735"), true)
	draw_rect(rect, accent, false, 4.0)
	var core: Vector2 = position + Vector2(0.0, -size.y * 0.11)
	for ring: int in 3:
		draw_arc(core, 20.0 + float(ring) * 12.0 + sin(mission_clock * 2.0 + float(ring)) * 2.0, 0.0, TAU, 28, Color(accent.r, accent.g, accent.b, 0.62 - float(ring) * 0.12), 2.0)
	draw_circle(core, 13.0, Color("ffe3f0"))
	draw_line(position + Vector2(-size.x * 0.45, size.y * 0.32), position + Vector2(size.x * 0.45, size.y * 0.32), Color("ff9fc2"), 3.0)

func _draw_generic_building(position: Vector2, size: Vector2, accent: Color) -> void:
	var rect: Rect2 = Rect2(position - size * 0.5, size)
	draw_rect(rect, Color("34425d"), true)
	draw_rect(rect, accent, false, 2.0)

func _draw_construction_scaffold(position: Vector2, size: Vector2, accent: Color, building: Dictionary) -> void:
	var progress: float = float(building.get("progress", 0.0)) / maxf(0.01, float(building.get("build_time", 1.0)))
	var rect: Rect2 = Rect2(position - size * 0.5, size)
	for x: float in range(rect.position.x, rect.end.x + 1.0, 18.0):
		draw_line(Vector2(x, rect.position.y), Vector2(x, rect.end.y), Color(accent.r, accent.g, accent.b, 0.72), 1.5)
	for y: float in range(rect.position.y, rect.end.y + 1.0, 18.0):
		draw_line(Vector2(rect.position.x, y), Vector2(rect.end.x, y), Color(accent.r, accent.g, accent.b, 0.72), 1.5)
	draw_rect(Rect2(position + Vector2(-size.x * 0.38, size.y * 0.63), Vector2(size.x * 0.76 * progress, 7.0)), accent, true)

func _draw_units() -> void:
	for unit: Dictionary in units:
		var position: Vector2 = unit["pos"] as Vector2
		if str(unit.get("team", "")) == SYNDICATE and not _revealed(position):
			continue
		var accent: Color = _unit_color(unit)
		var radius: float = float(unit.get("radius", 16.0))
		if not bool(unit.get("ready", true)):
			var pct: float = float(unit.get("progress", 0.0)) / maxf(0.01, float(unit.get("train_time", 1.0)))
			draw_arc(position, radius + 12.0, -PI * 0.5, -PI * 0.5 + TAU * pct, 18, accent, 3.0)
			continue
		if selected.has(int(unit.get("id", -1))):
			draw_arc(position, radius + 10.0, 0.0, TAU, 20, Color("ecf9ff"), 2.5)
		match str(unit.get("kind", "")):
			"drone": _draw_drone_unit(position, radius, accent, unit)
			"shield": _draw_shield_unit(position, radius, accent, unit)
			"hero": _draw_hero_unit(position, radius, accent, unit)
			"raider": _draw_raider_unit(position, radius, accent, unit)
			"hacker": _draw_hacker_unit(position, radius, accent, unit)
			_: _draw_deputy_unit(position, radius, accent, unit)
		_draw_health_bar(position + Vector2(-radius, -radius - 18.0), radius * 2.0, float(unit.get("hp", 0.0)) / maxf(1.0, float(unit.get("max", 1.0))))
		if int(unit.get("carrying", 0)) > 0:
			draw_circle(position + Vector2(0.0, -radius - 31.0), 5.0, Color("65eaff"))

func _draw_drone_unit(position: Vector2, radius: float, accent: Color, unit: Dictionary) -> void:
	var bob: float = sin(float(unit.get("walk_phase", 0.0)) * 1.5) * 3.0
	var body: PackedVector2Array = PackedVector2Array([position + Vector2(0.0, -radius + bob), position + Vector2(radius, bob), position + Vector2(0.0, radius + bob), position + Vector2(-radius, bob)])
	draw_colored_polygon(body, Color(accent.r, accent.g, accent.b, 0.72))
	draw_polyline(body, Color("eaffff"), 2.0, true)
	for offset: Vector2 in [Vector2(-radius * 1.1, 0.0), Vector2(radius * 1.1, 0.0), Vector2(0.0, -radius * 1.1), Vector2(0.0, radius * 1.1)]:
		draw_line(position + Vector2(0.0, bob), position + offset + Vector2(0.0, bob), accent, 1.5)
		draw_circle(position + offset + Vector2(0.0, bob), 3.5, Color("f4ffff"))

func _draw_deputy_unit(position: Vector2, radius: float, accent: Color, unit: Dictionary) -> void:
	var stride: float = sin(float(unit.get("walk_phase", 0.0))) * 3.0
	draw_circle(position + Vector2(0.0, -radius * 0.48), radius * 0.43, Color("d7f7ff"))
	var body: PackedVector2Array = PackedVector2Array([position + Vector2(-radius * 0.56, radius * 0.62), position + Vector2(-radius * 0.44, -radius * 0.20), position + Vector2(radius * 0.44, -radius * 0.20), position + Vector2(radius * 0.56, radius * 0.62)])
	draw_colored_polygon(body, Color(accent.r, accent.g, accent.b, 0.80))
	draw_polyline(body, Color("1d2f52"), 1.8, true)
	draw_line(position + Vector2(-radius * 0.26, radius * 0.55), position + Vector2(-radius * 0.34, radius + stride), Color("dbeeff"), 2.2)
	draw_line(position + Vector2(radius * 0.26, radius * 0.55), position + Vector2(radius * 0.34, radius - stride), Color("dbeeff"), 2.2)
	var facing: Vector2 = unit.get("facing", Vector2.RIGHT) as Vector2
	draw_line(position + Vector2(radius * 0.28, 0.0), position + facing * radius * 1.2, Color("edf8ff"), 2.5)

func _draw_shield_unit(position: Vector2, radius: float, accent: Color, unit: Dictionary) -> void:
	_draw_deputy_unit(position, radius, accent, unit)
	var shield: PackedVector2Array = PackedVector2Array([position + Vector2(-radius * 1.00, -radius * 0.48), position + Vector2(-radius * 1.35, 0.0), position + Vector2(-radius * 1.0, radius * 0.72), position + Vector2(-radius * 0.58, radius * 0.15)])
	draw_colored_polygon(shield, Color(0.88, 0.72, 1.0, 0.42))
	draw_polyline(shield, Color("f2e6ff"), 2.0, true)

func _draw_hero_unit(position: Vector2, radius: float, accent: Color, unit: Dictionary) -> void:
	_draw_deputy_unit(position, radius, accent, unit)
	draw_arc(position, radius * 1.42 + sin(mission_clock * 4.0) * 2.0, 0.0, TAU, 24, Color("ffd56d"), 2.5)
	draw_circle(position + Vector2(0.0, -radius * 0.52), radius * 0.20, Color("fff3bf"))

func _draw_raider_unit(position: Vector2, radius: float, accent: Color, unit: Dictionary) -> void:
	var facing: Vector2 = unit.get("facing", Vector2.LEFT) as Vector2
	var side: Vector2 = Vector2(-facing.y, facing.x)
	var hull: PackedVector2Array = PackedVector2Array([position + facing * radius, position - facing * radius * 0.65 + side * radius * 0.72, position - facing * radius * 0.65 - side * radius * 0.72])
	draw_colored_polygon(hull, Color(accent.r, accent.g, accent.b, 0.88))
	draw_polyline(hull, Color("ffe0ed"), 1.8, true)
	draw_line(position, position + facing * radius * 1.25, Color("ffcae0"), 2.0)

func _draw_hacker_unit(position: Vector2, radius: float, accent: Color, unit: Dictionary) -> void:
	draw_circle(position, radius * 0.72, Color(accent.r, accent.g, accent.b, 0.70))
	draw_circle(position + Vector2(0.0, -radius * 0.76), radius * 0.36, Color("fff0c6"))
	var phase: float = float(unit.get("walk_phase", 0.0))
	for index: int in 3:
		var angle: float = phase * 1.5 + float(index) * TAU / 3.0
		draw_circle(position + Vector2.from_angle(angle) * radius * 1.05, 3.5, accent)

func _draw_projectiles() -> void:
	for projectile: Dictionary in projectiles:
		var position: Vector2 = projectile["pos"] as Vector2
		var color: Color = projectile["color"] as Color
		draw_circle(position, 5.0, Color(color.r, color.g, color.b, 0.26))
		draw_circle(position, 2.6, Color("ffffff"))

func _draw_effects() -> void:
	for effect: Dictionary in effects:
		var age: float = float(effect.get("age", 0.0))
		var duration: float = maxf(0.01, float(effect.get("duration", 0.5)))
		var ratio: float = clampf(age / duration, 0.0, 1.0)
		var position: Vector2 = effect["pos"] as Vector2
		var color: Color = effect["color"] as Color
		var kind: String = str(effect.get("kind", "impact"))
		if kind == "impact":
			draw_circle(position, 5.0 + ratio * 17.0, Color(color.r, color.g, color.b, (1.0 - ratio) * 0.33), false, 2.0)
		elif kind == "explosion":
			draw_circle(position, 9.0 + ratio * 38.0, Color(color.r, color.g, color.b, (1.0 - ratio) * 0.28))
			draw_arc(position, 12.0 + ratio * 40.0, 0.0, TAU, 20, Color("ffd98a"), 2.0)
		elif kind == "construct":
			draw_arc(position, 18.0 + ratio * 54.0, -PI * 0.5, -PI * 0.5 + TAU * ratio, 24, color, 3.0)
		elif kind == "muzzle":
			draw_circle(position, 6.0 + ratio * 12.0, Color(color.r, color.g, color.b, 1.0 - ratio))
		elif kind == "spark":
			for index: int in 4:
				var angle: float = float(index) * TAU / 4.0 + ratio
				draw_line(position, position + Vector2.from_angle(angle) * (8.0 + ratio * 24.0), Color(color.r, color.g, color.b, 1.0 - ratio), 1.6)
		elif kind == "deposit":
			draw_arc(position, 25.0 + ratio * 38.0, 0.0, TAU, 18, Color(color.r, color.g, color.b, 1.0 - ratio), 2.0)

func _draw_fog() -> void:
	for x: int in range(int(WORLD.position.x / 90.0), int(WORLD.end.x / 90.0)):
		for y: int in range(int(WORLD.position.y / 90.0), int(WORLD.end.y / 90.0)):
			var block: Vector2 = Vector2(float(x) * 90.0, float(y) * 90.0)
			if not _revealed(block + Vector2(45.0, 45.0)):
				draw_rect(Rect2(block, Vector2(90.0, 90.0)), Color(0.01, 0.015, 0.05, 0.48), true)

func _building_color(building: Dictionary) -> Color:
	var accent: Color = building.get("accent", Color.WHITE) as Color
	if float(building.get("hit_flash", 0.0)) > 0.0:
		return Color.WHITE
	return accent

func _draw_health_bar(position: Vector2, width: float, ratio: float) -> void:
	draw_rect(Rect2(position, Vector2(width, 6.0)), Color("07101c"), true)
	var color: Color = Color("72f2bd") if ratio > 0.36 else Color("ff7589")
	draw_rect(Rect2(position, Vector2(width * clampf(ratio, 0.0, 1.0), 6.0)), color, true)
	draw_rect(Rect2(position, Vector2(width, 6.0)), Color("d8edff"), false, 0.8)

func _draw_result_banner(viewport_size: Vector2) -> void:
	var rect: Rect2 = Rect2(viewport_size * 0.5 - Vector2(385.0, 105.0), Vector2(770.0, 210.0))
	var color: Color = Color("efc75e") if victory else Color("ff7187")
	draw_rect(rect, Color(0.01, 0.025, 0.075, 0.95), true)
	draw_rect(rect, color, false, 3.0)
	var heading: String = "OPERATION COMPLETE // BREAKWATER SECURED" if victory else "OPERATION FAILED // NEXUS LOST"
	draw_string(font, rect.position + Vector2(46.0, 76.0), heading, HORIZONTAL_ALIGNMENT_CENTER, int(rect.size.x - 92.0), 28, color)
	draw_string(font, rect.position + Vector2(62.0, 122.0), note, HORIZONTAL_ALIGNMENT_CENTER, int(rect.size.x - 124.0), 15, Color("ecf6ff"))
	draw_string(font, rect.position + Vector2(62.0, 168.0), "PRESS R TO RESTART THE OPERATION", HORIZONTAL_ALIGNMENT_CENTER, int(rect.size.x - 124.0), 14, Color("a9c9e8"))
