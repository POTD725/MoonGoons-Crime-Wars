extends "res://rally_beacon_layer.gd"
## Authority operations layer: arrow-key camera control, hostile-environment infrastructure, and air support.

const AIR_STRIKE_COST_INTEL: int = 25
const AIR_STRIKE_RADIUS: float = 145.0
const AIR_STRIKE_DAMAGE: float = 110.0
const AIR_STRIKE_COOLDOWN: float = 18.0

var oxygen_reserve: float = 100.0
var air_support_cooldown: float = 0.0
var environment_tick: float = 0.0

func _ready() -> void:
	super._ready()
	_install_operations_specs()

func _install_operations_specs() -> void:
	building_specs["air_support_pad"] = {
		"name":"Air Support Pad", "cost":260, "size":Vector2(132.0, 86.0), "hp":980.0, "time":10.0,
		"accent":Color("77c8ff")
	}
	building_specs["o2_generator"] = {
		"name":"O2 Generator", "cost":145, "size":Vector2(76.0, 72.0), "hp":720.0, "time":6.0,
		"accent":Color("77f7d8")
	}
	building_specs["thermal_regulator"] = {
		"name":"Thermal Regulator", "cost":135, "size":Vector2(82.0, 68.0), "hp":760.0, "time":6.0,
		"accent":Color("ffbf7c")
	}
	building_specs["radiation_array"] = {
		"name":"Radiation Shield Array", "cost":210, "size":Vector2(96.0, 84.0), "hp":860.0, "time":8.0,
		"accent":Color("c09cff")
	}

func _process(delta: float) -> void:
	super._process(delta)
	air_support_cooldown = maxf(0.0, air_support_cooldown - delta)
	if not finished:
		_update_environment_support(delta)

func _movement_camera(delta: float) -> void:
	var direction: Vector2 = Vector2.ZERO
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		direction.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		direction.y += 1.0
	if (Input.is_key_pressed(KEY_A) and not attack_move_pending) or Input.is_key_pressed(KEY_LEFT):
		direction.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
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

func _update_environment_support(delta: float) -> void:
	var oxygen_generators: Array[Dictionary] = _completed_authority_buildings("o2_generator")
	var thermal_units: Array[Dictionary] = _completed_authority_buildings("thermal_regulator")
	if not oxygen_generators.is_empty():
		oxygen_reserve = minf(100.0, oxygen_reserve + delta * float(oxygen_generators.size()) * 1.8)
		for unit: Dictionary in units:
			if str(unit.get("team", "")) != AUTHORITY or not bool(unit.get("ready", true)):
				continue
			for generator: Dictionary in oxygen_generators:
				if (unit.get("pos", Vector2.ZERO) as Vector2).distance_to(generator.get("pos", Vector2.ZERO) as Vector2) <= 178.0:
					unit["hp"] = minf(float(unit.get("max", 0.0)), float(unit.get("hp", 0.0)) + 4.0 * delta)
					break
	else:
		oxygen_reserve = maxf(0.0, oxygen_reserve - delta * 0.08)
	if not thermal_units.is_empty():
		for building: Dictionary in buildings:
			if bool(building.get("done", false)) or str(building.get("team", "")) != AUTHORITY:
				continue
			for regulator: Dictionary in thermal_units:
				if (building.get("pos", Vector2.ZERO) as Vector2).distance_to(regulator.get("pos", Vector2.ZERO) as Vector2) <= 245.0:
					building["progress"] = minf(float(building.get("build_time", 0.0)), float(building.get("progress", 0.0)) + delta * 0.18)
					break
	environment_tick += delta
	if environment_tick >= 4.0 and not oxygen_generators.is_empty():
		environment_tick = 0.0
		supplies += oxygen_generators.size()

func _completed_authority_buildings(kind: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for building: Dictionary in buildings:
		if str(building.get("team", "")) == AUTHORITY and str(building.get("kind", "")) == kind and bool(building.get("done", false)):
			result.append(building)
	return result

func _request_air_strike(target: Vector2) -> void:
	if _completed_authority_buildings("air_support_pad").is_empty():
		flash("Build and finish an Air Support Pad before requesting air support.", 3.0)
		_sound("error")
		return
	if air_support_cooldown > 0.0:
		flash("Air support rearming // %ds remaining." % int(ceil(air_support_cooldown)), 2.0)
		_sound("error")
		return
	if intel < AIR_STRIKE_COST_INTEL:
		flash("Air strike requires %d Intel." % AIR_STRIKE_COST_INTEL, 2.4)
		_sound("error")
		return
	intel -= AIR_STRIKE_COST_INTEL
	air_support_cooldown = AIR_STRIKE_COOLDOWN
	effects.append({"kind":"air_strike", "pos":target, "color":Color("79d8ff"), "age":0.0, "duration":1.55, "resolved":false})
	flash("AIR SUPPORT INBOUND // Target painted. Impact in 1.5 seconds.", 2.2)
	_sound("alert")

func _update_effects(delta: float) -> void:
	var live_effects: Array[Dictionary] = []
	for effect: Dictionary in effects:
		effect["age"] = float(effect.get("age", 0.0)) + delta
		if str(effect.get("kind", "")) == "air_strike" and float(effect.get("age", 0.0)) >= 1.0 and not bool(effect.get("resolved", false)):
			effect["resolved"] = true
			_resolve_air_strike(effect.get("pos", Vector2.ZERO) as Vector2)
		if float(effect.get("age", 0.0)) < float(effect.get("duration", 0.5)):
			live_effects.append(effect)
	effects = live_effects

func _resolve_air_strike(target: Vector2) -> void:
	var hits: int = 0
	for unit: Dictionary in units:
		if str(unit.get("team", "")) == SYNDICATE and (unit.get("pos", Vector2.ZERO) as Vector2).distance_to(target) <= AIR_STRIKE_RADIUS:
			unit["hp"] = float(unit.get("hp", 0.0)) - AIR_STRIKE_DAMAGE
			unit["hit_flash"] = 0.45
			hits += 1
	for building: Dictionary in buildings:
		if str(building.get("team", "")) == SYNDICATE and (building.get("pos", Vector2.ZERO) as Vector2).distance_to(target) <= AIR_STRIKE_RADIUS:
			building["hp"] = float(building.get("hp", 0.0)) - AIR_STRIKE_DAMAGE * 0.75
			building["hit_flash"] = 0.45
			hits += 1
	_spawn_effect("explosion", target, Color("d9f7ff"), 1.0)
	flash("AIR STRIKE COMPLETE // %d hostile asset(s) hit." % hits, 2.0)
	_sound("impact")

func _draw() -> void:
	super._draw()
	var viewport_size: Vector2 = get_viewport_rect().size
	draw_set_transform(viewport_size * 0.5 - camera_position * zoom, 0.0, Vector2.ONE * zoom)
	_draw_operations_overlays()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_operations_overlays() -> void:
	for building: Dictionary in buildings:
		if str(building.get("team", "")) != AUTHORITY:
			continue
		var kind: String = str(building.get("kind", ""))
		var position: Vector2 = building.get("pos", Vector2.ZERO) as Vector2
		if kind == "air_support_pad":
			draw_arc(position, 44.0, 0.0, TAU, 28, Color("77c8ff"), 3.0)
			draw_line(position + Vector2(-48.0, 0.0), position + Vector2(48.0, 0.0), Color("cfefff"), 4.0)
			draw_line(position + Vector2(0.0, -31.0), position + Vector2(0.0, 31.0), Color("cfefff"), 4.0)
			draw_string(font, position + Vector2(-30.0, 6.0), "AIR", HORIZONTAL_ALIGNMENT_LEFT, 64, 13, Color("dff6ff"))
		elif kind == "o2_generator":
			draw_circle(position, 28.0, Color("77f7d8"), false, 3.0)
			draw_circle(position, 15.0 + sin(mission_clock * 3.0) * 2.0, Color(0.46, 0.97, 0.85, 0.35))
			draw_string(font, position + Vector2(-16.0, 5.0), "O2", HORIZONTAL_ALIGNMENT_LEFT, 40, 13, Color("e2fff8"))
		elif kind == "thermal_regulator":
			draw_circle(position, 27.0, Color("ffbf7c"), false, 3.0)
			for angle_index in range(6):
				var angle: float = float(angle_index) * TAU / 6.0 + mission_clock * 0.7
				draw_line(position, position + Vector2.from_angle(angle) * 23.0, Color("ffd7ab"), 2.5)
		elif kind == "radiation_array":
			draw_arc(position, 40.0 + sin(mission_clock * 2.0) * 3.0, 0.0, TAU, 26, Color("c09cff"), 3.0)
			draw_arc(position, 56.0, 0.0, TAU, 26, Color(0.75, 0.61, 1.0, 0.30), 1.5)
	for effect: Dictionary in effects:
		if str(effect.get("kind", "")) != "air_strike":
			continue
		var target: Vector2 = effect.get("pos", Vector2.ZERO) as Vector2
		var ratio: float = clampf(float(effect.get("age", 0.0)) / maxf(0.01, float(effect.get("duration", 1.0))), 0.0, 1.0)
		var warning: Color = Color("79d8ff") if ratio < 0.65 else Color("fff0bf")
		draw_arc(target, AIR_STRIKE_RADIUS, 0.0, TAU, 32, warning, 3.0)
		draw_line(target + Vector2(-24.0, 0.0), target + Vector2(24.0, 0.0), warning, 2.0)
		draw_line(target + Vector2(0.0, -24.0), target + Vector2(0.0, 24.0), warning, 2.0)
		if ratio < 0.65:
			draw_string(font, target + Vector2(-48.0, -AIR_STRIKE_RADIUS - 12.0), "AIR STRIKE", HORIZONTAL_ALIGNMENT_LEFT, 96, 13, warning)
