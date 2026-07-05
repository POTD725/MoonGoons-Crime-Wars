extends "res://core_png_presentation.gd"
## Click-to-harvest orders without resource timing constants.

func _resource_at(world_point: Vector2) -> int:
	var result: int = -1
	var closest_distance: float = 86.0
	for index in range(nodes.size()):
		var resource: Dictionary = nodes[index]
		if int(resource.get("amount", 0)) <= 0:
			continue
		var distance_value: float = world_point.distance_to(resource.get("pos", Vector2.ZERO) as Vector2)
		if distance_value < closest_distance:
			result = index
			closest_distance = distance_value
	return result

func _order_selected(world_point: Vector2) -> void:
	if selected.is_empty() or finished:
		return
	var resource_index: int = _resource_at(world_point)
	if resource_index >= 0 and not attack_move_pending and not patrol_pending:
		var resource: Dictionary = nodes[resource_index]
		var resource_type: String = str(resource.get("type", "ore"))
		var assigned: int = 0
		for entity_id in selected:
			var unit: Dictionary = _entity(int(entity_id))
			if unit.is_empty() or str(unit.get("kind", "")) != "drone":
				continue
			unit["order"] = "harvest"
			unit["target_id"] = resource_index
			if int(unit.get("carrying", 0)) <= 0:
				unit["cargo_type"] = resource_type
			unit["harvest_clock"] = 0.0
			assigned += 1
		if assigned > 0:
			var label: String = "EVIDENCE CACHE" if resource_type == "evidence" else "LUNAR ALLOY" if resource_type == "alloy" else "ORE DEPOSIT"
			flash("HARVEST ORDER // %d Builder Drone(s) assigned to %s." % [assigned, label], 2.6)
			_sound("order")
			return
	super._order_selected(world_point)
