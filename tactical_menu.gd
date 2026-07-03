extends Node
## F2 / P tactical menu for the stable playable demo.

var canvas: CanvasLayer
var panel: Panel
var volume_slider: HSlider
var fullscreen_toggle: CheckButton
var status: Label

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var key_event: InputEventKey = event
		if key_event.keycode == KEY_F2 or key_event.keycode == KEY_P:
			_toggle()
			get_viewport().set_input_as_handled()
		elif key_event.keycode == KEY_ESCAPE and panel.visible:
			_close()
			get_viewport().set_input_as_handled()

func _toggle() -> void:
	if panel.visible:
		_close()
	else:
		panel.visible = true
		get_tree().paused = true
		_refresh()

func _close() -> void:
	panel.visible = false
	get_tree().paused = false

func _build() -> void:
	canvas = CanvasLayer.new()
	canvas.layer = 64
	canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(canvas)
	panel = Panel.new()
	panel.position = Vector2(555.0, 205.0)
	panel.size = Vector2(490.0, 490.0)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color("061327")
	style.border_color = Color("efc75e")
	style.set_border_width_all(3)
	style.corner_radius_top_left = 15
	style.corner_radius_top_right = 15
	style.corner_radius_bottom_left = 15
	style.corner_radius_bottom_right = 15
	panel.add_theme_stylebox_override("panel", style)
	canvas.add_child(panel)
	var title: Label = Label.new()
	title.text = "TACTICAL PAUSE // MODE HUB"
	title.position = Vector2(24.0, 25.0)
	title.size = Vector2(442.0, 32.0)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 23)
	title.add_theme_color_override("font_color", Color("efc75e"))
	panel.add_child(title)
	_add_button("RESUME OPERATION", 82.0, _close)
	_add_button("OPEN CUSTOM GAME WAR ROOM", 136.0, _open_war_room)
	_add_button("RESTART CURRENT OPERATION", 190.0, _restart)
	_add_button("TOGGLE FULLSCREEN", 244.0, _toggle_fullscreen)
	var volume_label: Label = Label.new()
	volume_label.text = "TACTICAL AUDIO VOLUME"
	volume_label.position = Vector2(42.0, 313.0)
	volume_label.size = Vector2(400.0, 20.0)
	volume_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	volume_label.add_theme_font_size_override("font_size", 14)
	volume_label.add_theme_color_override("font_color", Color("b8d8f5"))
	panel.add_child(volume_label)
	volume_slider = HSlider.new()
	volume_slider.position = Vector2(48.0, 342.0)
	volume_slider.size = Vector2(394.0, 20.0)
	volume_slider.min_value = 0.0
	volume_slider.max_value = 1.0
	volume_slider.step = 0.05
	volume_slider.value = GameProfile.effects_volume
	volume_slider.value_changed.connect(_set_volume)
	panel.add_child(volume_slider)
	fullscreen_toggle = CheckButton.new()
	fullscreen_toggle.text = "FULLSCREEN WINDOW"
	fullscreen_toggle.position = Vector2(145.0, 378.0)
	fullscreen_toggle.size = Vector2(220.0, 30.0)
	fullscreen_toggle.button_pressed = GameProfile.fullscreen
	fullscreen_toggle.toggled.connect(_set_fullscreen)
	panel.add_child(fullscreen_toggle)
	status = Label.new()
	status.position = Vector2(30.0, 426.0)
	status.size = Vector2(430.0, 42.0)
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.add_theme_font_size_override("font_size", 12)
	status.add_theme_color_override("font_color", Color("9cbce0"))
	panel.add_child(status)
	panel.visible = false

func _add_button(text_value: String, y: float, action: Callable) -> void:
	var button: Button = Button.new()
	button.text = text_value
	button.position = Vector2(48.0, y)
	button.size = Vector2(394.0, 42.0)
	button.add_theme_font_size_override("font_size", 16)
	button.pressed.connect(action)
	panel.add_child(button)

func _open_war_room() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://custom_game.tscn")

func _restart() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _toggle_fullscreen() -> void:
	GameProfile.set_fullscreen(not GameProfile.fullscreen)
	fullscreen_toggle.button_pressed = GameProfile.fullscreen
	_refresh()

func _set_volume(value: float) -> void:
	GameProfile.effects_volume = value
	GameProfile.save_profile()
	_refresh()

func _set_fullscreen(value: bool) -> void:
	GameProfile.set_fullscreen(value)
	_refresh()

func _refresh() -> void:
	if status == null:
		return
	status.text = "F2 or P opens this hub. Current campaign progress: %d completed operations." % GameProfile.campaign_complete.size()
