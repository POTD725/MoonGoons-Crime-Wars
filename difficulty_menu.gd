extends Node
## F4 global difficulty selector, available in every mode.

var overlay: Control
var detail: Label
var chosen_id := "standard"

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	chosen_id = GameDifficulty.active_id
	_build_ui()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F4:
		overlay.visible = not overlay.visible
		get_tree().paused = overlay.visible
		get_viewport().set_input_as_handled()

func _build_ui() -> void:
	var canvas := CanvasLayer.new()
	canvas.layer = 56
	canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(canvas)
	overlay = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	canvas.add_child(overlay)

	var shade := ColorRect.new()
	shade.color = Color(0.005, 0.01, 0.04, 0.95)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(shade)

	var title := Label.new()
	title.text = "DIFFICULTY CONSOLE"
	title.position = Vector2(180, 105)
	title.size = Vector2(1240, 44)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", Color("f0f7ff"))
	overlay.add_child(title)

	var sub := Label.new()
	sub.text = "F4 closes this menu. Changes apply to new matches immediately and live AI pressure as the current scene updates."
	sub.position = Vector2(130, 155)
	sub.size = Vector2(1340, 26)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 14)
	sub.add_theme_color_override("font_color", Color("b6cae2"))
	overlay.add_child(sub)

	var ids := GameDifficulty.all_ids()
	for index in ids.size():
		var level_id: String = ids[index]
		var data := GameDifficulty.LEVELS[level_id]
		var button := Button.new()
		button.position = Vector2(125 + index * 350, 245)
		button.size = Vector2(300, 300)
		button.text = "%s\n\n%s\n\nStart support: %.0f%%\nAI damage: %.0f%%\nAI health: %.0f%%\nAI pace: %.0f%%\nRecon rewards: %.0f%%\n\nSELECT" % [data["name"], data["tagline"], float(data["start_multiplier"]) * 100.0, float(data["ai_damage"]) * 100.0, float(data["ai_health"]) * 100.0, 100.0 / float(data["ai_interval"]), float(data["recon_reward"]) * 100.0]
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.add_theme_font_size_override("font_size", 15)
		button.pressed.connect(_choose.bind(level_id))
		overlay.add_child(button)

	detail = Label.new()
	detail.position = Vector2(240, 605)
	detail.size = Vector2(1120, 58)
	detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.add_theme_font_size_override("font_size", 16)
	detail.add_theme_color_override("font_color", Color("d6e6f6"))
	overlay.add_child(detail)
	_refresh()
	overlay.visible = false

func _choose(level_id: String) -> void:
	chosen_id = level_id
	GameDifficulty.set_level(level_id)
	CustomMatchConfig.ai_difficulty = level_id
	_refresh()
	if InGameChat != null:
		InGameChat.post_system("Difficulty set to " + GameDifficulty.get_name() + ".")

func _refresh() -> void:
	var data := GameDifficulty.get_level()
	detail.text = "ACTIVE: %s  //  %s" % [data["name"], data["tagline"]]
