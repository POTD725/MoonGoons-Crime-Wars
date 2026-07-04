extends "res://resource_queue_hud.gd"
## Keeps tactical UI hidden during faction choice and campaign debriefs.

func _process(_delta: float) -> void:
	var current_scene: Node = get_tree().current_scene
	if current_scene == null or not current_scene.has_method("_entity") or not current_scene.has_method("_begin_build"):
		canvas.visible = false
		game = null
		return
	game = current_scene
	if bool(game.get_meta("faction_picker_active", false)) or bool(game.get_meta("campaign_debrief_active", false)):
		canvas.visible = false
		return
	canvas.visible = true
	_refresh()

func _objective_text() -> String:
	if game != null and game.has_meta("campaign_objective"):
		return str(game.get_meta("campaign_objective", ""))
	return super._objective_text()
