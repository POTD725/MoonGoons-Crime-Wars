extends Node
## Ensures scripted starting assets never begin inside a wall, void, crevasse, or map border.

var prepared_scene_id: int = -1

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(_delta: float) -> void:
	var scene: Node = get_tree().current_scene
	if scene == null or scene.get_instance_id() == prepared_scene_id:
		return
	if not scene.has_method("_blocked_by_map"):
		return
	prepared_scene_id = scene.get_instance_id()
	_move_blocked_entities_to_open_ground(scene, "buildings")
	_move_blocked_entities_to_open_ground(scene, "units")

func _move_blocked_entities_to_open_ground(scene: Node, property_name: String) -> void:
	var entities: Variant = scene.get(property_name)
	if not (entities is Array):
		return
	for entity_value: Variant in entities:
		if not (entity_value is Dictionary):
			continue
		var entity: Dictionary = entity_value as Dictionary
		var position: Vector2 = entity.get("pos", Vector2.ZERO) as Vector2
		var clearance: float = float(entity.get("radius", 28.0)) + 12.0
		if property_name == "buildings":
			var size: Vector2 = entity.get("size", Vector2(70.0, 50.0)) as Vector2
			clearance = maxf(size.x, size.y) * 0.5 + 14.0
		if not bool(scene.call("_blocked_by_map", position, clearance)):
			continue
		entity["pos"] = _nearest_open_position(scene, position, clearance)

func _nearest_open_position(scene: Node, origin: Vector2, clearance: float) -> Vector2:
	for ring: int in range(1, 27):
		var radius: float = float(ring) * 42.0
		for angle_index: int in range(20):
			var angle: float = TAU * float(angle_index) / 20.0
			var candidate: Vector2 = origin + Vector2.from_angle(angle) * radius
			if not bool(scene.call("_blocked_by_map", candidate, clearance)):
				return candidate
	return origin
