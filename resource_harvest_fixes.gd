extends "res://core_png_presentation.gd"
## Reliable Builder Drone resource collection.
## Ore becomes Credits/Supplies. Evidence caches become Intel.

const HARVEST_RANGE: float = 66.0
const DRONE_CARGO_LIMIT: int = 20

func _resource_at(world_point: Vector2) -> int:
	var result: int = -1
	var closest_distance: float = 86.0
	for index in range(nodes.size()):
		var resource: Dictionary = nodes[index]
		if int(resource.get("amount", 0)) <= 0:
			continue
		var resource_position: Vector2 = resource.get("pos", Vector2.ZERO) as Vector2
		var distance_value: float = world_point.distance_to(resource_position)
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
			var deposit_name: String = "INTEL CACHE" if resource_type == "evidence" else "ORE DEPOSIT"
			flash("HARVEST ORDER // %d Builder Drone(s) assigned to %s." % [assigned, deposit_name], 2.6)
			_sound("order")
			return
	super._order_selected(world_point)

func _update_harvest(unit: Dictionary, delta: float) -> void:
	var node_index: int = int(unit.get("target_id", -1))
	if node_index < 0 or node_index >= nodes.size():
		if int(unit.get("carrying", 0)) > 0:
			_return_drone_cargo(unit, str(unit.get("cargo_type", "ore")), delta)
		else:
			unit["order"] = "idle"
		return

	var resource: Dictionary = nodes[node_index]
	var resource_type: String = str(resource.get("type", "ore"))
	var carrying: int = int(unit.get("carrying", 0))
	var cargo_type: String = str(unit.get("cargo_type", resource_type))
	if cargo_type.is_empty():
		cargo_type = resource_type
		unit["cargo_type"] = cargo_type

	if carrying > 0 and (carrying >= DRONE_CARGO_LIMIT or int(resource.get("amount", 0)) <= 0 or cargo_type != resource_type):
		_return_drone_cargo(unit, cargo_type, delta)
		return

	if int(resource.get("amount", 0)) <= 0:
		unit["order"] = "idle"
		unit["action_state"] = "idle"
		flash("Deposit exhausted.", 1.8)
		return

	var resource_position: Vector2 = resource.get("pos", Vector2.ZERO) as Vector2
	var drone_position: Vector2 = unit.get("pos", Vector2.ZERO) as Vector2
	if drone_position.distance_to(resource_position) > HARVEST_RANGE:
		var service_offset: Vector2 = resource_position + resource_position.direction_to(drone_position) * 44.0
		unit["action_state"] = "moving"
		_move_unit(unit, service_offset, delta)
		return

	unit["facing"] = drone_position.direction_to(resource_position)
	unit["action_state"] = "harvesting"
	unit["harvest_clock"] = float(unit.get("harvest_clock", 0.0)) + delta
	if float(unit.get("harvest_clock", 0.0)) < 0.82:
		return

	unit["harvest_clock"] = 0.0
	var room: int = DRONE_CARGO_LIMIT - carrying
	var gathered: int = mini(room, int(resource.get("amount", 0)))
	resource["amount"] = int(resource.get("amount", 0)) - gathered
	unit["carrying"] = carrying + gathered
	unit["cargo_type"] = resource_type
	var effect_color: Color = Color("ffc46b") if resource_type == "evidence" else Color("66e8ff")
	_spawn_effect("spark", resource_position, effect_color, 0.35)

func _return_drone_cargo(unit: Dictionary, cargo_type: String, delta: float) -> void:
	var nexus: Dictionary = _home_nexus()
	if nexus.is_empty():
		return
	var nexus_position: Vector2 = nexus.get("pos", Vector2.ZERO) as Vector2
	var drone_position: Vector2 = unit.get("pos", Vector2.ZERO) as Vector2
	var dock_position: Vector2 = nexus_position + Vector2(78.0, 52.0)
	if drone_position.distance_to(dock_position) > 72.0:
		unit["action_state"] = "returning"
		_move_unit(unit, dock_position, delta)
		return

	var cargo: int = int(unit.get("carrying", 0))
	if cargo <= 0:
		return
	if cargo_type == "evidence":
		intel += cargo
		flash("INTEL DELIVERED // +%d Intel recovered." % cargo, 1.8)
		_spawn_effect("deposit", nexus_position, Color("ffc46b"), 0.45)
	else:
		credits += cargo
		supplies += maxi(1, cargo / 5)
		flash("ORE DELIVERED // +%d Credits, +%d Supplies." % [cargo, maxi(1, cargo / 5)], 1.8)
		_spawn_effect("deposit", nexus_position, Color("8deaff"), 0.45)
	unit["carrying"] = 0
	unit["cargo_type"] = ""
	unit["harvest_clock"] = 0.0
	_sound("complete")

func _draw_resources() -> void:
	super._draw_resources()
	for resource_index in range(nodes.size()):
		var resource: Dictionary = nodes[resource_index]
		if int(resource.get("amount", 0)) <= 0:
			continue
		var resource_position: Vector2 = resource.get("pos", Vector2.ZERO) as Vector2
		var resource_type: String = str(resource.get("type", "ore"))
		var marker_color: Color = Color("ffc46b") if resource_type == "evidence" else Color("65eaff")
		draw_arc(resource_position, 66.0, 0.0, TAU, 22, Color(marker_color.r, marker_color.g, marker_color.b, 0.34), 1.4)
		for unit: Dictionary in units:
			if str(unit.get("kind", "")) != "drone" or str(unit.get("order", "")) != "harvest":
				continue
			if int(unit.get("target_id", -1)) != resource_index:
				continue
			var drone_position: Vector2 = unit.get("pos", Vector2.ZERO) as Vector2
			draw_dashed_harvest_link(drone_position, resource_position, marker_color)

func draw_dashed_harvest_link(from_position: Vector2, to_position: Vector2, color_value: Color) -> void:
	var distance_value: float = from_position.distance_to(to_position)
	if distance_value <= 1.0:
		return
	var direction: Vector2 = from_position.direction_to(to_position)
	var cursor: float = 20.0
	while cursor < distance_value - 8.0:
		var segment_end: float = minf(cursor + 12.0, distance_value)
		draw_line(from_position + direction * cursor, from_position + direction * segment_end, Color(color_value.r, color_value.g, color_value.b, 0.78), 1.6)
		cursor += 24.0
