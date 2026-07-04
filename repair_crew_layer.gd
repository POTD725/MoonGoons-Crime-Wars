extends "res://defense_factory_layer.gd"
## Builder Drone repair behavior and Machine Shop producer support.

const REPAIR_RATE_PER_DRONE: float = 38.0
const REPAIR_MARGIN: float = 26.0
const REPAIR_SPARK_INTERVAL: float = 0.24

func _update_authority_unit(unit: Dictionary, delta: float) -> void:
	if str(unit.get("order", "")) == "repair":
		var structure: Dictionary = _entity(int(unit.get("repair_id", -1)))
		if structure.is_empty() or str(structure.get("team", "")) != AUTHORITY or not structure.has("size"):
			_release_repair_drone(unit)
			return
		var maximum: float = float(structure.get("max", 0.0))
		if float(structure.get("hp", 0.0)) >= maximum:
			_release_repair_drone(unit)
			return
		var work_position: Vector2 = _repair_work_position(structure, unit)
		var drone_position: Vector2 = unit.get("pos", Vector2.ZERO) as Vector2
		if drone_position.distance_to(work_position) > 7.0:
			_move_unit(unit, work_position, delta)
			return
		var structure_position: Vector2 = structure.get("pos", Vector2.ZERO) as Vector2
		unit["facing"] = drone_position.direction_to(structure_position)
		unit["walk_phase"] = float(unit.get("walk_phase", 0.0)) + delta * 15.0
		structure["hp"] = minf(maximum, float(structure.get("hp", 0.0)) + REPAIR_RATE_PER_DRONE * delta)
		unit["repair_fx"] = float(unit.get("repair_fx", 0.0)) + delta
		if float(unit.get("repair_fx", 0.0)) >= REPAIR_SPARK_INTERVAL:
			unit["repair_fx"] = 0.0
			_spawn_effect("spark", drone_position.lerp(structure_position, 0.58), Color("72f2bd"), 0.32)
		return
	super._update_authority_unit(unit, delta)

func _order_selected(world_point: Vector2) -> void:
	var damaged_structure: Dictionary = _damaged_authority_building_at(world_point)
	if not damaged_structure.is_empty() and not selected.is_empty():
		var assigned: int = 0
		for entity_id: int in selected:
			var unit: Dictionary = _entity(entity_id)
			if str(unit.get("team", "")) == AUTHORITY and str(unit.get("kind", "")) == "drone" and bool(unit.get("ready", true)):
				_assign_repair_drone(unit, damaged_structure)
				assigned += 1
		if assigned > 0:
			flash("REPAIR CREW // %d Builder Drone(s) repairing %s." % [assigned, str(damaged_structure.get("name", "structure"))], 2.4)
			_sound("order")
			return
	super._order_selected(world_point)

func _selected_producer(kind: String) -> Dictionary:
	var building: Dictionary = _entity(selected_building)
	if building.is_empty() or not bool(building.get("done", false)):
		return {}
	var building_kind: String = str(building.get("kind", ""))
	if kind == "shield" and building_kind == "armory":
		return building
	if kind == "bulwark_rover" and building_kind == "machine_shop":
		return building
	if kind != "shield" and kind != "bulwark_rover" and building_kind == "nexus":
		return building
	return {}

func _assign_repair_drone(drone: Dictionary, structure: Dictionary) -> void:
	drone["order"] = "repair"
	drone["repair_id"] = int(structure.get("id", -1))
	drone["repair_fx"] = 0.0
	drone.erase("construction_id")

func _release_repair_drone(drone: Dictionary) -> void:
	drone["order"] = "idle"
	drone.erase("repair_id")
	drone.erase("repair_fx")

func _repair_work_position(structure: Dictionary, drone: Dictionary) -> Vector2:
	var structure_position: Vector2 = structure.get("pos", Vector2.ZERO) as Vector2
	var size: Vector2 = structure.get("size", Vector2(80.0, 60.0)) as Vector2
	var drone_id: int = int(drone.get("id", 0))
	var angle: float = fposmod(float(drone_id) * 1.731, TAU)
	var radius: float = maxf(size.x, size.y) * 0.5 + REPAIR_MARGIN
	return structure_position + Vector2.from_angle(angle) * radius

func _damaged_authority_building_at(world_point: Vector2) -> Dictionary:
	for building: Dictionary in buildings:
		if str(building.get("team", "")) != AUTHORITY or not building.has("size"):
			continue
		if float(building.get("hp", 0.0)) >= float(building.get("max", 0.0)):
			continue
		var position: Vector2 = building.get("pos", Vector2.ZERO) as Vector2
		var size: Vector2 = building.get("size", Vector2(80.0, 60.0)) as Vector2
		if Rect2(position - size * 0.5, size).grow(38.0).has_point(world_point):
			return building
	return {}
