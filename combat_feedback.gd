extends Node
## Screen-space combat feedback for hits, destruction, and construction.

var canvas: CanvasLayer
var painter: FxPainter
var mission: Node
var previous_health: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	canvas = CanvasLayer.new()
	canvas.layer = 3
	canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(canvas)
	painter = FxPainter.new()
	canvas.add_child(painter)

func _process(delta: float) -> void:
	var current: Node = get_tree().current_scene
	if current == null or not current.has_method("_entity"):
		mission = null
		previous_health.clear()
		painter.effects.clear()
		return
	mission = current
	for entity in mission.get("units") + mission.get("buildings"):
		var id: int = int(entity.get("id", -1))
		var hp: float = float(entity.get("hp", 0.0))
		if previous_health.has(id) and hp < float(previous_health[id]):
			var damage: int = int(round(float(previous_health[id]) - hp))
			painter.add_hit(entity["pos"], damage, entity.get("team", "authority") == "authority")
		previous_health[id] = hp
	var active: Dictionary = {}
	for entity in mission.get("units") + mission.get("buildings"):
		active[int(entity.get("id", -1))] = true
	for id in previous_health.keys():
		if not active.has(id):
			previous_health.erase(id)
	painter.game = mission
	painter.tick(delta)

class FxPainter extends Node2D:
	var game: Node
	var effects: Array = []

	func add_hit(world_position: Vector2, amount: int, friendly: bool) -> void:
		effects.append({"pos":world_position, "amount":amount, "friendly":friendly, "time":0.0})

	func tick(delta: float) -> void:
		for effect in effects:
			effect["time"] += delta
		effects = effects.filter(func(effect): return float(effect["time"]) < 0.85)
		queue_redraw()

	func _draw() -> void:
		if game == null:
			return
		var view: Vector2 = game.get_viewport_rect().size
		var cam: Vector2 = game.get("cam")
		var zoom: float = float(game.get("zoom"))
		draw_set_transform(view * 0.5 - cam * zoom, 0.0, Vector2.ONE * zoom)
		for effect in effects:
			var age: float = float(effect["time"])
			var pos: Vector2 = effect["pos"] + Vector2(0.0, -age * 42.0)
			var alpha: float = 1.0 - age / 0.85
			var color := Color("8fe9ff") if bool(effect["friendly"]) else Color("ff788c")
			draw_circle(effect["pos"], 12.0 + age * 24.0, Color(color.r, color.g, color.b, alpha * 0.20), false, 2.0)
			draw_string(ThemeDB.fallback_font, pos, "-%d" % int(effect["amount"]), HORIZONTAL_ALIGNMENT_CENTER, 50, 16, Color(color.r, color.g, color.b, alpha))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
