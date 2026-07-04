extends "res://repair_crew_layer.gd"
## Persistent rally beacons for troop-producing structures.

func _draw() -> void:
	super._draw()
	var viewport_size: Vector2 = get_viewport_rect().size
	draw_set_transform(viewport_size * 0.5 - camera_position * zoom, 0.0, Vector2.ONE * zoom)
	_draw_rally_beacons()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_rally_beacons() -> void:
	for building: Dictionary in buildings:
		if str(building.get("team", "")) != AUTHORITY or not bool(building.get("done", false)):
			continue
		var kind: String = str(building.get("kind", ""))
		if kind != "nexus" and kind != "armory" and kind != "machine_shop":
			continue
		if not building.has("rally_point"):
			continue
		var source: Vector2 = building.get("pos", Vector2.ZERO) as Vector2
		var point: Vector2 = building.get("rally_point", source) as Vector2
		var selected_here: bool = int(building.get("id", -1)) == selected_building
		var pulse: float = 0.5 + sin(mission_clock * 4.0 + float(building.get("id", 0))) * 0.5
		var alpha: float = 0.95 if selected_here else 0.52
		var color: Color = Color(0.45, 0.95, 0.77, alpha)
		if kind == "armory":
			color = Color(0.66, 0.74, 1.0, alpha)
		elif kind == "machine_shop":
			color = Color(0.84, 0.68, 1.0, alpha)
		var line_width: float = 2.8 if selected_here else 1.5
		draw_line(source, point, Color(color.r, color.g, color.b, alpha * 0.65), line_width)
		var direction: Vector2 = source.direction_to(point)
		if direction.length_squared() > 0.0:
			var wing: Vector2 = Vector2(-direction.y, direction.x)
			var arrow_base: Vector2 = point - direction * 18.0
			draw_line(arrow_base + wing * 8.0, point, color, line_width)
			draw_line(arrow_base - wing * 8.0, point, color, line_width)
		var radius: float = 18.0 + pulse * 5.0 if selected_here else 15.0
		draw_arc(point, radius, 0.0, TAU, 24, color, line_width)
		draw_arc(point, radius + 6.0 + pulse * 3.0, 0.0, TAU, 24, Color(color.r, color.g, color.b, alpha * 0.36), 1.2)
		draw_line(point + Vector2(-10.0, 0.0), point + Vector2(10.0, 0.0), color, 2.0)
		draw_line(point + Vector2(0.0, -10.0), point + Vector2(0.0, 10.0), color, 2.0)
		if selected_here:
			draw_string(font, point + Vector2(-42.0, -28.0), "RALLY", HORIZONTAL_ALIGNMENT_LEFT, 84, 12, color)
