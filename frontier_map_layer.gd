extends "res://operations_layer.gd"
## Expanded Operation Breakwater battlefield with long approach lanes, obstacle fields, and dead-end salvage pockets.

const FRONTIER: Rect2 = Rect2(-2700.0, -1700.0, 5400.0, 3400.0)

var terrain_obstacles: Array[Dictionary] = []

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
	camera_position = Vector2(-1720.0, 720.0)
	camera_goal = camera_position
	zoom = 0.68
	zoom_goal = 0.68

	props = [
		{"kind":"rail", "pos":Vector2(-2480.0, 510.0), "length":1620.0},
		{"kind":"rail", "pos":Vector2(520.0, -980.0), "length":1740.0},
		{"kind":"crane", "pos":Vector2(-2120.0, 440.0)},
		{"kind":"crane", "pos":Vector2(1260.0, -1160.0)},
		{"kind":"wreck", "pos":Vector2(-520.0, 1160.0)},
		{"kind":"wreck", "pos":Vector2(910.0, 840.0)},
		{"kind":"cargo", "pos":Vector2(-1900.0, 980.0)},
		{"kind":"cargo", "pos":Vector2(-1080.0, -760.0)},
		{"kind":"cargo", "pos":Vector2(620.0, -920.0)},
		{"kind":"pipe", "pos":Vector2(-180.0, -970.0)},
		{"kind":"lamp", "pos":Vector2(-1540.0, 360.0)},
		{"kind":"lamp", "pos":Vector2(-260.0, -80.0)},
		{"kind":"lamp", "pos":Vector2(1130.0, -700.0)},
		{"kind":"sign", "pos":Vector2(1650.0, -1110.0)}
	]

	_build_obstacle_field()

	_spawn_building("nexus", AUTHORITY, Vector2(-1750.0, 720.0), true)
	_spawn_unit("hero", AUTHORITY, Vector2(-1750.0, 600.0))
	for position: Vector2 in [Vector2(-1655.0, 770.0), Vector2(-1802.0, 834.0), Vector2(-1872.0, 770.0)]:
		_spawn_unit("drone", AUTHORITY, position)
	for position: Vector2 in [Vector2(-1628.0, 645.0), Vector2(-1850.0, 635.0)]:
		_spawn_unit("deputy", AUTHORITY, position)

	_spawn_node("ore", Vector2(-2070.0, 700.0), 1050)
	_spawn_node("ore", Vector2(-1510.0, 410.0), 860)
	_spawn_node("evidence", Vector2(-1120.0, 1010.0), 620)
	_spawn_node("ore", Vector2(-760.0, 190.0), 1080)
	_spawn_node("evidence", Vector2(-180.0, -300.0), 760)
	_spawn_node("ore", Vector2(470.0, 280.0), 1120)
	_spawn_node("evidence", Vector2(980.0, -370.0), 720)
	_spawn_node("ore", Vector2(1420.0, -710.0), 980)
	_spawn_node("evidence", Vector2(1820.0, -1320.0), 640)

	_spawn_building("syndicate_relay", SYNDICATE, Vector2(1950.0, -980.0), true)
	for position: Vector2 in [Vector2(1785.0, -900.0), Vector2(2100.0, -875.0), Vector2(2215.0, -1090.0), Vector2(1860.0, -1150.0)]:
		_spawn_unit("raider", SYNDICATE, position)
	for position: Vector2 in [Vector2(1900.0, -1270.0), Vector2(2290.0, -980.0), Vector2(1680.0, -780.0)]:
		_spawn_unit("hacker", SYNDICATE, position)

func _build_obstacle_field() -> void:
	terrain_obstacles = [
		{"rect":Rect2(-1300.0, -1350.0, 610.0, 150.0), "name":"Collapsed Freight Wall", "type":"wall"},
		{"rect":Rect2(-980.0, -1180.0, 120.0, 500.0), "name":"Freight Spine", "type":"wall"},
		{"rect":Rect2(-1180.0, 820.0, 460.0, 110.0), "name":"Dead-End Salvage Bay North", "type":"wall"},
		{"rect":Rect2(-1180.0, 930.0, 110.0, 360.0), "name":"Dead-End Salvage Bay West", "type":"wall"},
		{"rect":Rect2(-790.0, 930.0, 110.0, 360.0), "name":"Dead-End Salvage Bay East", "type":"wall"},
		{"rect":Rect2(-470.0, 680.0, 460.0, 140.0), "name":"Crater Rampart", "type":"crater"},
		{"rect":Rect2(230.0, 760.0, 560.0, 135.0), "name":"Broken Conveyor", "type":"wall"},
		{"rect":Rect2(680.0, 900.0, 120.0, 410.0), "name":"Dead-End Dock East Wall", "type":"wall"},
		{"rect":Rect2(1040.0, 900.0, 120.0, 410.0), "name":"Dead-End Dock West Wall", "type":"wall"},
		{"rect":Rect2(680.0, 1200.0, 480.0, 110.0), "name":"Dead-End Dock Cap", "type":"wall"},
		{"rect":Rect2(640.0, -1280.0, 590.0, 145.0), "name":"Irradiated Wreck Line", "type":"crater"},
		{"rect":Rect2(1260.0, -1490.0, 130.0, 470.0), "name":"Relay Service Wall", "type":"wall"},
		{"rect":Rect2(1500.0, -520.0, 560.0, 135.0), "name":"Cartel Barricade", "type":"wall"},
		{"rect":Rect2(2260.0, -1250.0, 160.0, 520.0), "name":"Relay Dead-End Wall", "type":"wall"}
	]

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
	camera_goal.x = clampf(camera_goal.x, FRONTIER.position.x + 390.0, FRONTIER.end.x - 390.0)
	camera_goal.y = clampf(camera_goal.y, FRONTIER.position.y + 280.0, FRONTIER.end.y - 280.0)
	camera_position = camera_position.lerp(camera_goal, minf(1.0, delta * 8.5))

func _valid_build_site(world_point: Vector2, size: Vector2) -> bool:
	var candidate: Rect2 = Rect2(world_point - size * 0.5, size)
	if not FRONTIER.grow(-110.0).encloses(candidate):
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

func _move_unit(unit: Dictionary, target: Vector2, delta: float) -> void:
	var position: Vector2 = unit.get("pos", Vector2.ZERO) as Vector2
	var direction: Vector2 = position.direction_to(target)
	if direction.length_squared() > 0.0:
		unit["facing"] = direction
	var next_position: Vector2 = position.move_toward(target, float(unit.get("speed", 0.0)) * delta)
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

func _blocked_by_map(point: Vector2, clearance: float) -> bool:
	for obstacle: Dictionary in terrain_obstacles:
		var block: Rect2 = obstacle.get("rect", Rect2()) as Rect2
		if block.grow(clearance).has_point(point):
			return true
	return false

func _draw_lunar_dockyard() -> void:
	draw_rect(FRONTIER, Color("18233a"), true)
	for x: int in range(int(FRONTIER.position.x), int(FRONTIER.end.x), 100):
		draw_line(Vector2(float(x), FRONTIER.position.y), Vector2(float(x), FRONTIER.end.y), Color(0.27, 0.36, 0.54, 0.20), 1.0)
	for y: int in range(int(FRONTIER.position.y), int(FRONTIER.end.y), 100):
		draw_line(Vector2(FRONTIER.position.x, float(y)), Vector2(FRONTIER.end.x, float(y)), Color(0.27, 0.36, 0.54, 0.20), 1.0)
	var authority_zone: Rect2 = Rect2(-2440.0, 250.0, 980.0, 900.0)
	var syndicate_zone: Rect2 = Rect2(1450.0, -1500.0, 930.0, 920.0)
	draw_rect(authority_zone, Color("25456e"), true)
	draw_rect(authority_zone, Color("65c7f5"), false, 3.0)
	draw_rect(syndicate_zone, Color("54243d"), true)
	draw_rect(syndicate_zone, Color("ff74aa"), false, 3.0)
	for index in range(52):
		var crater_center: Vector2 = Vector2(-2500.0 + fposmod(float(index * 191), 5050.0), -1550.0 + fposmod(float(index * 109), 3150.0))
		var crater_radius: float = 14.0 + float(index % 5) * 8.0
		draw_circle(crater_center, crater_radius, Color(0.04, 0.07, 0.13, 0.34))
		draw_arc(crater_center, crater_radius, 0.0, TAU, 12, Color(0.40, 0.48, 0.62, 0.24), 1.0)
	_draw_frontier_obstacles()
	draw_rect(FRONTIER, Color("8aa6cf"), false, 5.0)

func _draw_frontier_obstacles() -> void:
	for obstacle: Dictionary in terrain_obstacles:
		var block: Rect2 = obstacle.get("rect", Rect2()) as Rect2
		var kind: String = str(obstacle.get("type", "wall"))
		var fill: Color = Color("303c50") if kind == "wall" else Color("2f253d")
		var edge: Color = Color("8fa6c2") if kind == "wall" else Color("b691d9")
		draw_rect(block, fill, true)
		draw_rect(block, edge, false, 3.0)
		for offset in range(10, int(block.size.x), 34):
			draw_line(block.position + Vector2(float(offset), 5.0), block.position + Vector2(float(offset), block.size.y - 5.0), Color(edge.r, edge.g, edge.b, 0.38), 1.1)
		if block.size.x >= 300.0:
			draw_string(font, block.position + Vector2(12.0, 24.0), str(obstacle.get("name", "OBSTRUCTION")).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, int(block.size.x - 18.0), 11, Color(edge.r, edge.g, edge.b, 0.82))
