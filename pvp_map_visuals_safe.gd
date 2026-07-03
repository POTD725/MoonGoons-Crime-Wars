extends Node2D
## Safe terrain layer for the active PvP map.

var mission_root: Node
var map_id: String = "breakwater_split"

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
	var view: Vector2 = mission_root.get_viewport_rect().size
	var camera: Vector2 = mission_root.get("cam")
	var zoom: float = float(mission_root.get("zoom"))
	var map_data: Dictionary = PvpMaps.get_map(map_id)
	draw_set_transform(view * 0.5 - camera * zoom, 0.0, Vector2.ONE * zoom)
	for zone in map_data.get("zones", []):
		_draw_zone(str(zone[0]), zone[1])
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_zone(kind: String, rect: Rect2) -> void:
	match kind:
		"dock":
			draw_rect(rect, Color("395179"), true)
			for x: int in range(int(rect.position.x), int(rect.end.x), 44):
				draw_line(Vector2(x, rect.position.y), Vector2(x, rect.end.y), Color("7392bb"), 2.0)
		"crater":
			_draw_oval(rect, Color("10192c"), Color("536889"))
		"crystal":
			draw_rect(rect, Color("612f9e").with_alpha(0.20), true)
		"canyon":
			draw_rect(rect, Color("25192e"), true)
		"dust", "ash", "salt", "solar":
			draw_rect(rect, Color("6b4234").with_alpha(0.18), true)
		"rail":
			draw_rect(rect, Color("273747"), true)
		"void":
			draw_rect(rect, Color("050814").with_alpha(0.72), true)
		"ice":
			draw_rect(rect, Color("78c9e8").with_alpha(0.14), true)
		"relay", "signal", "fracture":
			_draw_oval(rect, Color("58f5c5").with_alpha(0.12), Color("89ffe0"))
		"lava":
			_draw_oval(rect, Color("ff553b").with_alpha(0.32), Color("ffb05c"))
		"mirror":
			draw_rect(rect, Color("e6f7ff").with_alpha(0.12), true)
		"yard", "cells", "archive", "corridor", "neon", "alley", "undercity":
			draw_rect(rect, Color("54456e").with_alpha(0.25), true)
		"debris", "wreck", "engine":
			_draw_oval(rect, Color("3c3441").with_alpha(0.32), Color("9d839b"))
		"storm":
			draw_rect(rect, Color("7a3ce6").with_alpha(0.08), true)
		"ridge":
			draw_rect(rect, Color("ffbc61").with_alpha(0.20), true)
		_:
			draw_rect(rect, Color("416284").with_alpha(0.15), true)

func _draw_oval(rect: Rect2, fill: Color, line: Color) -> void:
	var center: Vector2 = rect.get_center()
	var radius: Vector2 = rect.size * 0.5
	var points: PackedVector2Array = PackedVector2Array()
	for index: int in 28:
		var angle: float = float(index) * TAU / 28.0
		points.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
	draw_colored_polygon(points, fill)
	for index: int in points.size():
		draw_line(points[index], points[(index + 1) % points.size()], line, 2.0)
