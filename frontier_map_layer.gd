extends "res://operations_layer.gd"
## Map-aware battlefield layer. Every War Room map now has real collision bounds,
## impassable terrain, elevation bands, movement modifiers, build restrictions, and spawn layout.

const DEFAULT_FRONTIER: Rect2 = Rect2(-2700.0, -1700.0, 5400.0, 3400.0)
const TacticalMapCatalog = preload("res://tactical_map_catalog.gd")

var active_frontier: Rect2 = DEFAULT_FRONTIER
var active_map: Dictionary = {}
var terrain_obstacles: Array[Dictionary] = []
var terrain_fields: Array[Dictionary] = []
var authority_zone: Rect2 = Rect2(-2440.0, 250.0, 980.0, 900.0)
var syndicate_zone: Rect2 = Rect2(1450.0, -1500.0, 930.0, 920.0)
var map_theme: String = "city"

func _setup_operation_breakwater() -> void:
	props.clear()
	units.clear()
	buildings.clear()
	nodes.clear()
	projectiles.clear()
	effects.clear()
	selected.clear()
	selected_building = -1
	next_id = 1
	mission_clock = 0.0
	enemy_wave_clock = 0.0
	finished = false
	victory = false

	active_map = TacticalMapCatalog.get_profile(_selected_map_label())
	active_frontier = active_map.get("bounds", DEFAULT_FRONTIER) as Rect2
	map_theme = str(active_map.get("theme", "city"))
	authority_zone = active_map.get("authority_zone", Rect2(-2440.0, 250.0, 980.0, 900.0)) as Rect2
	syndicate_zone = active_map.get("syndicate_zone", Rect2(1450.0, -1500.0, 930.0, 920.0)) as Rect2
	terrain_obstacles = _copy_dictionary_array(active_map.get("obstacles", []) as Array)
	terrain_fields = _copy_dictionary_array(active_map.get("terrain", []) as Array)

	var player_spawn: Vector2 = active_map.get("player_spawn", Vector2(-1750.0, 720.0)) as Vector2
	var relay_spawn: Vector2 = active_map.get("relay_spawn", Vector2(1950.0, -980.0)) as Vector2
	camera_position = player_spawn
	camera_goal = player_spawn
	zoom = 0.68
	zoom_goal = 0.68

	props = _props_for_map(player_spawn, relay_spawn)
	_spawn_authority_start(player_spawn)
	_spawn_resource_fields()
	_spawn_syndicate_start(relay_spawn)
	flash("BATTLEFIELD ONLINE // %s // Terrain elevation and hard perimeter active." % str(active_map.get("label", "Nexus Prime")), 5.0)

func _selected_map_label() -> String:
	if MatchState != null:
		var label: String = str(MatchState.selected_map)
		if not label.is_empty():
			return label
	return "Nexus Prime"

func _copy_dictionary_array(source: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for entry_value: Variant in source:
		if entry_value is Dictionary:
			result.append(entry_value as Dictionary)
	return result

func _props_for_map(player_spawn: Vector2, relay_spawn: Vector2) -> Array[Dictionary]:
	return [
		{"kind":"rail", "pos":player_spawn + Vector2(-420.0, 265.0), "length":980.0},
		{"kind":"rail", "pos":relay_spawn + Vector2(-270.0, 230.0), "length":900.0},
		{"kind":"crane", "pos":player_spawn + Vector2(-270.0, -245.0)},
		{"kind":"crane", "pos":relay_spawn + Vector2(-360.0, 260.0)},
		{"kind":"wreck", "pos":Vector2(-420.0, 1110.0)},
		{"kind":"wreck", "pos":Vector2(880.0, 820.0)},
		{"kind":"cargo", "pos":player_spawn + Vector2(360.0, 225.0)},
		{"kind":"cargo", "pos":relay_spawn + Vector2(-520.0, 270.0)},
		{"kind":"pipe", "pos":Vector2(-150.0, -960.0)},
		{"kind":"lamp", "pos":player_spawn + Vector2(240.0, -260.0)},
		{"kind":"lamp", "pos":Vector2(-210.0, -80.0)},
		{"kind":"lamp", "pos":relay_spawn + Vector2(-280.0, 220.0)},
		{"kind":"sign", "pos":relay_spawn + Vector2(-150.0, -210.0)}
	]

func _spawn_authority_start(player_spawn: Vector2) -> void:
	_spawn_building("nexus", AUTHORITY, player_spawn, true)
	_spawn_unit("hero", AUTHORITY, player_spawn + Vector2(0.0, -118.0))
	for offset: Vector2 in [Vector2(95.0, 52.0), Vector2(-52.0, 114.0), Vector2(-122.0, 50.0)]:
		_spawn_unit("drone", AUTHORITY, player_spawn + offset)
	for offset: Vector2 in [Vector2(122.0, -66.0), Vector2(-102.0, -72.0)]:
		_spawn_unit("deputy", AUTHORITY, player_spawn + offset)

func _spawn_resource_fields() -> void:
	var resource_entries: Array = active_map.get("resources", []) as Array
	for entry_value: Variant in resource_entries:
		if not (entry_value is Dictionary):
			continue
		var entry: Dictionary = entry_value as Dictionary
		_spawn_node(str(entry.get("type", "ore")), entry.get("pos", Vector2.ZERO) as Vector2, int(entry.get("amount", 800)))

func _spawn_syndicate_start(relay_spawn: Vector2) -> void:
	_spawn_building("syndicate_relay", SYNDICATE, relay_spawn, true)
	for offset: Vector2 in [Vector2(-165.0, 80.0), Vector2(150.0, 105.0), Vector2(255.0, -105.0), Vector2(-90.0, -180.0)]:
		_spawn_unit("raider", SYNDICATE, relay_spawn + offset)
	for offset: Vector2 in [Vector2(-50.0, -250.0), Vector2(315.0, 0.0), Vector2(-270.0, 170.0)]:
		_spawn_unit("hacker", SYNDICATE, relay_spawn + offset)

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
		camera_goal += direction.normalized() * 780.0 * delta / maxf(zoom, 0.1)
	camera_goal.x = clampf(camera_goal.x, active_frontier.position.x + 390.0, active_frontier.end.x - 390.0)
	camera_goal.y = clampf(camera_goal.y, active_frontier.position.y + 280.0, active_frontier.end.y - 280.0)
	camera_position = camera_position.lerp(camera_goal, minf(1.0, delta * 8.5))

func _valid_build_site(world_point: Vector2, size: Vector2) -> bool:
	var candidate: Rect2 = Rect2(world_point - size * 0.5, size)
	if not active_frontier.grow(-110.0).encloses(candidate):
		return false
	if not _terrain_allows_build(candidate):
		return false
	for building: Dictionary in buildings:
		var other_size: Vector2 = building.get("size", Vector2(70.0, 50.0)) as Vector2
		var other: Rect2 = Rect2(building.get("pos", Vector2.ZERO) as Vector2 - other_size * 0.5, other_size)
		if candidate.grow(28.0).intersects(other):
			return false
	for resource: Dictionary in nodes:
		if candidate.grow(30.0).has_point(resource.get("pos", Vector2.ZERO) as Vector2):
			return false
	for obstacle: Dictionary in terrain_obstacles:
		var block: Rect2 = obstacle.get("rect", Rect2()) as Rect2
		if candidate.grow(30.0).intersects(block):
			return false
	return true

func _terrain_allows_build(candidate: Rect2) -> bool:
	for field: Dictionary in terrain_fields:
		var field_rect: Rect2 = field.get("rect", Rect2()) as Rect2
		if candidate.intersects(field_rect) and not bool(field.get("buildable", true)):
			return false
	return true

func _move_unit(unit: Dictionary, target: Vector2, delta: float) -> void:
	var position: Vector2 = unit.get("pos", Vector2.ZERO) as Vector2
	var direction: Vector2 = position.direction_to(target)
	if direction.length_squared() > 0.0:
		unit["facing"] = direction
	var speed_multiplier: float = _terrain_speed_multiplier(position, position.move_toward(target, 1.0), unit)
	var next_position: Vector2 = position.move_toward(target, float(unit.get("speed", 0.0)) * speed_multiplier * delta)
	var clearance: float = float(unit.get("radius", 16.0)) + 5.0
	if not _blocked_by_map(next_position, clearance):
		unit["pos"] = next_position
		return
	var horizontal_slide: Vector2 = Vector2(next_position.x, position.y)
	var vertical_slide: Vector2 = Vector2(position.x, next_position.y)
	var horizontal_open: bool = not _blocked_by_map(horizontal_slide, clearance)
	var vertical_open: bool = not _blocked_by_map(vertical_slide, clearance)
	if horizontal_open and vertical_open:
		unit["pos"] = horizontal_slide if absf(next_position.x - position.x) >= absf(next_position.y - position.y) else vertical_slide
	elif horizontal_open:
		unit["pos"] = horizontal_slide
	elif vertical_open:
		unit["pos"] = vertical_slide

func _terrain_speed_multiplier(source: Vector2, destination: Vector2, unit: Dictionary) -> float:
	if bool(unit.get("airborne", false)):
		return 1.0
	var source_field: Dictionary = _terrain_at(source)
	var target_field: Dictionary = _terrain_at(destination)
	var multiplier: float = float(target_field.get("move_mult", 1.0))
	var elevation_change: int = int(target_field.get("elevation", 0)) - int(source_field.get("elevation", 0))
	if elevation_change > 0:
		multiplier *= 0.78
	elif elevation_change < 0:
		multiplier *= 1.04
	return clampf(multiplier, 0.38, 1.18)

func _terrain_at(point: Vector2) -> Dictionary:
	for field: Dictionary in terrain_fields:
		var field_rect: Rect2 = field.get("rect", Rect2()) as Rect2
		if field_rect.has_point(point):
			return field
	return {"type":"open", "elevation":0, "move_mult":1.0, "buildable":true, "blocked":false}

func _blocked_by_map(point: Vector2, clearance: float) -> bool:
	if not active_frontier.grow(-clearance).has_point(point):
		return true
	for obstacle: Dictionary in terrain_obstacles:
		var block: Rect2 = obstacle.get("rect", Rect2()) as Rect2
		if block.grow(clearance).has_point(point):
			return true
	for field: Dictionary in terrain_fields:
		if not bool(field.get("blocked", false)):
			continue
		var blocked_rect: Rect2 = field.get("rect", Rect2()) as Rect2
		if blocked_rect.grow(clearance).has_point(point):
			return true
	return false

func _draw_lunar_dockyard() -> void:
	var palette: Dictionary = _theme_palette()
	draw_rect(active_frontier, palette.get("background", Color("18233a")) as Color, true)
	for x: int in range(int(active_frontier.position.x), int(active_frontier.end.x), 100):
		draw_line(Vector2(float(x), active_frontier.position.y), Vector2(float(x), active_frontier.end.y), palette.get("grid", Color(0.27, 0.36, 0.54, 0.20)) as Color, 1.0)
	for y: int in range(int(active_frontier.position.y), int(active_frontier.end.y), 100):
		draw_line(Vector2(active_frontier.position.x, float(y)), Vector2(active_frontier.end.x, float(y)), palette.get("grid", Color(0.27, 0.36, 0.54, 0.20)) as Color, 1.0)
	_draw_terrain_fields()
	draw_rect(authority_zone, palette.get("authority_fill", Color("25456e")) as Color, true)
	draw_rect(authority_zone, palette.get("authority_edge", Color("65c7f5")) as Color, false, 3.0)
	draw_rect(syndicate_zone, palette.get("syndicate_fill", Color("54243d")) as Color, true)
	draw_rect(syndicate_zone, palette.get("syndicate_edge", Color("ff74aa")) as Color, false, 3.0)
	for index: int in range(52):
		var crater_center: Vector2 = Vector2(active_frontier.position.x + 170.0 + fposmod(float(index * 191), active_frontier.size.x - 340.0), active_frontier.position.y + 140.0 + fposmod(float(index * 109), active_frontier.size.y - 280.0))
		var crater_radius: float = 14.0 + float(index % 5) * 8.0
		draw_circle(crater_center, crater_radius, Color(0.04, 0.07, 0.13, 0.30))
		draw_arc(crater_center, crater_radius, 0.0, TAU, 12, Color(0.40, 0.48, 0.62, 0.20), 1.0)
	_draw_frontier_obstacles()
	draw_rect(active_frontier, palette.get("boundary", Color("8aa6cf")) as Color, false, 5.0)
	_draw_map_corner_marker()

func _draw_terrain_fields() -> void:
	for field: Dictionary in terrain_fields:
		var rect_value: Rect2 = field.get("rect", Rect2()) as Rect2
		var terrain_type: String = str(field.get("type", "open"))
		var elevation: int = int(field.get("elevation", 0))
		var colors: Dictionary = _terrain_colors(terrain_type)
		var fill: Color = colors.get("fill", Color(0.24, 0.30, 0.42, 0.28)) as Color
		var edge: Color = colors.get("edge", Color(0.58, 0.72, 0.88, 0.48)) as Color
		draw_rect(rect_value, fill, true)
		draw_rect(rect_value, edge, false, 2.0)
		if elevation != 0:
			var bands: int = mini(4, absi(elevation))
			for band_index: int in range(bands):
				var inset: float = 8.0 + float(band_index) * 7.0
				draw_rect(rect_value.grow(-inset), Color(edge.r, edge.g, edge.b, 0.40), false, 1.4)
		if rect_value.size.x >= 220.0 and rect_value.size.y >= 120.0:
			var label_text: String = str(field.get("label", ""))
			if not label_text.is_empty():
				draw_string(font, rect_value.position + Vector2(10.0, 22.0), label_text, HORIZONTAL_ALIGNMENT_LEFT, int(rect_value.size.x - 20.0), 11, Color(edge.r, edge.g, edge.b, 0.90))

func _draw_frontier_obstacles() -> void:
	for obstacle: Dictionary in terrain_obstacles:
		var block: Rect2 = obstacle.get("rect", Rect2()) as Rect2
		var kind: String = str(obstacle.get("type", "wall"))
		var fill: Color = Color("303c50") if kind == "wall" else Color("2f253d")
		var edge: Color = Color("8fa6c2") if kind == "wall" else Color("b691d9")
		draw_rect(block, fill, true)
		draw_rect(block, edge, false, 3.0)
		for offset: int in range(10, int(block.size.x), 34):
			draw_line(block.position + Vector2(float(offset), 5.0), block.position + Vector2(float(offset), block.size.y - 5.0), Color(edge.r, edge.g, edge.b, 0.38), 1.1)
		if block.size.x >= 220.0:
			draw_string(font, block.position + Vector2(12.0, 25.0), str(obstacle.get("name", "BARRIER")).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, int(block.size.x - 24.0), 11, Color("d8ebff"))

func _draw_map_corner_marker() -> void:
	var map_label: String = str(active_map.get("label", "NEXUS PRIME")).to_upper()
	var marker: Rect2 = Rect2(active_frontier.position + Vector2(34.0, 34.0), Vector2(390.0, 56.0))
	draw_rect(marker, Color(0.01, 0.03, 0.08, 0.74), true)
	draw_rect(marker, Color("8fe9ff"), false, 2.0)
	draw_string(font, marker.position + Vector2(13.0, 23.0), "BATTLEFIELD // " + map_label, HORIZONTAL_ALIGNMENT_LEFT, int(marker.size.x - 24.0), 15, Color("dff8ff"))
	draw_string(font, marker.position + Vector2(13.0, 43.0), "HARD BORDER • ELEVATION ROUTING • TERRAIN CONTROL", HORIZONTAL_ALIGNMENT_LEFT, int(marker.size.x - 24.0), 10, Color("9ec5e8"))

func _terrain_colors(terrain_type: String) -> Dictionary:
	match terrain_type:
		"crater_floor", "low_canyon", "slag_lowland", "debris_basin", "snow_drift":
			return {"fill":Color(0.21, 0.15, 0.30, 0.48), "edge":Color("bc9cff")}
		"high_rim", "hull_ridge", "ice_shelf":
			return {"fill":Color(0.34, 0.31, 0.38, 0.55), "edge":Color("ffd27b")}
		"elevated_deck", "elevated_walkway", "concourse", "relay_platform", "dock_deck":
			return {"fill":Color(0.13, 0.31, 0.43, 0.46), "edge":Color("74d9ff")}
		"void_water", "magma_crack", "deep_crevasse":
			return {"fill":Color(0.02, 0.02, 0.06, 0.88), "edge":Color("ff718f")}
		"ice_sheet":
			return {"fill":Color(0.42, 0.76, 0.90, 0.32), "edge":Color("b4f4ff")}
		"underhive_floor", "terminal_floor", "chapel_floor", "smuggler_track", "wreckage_ground":
			return {"fill":Color(0.12, 0.22, 0.30, 0.40), "edge":Color("78b7dd")}
		"regolith", "ash_plain", "iron_flats", "obsidian_plain", "snowfield", "scrap_yard":
			return {"fill":Color(0.31, 0.29, 0.25, 0.36), "edge":Color("a8b8c9")}
		_:
			return {"fill":Color(0.20, 0.30, 0.42, 0.30), "edge":Color("6fa4ce")}

func _theme_palette() -> Dictionary:
	match map_theme:
		"moon":
			return {"background":Color("11141e"), "grid":Color(0.40, 0.42, 0.54, 0.18), "authority_fill":Color("1a3f56"), "authority_edge":Color("7ad8ff"), "syndicate_fill":Color("41223b"), "syndicate_edge":Color("ff91c7"), "boundary":Color("d2d6e4")}
		"docks":
			return {"background":Color("07182a"), "grid":Color(0.18, 0.52, 0.74, 0.18), "authority_fill":Color("153c58"), "authority_edge":Color("80e6ff"), "syndicate_fill":Color("4a2432"), "syndicate_edge":Color("ff9f82"), "boundary":Color("76d4ff")}
		"frost":
			return {"background":Color("17283b"), "grid":Color(0.66, 0.88, 1.0, 0.18), "authority_fill":Color("194461"), "authority_edge":Color("a7efff"), "syndicate_fill":Color("3d3557"), "syndicate_edge":Color("e2b7ff"), "boundary":Color("d2f5ff")}
		"volcanic":
			return {"background":Color("24151b"), "grid":Color(0.80, 0.30, 0.18, 0.17), "authority_fill":Color("3c3346"), "authority_edge":Color("a7e9ff"), "syndicate_fill":Color("54261f"), "syndicate_edge":Color("ffac75"), "boundary":Color("f7ad77")}
		"underhive", "terminal", "chapel":
			return {"background":Color("0b1424"), "grid":Color(0.38, 0.62, 0.82, 0.16), "authority_fill":Color("18395a"), "authority_edge":Color("78d9ff"), "syndicate_fill":Color("3e244e"), "syndicate_edge":Color("d49dff"), "boundary":Color("9bc9ef")}
		_:
			return {"background":Color("18233a"), "grid":Color(0.27, 0.36, 0.54, 0.20), "authority_fill":Color("25456e"), "authority_edge":Color("65c7f5"), "syndicate_fill":Color("54243d"), "syndicate_edge":Color("ff74aa"), "boundary":Color("8aa6cf")}
