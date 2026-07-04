extends "res://campaign_clean_hud.gd"
## HUD presentation for the canonical four-resource economy and Command Capacity loop.

func _refresh() -> void:
	super._refresh()
	if game == null:
		return
	var queue_count: int = int(game.call("_get_total_pending_spawns")) if game.has_method("_get_total_pending_spawns") else 0
	var alloy_value: int = int(game.get("lunar_alloy")) if game.get("lunar_alloy") != null else 0
	var evidence_value: int = int(game.get("evidence")) if game.get("evidence") != null else 0
	var capacity_used: int = int(game.get("command_used")) if game.get("command_used") != null else 0
	var capacity_reserved: int = int(game.get("command_reserved")) if game.get("command_reserved") != null else 0
	var capacity_max: int = int(game.get("command_capacity")) if game.get("command_capacity") != null else 0
	resource_line.text = "CREDITS %04d  SUPPLIES %03d  INTEL %03d  ALLOY %03d  EVIDENCE %02d  CMD %02d+%02d/%02d  QUEUE %02d" % [int(game.get("credits")), int(game.get("supplies")), int(game.get("intel")), alloy_value, evidence_value, capacity_used, capacity_reserved, capacity_max, queue_count]
	var ore_remaining: int = int(game.call("_get_total_resource_amount", "ore")) if game.has_method("_get_total_resource_amount") else 0
	var evidence_remaining: int = int(game.call("_get_total_resource_amount", "evidence")) if game.has_method("_get_total_resource_amount") else 0
	var alloy_remaining: int = int(game.call("_get_total_resource_amount", "alloy")) if game.has_method("_get_total_resource_amount") else 0
	objective_line.text = _objective_text() + "\nFIELD DEPOSITS // ORE %d  EVIDENCE %d  ALLOY %d" % [ore_remaining, evidence_remaining, alloy_remaining]

func _set_command_tab(tab_id: String) -> void:
	super._set_command_tab(tab_id)
	if command_stage == null:
		return
	if tab_id == "BUILD":
		_clear_command_stage()
		_add_actions([
			["TACTICAL ARMORY\n160 C [1]", "build", "armory", "1b3658", "6fa8dc"],
			["COMMS RELAY\n60 C [2] +8 CMD", "build", "relay", "1b3658", "6fa8dc"],
			["FIELD MEDBAY\n120 C [3]", "build", "medbay", "164449", "72f2bd"],
			["DRONE BAY\n110 C [4]", "build", "bay", "203d68", "7aa8ff"],
			["HOLDING CELLS\n170 C [5]", "build", "cells", "55432d", "f3b85e"],
			["EVIDENCE VAULT\n210 C +20 A [9]", "build", "evidence_vault", "5a4324", "ffca69"],
			["NEXUS UPGRADE\n[U] +10 CMD", "upgrade_nexus", "", "234466", "8fe9ff"],
			["LEADERSHIP NETWORK\n[L] Intel + Evidence", "research", "", "303759", "d9c4ff"],
			["SET RALLY\n[Y]", "rally", "", "2a2350", "d9c4ff"]
		])
	elif tab_id == "SUPPORT":
		_clear_command_stage()
		_add_actions([
			["AIR SUPPORT PAD\n260 C +20 A", "build", "air_support_pad", "183d59", "77c8ff"],
			["AIR STRIKE\n25 INTEL [Z]", "airstrike", "", "233d63", "a3dcff"],
			["O2 GENERATOR\n145 C +8 A", "build", "o2_generator", "1b4c45", "77f7d8"],
			["THERMAL REGULATOR\n135 C +20 A", "build", "thermal_regulator", "4b3425", "ffbf7c"],
			["RADIATION ARRAY\n210 C +20 A", "build", "radiation_array", "34234f", "c09cff"],
			["ORBITAL WATCHTOWER\n280 C +45 A [0]", "build", "orbital_watchtower", "173c50", "9ed7ff"],
			["SKY LIFTER\n390 C +22 A", "train", "sky_lifter", "205269", "a2efff"],
			["SPECTER FLYER\n440 C +26 A +8 E", "train", "specter_flyer", "3a2f61", "b49cff"],
			["LUNAR BOMBER\n520 C +34 A", "train", "lunar_bomber", "5d3f29", "ffbf82"]
		])

func _clear_command_stage() -> void:
	for child in command_stage.get_children():
		child.queue_free()

func _run_force_action(action: String, value: String) -> void:
	match action:
		"upgrade_nexus":
			if game != null and game.has_method("_upgrade_command_nexus"):
				game.call("_upgrade_command_nexus")
		"research":
			if game != null and game.has_method("_research_leadership"):
				game.call("_research_leadership")
		_:
			super._run_force_action(action, value)
