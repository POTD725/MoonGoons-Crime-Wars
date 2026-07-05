extends Control
## LAN multiplayer is not implemented yet. This prevents a silent no-op flow and makes the limitation explicit.

func _ready() -> void:
	var background: ColorRect = ColorRect.new()
	background.color = Color("071021")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var label: Label = Label.new()
	label.text = "LAN MULTIPLAYER // UNDER CONSTRUCTION\nLocal host/join flow is scheduled after the RTS simulation and campaign are stable."
	label.position = Vector2(220.0, 350.0)
	label.size = Vector2(1160.0, 90.0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", Color("8fe9ff"))
	add_child(label)
	var back: Button = Button.new()
	back.text = "RETURN TO MAIN MISSION"
	back.position = Vector2(610.0, 475.0)
	back.size = Vector2(380.0, 52.0)
	back.add_theme_font_size_override("font_size", 16)
	back.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://main.tscn"))
	add_child(back)
