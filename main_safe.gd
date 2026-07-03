extends Node2D
## Typed playable RTS core used by the first Crime Wars demo.

const WORLD: Rect2 = Rect2(-1150, -760, 2500, 1500)
const AUTH: String = "authority"
const SYND: String = "syndicate"

var cam: Vector2 = Vector2(60, 50)
var zoom: float = 0.82
var credits: int = 420
var supplies: int = 180
var intel: int = 0
var units: Array[Dictionary] = []
var buildings: Array[Dictionary] = []
var nodes: Array[Dictionary] = []
var selected: Array[int] = []
var selected_building: int = -1
var next_id: int = 1
var build_kind: String = ""
var drag_from: Vector2 = Vector2.ZERO
var dragging: bool = false
var wave_clock: float = 0.0
var finished: bool = false
var victory: bool = false
var note: String = ""
var note_time: float = 0.0
var font: Font

var B: Dictionary = {
	"nexus": {"name":"Command Nexus", "cost":0, "size":Vector2(116,86), "hp":1250, "time":0.0, "color":Color("5976e8")},
	"armory": {"name":"Tactical Armory", "cost":160, "size":Vector2(94,72), "hp":850, "time":8.0, "color":Color("bd76ef")},
	"relay": {"name":"Power Relay", "cost":60, "size":Vector2(52,52), "hp":420, "time":4.0, "color":Color("62dcea")},
	"medbay": {"name":"Field Medbay", "cost":120, "size":Vector2(78,62), "hp":620, "time":6.0, "color":Color("64dfb2")},
	"bay": {"name":"Drone Bay", "cost":110, "size":Vector2(82,62), "hp":600, "time":6.0, "color":Color("79a9ff")},
	"cells": {"name":"Containment Block", "cost":170, "size":Vector2(100,76), "hp":920, "time":8.0, "color":Color("f4b96b")},
	"syndicate_relay": {"name":"Syndicate Relay", "cost":0, "size":Vector2(138,100), "hp":1650, "time":0.0, "color":Color("ef5877")}
}

var U: Dictionary = {
	"drone": {"name":"Builder Drone", "hp":90, "speed":145.0, "range":0.0, "damage":0, "cool":0.0, "r":15.0, "color":Color("91edff"), "cost":65, "time":4.0},
	"deputy": {"name":"Patrol Deputy", "hp":155, "speed":122.0, "range":155.0, "damage":13, "cool":0.65, "r":18.0, "color":Color("a0baff"), "cost":85, "time":5.0},
	"shield": {"name":"Shield Deputy", "hp":280, "speed":92.0, "range":105.0, "damage":20, "cool":0.85, "r":22.0, "color":Color("dda7ff"), "cost":145, "time":8.0},
	"hero": {"name":"Field Commander", "hp":420, "speed":116.0, "range":185.0, "damage":28, "cool":0.75, "r":24.0, "color":Color("ffd16a"), "cost":0, "time":0.0},
	"raider": {"name":"Syndicate Raider", "hp":130, "speed":110.0, "range":130.0, "damage":11, "cool":0.8, "r":18.0, "color":Color("ff8094"), "cost":0, "time":0.0},
	"hacker": {"name":"Syndicate Hacker", "hp":90, "speed":104.0, "range":190.0, "damage":8, "cool":0.52, "r":15.0, "color":Color("ffc36e"), "cost":0, "time":0.0}
}

func _ready() -> void:
	font = ThemeDB.fallback_font
	_setup_breakwater()
	flash("Operation Breakwater: build an Armory, train a force, and silence the Syndicate Relay.", 8.0)

func _setup_breakwater() -> void:
	_spawn_building("nexus", AUTH, Vector2(-260, 145), true)
	for pos: Vector2 in [Vector2(-166,180), Vector2(-215,245), Vector2(-310,255)]:
		_spawn_unit("drone", AUTH, pos)
	for pos: Vector2 in [Vector2(-145,92), Vector2(-332,78)]:
		_spawn_unit("deputy", AUTH, pos)
	_spawn_node("ore", Vector2(-550,210), 980)
	_spawn_node("ore", Vector2(-420,-95), 720)
	_spawn_node("evidence", Vector2(90,280), 480)
	_spawn_node("ore", Vector2(210,-155), 930)
	_spawn_node("evidence", Vector2(480,150), 520)
	_spawn_building("syndicate_relay", SYND, Vector2(780,-250), true)
	for pos: Vector2 in [Vector2(675,-180), Vector2(845,-145), Vector2(895,-330)]:
		_spawn_unit("raider", SYND, pos)
	for pos: Vector2 in [Vector2(740,-385), Vector2(990,-250)]:
		_spawn_unit("hacker", SYND, pos)

func _process(delta: float) -> void:
	if finished:
		queue_redraw()
		return
	note_time = maxf(0.0, note_time - delta)
	_move_camera(delta)
	_update_buildings(delta)
	_update_units(delta)
	_heal_units(delta)
	wave_clock += delta
	if wave_clock >= 35.0:
		wave_clock = 0.0
		_spawn_enemy_wave()
	_cleanup()
	_check_end()
	queue_redraw()

func _move_camera(delta: float) -> void:
	var direction: Vector2 = Vector2.ZERO
	if Input.is_key_pressed(KEY_W): direction.y -= 1.0
	if Input.is_key_pressed(KEY_S): direction.y += 1.0
	if Input.is_key_pressed(KEY_A): direction.x -= 1.0
	if Input.is_key_pressed(KEY_D): direction.x += 1.0
	if direction.length_squared() > 0.0:
		cam += direction.normalized() * 720.0 * delta / zoom
		cam.x = clampf(cam.x, WORLD.position.x + 320.0, WORLD.end.x - 320.0)
		cam.y = clampf(cam.y, WORLD.position.y + 220.0, WORLD.end.y - 220.0)

func _update_buildings(delta: float) -> void:
	for building: Dictionary in buildings:
		if not bool(building.get("done", false)):
			building["progress"] = minf(float(building.get("progress", 0.0)) + delta, float(building.get("time", 0.0)))
			if float(building["progress"]) >= float(building["time"]):
				building["done"] = true
				flash(str(building.get("name", "Structure")) + " is online.", 2.5)

func _update_units(delta: float) -> void:
	for unit: Dictionary in units:
		if not bool(unit.get("ready", true)):
			unit["progress"] = float(unit.get("progress", 0.0)) + delta
			if float(unit["progress"]) >= float(unit.get("time", 0.0)):
				unit["ready"] = true
				flash(str(unit.get("name", "Unit")) + " deployed.", 2.0)
			continue
		if str(unit.get("team", AUTH)) == SYND:
			_enemy_ai(unit, delta)
		else:
			_authority_ai(unit, delta)

func _authority_ai(unit: Dictionary, delta: float) -> void:
	var order: String = str(unit.get("order", "idle"))
	if order == "move":
		_walk(unit, unit.get("target", unit["pos"]) as Vector2, delta)
		if (unit["pos"] as Vector2).distance_to(unit.get("target", unit["pos"]) as Vector2) < 4.0:
			unit["order"] = "idle"
	elif order == "attack":
		var target: Dictionary = _entity(int(unit.get("target_id", -1)))
		if target.is_empty():
			unit["order"] = "idle"
		elif (unit["pos"] as Vector2).distance_to(target["pos"] as Vector2) > float(unit.get("range", 0.0)):
			_walk(unit, target["pos"] as Vector2, delta)
		else:
			_hit(unit, target, delta)
	elif order == "harvest":
		_harvest(unit, delta)
	else:
		var enemy: Dictionary = _enemy_near(unit, float(unit.get("range", 0.0)))
		if not enemy.is_empty():
			_hit(unit, enemy, delta)

func _enemy_ai(unit: Dictionary, delta: float) -> void:
	var target: Dictionary = _closest_authority(unit)
	if target.is_empty():
		return
	if (unit["pos"] as Vector2).distance_to(target["pos"] as Vector2) > float(unit.get("range", 0.0)):
		_walk(unit, target["pos"] as Vector2, delta)
	else:
		_hit(unit, target, delta)

func _walk(unit: Dictionary, target: Vector2, delta: float) -> void:
	unit["pos"] = (unit["pos"] as Vector2).move_toward(target, float(unit.get("speed", 0.0)) * delta)

func _harvest(unit: Dictionary, delta: float) -> void:
	var index: int = int(unit.get("target_id", -1))
	if index < 0 or index >= nodes.size():
		unit["order"] = "idle"
		return
	var resource: Dictionary = nodes[index]
	if int(resource.get("amount", 0)) <= 0:
		unit["order"] = "idle"
		flash("Resource deposit exhausted.", 2.0)
		return
	if (unit["pos"] as Vector2).distance_to(resource["pos"] as Vector2) > 48.0:
		_walk(unit, resource["pos"] as Vector2, delta)
		return
	unit["harvest"] = float(unit.get("harvest", 0.0)) + delta
	if float(unit["harvest"]) >= 1.0:
		unit["harvest"] = 0.0
		resource["amount"] = maxi(0, int(resource["amount"]) - 20)
		if str(resource.get("type", "ore")) == "ore":
			credits += 14
			supplies += 4
		else:
			credits += 8
			intel += 5

func _hit(attacker: Dictionary, target: Dictionary, delta: float) -> void:
	if int(attacker.get("damage", 0)) <= 0:
		return
	attacker["attack"] = float(attacker.get("attack", 0.0)) + delta
	if float(attacker["attack"]) < float(attacker.get("cool", 1.0)):
		return
	attacker["attack"] = 0.0
	target["hp"] = float(target.get("hp", 0.0)) - float(attacker.get("damage", 0))
	if float(target["hp"]) <= 0.0 and str(target.get("team", "")) == SYND:
		credits += 18
		intel += 3

func _heal_units(delta: float) -> void:
	for building: Dictionary in buildings:
		if str(building.get("team", "")) != AUTH or str(building.get("kind", "")) != "medbay" or not bool(building.get("done", false)):
			continue
		for unit: Dictionary in units:
			if str(unit.get("team", "")) == AUTH and (unit["pos"] as Vector2).distance_to(building["pos"] as Vector2) < 150.0:
				unit["hp"] = minf(float(unit.get("max", 0.0)), float(unit.get("hp", 0.0)) + delta * 9.0)

func _spawn_enemy_wave() -> void:
	var relay: Dictionary = _relay()
	if relay.is_empty():
		return
	for offset: Vector2 in [Vector2(-130,110), Vector2(120,90), Vector2(25,-145)]:
		_spawn_unit("raider", SYND, relay["pos"] as Vector2 + offset)
	flash("Syndicate reinforcements have deployed.", 3.0)

func _cleanup() -> void:
	units = units.filter(func(entry: Dictionary) -> bool: return float(entry.get("hp", 0.0)) > 0.0)
	buildings = buildings.filter(func(entry: Dictionary) -> bool: return float(entry.get("hp", 0.0)) > 0.0)
	selected = selected.filter(func(entity_id: int) -> bool: return not _entity(entity_id).is_empty())
	if selected_building != -1 and _entity(selected_building).is_empty():
		selected_building = -1

func _check_end() -> void:
	if _relay().is_empty():
		finished = true
		victory = true
		flash("Operation Breakwater complete. The Relay is silent.", 999.0)
		return
	var nexus_alive: bool = false
	for building: Dictionary in buildings:
		if str(building.get("team", "")) == AUTH and str(building.get("kind", "")) == "nexus":
			nexus_alive = true
	if not nexus_alive:
		finished = true
		victory = false
		flash("The Command Nexus has fallen.", 999.0)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			zoom = clampf(zoom * 1.12, 0.48, 1.42)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			zoom = clampf(zoom / 1.12, 0.48, 1.42)
		elif event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				drag_from = event.position
				dragging = true
				if not build_kind.is_empty():
					_place(_world(event.position))
					dragging = false
			else:
				if dragging:
					_select(_world(event.position))
				dragging = false
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			_order(_world(event.position))
	elif event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_ESCAPE:
				build_kind = ""
				flash("Build order cancelled.", 1.5)
			KEY_1: _build("armory")
			KEY_2: _build("relay")
			KEY_3: _build("medbay")
			KEY_4: _build("bay")
			KEY_5: _build("cells")
			KEY_Q: _train("deputy")
			KEY_E: _train("drone")
			KEY_R: _train("shield")

func _select(point: Vector2) -> void:
	if finished:
		return
	selected.clear()
	selected_building = -1
	var start: Vector2 = _world(drag_from)
	var box: Rect2 = Rect2(start, point - start).abs()
	if box.size.length() < 20.0:
		var unit: Dictionary = _our_unit(point)
		if not unit.is_empty():
			selected.append(int(unit["id"]))
			return
		var building: Dictionary = _our_building(point)
		if not building.is_empty():
			selected_building = int(building["id"])
		return
	for unit: Dictionary in units:
		if str(unit.get("team", "")) == AUTH and box.has_point(unit["pos"] as Vector2):
			selected.append(int(unit["id"]))

func _order(point: Vector2) -> void:
	if selected.is_empty() or finished:
		return
	var enemy: Dictionary = _enemy_at(point)
	var resource_index: int = _node_at(point)
	var formation: int = 0
	for unit_id: int in selected:
		var unit: Dictionary = _entity(unit_id)
		if unit.is_empty():
			continue
		if not enemy.is_empty():
			unit["order"] = "attack"
			unit["target_id"] = int(enemy["id"])
		elif str(unit.get("kind", "")) == "drone" and resource_index >= 0:
			unit["order"] = "harvest"
			unit["target_id"] = resource_index
		else:
			unit["order"] = "move"
			unit["target"] = point + Vector2((formation % 3 - 1) * 28.0, (formation / 3 - 1) * 28.0)
			formation += 1

func _build(kind: String) -> void:
	if not B.has(kind):
		return
	if not _has_drone():
		flash("Select a Builder Drone before placing a structure.", 2.5)
		return
	build_kind = kind
	var spec: Dictionary = B[kind]
	flash("Place " + str(spec.get("name", "structure")) + " with left-click.", 3.0)

func _place(point: Vector2) -> void:
	if build_kind.is_empty() or not B.has(build_kind):
		return
	var spec: Dictionary = B[build_kind]
	if credits < int(spec.get("cost", 0)):
		flash("Insufficient Credits.", 2.0)
		return
	var size: Vector2 = spec.get("size", Vector2(50, 50)) as Vector2
	if not _valid(point, size):
		flash("Construction zone blocked.", 2.0)
		return
	credits -= int(spec.get("cost", 0))
	_spawn_building(build_kind, AUTH, point, false)
	build_kind = ""

func _train(kind: String) -> void:
	if not U.has(kind):
		return
	var producer: Dictionary = _producer(kind)
	if producer.is_empty():
		flash("Select a Command Nexus, or an Armory for Shield Deputies.", 2.5)
		return
	var spec: Dictionary = U[kind]
	if credits < int(spec.get("cost", 0)):
		flash("Insufficient Credits.", 2.0)
		return
	credits -= int(spec.get("cost", 0))
	var unit: Dictionary = _spawn_unit(kind, AUTH, producer["pos"] as Vector2 + Vector2(88, 58))
	unit["ready"] = false
	unit["progress"] = 0.0
	unit["time"] = float(spec.get("time", 0.0))
	flash(str(spec.get("name", "Unit")) + " queued.", 2.0)

func _has_drone() -> bool:
	for unit_id: int in selected:
		var unit: Dictionary = _entity(unit_id)
		if not unit.is_empty() and str(unit.get("kind", "")) == "drone":
			return true
	return false

func _producer(kind: String) -> Dictionary:
	var building: Dictionary = _entity(selected_building)
	if building.is_empty() or not bool(building.get("done", false)):
		return {}
	if kind == "shield" and str(building.get("kind", "")) == "armory":
		return building
	if kind != "shield" and str(building.get("kind", "")) == "nexus":
		return building
	return {}

func _spawn_unit(kind: String, team: String, position: Vector2) -> Dictionary:
	var spec: Dictionary = U.get(kind, U["deputy"]) as Dictionary
	var hp: float = float(spec.get("hp", 100.0))
	var unit: Dictionary = {"id":next_id, "kind":kind, "name":str(spec.get("name", kind)), "team":team, "pos":position, "target":position, "target_id":-1, "order":"idle", "hp":hp, "max":hp, "speed":float(spec.get("speed", 100.0)), "range":float(spec.get("range", 0.0)), "damage":int(spec.get("damage", 0)), "cool":float(spec.get("cool", 1.0)), "r":float(spec.get("r", 16.0)), "color":spec.get("color", Color.WHITE), "attack":0.0, "harvest":0.0, "ready":true, "progress":0.0, "time":0.0}
	next_id += 1
	units.append(unit)
	return unit

func _spawn_building(kind: String, team: String, position: Vector2, done: bool) -> Dictionary:
	var spec: Dictionary = B.get(kind, B["nexus"]) as Dictionary
	var hp: float = float(spec.get("hp", 500.0))
	var build_time: float = float(spec.get("time", 0.0))
	var building: Dictionary = {"id":next_id, "kind":kind, "name":str(spec.get("name", kind)), "team":team, "pos":position, "hp":hp, "max":hp, "size":spec.get("size", Vector2(70, 50)), "color":spec.get("color", Color.WHITE), "done":done, "time":build_time, "progress":build_time if done else 0.0}
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

func _relay() -> Dictionary:
	for building: Dictionary in buildings:
		if str(building.get("kind", "")) == "syndicate_relay":
			return building
	return {}

func _enemy_near(unit: Dictionary, distance: float) -> Dictionary:
	if distance <= 0.0:
		return {}
	var best: Dictionary = {}
	var best_distance: float = distance
	for entity: Dictionary in units + buildings:
		if str(entity.get("team", "")) == SYND:
			var measured: float = (unit["pos"] as Vector2).distance_to(entity["pos"] as Vector2)
			if measured < best_distance:
				best = entity
				best_distance = measured
	return best

func _closest_authority(unit: Dictionary) -> Dictionary:
	var best: Dictionary = {}
	var best_distance: float = INF
	for entity: Dictionary in units + buildings:
		if str(entity.get("team", "")) == AUTH:
			var measured: float = (unit["pos"] as Vector2).distance_to(entity["pos"] as Vector2)
			if measured < best_distance:
				best = entity
				best_distance = measured
	return best

func _our_unit(point: Vector2) -> Dictionary:
	var best: Dictionary = {}
	var best_distance: float = 34.0
	for unit: Dictionary in units:
		if str(unit.get("team", "")) == AUTH:
			var measured: float = point.distance_to(unit["pos"] as Vector2)
			if measured < best_distance:
				best = unit
				best_distance = measured
	return best

func _our_building(point: Vector2) -> Dictionary:
	for building: Dictionary in buildings:
		var size: Vector2 = building.get("size", Vector2(70, 50)) as Vector2
		if str(building.get("team", "")) == AUTH and Rect2(building["pos"] as Vector2 - size * 0.5, size).has_point(point):
			return building
	return {}

func _enemy_at(point: Vector2) -> Dictionary:
	var best: Dictionary = {}
	var best_distance: float = 44.0
	for unit: Dictionary in units:
		if str(unit.get("team", "")) == SYND and _revealed(unit["pos"] as Vector2):
			var measured: float = point.distance_to(unit["pos"] as Vector2)
			if measured < best_distance:
				best = unit
				best_distance = measured
	for building: Dictionary in buildings:
		var size: Vector2 = building.get("size", Vector2(70, 50)) as Vector2
		if str(building.get("team", "")) == SYND and _revealed(building["pos"] as Vector2) and Rect2(building["pos"] as Vector2 - size * 0.5, size).grow(20.0).has_point(point):
			return building
	return best

func _node_at(point: Vector2) -> int:
	var selected_index: int = -1
	var best_distance: float = 54.0
	for index: int in nodes.size():
		var resource: Dictionary = nodes[index]
		if int(resource.get("amount", 0)) > 0:
			var measured: float = point.distance_to(resource["pos"] as Vector2)
			if measured < best_distance:
				selected_index = index
				best_distance = measured
	return selected_index

func _valid(point: Vector2, size: Vector2) -> bool:
	var candidate: Rect2 = Rect2(point - size * 0.5, size)
	if not WORLD.grow(-80.0).encloses(candidate):
		return false
	for building: Dictionary in buildings:
		var other_size: Vector2 = building.get("size", Vector2(70, 50)) as Vector2
		if candidate.grow(30.0).intersects(Rect2(building["pos"] as Vector2 - other_size * 0.5, other_size)):
			return false
	for resource: Dictionary in nodes:
		if candidate.grow(22.0).has_point(resource["pos"] as Vector2):
			return false
	return true

func _world(screen: Vector2) -> Vector2:
	return cam + (screen - get_viewport_rect().size * 0.5) / zoom

func _revealed(point: Vector2) -> bool:
	for entity: Dictionary in units + buildings:
		if str(entity.get("team", "")) == AUTH and (entity["pos"] as Vector2).distance_to(point) < 340.0:
			return true
	return false

func flash(message: String, duration: float = 3.0) -> void:
	note = message
	note_time = duration

func _draw() -> void:
	var view: Vector2 = get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, view), Color("071021"), true)
	draw_set_transform(view * 0.5 - cam * zoom, 0.0, Vector2.ONE * zoom)
	_draw_terrain()
	_draw_resources()
	_draw_buildings()
	_draw_units()
	_draw_fog()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if dragging and build_kind.is_empty():
		draw_rect(Rect2(drag_from, get_viewport().get_mouse_position() - drag_from).abs(), Color(0.6, 0.8, 1.0, 0.12), true)
	if finished:
		_draw_banner(view)

func _draw_terrain() -> void:
	draw_rect(WORLD, Color("131e33"), true)
	for x: int in range(int(WORLD.position.x), int(WORLD.end.x), 80):
		draw_line(Vector2(x, WORLD.position.y), Vector2(x, WORLD.end.y), Color(0.24, 0.32, 0.47, 0.36))
	for y: int in range(int(WORLD.position.y), int(WORLD.end.y), 80):
		draw_line(Vector2(WORLD.position.x, y), Vector2(WORLD.end.x, y), Color(0.24, 0.32, 0.47, 0.36))
	draw_rect(WORLD, Color("5d759e"), false, 5.0)

func _draw_resources() -> void:
	for resource: Dictionary in nodes:
		if int(resource.get("amount", 0)) <= 0:
			continue
		var color: Color = Color("65e6ff") if str(resource.get("type", "ore")) == "ore" else Color("ffc15e")
		var position: Vector2 = resource["pos"] as Vector2
		draw_circle(position, 29.0, Color(color.r, color.g, color.b, 0.22))
		for index: int in 5:
			var angle: float = float(index) * TAU / 5.0
			draw_colored_polygon(PackedVector2Array([position, position + Vector2.from_angle(angle - 0.35) * 26.0, position + Vector2.from_angle(angle + 0.22) * 30.0]), color)

func _draw_buildings() -> void:
	for building: Dictionary in buildings:
		if str(building.get("team", "")) == SYND and not _revealed(building["pos"] as Vector2):
			continue
		var size: Vector2 = building.get("size", Vector2(70, 50)) as Vector2
		var rect: Rect2 = Rect2(building["pos"] as Vector2 - size * 0.5, size)
		var color: Color = building.get("color", Color.WHITE) as Color
		draw_rect(rect.grow(9.0), Color(color.r, color.g, color.b, 0.10), true)
		draw_rect(rect, Color(color.r, color.g, color.b, 0.30 if bool(building.get("done", false)) else 0.14), true)
		draw_rect(rect, color.lightened(0.25), false, 3.0 if int(building.get("id", -1)) == selected_building else 2.0)
		_bar(building["pos"] as Vector2 + Vector2(-size.x * 0.45, -size.y * 0.63), size.x * 0.9, float(building.get("hp", 0.0)) / maxf(1.0, float(building.get("max", 1.0))))
		if not bool(building.get("done", false)):
			var time: float = maxf(0.01, float(building.get("time", 1.0)))
			draw_rect(Rect2(building["pos"] as Vector2 + Vector2(-size.x * 0.4, size.y * 0.5 + 27.0), Vector2(size.x * 0.8 * float(building.get("progress", 0.0)) / time, 6.0)), Color("6ee4d2"), true)

func _draw_units() -> void:
	for unit: Dictionary in units:
		if str(unit.get("team", "")) == SYND and not _revealed(unit["pos"] as Vector2):
			continue
		var position: Vector2 = unit["pos"] as Vector2
		var radius: float = float(unit.get("r", 16.0))
		var color: Color = unit.get("color", Color.WHITE) as Color
		if not bool(unit.get("ready", true)):
			var time: float = maxf(0.01, float(unit.get("time", 1.0)))
			draw_arc(position, radius + 10.0, -PI * 0.5, -PI * 0.5 + TAU * float(unit.get("progress", 0.0)) / time, 18, color, 3.0)
			continue
		if selected.has(int(unit.get("id", -1))):
			draw_arc(position, radius + 9.0, 0.0, TAU, 20, Color("deecff"), 2.5)
		if str(unit.get("team", "")) == AUTH:
			draw_circle(position, radius + 6.0, Color(color.r, color.g, color.b, 0.16))
			draw_circle(position, radius, Color(color.r, color.g, color.b, 0.82))
			draw_circle(position, radius * 0.45, Color("101b31"))
		else:
			draw_colored_polygon(PackedVector2Array([position + Vector2(0, -radius), position + Vector2(radius, radius), position + Vector2(-radius, radius)]), Color(color.r, color.g, color.b, 0.9))
		_bar(position + Vector2(-radius, -radius - 17.0), radius * 2.0, float(unit.get("hp", 0.0)) / maxf(1.0, float(unit.get("max", 1.0))))

func _draw_fog() -> void:
	for x: int in range(int(WORLD.position.x / 80.0), int(WORLD.end.x / 80.0)):
		for y: int in range(int(WORLD.position.y / 80.0), int(WORLD.end.y / 80.0)):
			var point: Vector2 = Vector2(x * 80.0, y * 80.0)
			if not _revealed(point + Vector2(40, 40)):
				draw_rect(Rect2(point, Vector2(80, 80)), Color(0.01, 0.02, 0.06, 0.48), true)

func _bar(position: Vector2, width: float, ratio: float) -> void:
	draw_rect(Rect2(position, Vector2(width, 6.0)), Color("09111e"), true)
	draw_rect(Rect2(position, Vector2(width * clampf(ratio, 0.0, 1.0), 6.0)), Color("72f2bd") if ratio > 0.35 else Color("ff7187"), true)

func _draw_banner(view: Vector2) -> void:
	var rect: Rect2 = Rect2(view * 0.5 - Vector2(360, 100), Vector2(720, 200))
	draw_rect(rect, Color(0.01, 0.03, 0.08, 0.94), true)
	draw_rect(rect, Color("efc75e") if victory else Color("ff7187"), false, 3.0)
	var title: String = "MISSION COMPLETE" if victory else "MISSION FAILED"
	draw_string(font, rect.position + Vector2(190, 82), title, HORIZONTAL_ALIGNMENT_CENTER, 340, 30, Color("efc75e") if victory else Color("ff7187"))
	draw_string(font, rect.position + Vector2(80, 132), note, HORIZONTAL_ALIGNMENT_CENTER, 560, 16, Color("eaf5ff"))
