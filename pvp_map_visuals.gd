extends Node2D
## Terrain layer for the active PvP map. Drawn behind tactical units and buildings.

var mission_root: Node
var map_id := "breakwater_split"

func _ready() -> void:
	z_index = -20

func configure(root: Node, new_map_id: String) -> void:
	mission_root = root
	map_id = new_map_id
	queue_redraw()

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	if mission_root == null:
		return
	var view := mission_root.get_viewport_rect().size
	var camera: Vector2 = mission_root.get("cam")
	var zoom: float = mission_root.get("zoom")
	var map_data := PvpMaps.get_map(map_id)
	draw_set_transform(view * 0.5 - camera * zoom, 0.0, Vector2.ONE * zoom)
	for zone in map_data.get("zones", []):
		_draw_zone(str(zone[0]), zone[1])
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_zone(kind: String, rect: Rect2) -> void:
	match kind:
		"dock":
			draw_rect(rect, Color("395179"), true)
			for x in range(int(rect.position.x), int(rect.end.x), 44):
				draw_line(Vector2(x, rect.position.y), Vector2(x, rect.end.y), Color("7392bb"), 2.0)
		"crater":
			draw_ellipse(rect, Color("10192c"), Color("536889"))
		"crystal":
			draw_rect(rect, Color(0.38, 0.20, 0.62, 0.20), true)
			for y in range(int(rect.position.y) + 30, int(rect.end.y), 110):
				draw_line(Vector2(rect.position.x, y), Vector2(rect.end.x, y - 42), Color("b993ff"), 3.0)
		"canyon":
			draw_rect(rect, Color("25192e"), true)
		"dust", "ash", "salt", "solar":
			draw_rect(rect, Color("6b4234", 0.18), true)
		"rail":
			draw_rect(rect, Color("273747"), true)
			for x in range(int(rect.position.x), int(rect.end.x), 68):
				draw_line(Vector2(x, rect.position.y + 26), Vector2(x + 36, rect.end.y - 26), Color("9ec5d0"), 3.0)
		"void":
			draw_rect(rect, Color("050814", 0.72), true)
		"ice":
			draw_rect(rect, Color("78c9e8", 0.14), true)
		"relay", "signal", "fracture":
			draw_ellipse(rect, Color("58f5c5", 0.12), Color("89ffe0"))
		"lava":
			draw_ellipse(rect, Color("ff553b", 0.32), Color("ffb05c"))
		"mirror":
			draw_rect(rect, Color("e6f7ff", 0.12), true)
		"yard", "cells", "archive", "corridor", "neon", "alley", "undercity":
			draw_rect(rect, Color("54456e", 0.25), true)
		"debris", "wreck", "engine":
			draw_ellipse(rect, Color("3c3441", 0.32), Color("9d839b"))
		"storm":
			draw_rect(rect, Color("7a3ce6", 0.08), true)
		"ridge":
			draw_rect(rect, Color("ffbc61", 0.20), true)
		_:
			draw_rect(rect, Color("416284", 0.15), true)

func draw_ellipse(rect: Rect2, fill: Color, line: Color) -> void:
	var center := rect.get_center()
	var radius := rect.size * 0.5
	var points := PackedVector2Array()
	for index in 28:
		var angle := float(index) * TAU / 28.0
		points.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
	draw_colored_polygon(points, fill)
	for index in points.size():
		draw_line(points[index], points[(index + 1) % points.size()], line, 2.0)
