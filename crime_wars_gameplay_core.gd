extends "res://campaign_stage_layer.gd"
## MoonGoons: Crime Wars gameplay foundation.
## Canonical systems: Credits, Intel, Lunar Alloy, Evidence, Command Capacity, districts, and precinct upgrades.

const HARVEST_RANGE: float = 66.0
const DRONE_CARGO_LIMIT: int = 20
const DISTRICT_CAPTURE_RADIUS: float = 150.0
const DISTRICT_CAPTURE_SECONDS: float = 8.0
const DISTRICT_PAYOUT_SECONDS: float = 7.0

var lunar_alloy: int = 0
var evidence: int = 0
var command_capacity: int = 20
var command_used: int = 0
var command_reserved: int = 0
var nexus_level: int = 1
var leadership_level: int = 0
var investigation_level: int = 0
var orbital_level: int = 0
var districts: Array[Dictionary] = []
var district_payout_clock: float = 0.0

func _ready() -> void:
	super._ready()
	_install_crime_wars_specs()
	_seed_alloy_fields()
	_setup_districts()
	_refresh_command_capacity()
	set_meta("crime_wars_core_ready", true)
	call_deferred("_announce_core_systems")

func _announce_core_systems() -> void:
	flash("COMMAND NEXUS ONLINE // Secure districts, recover Evidence, refine Lunar Alloy, and expand Command Capacity.", 5.0)

func _process(delta: float) -> void:
	super._process(delta)
	_refresh_command_capacity()
	if finished:
		return
	_update_districts(delta)
	_update_precinct_networks(delta)

func _install_crime_wars_specs() -> void:
	building_specs["evidence_vault"] = {"name":"Evidence Vault", "cost":210, "alloy":20, "size":Vector2(96.0, 72.0), "hp":820.0, "time":8.0, "accent":Color("ffca69")}
	building_specs["orbital_watchtower"] = {"name":"Orbital Watchtower", "cost":280, "alloy":45, "size":Vector2(78.0, 104.0), "hp":760.0, "time":10.0, "accent":Color("9ed7ff")}
	for building_kind in ["machine_shop", "air_support_pad", "radiation_array", "thermal_regulator"]:
		if building_specs.has(building_kind):
			var building_spec: Dictionary = building_specs[building_kind] as Dictionary
			if not building_spec.has("alloy"):
				building_spec["alloy"] = 20
			building_specs[building_kind] = building_spec
	for building_kind in ["sentry_turret", "pulse_cannon", "o2_generator"]:
		if building_specs.has(building_kind):
			var defense_spec: Dictionary = building_specs[building_kind] as Dictionary
			if not defense_spec.has("alloy"):
				defense_spec["alloy"] = 8
			building_specs[building_kind] = defense_spec

	var command_costs: Dictionary = {
		"drone":1, "deputy":2, "shield":3, "hero":4,
		"breacher":3, "ranger":3, "medic":2, "engineer":2, "recon":2, "warden":4,
		"bulwark_rover":4, "siege_crawler":5, "arc_lancer":4, "pursuit_skimmer":3,
		"bastion_tank":6, "troop_carrier":5, "mech_mover":8,
		"sky_lifter":5, "specter_flyer":4, "lunar_bomber":6
	}
	var alloy_costs: Dictionary = {
		"shield":5, "breacher":4, "ranger":5, "medic":2, "engineer":3, "recon":4, "warden":8,
		"bulwark_rover":12, "siege_crawler":22, "arc_lancer":18, "pursuit_skimmer":14,
		"bastion_tank":28, "troop_carrier":20, "mech_mover":38,
		"sky_lifter":22, "specter_flyer":26, "lunar_bomber":34
	}
	for kind_value in command_costs.keys():
		var kind_name: String = str(kind_value)
		if not unit_specs.has(kind_name):
			continue
		var unit_spec: Dictionary = unit_specs[kind_name] as Dictionary
		unit_spec["command"] = int(command_costs[kind_name])
		unit_spec["alloy"] = int(alloy_costs.get(kind_name, 0))
		unit_specs[kind_name] = unit_spec
	if unit_specs.has("warden"):
		var warden_spec: Dictionary = unit_specs["warden"] as Dictionary
		warden_spec["evidence"] = 6
		unit_specs["warden"] = warden_spec
	if unit_specs.has("specter_flyer"):
		var specter_spec: Dictionary = unit_specs["specter_flyer"] as Dictionary
		specter_spec["evidence"] = 8
		unit_specs["specter_flyer"] = specter_spec

func _seed_alloy_fields() -> void:
	var alloy_count: int = 0
	for resource: Dictionary in nodes:
		if str(resource.get("type", "")) == "alloy":
			alloy_count += 1
	if alloy_count > 0:
		return
	var player_center: Vector2 = authority_zone.get_center()
	var enemy_center: Vector2 = syndicate_zone.get_center()
	_spawn_node("alloy", player_center + Vector2(460.0, -310.0), 420)
	_spawn_node("alloy", enemy_center + Vector2(-420.0, 300.0), 520)

func _setup_districts() -> void:
	districts = [
		{"name":"BREAKWATER YARDS", "pos":authority_zone.get_center() + Vector2(500.0, -130.0), "owner":"neutral", "capture":0.0, "resource":"credits", "amount":10},
		{"name":"CRATER MARKET", "pos":Vector2(-120.0, -160.0), "owner":"neutral", "capture":0.0, "resource":"intel", "amount":3},
		{"name":"ALLOY MINE", "pos":Vector2(680.0, 260.0), "owner":"neutral", "capture":0.0, "resource":"alloy", "amount":3},
		{"name":"BLACK SITE ARCHIVE", "pos":syndicate_zone.get_center() + Vector2(-500.0, 300.0), "owner":"syndicate", "capture":0.0, "resource":"evidence", "amount":1}
	]

func _refresh_command_capacity() -> void:
	var capacity: int = 20 + maxi(0, nexus_level - 1) * 10 + leadership_level * 6
	for building: Dictionary in buildings:
		if str(building.get("team", "")) != AUTHORITY or not bool(building.get("done", false)):
			continue
		match str(building.get("kind", "")):
			"relay": capacity += 8
			"orbital_watchtower": capacity += 8
			"evidence_vault": capacity += 2
	command_capacity = capacity
	var used: int = 0
	for unit: Dictionary in units:
		if str(unit.get("team", "")) != AUTHORITY:
			continue
		var unit_kind: String = str(unit.get("kind", ""))
		var spec: Dictionary = unit_specs.get(unit_kind, {}) as Dictionary
		used += int(spec.get("command", 1))
	command_used = used
	command_reserved = _queued_command_capacity()

func _queued_command_capacity() -> int:
	var total: int = 0
	for producer_key in production_queues.keys():
		var queue: Array = production_queues.get(producer_key, []) as Array
		for entry_value in queue:
			if not (entry_value is Dictionary):
				continue
			var entry: Dictionary = entry_value as Dictionary
			var unit_kind: String = str(entry.get("kind", ""))
			var spec: Dictionary = unit_specs.get(unit_kind, {}) as Dictionary
			total += int(spec.get("command", 1))
	return total

func _train(kind: String) -> void:
	if not unit_specs.has(kind):
		return
	_refresh_command_capacity()
	var spec: Dictionary = unit_specs[kind] as Dictionary
	var required_command: int = int(spec.get("command", 1))
	if command_used + command_reserved + required_command > command_capacity:
		flash("COMMAND CAPACITY FULL // %d/%d in use. Build Communications Relays or upgrade the Command Nexus." % [command_used + command_reserved, command_capacity], 3.2)
		_sound("error")
		return
	var alloy_cost: int = int(spec.get("alloy", 0))
	var evidence_cost: int = int(spec.get("evidence", 0))
	if lunar_alloy < alloy_cost:
		flash("INSUFFICIENT LUNAR ALLOY // %d Alloy required for %s." % [alloy_cost, str(spec.get("name", kind))], 2.8)
		_sound("error")
		return
	if evidence < evidence_cost:
		flash("INSUFFICIENT EVIDENCE // %d Evidence required for %s." % [evidence_cost, str(spec.get("name", kind))], 2.8)
		_sound("error")
		return
	var queue_before: int = _queued_command_capacity()
	super._train(kind)
	var queue_after: int = _queued_command_capacity()
	if queue_after > queue_before:
		lunar_alloy -= alloy_cost
		evidence -= evidence_cost
		_refresh_command_capacity()

func _begin_build(kind: String) -> void:
	if not _can_begin_structure(kind):
		return
	super._begin_build(kind)

func _can_begin_structure(kind: String) -> bool:
	if not building_specs.has(kind):
		return false
	var spec: Dictionary = building_specs[kind] as Dictionary
	var alloy_cost: int = int(spec.get("alloy", 0))
	if lunar_alloy < alloy_cost:
		flash("INSUFFICIENT LUNAR ALLOY // %d Alloy required for %s." % [alloy_cost, str(spec.get("name", kind))], 2.8)
		return false
	return true

func _consume_structure_alloy(kind: String) -> void:
	if not building_specs.has(kind):
		return
	var spec: Dictionary = building_specs[kind] as Dictionary
	lunar_alloy = maxi(0, lunar_alloy - int(spec.get("alloy", 0)))
	_refresh_command_capacity()

func _upgrade_command_nexus() -> void:
	var nexus: Dictionary = _home_nexus()
	if nexus.is_empty():
		return
	var credit_cost: int = 250 + (nexus_level - 1) * 150
	var alloy_cost: int = 25 + (nexus_level - 1) * 15
	if credits < credit_cost or lunar_alloy < alloy_cost:
		flash("NEXUS UPGRADE REQUIRES %d Credits and %d Lunar Alloy." % [credit_cost, alloy_cost], 3.0)
		_sound("error")
		return
	credits -= credit_cost
	lunar_alloy -= alloy_cost
	nexus_level += 1
	nexus["command_level"] = nexus_level
	nexus["max"] = float(nexus.get("max", 1400.0)) + 260.0
	nexus["hp"] = float(nexus.get("max", 1400.0))
	_refresh_command_capacity()
	flash("COMMAND NEXUS UPGRADED // Level %d // Command Capacity %d." % [nexus_level, command_capacity], 3.6)
	_spawn_effect("construct", nexus.get("pos", Vector2.ZERO) as Vector2, Color("8fe9ff"), 1.0)
	_sound("complete")

func _research_leadership() -> void:
	if not _has_completed_structure("evidence_vault"):
		flash("Build an Evidence Vault before researching leadership upgrades.", 2.8)
		return
	var intel_cost: int = 30 + leadership_level * 20
	var evidence_cost: int = 4 + leadership_level * 2
	if intel < intel_cost or evidence < evidence_cost:
		flash("LEADERSHIP NETWORK REQUIRES %d Intel and %d Evidence." % [intel_cost, evidence_cost], 2.8)
		_sound("error")
		return
	intel -= intel_cost
	evidence -= evidence_cost
	leadership_level += 1
	_refresh_command_capacity()
	flash("LEADERSHIP NETWORK %d ONLINE // +6 Command Capacity." % leadership_level, 3.2)
	_sound("complete")

func _has_completed_structure(kind_name: String) -> bool:
	for building: Dictionary in buildings:
		if str(building.get("team", "")) == AUTHORITY and str(building.get("kind", "")) == kind_name and bool(building.get("done", false)):
			return true
	return false

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
	var effect_color: Color = _resource_color(resource_type)
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
	match cargo_type:
		"evidence":
			var intel_gain: int = cargo + investigation_level * 2
			var evidence_gain: int = maxi(1, cargo / 4)
			intel += intel_gain
			evidence += evidence_gain
			flash("EVIDENCE DELIVERED // +%d Intel, +%d Evidence." % [intel_gain, evidence_gain], 1.8)
		"alloy":
			lunar_alloy += cargo
			flash("LUNAR ALLOY REFINED // +%d Alloy." % cargo, 1.8)
		_:
			credits += cargo
			supplies += maxi(1, cargo / 5)
			flash("ORE DELIVERED // +%d Credits, +%d Supplies." % [cargo, maxi(1, cargo / 5)], 1.8)
	_spawn_effect("deposit", nexus_position, _resource_color(cargo_type), 0.45)
	unit["carrying"] = 0
	unit["cargo_type"] = ""
	unit["harvest_clock"] = 0.0
	_sound("complete")

func _resource_color(resource_type: String) -> Color:
	match resource_type:
		"evidence": return Color("ffca69")
		"alloy": return Color("c7a8ff")
		_: return Color("65eaff")

func _update_districts(delta: float) -> void:
	district_payout_clock += delta
	for district: Dictionary in districts:
		var point: Vector2 = district.get("pos", Vector2.ZERO) as Vector2
		var authority_count: int = _team_presence(AUTHORITY, point)
		var syndicate_count: int = _team_presence(SYNDICATE, point)
		var owner: String = str(district.get("owner", "neutral"))
		if authority_count > 0 and syndicate_count == 0:
			if owner != AUTHORITY:
				district["capture"] = float(district.get("capture", 0.0)) + delta
				if float(district.get("capture", 0.0)) >= DISTRICT_CAPTURE_SECONDS:
					district["owner"] = AUTHORITY
					district["capture"] = 0.0
					flash("DISTRICT SECURED // " + str(district.get("name", "Control Point")), 2.5)
			elif owner == AUTHORITY:
				district["capture"] = 0.0
		elif syndicate_count > 0 and authority_count == 0:
			if owner == AUTHORITY:
				district["capture"] = float(district.get("capture", 0.0)) - delta
				if float(district.get("capture", 0.0)) <= -DISTRICT_CAPTURE_SECONDS:
					district["owner"] = SYNDICATE
					district["capture"] = 0.0
					flash("DISTRICT LOST // " + str(district.get("name", "Control Point")), 2.5)
		elif authority_count > 0 and syndicate_count > 0:
			district["capture"] = move_toward(float(district.get("capture", 0.0)), 0.0, delta * 0.5)
	if district_payout_clock >= DISTRICT_PAYOUT_SECONDS:
		district_payout_clock = 0.0
		_award_district_income()

func _team_presence(team_name: String, point: Vector2) -> int:
	var count: int = 0
	for unit: Dictionary in units:
		if str(unit.get("team", "")) == team_name and bool(unit.get("ready", true)) and (unit.get("pos", Vector2.ZERO) as Vector2).distance_to(point) <= DISTRICT_CAPTURE_RADIUS:
			count += 1
	return count

func _award_district_income() -> void:
	var credit_income: int = 0
	var intel_income: int = 0
	var alloy_income: int = 0
	var evidence_income: int = 0
	for district: Dictionary in districts:
		if str(district.get("owner", "")) != AUTHORITY:
			continue
		var amount: int = int(district.get("amount", 0))
		match str(district.get("resource", "credits")):
			"credits": credit_income += amount
			"intel": intel_income += amount
			"alloy": alloy_income += amount
			"evidence": evidence_income += amount
	credits += credit_income
	intel += intel_income
	lunar_alloy += alloy_income
	evidence += evidence_income
	if credit_income + intel_income + alloy_income + evidence_income > 0:
		flash("DISTRICT INCOME // +%d Credits  +%d Intel  +%d Alloy  +%d Evidence" % [credit_income, intel_income, alloy_income, evidence_income], 1.7)

func _update_precinct_networks(delta: float) -> void:
	if _has_completed_structure("evidence_vault"):
		investigation_level = maxi(investigation_level, 1)
	if _has_completed_structure("orbital_watchtower"):
		orbital_level = maxi(orbital_level, 1)
	if orbital_level > 0:
		for unit: Dictionary in units:
			if str(unit.get("team", "")) == AUTHORITY and str(unit.get("kind", "")) == "recon":
				unit["vision_bonus"] = 90.0

func _get_resource_stock(resource_type: String) -> int:
	match resource_type:
		"credits": return credits
		"intel": return intel
		"alloy": return lunar_alloy
		"evidence": return evidence
		"supplies": return supplies
		_: return 0

func _draw_resources() -> void:
	super._draw_resources()
	for district: Dictionary in districts:
		var position: Vector2 = district.get("pos", Vector2.ZERO) as Vector2
		var owner: String = str(district.get("owner", "neutral"))
		var color_value: Color = Color("8fe9ff") if owner == AUTHORITY else Color("ff74aa") if owner == SYNDICATE else Color("d7dfea")
		draw_circle(position, DISTRICT_CAPTURE_RADIUS, Color(color_value.r, color_value.g, color_value.b, 0.055))
		draw_arc(position, DISTRICT_CAPTURE_RADIUS, 0.0, TAU, 28, Color(color_value.r, color_value.g, color_value.b, 0.72), 2.0)
		draw_circle(position, 9.0 + sin(mission_clock * 2.0) * 1.5, color_value)
		var label_text: String = str(district.get("name", "DISTRICT")) + " // " + str(district.get("resource", "credits")).to_upper()
		draw_string(font, position + Vector2(-110.0, -DISTRICT_CAPTURE_RADIUS - 12.0), label_text, HORIZONTAL_ALIGNMENT_CENTER, 220.0, 11, color_value)
