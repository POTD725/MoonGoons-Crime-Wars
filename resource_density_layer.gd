extends "res://crime_wars_gameplay_core.gd"
## Resource-density pass for every tactical map.
## Each battlefield keeps its authored map resources and gains safe starter, contested,
## and high-risk resource fields so economy decisions stay active through midgame.

const EXTRA_RESOURCE_FIELDS: Array[Dictionary] = [
	{"anchor":"player", "offset":Vector2(390.0, -250.0), "type":"ore", "amount":700},
	{"anchor":"player", "offset":Vector2(455.0, 105.0), "type":"ore", "amount":620},
	{"anchor":"player", "offset":Vector2(-290.0, -255.0), "type":"evidence", "amount":360},
	{"anchor":"player", "offset":Vector2(210.0, 360.0), "type":"alloy", "amount":320},
	{"anchor":"center", "offset":Vector2(-330.0, -230.0), "type":"ore", "amount":980},
	{"anchor":"center", "offset":Vector2(-90.0, 255.0), "type":"evidence", "amount":640},
	{"anchor":"center", "offset":Vector2(250.0, -185.0), "type":"alloy", "amount":520},
	{"anchor":"center", "offset":Vector2(370.0, 245.0), "type":"ore", "amount":860},
	{"anchor":"relay", "offset":Vector2(-430.0, 295.0), "type":"evidence", "amount":560},
	{"anchor":"relay", "offset":Vector2(-360.0, -275.0), "type":"alloy", "amount":470}
]

func _spawn_resource_fields() -> void:
	super._spawn_resource_fields()
	_add_resource_density_fields()

func _add_resource_density_fields() -> void:
	var player_spawn: Vector2 = active_map.get("player_spawn", Vector2(-1750.0, 720.0)) as Vector2
	var relay_spawn: Vector2 = active_map.get("relay_spawn", Vector2(1950.0, -980.0)) as Vector2
	var center: Vector2 = player_spawn.lerp(relay_spawn, 0.5)
	var added: int = 0
	for field: Dictionary in EXTRA_RESOURCE_FIELDS:
		var anchor: Vector2 = center
		match str(field.get("anchor", "center")):
			"player": anchor = player_spawn
			"relay": anchor = relay_spawn
		var preferred: Vector2 = anchor + (field.get("offset", Vector2.ZERO) as Vector2)
		var location: Vector2 = _find_open_resource_location(preferred)
		if location == Vector2.INF:
			continue
		_spawn_node(str(field.get("type", "ore")), location, int(field.get("amount", 500)))
		added += 1
	if added > 0:
		set_meta("extra_resource_fields", added)

func _find_open_resource_location(preferred: Vector2) -> Vector2:
	var candidates: Array[Vector2] = [
		preferred,
		preferred + Vector2(170.0, 0.0),
		preferred + Vector2(-170.0, 0.0),
		preferred + Vector2(0.0, 150.0),
		preferred + Vector2(0.0, -150.0),
		preferred + Vector2(150.0, 130.0),
		preferred + Vector2(-150.0, -130.0),
		preferred + Vector2(-150.0, 130.0),
		preferred + Vector2(150.0, -130.0)
	]
	for candidate: Vector2 in candidates:
		if not active_frontier.grow(-120.0).has_point(candidate):
			continue
		if _blocked_by_map(candidate, 34.0):
			continue
		if not _resource_spacing_open(candidate):
			continue
		return candidate
	return Vector2.INF

func _resource_spacing_open(candidate: Vector2) -> bool:
	for resource: Dictionary in nodes:
		var resource_position: Vector2 = resource.get("pos", Vector2.ZERO) as Vector2
		if candidate.distance_to(resource_position) < 150.0:
			return false
	for building: Dictionary in buildings:
		var building_position: Vector2 = building.get("pos", Vector2.ZERO) as Vector2
		if candidate.distance_to(building_position) < 190.0:
			return false
	return true
