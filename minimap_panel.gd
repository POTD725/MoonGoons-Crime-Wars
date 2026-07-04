extends Control
## Live tactical minimap for MoonGoons: Crime Wars.

const FRONTIER_RECT: Rect2 = Rect2(-2700.0, -1700.0, 5400.0, 3400.0)

var game: Node = null

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP

func set_game(scene: Node) -> void:
	game = scene
	queue_redraw()

func _process(_delta: float) -> void:
	if visible:
		queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if game == null:
		return
	if event is InputEventMouseButton:
		var mouse: InputEventMouseButton = event as InputEventMouseButton
		if mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT:
			var world_point: Vector2 = _mini_to_world(mouse.position)
			if game.get("camera_goal") != null:
				game.set("camera_goal", world_point)
			if game.get("camera_position") != null:
				game.set("camera_position", world_point)
			accept_event()

func _draw() -> void:
	_draw_background()
	if game == null:
		_draw_no_signal()
		return
	_draw_grid()
	_draw_obstacles()
	_draw_resources()
	_draw_buildings()
	_draw_units()
	_draw_camera_window()
	_draw_border_and_labels()

func _draw_background() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("06101d"), true)
	draw_rect(Rect2(Vector2.ZERO, size), Color("5fbfff"), false, 2.0)

func _draw_no_signal() -> void:
	draw_string(get_theme_default_font(), Vector2(12.0, size.y * 0.5), "MINIMAP LINKING...", HORIZONTAL_ALIGNMENT_LEFT, size.x - 24.0, 12, Color("8fe9ff"))

func _draw_grid() -> void:
	for i in range(1, 6):
		var x: float = size.x * float(i) / 6.0
		draw_line(Vector2(x, 0.0), Vector2(x, size.y), Color(0.26, 0.45, 0.65, 0.22), 1.0)
	for j in range(1, 4):
		var y: float = size.y * float(j) / 4.0
		draw_line(Vector2(0.0, y), Vector2(size.x, y), Color(0.26, 0.45, 0.65, 0.22), 1.0)

func _draw_obstacles() -> void:
	if game.get("terrain_obstacles") == null:
		return
	for obstacle in game.get("terrain_obstacles") as Array:
		if not (obstacle is Dictionary):
			continue
		var block: Rect2 = obstacle.get("rect", Rect2()) as Rect2
		var mini_position: Vector2 = _world_to_mini(block.position)
		var mini_end: Vector2 = _world_to_mini(block.end)
		var mini_rect: Rect2 = Rect2(mini_position, mini_end - mini_position)
		var color_value: Color = Color(0.58, 0.72, 0.86, 0.35) if str(obstacle.get("type", "wall")) == "wall" else Color(0.75, 0.57, 1.0, 0.32)
		draw_rect(mini_rect.abs(), color_value, true)

func _draw_resources() -> void:
	if game.get("nodes") == null:
		return
	for resource in game.get("nodes") as Array:
		if not (resource is Dictionary):
			continue
		if int(resource.get("amount", 0)) <= 0:
			continue
		var pos: Vector2 = _world_to_mini(resource.get("pos", Vector2.ZERO) as Vector2)
		var color_value: Color = Color("ffca69") if str(resource.get("type", "ore")) == "evidence" else Color("65eaff")
		draw_circle(pos, 2.8, color_value)

func _draw_buildings() -> void:
	if game.get("buildings") == null:
		return
	for building in game.get("buildings") as Array:
		if not (building is Dictionary):
			continue
		var pos: Vector2 = _world_to_mini(building.get("pos", Vector2.ZERO) as Vector2)
		var team: String = str(building.get("team", ""))
		var color_value: Color = Color("73f2ff") if team == "authority" else Color("ff74aa")
		var radius: float = 4.0 if bool(building.get("done", false)) else 2.8
		draw_rect(Rect2(pos - Vector2(radius, radius), Vector2(radius * 2.0, radius * 2.0)), color_value, true)

func _draw_units() -> void:
	if game.get("units") == null:
		return
	for unit in game.get("units") as Array:
		if not (unit is Dictionary):
			continue
		if not bool(unit.get("ready", true)):
			continue
		var pos: Vector2 = _world_to_mini(unit.get("pos", Vector2.ZERO) as Vector2)
		var team: String = str(unit.get("team", ""))
		var color_value: Color = Color("dffaff") if team == "authority" else Color("ff9ac0")
		var marker_size: float = 2.6 if not bool(unit.get("airborne", false)) else 3.5
		draw_circle(pos, marker_size, color_value)

func _draw_camera_window() -> void:
	var camera_position: Vector2 = game.get("camera_position") as Vector2
	var zoom_value: float = maxf(0.1, float(game.get("zoom")))
	var viewport_world: Vector2 = get_viewport_rect().size / zoom_value
	var camera_rect_world: Rect2 = Rect2(camera_position - viewport_world * 0.5, viewport_world)
	var mini_a: Vector2 = _world_to_mini(camera_rect_world.position)
	var mini_b: Vector2 = _world_to_mini(camera_rect_world.end)
	draw_rect(Rect2(mini_a, mini_b - mini_a).abs(), Color("ffffff"), false, 1.6)

func _draw_border_and_labels() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("8fe9ff"), false, 2.0)
	draw_string(get_theme_default_font(), Vector2(8.0, 16.0), "TACTICAL MAP", HORIZONTAL_ALIGNMENT_LEFT, size.x - 16.0, 12, Color("8fe9ff"))
	draw_string(get_theme_default_font(), Vector2(8.0, size.y - 8.0), "CLICK TO JUMP CAMERA", HORIZONTAL_ALIGNMENT_LEFT, size.x - 16.0, 10, Color("ffd16a"))

func _world_to_mini(world_point: Vector2) -> Vector2:
	var normalized_x: float = inverse_lerp(FRONTIER_RECT.position.x, FRONTIER_RECT.end.x, world_point.x)
	var normalized_y: float = inverse_lerp(FRONTIER_RECT.position.y, FRONTIER_RECT.end.y, world_point.y)
	return Vector2(clampf(normalized_x, 0.0, 1.0) * size.x, clampf(normalized_y, 0.0, 1.0) * size.y)

func _mini_to_world(mini_point: Vector2) -> Vector2:
	var normalized_x: float = clampf(mini_point.x / maxf(1.0, size.x), 0.0, 1.0)
	var normalized_y: float = clampf(mini_point.y / maxf(1.0, size.y), 0.0, 1.0)
	return Vector2(lerpf(FRONTIER_RECT.position.x, FRONTIER_RECT.end.x, normalized_x), lerpf(FRONTIER_RECT.position.y, FRONTIER_RECT.end.y, normalized_y))
