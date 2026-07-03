extends Node
## Global difficulty rules shared by Story, Free Roam, Custom Skirmish, and LAN solo-host sessions.

const LEVELS := {
	"easy": {
		"name":"Easy", "tagline":"For learning the lunar ropes.",
		"start_multiplier":1.35, "player_damage":1.15, "player_health":1.18,
		"ai_damage":0.72, "ai_health":0.80, "ai_interval":1.45,
		"recon_reward":1.30, "patrol_speed":0.72, "patrol_pressure":0.65
	},
	"standard": {
		"name":"Standard", "tagline":"The moon fights back fairly.",
		"start_multiplier":1.0, "player_damage":1.0, "player_health":1.0,
		"ai_damage":1.0, "ai_health":1.0, "ai_interval":1.0,
		"recon_reward":1.0, "patrol_speed":1.0, "patrol_pressure":1.0
	},
	"hard": {
		"name":"Hard", "tagline":"Veteran command conditions.",
		"start_multiplier":0.88, "player_damage":0.95, "player_health":0.92,
		"ai_damage":1.18, "ai_health":1.15, "ai_interval":0.78,
		"recon_reward":0.92, "patrol_speed":1.20, "patrol_pressure":1.30
	},
	"nightmare": {
		"name":"Nightmare", "tagline":"The siren never stops.",
		"start_multiplier":0.72, "player_damage":0.90, "player_health":0.82,
		"ai_damage":1.40, "ai_health":1.32, "ai_interval":0.58,
		"recon_reward":0.80, "patrol_speed":1.45, "patrol_pressure":1.60
	}
}

var active_id := "standard"

func set_level(level_id: String) -> void:
	if LEVELS.has(level_id):
		active_id = level_id

func get_level() -> Dictionary:
	return LEVELS.get(active_id, LEVELS["standard"])

func get_name() -> String:
	return str(get_level()["name"])

func multiplier(key: String, fallback: float = 1.0) -> float:
	return float(get_level().get(key, fallback))

func all_ids() -> Array[String]:
	return ["easy", "standard", "hard", "nightmare"]
