extends Node
## Persistent custom-game setup. Read by RaceMode when main.tscn opens.

const SIZE_OPTIONS := [2, 4, 6, 8]
const SCENARIOS := {
	"standard": {"name":"Standard Skirmish", "description":"Destroy every opposing command structure.", "credits":420, "supplies":180, "intel":10},
	"resource_rush": {"name":"Resource Rush", "description":"High starting resources and dense central deposits. Expand fast.", "credits":800, "supplies":400, "intel":40},
	"king_of_relay": {"name":"King of the Relay", "description":"A central relay cache provides extra Intel and income control.", "credits":480, "supplies":200, "intel":60},
	"last_convoy": {"name":"Last Convoy", "description":"Secure the convoy field while the enemy tries to starve your supply lanes.", "credits":560, "supplies":300, "intel":20},
	"sudden_death": {"name":"Sudden Death", "description":"Low economy, heavy opening armies, fast resolution.", "credits":240, "supplies":80, "intel":0}
}

var pending := false
var team_size := 2
var map_id := "prisoner_exchange"
var scenario_id := "standard"
var local_race := "authority"
var slots: Array[Dictionary] = []
var ai_difficulty := "standard"

func configure(new_team_size: int, new_map_id: String, new_scenario_id: String, new_slots: Array[Dictionary], difficulty: String) -> void:
	team_size = clampi(new_team_size, 2, 8)
	map_id = new_map_id if PvpMaps.MAPS.has(new_map_id) else "breakwater_split"
	scenario_id = new_scenario_id if SCENARIOS.has(new_scenario_id) else "standard"
	slots = new_slots.duplicate(true)
	ai_difficulty = difficulty if GameDifficulty.LEVELS.has(difficulty) else "standard"
	GameDifficulty.set_level(ai_difficulty)
	local_race = _find_local_race()
	pending = true

func consume() -> bool:
	var value := pending
	pending = false
	return value

func is_pending() -> bool:
	return pending

func total_slots() -> int:
	return team_size * 2

func scenario() -> Dictionary:
	return SCENARIOS.get(scenario_id, SCENARIOS["standard"])

func _find_local_race() -> String:
	for slot in slots:
		if str(slot.get("team", "A")) == "A" and str(slot.get("controller", "human")) == "human":
			return str(slot.get("race", "authority"))
	return "authority"
