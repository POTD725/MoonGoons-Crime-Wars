extends "res://campaign_map_router.gd"
## Expanded Peacekeeper roster and tactical support behavior.
## Kept deliberately focused: roster ownership, production routing, transport deployment,
## medic/engineer support, and building-aware movement.

const INFANTRY_KINDS: Array[String] = ["breacher", "ranger", "medic", "engineer", "recon", "warden"]
const VEHICLE_KINDS: Array[String] = ["bulwark_rover", "siege_crawler", "arc_lancer", "pursuit_skimmer", "bastion_tank", "troop_carrier", "mech_mover"]
const AIR_KINDS: Array[String] = ["sky_lifter", "specter_flyer", "lunar_bomber"]
const TRANSPORT_KINDS: Array[String] = ["troop_carrier", "sky_lifter"]

func _ready() -> void:
	_install_force_specs()
	super._ready()

func _install_force_specs() -> void:
	unit_specs["breacher"] = {"name":"Breach Deputy", "hp":245.0, "speed":108.0, "range":92.0, "damage":34.0, "cool":0.90, "radius":21.0, "accent":Color("ffad78"), "cost":145, "time":8.0, "role":"close"}
	unit_specs["ranger"] = {"name":"Lunar Ranger", "hp":145.0, "speed":126.0, "range":295.0, "damage":28.0, "cool":1.10, "radius":18.0, "accent":Color("b4e5ff"), "cost":165, "time":9.0, "role":"range"}
	unit_specs["medic"] = {"name":"Combat Medic", "hp":135.0, "speed":122.0, "range":0.0, "damage":0.0, "cool":0.0, "radius":18.0, "accent":Color("7dffd0"), "cost":130, "time":8.0, "role":"medic"}
	unit_specs["engineer"] = {"name":"Combat Engineer", "hp":175.0, "speed":114.0, "range":110.0, "damage":11.0, "cool":0.85, "radius":19.0, "accent":Color("ffd66e"), "cost":145, "time":8.0, "role":"engineer"}
	unit_specs["recon"] = {"name":"Recon Specialist", "hp":120.0, "speed":165.0, "range":205.0, "damage":16.0, "cool":0.56, "radius":16.0, "accent":Color("8deaff"), "cost":150, "time":8.0, "role":"recon"}
	unit_specs["warden"] = {"name":"Riot Warden", "hp":355.0, "speed":90.0, "range":145.0, "damage":27.0, "cool":0.76, "radius":25.0, "accent":Color("d7b6ff"), "cost":190, "time":11.0, "role":"warden"}
	unit_specs["bulwark_rover"] = {"name":"Bulwark Rover", "hp":720.0, "speed":82.0, "range":210.0, "damage":37.0, "cool":0.92, "radius":28.0, "accent":Color("7acfff"), "cost":305, "time":15.0, "role":"vehicle"}
	unit_specs["siege_crawler"] = {"name":"Siege Crawler", "hp":1050.0, "speed":54.0, "range":410.0, "damage":74.0, "cool":1.90, "radius":36.0, "accent":Color("ffc072"), "cost":390, "time":18.0, "role":"vehicle"}
	unit_specs["arc_lancer"] = {"name":"Arc Lancer", "hp":670.0, "speed":91.0, "range":270.0, "damage":46.0, "cool":0.94, "radius":28.0, "accent":Color("79e8ff"), "cost":330, "time":16.0, "role":"vehicle"}
	unit_specs["pursuit_skimmer"] = {"name":"Pursuit Skimmer", "hp":480.0, "speed":152.0, "range":210.0, "damage":31.0, "cool":0.62, "radius":24.0, "accent":Color("9dcbff"), "cost":275, "time":13.0, "role":"vehicle"}
	unit_specs["bastion_tank"] = {"name":"Bastion Tank", "hp":1280.0, "speed":63.0, "range":245.0, "damage":58.0, "cool":1.24, "radius":38.0, "accent":Color("ffb18b"), "cost":440, "time":21.0, "role":"vehicle"}
	unit_specs["troop_carrier"] = {"name":"Aegis Troop Carrier", "hp":960.0, "speed":88.0, "range":165.0, "damage":22.0, "cool":0.78, "radius":34.0, "accent":Color("9ce0c0"), "cost":360, "time":18.0, "role":"transport"}
	unit_specs["mech_mover"] = {"name":"Atlas Mech Mover", "hp":1600.0, "speed":66.0, "range":285.0, "damage":82.0, "cool":1.36, "radius":43.0, "accent":Color("f3d88d"), "cost":560, "time":25.0, "role":"mech"}
	unit_specs["sky_lifter"] = {"name":"Sky Lifter Transport", "hp":690.0, "speed":178.0, "range":0.0, "damage":0.0, "cool":0.0, "radius":30.0, "accent":Color("a2efff"), "cost":390, "time":20.0, "role":"air_transport", "airborne":true}
	unit_specs["specter_flyer"] = {"name":"Specter Stealth Flyer", "hp":420.0, "speed":220.0, "range":310.0, "damage":43.0, "cool":0.88, "radius":24.0, "accent":Color("b49cff"), "cost":440, "time":20.0, "role":"air", "airborne":true, "stealth":true}
	unit_specs["lunar_bomber"] = {"name":"Lunar Bomber", "hp":850.0, "speed":145.0, "range":350.0, "damage":96.0, "cool":2.05, "radius":34.0, "accent":Color("ffbf82"), "cost":520, "time":24.0, "role":"air", "airborne":true}

func _spawn_building(kind: String, team: String, position: Vector2, done: bool) -> Dictionary:
	var building: Dictionary = super._spawn_building(kind, team, position, done)
	if kind == "air_support_pad":
		building["rally_point"] = position + Vector2(188.0, 70.0)
	return building

func _spawn_unit(kind: String, team: String, position: Vector2) -> Dictionary:
	var unit: Dictionary = super._spawn_unit(kind, team, position)
	var spec: Dictionary = unit_specs.get(kind, {}) as Dictionary
	unit["airborne"] = bool(spec.get("airborne", false))
	unit["stealth"] = bool(spec.get("stealth", false))
	unit["role"] = str(spec.get("role", ""))
	unit["action_state"] = "idle"
	unit["action_flash"] = 0.0
	unit["support_clock"] = 0.0
	if kind == "troop_carrier":
		unit["payload"] = ["deputy", "breacher", "medic", "engineer"]
		unit["capacity"] = 4
	elif kind == "sky_lifter":
		unit["payload"] = ["recon", "ranger", "breacher", "medic", "engineer", "deputy"]
		unit["capacity"] = 6
	return unit

func _selected_producer(kind: String) -> Dictionary:
	var building: Dictionary = _entity(selected_building)
	if building.is_empty() or not bool(building.get("done", false)):
		return {}
	var building_kind: String = str(building.get("kind", ""))
	if kind == "deputy" or kind == "drone":
		return building if building_kind == "nexus" else {}
	if kind in INFANTRY_KINDS or kind == "shield":
		return building if building_kind == "armory" else {}
	if kind in VEHICLE_KINDS:
		return building if building_kind == "machine_shop" else {}
	if kind in AIR_KINDS:
		return building if building_kind == "air_support_pad" else {}
	return super._selected_producer(kind)

func _process(delta: float) -> void:
	super._process(delta)
	for unit: Dictionary in units:
		unit["action_flash"] = maxf(0.0, float(unit.get("action_flash", 0.0)) - delta)

func _update_authority_unit(unit: Dictionary, delta: float) -> void:
	var order: String = str(unit.get("order", "idle"))
	if order == "deploy":
		_update_transport_deployment(unit, delta)
		return
	if str(unit.get("kind", "")) == "medic" and (order == "idle" or order == "hold") and _medic_step(unit, delta):
		return
	if str(unit.get("kind", "")) == "engineer" and (order == "idle" or order == "hold") and _engineer_step(unit, delta):
		return
	unit["action_state"] = _state_for_order(order)
	super._update_authority_unit(unit, delta)

func _state_for_order(order: String) -> String:
	match order:
		"move", "attack_move", "patrol": return "moving"
		"construct": return "constructing"
		"repair": return "repairing"
		"harvest": return "harvesting"
		"attack": return "attacking"
		_: return "idle"

func _medic_step(unit: Dictionary, delta: float) -> bool:
	var patient: Dictionary = _nearest_wounded_authority(unit, 150.0)
	if patient.is_empty():
		return false
	var patient_position: Vector2 = patient.get("pos", Vector2.ZERO) as Vector2
	var unit_position: Vector2 = unit.get("pos", Vector2.ZERO) as Vector2
	if unit_position.distance_to(patient_position) > 92.0:
		_move_unit(unit, patient_position, delta)
		return true
	unit["action_state"] = "healing"
	unit["facing"] = unit_position.direction_to(patient_position)
	patient["hp"] = minf(float(patient.get("max", 0.0)), float(patient.get("hp", 0.0)) + 24.0 * delta)
	return true

func _engineer_step(unit: Dictionary, delta: float) -> bool:
	var building: Dictionary = _nearest_damaged_building(unit, 165.0)
	if building.is_empty():
		return false
	var building_position: Vector2 = building.get("pos", Vector2.ZERO) as Vector2
	var unit_position: Vector2 = unit.get("pos", Vector2.ZERO) as Vector2
	var size: Vector2 = building.get("size", Vector2(70.0, 50.0)) as Vector2
	var work_radius: float = maxf(size.x, size.y) * 0.5 + 34.0
	if unit_position.distance_to(building_position) > work_radius:
		_move_unit(unit, building_position + unit_position.direction_to(building_position) * -work_radius, delta)
		return true
	unit["action_state"] = "repairing"
	unit["facing"] = unit_position.direction_to(building_position)
	building["hp"] = minf(float(building.get("max", 0.0)), float(building.get("hp", 0.0)) + 16.0 * delta)
	return true

func _nearest_wounded_authority(unit: Dictionary, maximum_distance: float) -> Dictionary:
	var result: Dictionary = {}
	var best_distance: float = maximum_distance
	var position: Vector2 = unit.get("pos", Vector2.ZERO) as Vector2
	for candidate: Dictionary in units:
		if int(candidate.get("id", -1)) == int(unit.get("id", -2)) or str(candidate.get("team", "")) != AUTHORITY:
			continue
		if float(candidate.get("hp", 0.0)) >= float(candidate.get("max", 0.0)):
			continue
		var distance_value: float = position.distance_to(candidate.get("pos", Vector2.ZERO) as Vector2)
		if distance_value < best_distance:
			result = candidate
			best_distance = distance_value
	return result

func _nearest_damaged_building(unit: Dictionary, maximum_distance: float) -> Dictionary:
	var result: Dictionary = {}
	var best_distance: float = maximum_distance
	var position: Vector2 = unit.get("pos", Vector2.ZERO) as Vector2
	for building: Dictionary in buildings:
		if str(building.get("team", "")) != AUTHORITY or float(building.get("hp", 0.0)) >= float(building.get("max", 0.0)):
			continue
		var distance_value: float = position.distance_to(building.get("pos", Vector2.ZERO) as Vector2)
		if distance_value < best_distance:
			result = building
			best_distance = distance_value
	return result

func _order_selected(world_point: Vector2) -> void:
	var enemy: Dictionary = _enemy_at(world_point)
	if enemy.is_empty() and not selected.is_empty():
		var assigned: int = 0
		for entity_id: int in selected:
			var unit: Dictionary = _entity(entity_id)
			if unit.is_empty() or not (str(unit.get("kind", "")) in TRANSPORT_KINDS):
				continue
			var payload: Array = unit.get("payload", []) as Array
			if payload.is_empty():
				continue
			unit["order"] = "deploy"
			unit["target"] = world_point + _formation_offset(assigned)
			unit["action_state"] = "deploying"
			assigned += 1
		if assigned > 0:
			flash("TRANSPORT DEPLOYMENT // %d transport(s) moving to release their carried squad." % assigned, 2.8)
			_sound("order")
			return
	super._order_selected(world_point)

func _update_transport_deployment(unit: Dictionary, delta: float) -> void:
	var target: Vector2 = unit.get("target", unit.get("pos", Vector2.ZERO)) as Vector2
	if (unit.get("pos", Vector2.ZERO) as Vector2).distance_to(target) > 12.0:
		unit["action_state"] = "deploying"
		_move_unit(unit, target, delta)
		return
	unit["order"] = "unloading"
	call_deferred("_complete_transport_deployment", int(unit.get("id", -1)))

func _complete_transport_deployment(transport_id: int) -> void:
	var transport: Dictionary = _entity(transport_id)
	if transport.is_empty():
		return
	var payload: Array = transport.get("payload", []) as Array
	if payload.is_empty():
		transport["order"] = "idle"
		return
	var position: Vector2 = transport.get("pos", Vector2.ZERO) as Vector2
	for index in range(payload.size()):
		var angle: float = TAU * float(index) / float(maxi(1, payload.size())) + 0.35
		var passenger: Dictionary = _spawn_unit(str(payload[index]), AUTHORITY, position + Vector2.from_angle(angle) * 52.0)
		passenger["arrival_flash"] = 0.75
	transport["payload"] = []
	transport["order"] = "idle"
	transport["action_state"] = "idle"
	flash(str(transport.get("name", "Transport")) + " deployed its squad.", 2.2)
	_sound("complete")

func _spawn_projectile(attacker: Dictionary, target: Dictionary) -> void:
	attacker["action_flash"] = 0.26
	attacker["action_state"] = "firing"
	super._spawn_projectile(attacker, target)

func _move_unit(unit: Dictionary, target: Vector2, delta: float) -> void:
	var position: Vector2 = unit.get("pos", Vector2.ZERO) as Vector2
	var direction: Vector2 = position.direction_to(target)
	if direction.length_squared() > 0.0:
		unit["facing"] = direction
	var next_position: Vector2 = position.move_toward(target, float(unit.get("speed", 0.0)) * delta)
	if bool(unit.get("airborne", false)):
		unit["pos"] = next_position
		return
	var clearance: float = float(unit.get("radius", 16.0)) + 5.0
	if not _blocked_by_map(next_position, clearance) and not _blocked_by_buildings(next_position, clearance):
		unit["pos"] = next_position
		return
	var horizontal_slide: Vector2 = Vector2(next_position.x, position.y)
	var vertical_slide: Vector2 = Vector2(position.x, next_position.y)
	if not _blocked_by_map(horizontal_slide, clearance) and not _blocked_by_buildings(horizontal_slide, clearance):
		unit["pos"] = horizontal_slide
	elif not _blocked_by_map(vertical_slide, clearance) and not _blocked_by_buildings(vertical_slide, clearance):
		unit["pos"] = vertical_slide

func _blocked_by_buildings(point: Vector2, clearance: float) -> bool:
	for building: Dictionary in buildings:
		if float(building.get("hp", 0.0)) <= 0.0:
			continue
		var position: Vector2 = building.get("pos", Vector2.ZERO) as Vector2
		var size: Vector2 = building.get("size", Vector2(70.0, 50.0)) as Vector2
		if Rect2(position - size * 0.5, size).grow(clearance).has_point(point):
			return true
	return false

func _revealed(world_point: Vector2) -> bool:
	for entity: Dictionary in units:
		if str(entity.get("team", "")) != AUTHORITY:
			continue
		var reveal_range: float = 610.0 if str(entity.get("kind", "")) == "recon" else 500.0 if bool(entity.get("airborne", false)) else 360.0
		if (entity.get("pos", Vector2.ZERO) as Vector2).distance_to(world_point) < reveal_range:
			return true
	return super._revealed(world_point)
