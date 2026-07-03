extends Node
## Persistent player settings and campaign state.

const SAVE_PATH := "user://moongoons_profile.cfg"

var master_volume := 0.85
var music_volume := 0.70
var effects_volume := 0.85
var fullscreen := false
var campaign_complete: Dictionary = {}
var best_scores: Dictionary = {}

func _ready() -> void:
	load_profile()

func load_profile() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return
	master_volume = float(config.get_value("settings", "master_volume", master_volume))
	music_volume = float(config.get_value("settings", "music_volume", music_volume))
	effects_volume = float(config.get_value("settings", "effects_volume", effects_volume))
	fullscreen = bool(config.get_value("settings", "fullscreen", fullscreen))
	campaign_complete = config.get_value("campaign", "complete", {})
	best_scores = config.get_value("campaign", "best_scores", {})
	_apply_window_setting()

func save_profile() -> void:
	var config := ConfigFile.new()
	config.set_value("settings", "master_volume", master_volume)
	config.set_value("settings", "music_volume", music_volume)
	config.set_value("settings", "effects_volume", effects_volume)
	config.set_value("settings", "fullscreen", fullscreen)
	config.set_value("campaign", "complete", campaign_complete)
	config.set_value("campaign", "best_scores", best_scores)
	config.save(SAVE_PATH)

func set_fullscreen(value: bool) -> void:
	fullscreen = value
	_apply_window_setting()
	save_profile()

func _apply_window_setting() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)

func complete_mission(mission_id: String, score: int) -> void:
	campaign_complete[mission_id] = true
	best_scores[mission_id] = maxi(int(best_scores.get(mission_id, 0)), score)
	save_profile()

func is_complete(mission_id: String) -> bool:
	return bool(campaign_complete.get(mission_id, false))

func reset_campaign() -> void:
	campaign_complete.clear()
	best_scores.clear()
	save_profile()
