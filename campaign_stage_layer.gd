extends "res://resource_orders_layer.gd"

const PLAYABLE_STAGES: Array[String] = ["CW-001", "CW-002", "CW-003"]

var campaign_mission_id: String = "CW-001"
var campaign_enabled: bool = true

func _ready() -> void:
	super._ready()
	campaign_enabled = not (MatchState != null and MatchState.is_ready())
	if not campaign_enabled:
		set_meta("campaign_mode", false)
		return
	campaign_mission_id = _next_playable_stage()
	set_meta("campaign_mode", true)
	set_meta("campaign_mission_id", campaign_mission_id)
	set_meta("campaign_debrief_active", false)
	set_meta("campaign_objective", _campaign_objective_text())
	call_deferred("_announce_campaign_stage")

func _next_playable_stage() -> String:
	for mission_id in PLAYABLE_STAGES:
		if not GameProfile.is_complete(mission_id):
			return mission_id
	return PLAYABLE_STAGES[PLAYABLE_STAGES.size() - 1]

func _announce_campaign_stage() -> void:
	var mission: Dictionary = CampaignData.get_mission(campaign_mission_id)
	flash("CAMPAIGN // %s // %s" % [campaign_mission_id, str(mission.get("title", campaign_mission_id))], 5.0)

func _campaign_objective_text() -> String:
	match campaign_mission_id:
		"CW-001": return "CW-001 // Build defenses, gather resources, finish a Tactical Armory, and destroy the hostile relay."
		"CW-002": return "CW-002 // Recover and return 80 Intel from gold Evidence Caches."
		"CW-003": return "CW-003 // Build 3 Communications Relays and hold the district for 120 seconds."
		_: return "Complete the current operation."

func _check_mission_end() -> void:
	if not campaign_enabled or bool(get_meta("custom_match", false)):
		return
	if _home_nexus().is_empty():
		_finish_campaign_stage(false)
		return
	match campaign_mission_id:
		"CW-001":
			if _relay().is_empty():
				_finish_campaign_stage(true)
		"CW-002":
			if intel >= 80:
				_finish_campaign_stage(true)
		"CW-003":
			if _completed_power_relays() >= 3 and mission_clock >= 120.0:
				_finish_campaign_stage(true)

func _completed_power_relays() -> int:
	var count: int = 0
	for building: Dictionary in buildings:
		if str(building.get("team", "")) == AUTHORITY and str(building.get("kind", "")) == "relay" and bool(building.get("done", false)):
			count += 1
	return count

func _finish_campaign_stage(won: bool) -> void:
	if finished:
		return
	finished = true
	victory = won
	if won:
		set_meta("campaign_debrief_active", true)
		flash("MISSION COMPLETE // Preparing campaign debrief.", 999.0)
		_sound("victory")
	else:
		flash("MISSION FAILED // The Command Nexus has fallen. Press R to retry.", 999.0)
		_sound("defeat")
