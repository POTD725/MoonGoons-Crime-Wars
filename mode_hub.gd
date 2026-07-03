extends Node
## Press F2 anywhere to move between story operations, free roam, and LAN party.

var overlay: Control

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_overlay()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F2:
		overlay.visible = not overlay.visible
		get_tree().paused = overlay.visible
		get_viewport().set_input_as_handled()

func _build_overlay() -> void:
	var canvas := CanvasLayer.new()
	canvas.layer = 50
	canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(canvas)
	overlay = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	canvas.add_child(overlay)

	var shade := ColorRect.new()
	shade.color = Color(0.0, 0.01, 0.04, 0.92)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(shade)

	var title := Label.new()
	title.text = "MOONGOONS: CRIME WARS // MODE HUB"
	title.position = Vector2(180, 110)
	title.size = Vector2(1240, 48)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", Color("edf6ff"))
	overlay.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "F2 closes this hub. Choose your kind of trouble."
	subtitle.position = Vector2(180, 166)
	subtitle.size = Vector2(1240, 26)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 16)
	subtitle.add_theme_color_override("font_color", Color("a8c4e5"))
	overlay.add_child(subtitle)

	_add_mode_button("STORY OPERATIONS", "Faction RTS battles, campaign missions, cutscenes, and recon branches.", Vector2(230, 275), "res://main.tscn", Color("8fe9ff"))
	_add_mode_button("FREE ROAM", "Explore the Fracture Belt with a recon vessel. Scan sites, uncover risks, and collect campaign clues.", Vector2(630, 275), "res://free_roam.tscn", Color("72f2bd"))
	_add_mode_button("LAN PARTY", "Host or join a local network lobby, use ready slots and chat, then launch the LAN recon session.", Vector2(1030, 275), "res://lan_lobby.tscn", Color("ff9b62"))

	var footer := Label.new()
	footer.text = "LOCAL DEVELOPMENT BUILD // F9 developer console // F1 faction selection in RTS mode"
	footer.position = Vector2(180, 650)
	footer.size = Vector2(1240, 28)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.add_theme_font_size_override("font_size", 14)
	footer.add_theme_color_override("font_color", Color("c7d8eb"))
	overlay.add_child(footer)
	overlay.visible = false

func _add_mode_button(title: String, description: String, position: Vector2, target_scene: String, accent: Color) -> void:
	var button := Button.new()
	button.position = position
	button.size = Vector2(340, 270)
	button.text = title + "\n\n" + description + "\n\nCLICK TO OPEN"
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.add_theme_font_size_override("font_size", 17)
	button.add_theme_color_override("font_color", Color("f2f7ff"))
	var style := StyleBoxFlat.new()
	style.bg_color = accent.darkened(0.72)
	style.border_color = accent
	style.set_border_width_all(3)
	style.corner_radius_top_left = 18
	style.corner_radius_top_right = 18
	style.corner_radius_bottom_left = 18
	style.corner_radius_bottom_right = 18
	button.add_theme_stylebox_override("normal", style)
	button.pressed.connect(_go_to.bind(target_scene))
	overlay.add_child(button)

func _go_to(scene_path: String) -> void:
	overlay.visible = false
	get_tree().paused = false
	get_tree().change_scene_to_file(scene_path)
