extends "res://sprite_art_layer.gd"
## Scenic paint pass for the expanded lunar battlefield.
## Gameplay collision remains tied to the existing obstacle rectangles; this layer makes them read as real locations.

func _draw_lunar_dockyard() -> void:
	super._draw_lunar_dockyard()
	_draw_obstacle_surface_detail()
	_draw_lunar_props()

func _draw_obstacle_surface_detail() -> void:
	for obstacle: Dictionary in terrain_obstacles:
		var rect_value: Rect2 = obstacle.get("rect", Rect2()) as Rect2
		var obstacle_type: String = str(obstacle.get("type", "wall"))
		if obstacle_type == "crater":
			_draw_crater_rampart(rect_value)
		else:
			_draw_cargo_wall(rect_value, str(obstacle.get("name", "BARRICADE")))

func _draw_cargo_wall(rect_value: Rect2, label_text: String) -> void:
	var fill_color: Color = Color("202e40")
	var edge_color: Color = Color("91b8d7")
	draw_rect(rect_value.grow(-3.0), fill_color, true)
	draw_rect(rect_value.grow(-3.0), edge_color, false, 2.6)
	var horizontal: bool = rect_value.size.x >= rect_value.size.y
	var span: float = rect_value.size.x if horizontal else rect_value.size.y
	var panels: int = maxi(2, int(span / 55.0))
	for panel_index in range(1, panels):
		var ratio: float = float(panel_index) / float(panels)
		if horizontal:
			var panel_x: float = rect_value.position.x + rect_value.size.x * ratio
			draw_line(Vector2(panel_x, rect_value.position.y + 5.0), Vector2(panel_x, rect_value.end.y - 5.0), Color("58718c"), 1.4)
		else:
			var panel_y: float = rect_value.position.y + rect_value.size.y * ratio
			draw_line(Vector2(rect_value.position.x + 5.0, panel_y), Vector2(rect_value.end.x - 5.0, panel_y), Color("58718c"), 1.4)
	for light_index in range(3):
		var light_ratio: float = (float(light_index) + 0.5) / 3.0
		var light_position: Vector2 = Vector2(rect_value.position.x + rect_value.size.x * light_ratio, rect_value.position.y + 11.0) if horizontal else Vector2(rect_value.position.x + 11.0, rect_value.position.y + rect_value.size.y * light_ratio)
		var pulse: float = 0.55 + sin(mission_clock * 3.0 + float(light_index)) * 0.25
		draw_circle(light_position, 5.0, Color(0.44, 0.82, 1.0, pulse))
		if horizontal:
			draw_line(light_position + Vector2(-12.0, 11.0), light_position + Vector2(12.0, 11.0), Color("f0ba5b"), 2.0)
	if rect_value.size.x >= 240.0:
		draw_string(font, rect_value.position + Vector2(12.0, 27.0), label_text.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, int(rect_value.size.x - 24.0), 11, Color("d5edff"))

func _draw_crater_rampart(rect_value: Rect2) -> void:
	var center: Vector2 = rect_value.get_center()
	var radius_x: float = rect_value.size.x * 0.43
	var radius_y: float = rect_value.size.y * 0.52
	draw_ellipse(center, Vector2(radius_x, radius_y), Color("182033"), Color("9d89c9"))
	for shard_index in range(7):
		var angle: float = float(shard_index) * TAU / 7.0 + 0.3
		var shard_center: Vector2 = center + Vector2(cos(angle) * radius_x * 0.72, sin(angle) * radius_y * 0.72)
		draw_circle(shard_center, 9.0 + float(shard_index % 3) * 3.0, Color("4c3b61"))
		draw_arc(center, minf(radius_x, radius_y) * 0.55, mission_clock * 0.28, mission_clock * 0.28 + PI * 1.1, 18, Color(0.72, 0.60, 1.0, 0.58), 2.0)

func draw_ellipse(center: Vector2, radii: Vector2, fill_color: Color, edge_color: Color) -> void:
	var points: PackedVector2Array = PackedVector2Array()
	for index in range(25):
		var angle: float = TAU * float(index) / 24.0
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	draw_colored_polygon(points, fill_color)
	draw_polyline(points, edge_color, 2.4, true)

func _draw_lunar_props() -> void:
	var crate_positions: Array[Vector2] = [Vector2(-2260.0, 880.0), Vector2(-1350.0, 530.0), Vector2(-610.0, 560.0), Vector2(160.0, 405.0), Vector2(850.0, 470.0), Vector2(1460.0, -600.0), Vector2(2040.0, -1180.0)]
	for index in range(crate_positions.size()):
		_draw_salvage_crate(crate_positions[index], index)
	var wreck_positions: Array[Vector2] = [Vector2(-1320.0, -320.0), Vector2(-430.0, 1010.0), Vector2(510.0, -620.0), Vector2(1170.0, -970.0)]
	for index in range(wreck_positions.size()):
		_draw_wrecked_shuttle(wreck_positions[index], index)
	var beacon_positions: Array[Vector2] = [Vector2(-2120.0, 410.0), Vector2(-820.0, 180.0), Vector2(250.0, 100.0), Vector2(1010.0, -310.0), Vector2(1770.0, -860.0)]
	for index in range(beacon_positions.size()):
		_draw_landing_beacon(beacon_positions[index], index)

func _draw_salvage_crate(position: Vector2, variant: int) -> void:
	var size: Vector2 = Vector2(40.0 + float(variant % 2) * 10.0, 30.0)
	var rect_value: Rect2 = Rect2(position - size * 0.5, size)
	draw_rect(rect_value, Color("5a513f"), true)
	draw_rect(rect_value, Color("d9b769"), false, 2.2)
	draw_line(rect_value.position + Vector2(5.0, 5.0), rect_value.end - Vector2(5.0, 5.0), Color("f5e2a6"), 1.6)
	draw_line(Vector2(rect_value.position.x + 5.0, rect_value.end.y - 5.0), Vector2(rect_value.end.x - 5.0, rect_value.position.y + 5.0), Color("f5e2a6"), 1.6)
	if variant % 3 == 0:
		draw_circle(position + Vector2(0.0, -22.0), 4.0, Color("73f5d5"))

func _draw_wrecked_shuttle(position: Vector2, variant: int) -> void:
	var hull_color: Color = Color("435166")
	var edge_color: Color = Color("94b9d8")
	draw_line(position + Vector2(-52.0, 17.0), position + Vector2(44.0, -13.0), hull_color, 20.0)
	draw_line(position + Vector2(-52.0, 17.0), position + Vector2(44.0, -13.0), edge_color, 2.4)
	draw_line(position + Vector2(-11.0, -7.0), position + Vector2(-27.0, -42.0), edge_color, 8.0)
	draw_line(position + Vector2(14.0, 4.0), position + Vector2(34.0, 37.0), edge_color, 8.0)
	draw_circle(position + Vector2(49.0, -15.0), 8.0 + sin(mission_clock * 3.0 + float(variant)) * 1.5, Color("ff9e6a"))
	draw_circle(position + Vector2(49.0, -15.0), 18.0, Color(1.0, 0.45, 0.20, 0.11))

func _draw_landing_beacon(position: Vector2, index: int) -> void:
	var pulse: float = 0.50 + sin(mission_clock * 2.6 + float(index)) * 0.32
	draw_circle(position, 7.0, Color(0.40, 0.92, 1.0, 0.90))
	draw_arc(position, 24.0 + pulse * 8.0, 0.0, TAU, 18, Color(0.40, 0.92, 1.0, pulse), 1.8)
	draw_line(position + Vector2(0.0, 7.0), position + Vector2(0.0, 22.0), Color("b7f6ff"), 2.0)
