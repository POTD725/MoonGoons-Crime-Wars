extends "res://lunar_render_layer.gd"
## Builder Drone construction layer.
## Structures progress only while assigned Builder Drones are at the blueprint.

const BUILD_WORK_MARGIN: float = 24.0
const BUILD_SPARK_INTERVAL: float = 0.24

func _update_buildings(delta: float) -> void:
	for building: Dictionary in buildings:
		if bool(building.get("done", false)):
			continue
		_ensure_construction_crew(building)
		var active_workers: int = _active_workers_at_site(building)
		if active_workers <= 0:
			continue
		var build_time: float = maxf(0.1, float(building.get("build_time", 1.0)))
		var progress: float = float(building.get("progress", 0.0))
		var build_rate: float = 1.0 + float(maxi(0, active_workers - 1)) * 0.55
		building["progress"] = minf(progress + delta * build_rate, build_time)
		if float(building.get("progress", 0.0)) >= build_time:
			building["done"] = true
			_release_construction_crew(building)
			_spawn_effect("construct", building["pos"] as Vector2, Color("8fe9ff"), 0.95)
			flash(str(building.get("name", "Structure")) + " online.", 2.0)
			_sound("complete")

func _update_authority_unit(unit: Dictionary, delta: float) -> void:
	if str(unit.get("order", "")) == "construct":
		var site: Dictionary = _entity(int(unit.get("construction_id", -1)))
		if site.is_empty() or bool(site.get("done", false)):
			unit["order"] = "idle"
			unit.erase("construction_id")
			return
		if str(site.get("team", "")) != AUTHORITY:
			unit["order"] = "idle"
			unit.erase("construction_id")
			return
		var work_position: Vector2 = _construction_work_position(site, unit)
		var unit_position: Vector2 = unit.get("pos", Vector2.ZERO) as Vector2
		if unit_position.distance_to(work_position) > 7.0:
			_move_unit(unit, work_position, delta)
			return
		var site_position: Vector2 = site.get("pos", Vector2.ZERO) as Vector2
		unit["facing"] = unit_position.direction_to(site_position)
		unit["walk_phase"] = float(unit.get("walk_phase", 0.0)) + delta * 16.0
		unit["build_fx"] = float(unit.get("build_fx", 0.0)) + delta
		if float(unit.get("build_fx", 0.0)) >= BUILD_SPARK_INTERVAL:
			unit["build_fx"] = 0.0
			_spawn_effect("spark", unit_position.lerp(site_position, 0.55), Color("72f2bd"), 0.32)
		return
	super._update_authority_unit(unit, delta)

func _order_selected(world_point: Vector2) -> void:
	var construction: Dictionary = _unfinished_authority_building_at(world_point)
	if not construction.is_empty() and not selected.is_empty():
		var assigned: int = 0
		for entity_id: int in selected:
			var unit: Dictionary = _entity(entity_id)
			if str(unit.get("team", "")) == AUTHORITY and str(unit.get("kind", "")) == "drone" and bool(unit.get("ready", true)):
				_assign_builder(unit, construction)
				assigned += 1
		if assigned > 0:
			flash("CONSTRUCTION CREW // %d Builder Drone(s) assigned to %s." % [assigned, str(construction.get("name", "blueprint"))], 2.4)
			_sound("order")
			return
	super._order_selected(world_point)

func _ensure_construction_crew(building: Dictionary) -> void:
	var valid_builders: Array = _valid_builder_ids(building)
	if valid_builders.is_empty():
		var available: Dictionary = _available_builder_drone()
		if not available.is_empty():
			_assign_builder(available, building)

func _valid_builder_ids(building: Dictionary) -> Array:
	var result: Array = []
	var assigned: Array = building.get("builder_ids", []) as Array
	for value in assigned:
		var drone: Dictionary = _entity(int(value))
		if drone.is_empty():
			continue
		if str(drone.get("team", "")) != AUTHORITY or str(drone.get("kind", "")) != "drone" or not bool(drone.get("ready", true)):
			continue
		if int(drone.get("construction_id", -1)) != int(building.get("id", -1)):
			continue
		result.append(int(value))
	building["builder_ids"] = result
	return result

func _active_workers_at_site(building: Dictionary) -> int:
	var count: int = 0
	var building_position: Vector2 = building.get("pos", Vector2.ZERO) as Vector2
	var size: Vector2 = building.get("size", Vector2(80.0, 60.0)) as Vector2
	var work_radius: float = maxf(size.x, size.y) * 0.5 + BUILD_WORK_MARGIN + 18.0
	for value in _valid_builder_ids(building):
		var drone: Dictionary = _entity(int(value))
		if drone.is_empty():
			continue
		var drone_position: Vector2 = drone.get("pos", Vector2.ZERO) as Vector2
		if drone_position.distance_to(building_position) <= work_radius:
			count += 1
	return count

func _available_builder_drone() -> Dictionary:
	var fallback: Dictionary = {}
	for unit: Dictionary in units:
		if str(unit.get("team", "")) != AUTHORITY or str(unit.get("kind", "")) != "drone" or not bool(unit.get("ready", true)):
			continue
		if str(unit.get("order", "")) == "construct":
			continue
		if str(unit.get("order", "")) == "idle":
			return unit
		if fallback.is_empty():
			fallback = unit
	return fallback

func _assign_builder(drone: Dictionary, building: Dictionary) -> void:
	var building_id: int = int(building.get("id", -1))
	var previous_id: int = int(drone.get("construction_id", -1))
	if previous_id != -1 and previous_id != building_id:
		var previous_building: Dictionary = _entity(previous_id)
		if not previous_building.is_empty():
			var previous_ids: Array = previous_building.get("builder_ids", []) as Array
			previous_ids.erase(int(drone.get("id", -1)))
			previous_building["builder_ids"] = previous_ids
	var ids: Array = building.get("builder_ids", []) as Array
	var drone_id: int = int(drone.get("id", -1))
	if not ids.has(drone_id):
		ids.append(drone_id)
	building["builder_ids"] = ids
	drone["construction_id"] = building_id
	drone["order"] = "construct"
	drone["build_fx"] = 0.0

func _release_construction_crew(building: Dictionary) -> void:
	var ids: Array = building.get("builder_ids", []) as Array
	for value in ids:
		var drone: Dictionary = _entity(int(value))
		if drone.is_empty():
			continue
		if int(drone.get("construction_id", -1)) == int(building.get("id", -1)):
			drone["order"] = "idle"
			drone.erase("construction_id")
	building["builder_ids"] = []

func _construction_work_position(building: Dictionary, drone: Dictionary) -> Vector2:
	var building_position: Vector2 = building.get("pos", Vector2.ZERO) as Vector2
	var size: Vector2 = building.get("size", Vector2(80.0, 60.0)) as Vector2
	var ids: Array = building.get("builder_ids", []) as Array
	var index: int = maxi(0, ids.find(int(drone.get("id", -1))))
	var angle: float = TAU * float(index) / float(maxi(1, ids.size())) + 0.45
	var radius: float = maxf(size.x, size.y) * 0.5 + BUILD_WORK_MARGIN
	return building_position + Vector2.from_angle(angle) * radius

func _unfinished_authority_building_at(world_point: Vector2) -> Dictionary:
	for building: Dictionary in buildings:
		if str(building.get("team", "")) != AUTHORITY or bool(building.get("done", false)):
			continue
		var position: Vector2 = building.get("pos", Vector2.ZERO) as Vector2
		var size: Vector2 = building.get("size", Vector2(80.0, 60.0)) as Vector2
		if Rect2(position - size * 0.5, size).grow(36.0).has_point(world_point):
			return building
	return {}
