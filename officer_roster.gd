extends Node
## F7 Authority Roster screen backed by the user-provided officer rank graphic.

var canvas: CanvasLayer
var overlay: Control
var poster: TextureRect
var status: Label

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_screen()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F7:
			_toggle()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_ESCAPE and overlay.visible:
			_close()
			get_viewport().set_input_as_handled()

func _toggle() -> void:
	if overlay.visible:
		_close()
	else:
		overlay.visible = true
		get_tree().paused = true

func _close() -> void:
	overlay.visible = false
	get_tree().paused = false

func _build_screen() -> void:
	canvas = CanvasLayer.new()
	canvas.layer = 64
	canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(canvas)
	overlay = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	canvas.add_child(overlay)

	var shade: ColorRect = ColorRect.new()
	shade.color = Color(0.003, 0.008, 0.022, 0.97)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(shade)

	var title: Label = Label.new()
	title.text = "MOONGOONS AUTHORITY // OFFICER ROSTER"
	title.position = Vector2(58, 20)
	title.size = Vector2(1484, 38)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 29)
	title.add_theme_color_override("font_color", Color("8fe9ff"))
	overlay.add_child(title)

	var subtitle: Label = Label.new()
	subtitle.text = "COMMAND STAFF • FIELD OFFICERS • ENLISTED OFFICERS  //  Used to guide Authority troop promotions and hero command tiers."
	subtitle.position = Vector2(60, 58)
	subtitle.size = Vector2(1480, 23)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 14)
	subtitle.add_theme_color_override("font_color", Color("c4d8ec"))
	overlay.add_child(subtitle)

	var frame: Panel = Panel.new()
	frame.position = Vector2(30, 96)
	frame.size = Vector2(1160, 770)
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color("061426")
	style.border_color = Color("2a9de0")
	style.set_border_width_all(2)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	frame.add_theme_stylebox_override("panel", style)
	overlay.add_child(frame)

	poster = TextureRect.new()
	poster.position = Vector2(18, 18)
	poster.size = Vector2(1124, 735)
	poster.texture = OfficerRosterTexture.get_texture()
	poster.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	poster.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	poster.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(poster)

	var side: Panel = Panel.new()
	side.position = Vector2(1212, 96)
	side.size = Vector2(328, 770)
	var side_style: StyleBoxFlat = StyleBoxFlat.new()
	side_style.bg_color = Color("08182b")
	side_style.border_color = Color("efc75e")
	side_style.set_border_width_all(2)
	side_style.corner_radius_top_left = 12
	side_style.corner_radius_top_right = 12
	side_style.corner_radius_bottom_left = 12
	side_style.corner_radius_bottom_right = 12
	side.add_theme_stylebox_override("panel", side_style)
	overlay.add_child(side)

	var briefing: Label = Label.new()
	briefing.text = "RANK PROGRESSION\n\nChief of Police\nDeputy Chief\nAssistant Chief\nCommander\nLieutenant Commander\nExecutive Officer\n\nCaptain\nFirst Lieutenant\nLieutenant\nSergeant\nCorporal\nDetective\n\nSenior Officer\nPolice Officer\nOfficer First Class\nCadet\nRecruit\nCadet Trainee\n\nFIELD USE\nHigher ranks unlock stronger Authority mesh variants, command auras, and advanced squad assignments."
	briefing.position = Vector2(22, 26)
	briefing.size = Vector2(282, 584)
	briefing.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	briefing.add_theme_font_size_override("font_size", 16)
	briefing.add_theme_color_override("font_color", Color("e7f4ff"))
	side.add_child(briefing)

	status = Label.new()
	status.text = "ASSET LINK // USER-PROVIDED OFFICER ROSTER\nF7 or ESC closes this console"
	status.position = Vector2(22, 655)
	status.size = Vector2(282, 56)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.add_theme_font_size_override("font_size", 12)
	status.add_theme_color_override("font_color", Color("8fe9ff"))
	side.add_child(status)

	var close_button: Button = Button.new()
	close_button.text = "RETURN TO COMMAND DECK"
	close_button.position = Vector2(22, 714)
	close_button.size = Vector2(282, 36)
	close_button.pressed.connect(_close)
	side.add_child(close_button)
	overlay.visible = false
