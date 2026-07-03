extends Node

var match_ready: bool = false
var player_race: String = "authority"
var opposing_race: String = "lunar_cartel"
var selected_map: String = "Breakwater Split"
var selected_mode: String = "Standard Skirmish"
var level_id: String = "standard"
var bots: int = 1

func set_match(race_id: String, opponent_id: String, map_label: String, mode_label: String, difficulty_label: String, bot_count: int) -> void:
	player_race = race_id
	opposing_race = opponent_id
	selected_map = map_label
	selected_mode = mode_label
	level_id = difficulty_label
	bots = clampi(bot_count, 1, 7)
	GameDifficulty.set_level(level_id)
	match_ready = true

func is_ready() -> bool:
	return match_ready

func take_ready() -> bool:
	if not match_ready:
		return false
	match_ready = false
	return true
