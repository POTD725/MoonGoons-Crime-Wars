extends Node2D
## Lightweight faction visual overlay for the four RTS races.

var mission_root: Node

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	if mission_root == null:
		return
	var view := mission_root.get_viewport_rect().size
	var camera: Vector2 = mission_root.get("cam")
	var zoom: float = mission_root.get("zoom")
	draw_set_transform(view * 0.5 - camera * zoom, 0.0, Vector2.ONE * zoom)
	for building in mission_root.get("buildings"):
		_draw_building_mark(building)
	for unit in mission_root.get("units"):
		_draw_unit_mark(unit)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _accent(entity: Dictionary) -> Color:
	var race_id := str(entity.get("race", "authority"))
	var race: Dictionary = RaceCatalog.RACES.get(race_id, RaceCatalog.RACES["authority"])
	return Color(str(race["accent"]))

func _draw_building_mark(building: Dictionary) -> void:
	var pos: Vector2 = building.get("pos", Vector2.ZERO)
	var size: Vector2 = building.get("size", Vector2(60, 60))
	var accent := _accent(building)
	var race_id := str(building.get("race", "authority"))
	if race_id == "authority":
		draw_arc(pos, minf(size.x, size.y) * 0.28, PI, TAU, 18, Color("e9f6ff"), 2.0)
	elif race_id == "lunar_cartel":
		draw_line(pos + Vector2(-size.x * 0.25, size.y * 0.18), pos + Vector2(size.x * 0.25, -size.y * 0.20), accent, 4.0)
	elif race_id == "null_choir":
		draw_arc(pos, minf(size.x, size.y) * 0.31, 0.0, TAU, 24, accent, 3.0)
	else:
		for index in 6:
			var a := index * TAU / 6.0
			draw_line(pos, pos + Vector2.from_angle(a) * minf(size.x, size.y) * 0.30, accent, 2.0)

func _draw_unit_mark(unit: Dictionary) -> void:
	var pos: Vector2 = unit.get("pos", Vector2.ZERO)
	var radius: float = float(unit.get("r", 15.0))
	var accent := _accent(unit)
	var race_id := str(unit.get("race", "authority"))
	if race_id == "authority":
		draw_line(pos + Vector2(-radius * 0.52, radius * 0.32), pos + Vector2(radius * 0.52, radius * 0.32), Color("edf7ff"), 2.0)
	elif race_id == "lunar_cartel":
		draw_circle(pos + Vector2(0, radius * 0.15), radius * 0.18, Color("5dfff1"))
	elif race_id == "null_choir":
		draw_arc(pos, radius * 0.62, 0.0, TAU, 14, accent, 2.0)
	else:
		draw_line(pos + Vector2(-radius * 0.42, -radius * 0.42), pos + Vector2(radius * 0.42, radius * 0.42), accent, 2.0)
		draw_line(pos + Vector2(-radius * 0.42, radius * 0.42), pos + Vector2(radius * 0.42, -radius * 0.42), accent, 2.0)
	if unit.get("kind", "") == "hero":
		draw_arc(pos, radius + 11.0, 0.0, TAU, 24, accent.lightened(0.25), 2.5)
