extends "res://force_expansion_layer.gd"
## Keeps ground units outside building interiors while leaving usable service space for construction and repair crews.

func _blocked_by_buildings(point: Vector2, _clearance: float) -> bool:
	for building: Dictionary in buildings:
		if float(building.get("hp", 0.0)) <= 0.0:
			continue
		var position: Vector2 = building.get("pos", Vector2.ZERO) as Vector2
		var size: Vector2 = building.get("size", Vector2(70.0, 50.0)) as Vector2
		if Rect2(position - size * 0.5, size).grow(5.0).has_point(point):
			return true
	return false
