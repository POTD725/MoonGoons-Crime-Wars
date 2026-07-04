extends "res://construction_crew_layer.gd"
## Early defense and vehicle-production layer.

const TURRET_KIND: String = "sentry_turret"
const CANNON_KIND: String = "pulse_cannon"
const FACTORY_KIND: String = "machine_shop"
const TANK_KIND: String = "bulwark_rover"

func _ready() -> void:
	_install_defense_specs()
	super._ready()

func _install_defense_specs() -> void:
	building_specs[TURRET_KIND] = {
		"name":"Sentry Turret", "cost":95, "size":Vector2(58.0, 58.0), "hp":620.0, "time":5.0,
		"accent":Color("78d8ff"), "range":255.0, "damage":18.0, "cool":0.52
	}
	building_specs[CANNON_KIND] = {
		"name":"Pulse Cannon", "cost":180, "size":Vector2(76.0, 76.0), "hp":900.0, "time":8.0,
		"accent":Color("ffc46b"), "range":360.0, "damage":42.0, "cool":1.35
	}
	building_specs[FACTORY_KIND] = {
		"name":"Machine Shop", "cost":230, "size":Vector2(128.0, 88.0), "hp":1180.0, "time":10.0,
		"accent":Color("a98cff")
	}
	unit_specs[TANK_KIND] = {
		"name":"Bulwark Rover", "hp":760.0, "speed":76.0, "range":250.0, "damage":38.0, "cool":1.12,
		"radius":30.0, "accent":Color("d9c4ff"), "cost":255, "time":13.0
	}

func _spawn_building(kind: String, team: String, position: Vector2, done: bool) -> Dictionary:
	var building: Dictionary = super._spawn_building(kind, team, position, done)
	var spec: Dictionary = building_specs.get(kind, {}) as Dictionary
	if spec.has("range"):
		building["range"] = float(spec.get("range", 0.0))
		building["damage"] = float(spec.get("damage", 0.0))
		building["cool"] = float(spec.get("cool", 1.0))
		building["attack_clock"] = 0.0
		building["facing"] = Vector2.RIGHT
	if kind == FACTORY_KIND:
		building["rally_point"] = position + Vector2(168.0, 68.0)
	return building

func _update_buildings(delta: float) -> void:
	super._update_buildings(delta)
	for building: Dictionary in buildings:
		if str(building.get("team", "")) != AUTHORITY or not bool(building.get("done", false)):
			continue
		var kind: String = str(building.get("kind", ""))
		if kind == TURRET_KIND or kind == CANNON_KIND:
			_update_defense_weapon(building, delta)

func _update_defense_weapon(building: Dictionary, delta: float) -> void:
	var range_value: float = float(building.get("range", 0.0))
	if range_value <= 0.0:
		return
	var target: Dictionary = _nearest_enemy(building, range_value)
	if target.is_empty():
		return
	var building_position: Vector2 = building.get("pos", Vector2.ZERO) as Vector2
	var target_position: Vector2 = target.get("pos", Vector2.ZERO) as Vector2
	building["facing"] = building_position.direction_to(target_position)
	building["attack_clock"] = float(building.get("attack_clock", 0.0)) + delta
	if float(building.get("attack_clock", 0.0)) < float(building.get("cool", 1.0)):
		return
	building["attack_clock"] = 0.0
	_spawn_projectile(building, target)

func _draw() -> void:
	super._draw()
	var viewport_size: Vector2 = get_viewport_rect().size
	draw_set_transform(viewport_size * 0.5 - camera_position * zoom, 0.0, Vector2.ONE * zoom)
	_draw_defense_overlays()
	_draw_vehicle_overlays()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_defense_overlays() -> void:
	for building: Dictionary in buildings:
		if str(building.get("team", "")) != AUTHORITY:
			continue
		var kind: String = str(building.get("kind", ""))
		var position: Vector2 = building.get("pos", Vector2.ZERO) as Vector2
		if kind == TURRET_KIND:
			var facing: Vector2 = building.get("facing", Vector2.RIGHT) as Vector2
			draw_circle(position, 20.0, Color("102c47"))
			draw_circle(position, 20.0, Color("78d8ff"), false, 2.0)
			draw_rect(Rect2(position - Vector2(10.0, 9.0), Vector2(20.0, 18.0)), Color("5d9cbf"), true)
			draw_line(position, position + facing * 36.0, Color("d8f8ff"), 7.0)
			draw_circle(position + facing * 36.0, 5.0, Color("8fe9ff"))
		elif kind == CANNON_KIND:
			var cannon_facing: Vector2 = building.get("facing", Vector2.RIGHT) as Vector2
			draw_circle(position, 28.0, Color("3b2734"))
			draw_circle(position, 28.0, Color("ffc46b"), false, 2.5)
			draw_rect(Rect2(position - Vector2(14.0, 12.0), Vector2(28.0, 24.0)), Color("8e6249"), true)
			draw_line(position, position + cannon_facing * 47.0, Color("ffe1a8"), 10.0)
			draw_circle(position + cannon_facing * 47.0, 7.0, Color("fff5d7"))
		elif kind == FACTORY_KIND:
			var shop_rect: Rect2 = Rect2(position - Vector2(64.0, 44.0), Vector2(128.0, 88.0))
			draw_rect(shop_rect, Color("201a39"), true)
			draw_rect(shop_rect, Color("b9a4ff"), false, 3.0)
			draw_line(position + Vector2(-52.0, -8.0), position + Vector2(52.0, -8.0), Color("8a71cc"), 6.0)
			draw_circle(position + Vector2(-34.0, 24.0), 10.0, Color("71e7ff"))
			draw_circle(position + Vector2(34.0, 24.0), 10.0, Color("71e7ff"))
			draw_string(font, position + Vector2(-47.0, 9.0), "MACHINE", HORIZONTAL_ALIGNMENT_LEFT, 98, 12, Color("eeeaff"))

func _draw_vehicle_overlays() -> void:
	for unit: Dictionary in units:
		if str(unit.get("team", "")) != AUTHORITY or str(unit.get("kind", "")) != TANK_KIND:
			continue
		var position: Vector2 = unit.get("pos", Vector2.ZERO) as Vector2
		var facing: Vector2 = unit.get("facing", Vector2.RIGHT) as Vector2
		var right: Vector2 = Vector2(-facing.y, facing.x)
		var body: PackedVector2Array = PackedVector2Array([
			position + facing * 24.0 + right * 17.0,
			position + facing * 24.0 - right * 17.0,
			position - facing * 20.0 - right * 17.0,
			position - facing * 20.0 + right * 17.0
		])
		draw_colored_polygon(body, Color("4a4168"))
		draw_polyline(body, Color("d9c4ff"), 2.0, true)
		draw_circle(position + facing * 3.0, 12.0, Color("786b9d"))
		draw_line(position + facing * 9.0, position + facing * 42.0, Color("eee6ff"), 7.0)
		draw_circle(position - right * 18.0, 7.0, Color("18202f"))
		draw_circle(position + right * 18.0, 7.0, Color("18202f"))
