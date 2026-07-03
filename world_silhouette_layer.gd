extends Node
## Readable 2.5D silhouettes added above the original RTS markers.

var canvas: CanvasLayer
var painter: Node2D
var game: Node

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	canvas = CanvasLayer.new()
	canvas.layer = 0
	canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(canvas)
	painter = WorldPainter.new()
	canvas.add_child(painter)

func _process(_delta: float) -> void:
	var current: Node = get_tree().current_scene
	if current != null and current.has_method("_entity") and current.has_method("_revealed"):
		game = current
	else:
		game = null
	painter.set("game", game)
	painter.queue_redraw()

class WorldPainter extends Node2D:
	var game: Node

	func _draw() -> void:
		if game == null:
			return
		var view: Vector2 = game.get_viewport_rect().size
		var cam: Vector2 = game.get("cam")
		var zoom: float = float(game.get("zoom"))
		draw_set_transform(view * 0.5 - cam * zoom, 0.0, Vector2.ONE * zoom)
		for building in game.get("buildings"):
			if _visible(building):
				_draw_building(building)
		for unit in game.get("units"):
			if bool(unit.get("ready", true)) and _visible(unit):
				_draw_unit(unit)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	func _visible(entity: Dictionary) -> bool:
		if str(entity.get("team", "authority")) != "syndicate":
			return true
		return bool(game.call("_revealed", entity["pos"]))

	func _color(entity: Dictionary) -> Color:
		match str(entity.get("race", "authority")):
			"lunar_cartel": return Color("ff79c6")
			"null_choir": return Color("72f2bd")
			"hollow_fang": return Color("ff9b62")
			_: return Color("8fe9ff") if str(entity.get("team", "authority")) == "authority" else Color("ff7187")

	func _draw_unit(unit: Dictionary) -> void:
		var p: Vector2 = unit["pos"]
		var r: float = maxf(14.0, float(unit.get("r", 16.0)))
		var c: Color = _color(unit)
		var kind: String = str(unit.get("kind", "deputy"))
		if kind in ["drone", "signal_seed", "scrapwright"]:
			var diamond := PackedVector2Array([p + Vector2(0, -r), p + Vector2(r, 0), p + Vector2(0, r), p + Vector2(-r, 0)])
			draw_polyline(diamond, c.lightened(0.2), 2.0, true)
			draw_line(p + Vector2(-r * 1.1, 0), p + Vector2(r * 1.1, 0), c, 1.6)
			draw_line(p + Vector2(0, -r * 1.1), p + Vector2(0, r * 1.1), c, 1.6)
		elif kind in ["shield", "enforcer", "brute"]:
			var body := PackedVector2Array([p + Vector2(-r * .86, r * .7), p + Vector2(-r * .62, -r * .6), p + Vector2(r * .62, -r * .6), p + Vector2(r * .86, r * .7)])
			draw_polyline(body, c.lightened(0.2), 2.4, true)
			draw_arc(p + Vector2(-r, 0), r * .72, -PI * .5, PI * .5, 10, Color("efc75e"), 2.2)
		else:
			var torso := PackedVector2Array([p + Vector2(-r * .56, r * .55), p + Vector2(-r * .48, -r * .35), p + Vector2(r * .48, -r * .35), p + Vector2(r * .56, r * .55)])
			draw_polyline(torso, c.lightened(0.18), 1.8, true)
			draw_circle(p + Vector2(0, -r * .68), r * .30, c.lightened(0.24), false, 1.8)
			if kind == "hero":
				draw_arc(p, r * 1.34, 0.0, TAU, 18, Color("ffd16a"), 2.0)

	func _draw_building(building: Dictionary) -> void:
		var p: Vector2 = building["pos"]
		var s: Vector2 = building.get("size", Vector2(70, 56))
		var c: Color = _color(building)
		var kind: String = str(building.get("kind", "nexus"))
		if kind in ["nexus", "syndicate_relay", "harmonic_core", "war_rig"]:
			var points := PackedVector2Array()
			for i in 6:
				points.append(p + Vector2.from_angle(float(i) * TAU / 6.0 + PI / 6.0) * minf(s.x, s.y) * .43)
			draw_polyline(points, c.lightened(0.22), 2.4, true)
			draw_circle(p, minf(s.x, s.y) * .20, c, false, 2.0)
		elif kind in ["relay", "research_lab", "signal_spire", "war_drums"]:
			var triangle := PackedVector2Array([p + Vector2(-s.x * .32, s.y * .34), p + Vector2(0, -s.y * .46), p + Vector2(s.x * .32, s.y * .34)])
			draw_polyline(triangle, c.lightened(0.22), 2.2, true)
		else:
			draw_rect(Rect2(p - s * .38, s * .76), c.lightened(0.16), false, 2.0)
