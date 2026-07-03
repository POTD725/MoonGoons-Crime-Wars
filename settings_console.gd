extends Node
## F10 player settings: audio, fullscreen, and campaign reset.

var canvas: CanvasLayer
var panel: Panel
var master_slider: HSlider
var effects_slider: HSlider
var fullscreen_toggle: CheckButton
var status: Label

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F10:
		panel.visible = not panel.visible
		get_tree().paused = panel.visible
		get_viewport().set_input_as_handled()

func _build() -> void:
	canvas = CanvasLayer.new()
	canvas.layer = 66
	canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(canvas)
	panel = Panel.new()
	panel.position = Vector2(520, 200)
	panel.size = Vector2(560, 470)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.02, 0.05, 0.11, 0.98)
	style.border_color = Color("8fe9ff")
	style.set_border_width_all(3)
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_left = 14
	style.corner_radius_bottom_right = 14
	panel.add_theme_stylebox_override("panel", style)
	canvas.add_child(panel)
	var title := Label.new()
	title.text = "COMMAND DECK SETTINGS"
	title.position = Vector2(30, 24)
	title.size = Vector2(500, 32)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color("8fe9ff"))
	panel.add_child(title)
	master_slider = _slider("MASTER VOLUME", 92, GameProfile.master_volume)
	master_slider.value_changed.connect(_on_master_changed)
	effects_slider = _slider("EFFECTS VOLUME", 166, GameProfile.effects_volume)
	effects_slider.value_changed.connect(_on_effects_changed)
	fullscreen_toggle = CheckButton.new()
	fullscreen_toggle.text = "FULLSCREEN WINDOW"
	fullscreen_toggle.position = Vector2(54, 242)
	fullscreen_toggle.size = Vector2(450, 38)
	fullscreen_toggle.button_pressed = GameProfile.fullscreen
	fullscreen_toggle.toggled.connect(_on_fullscreen_toggled)
	panel.add_child(fullscreen_toggle)
	var reset := Button.new()
	reset.text = "RESET CAMPAIGN PROGRESS"
	reset.position = Vector2(54, 300)
	reset.size = Vector2(452, 46)
	reset.pressed.connect(_reset_campaign)
	panel.add_child(reset)
	status = Label.new()
	status.position = Vector2(54, 360)
	status.size = Vector2(452, 50)
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.add_theme_font_size_override("font_size", 13)
	status.add_theme_color_override("font_color", Color("d8e9f8"))
	panel.add_child(status)
	var close := Button.new()
	close.text = "RETURN TO COMMAND"
	close.position = Vector2(54, 414)
	close.size = Vector2(452, 38)
	close.pressed.connect(_close)
	panel.add_child(close)
	panel.visible = false
	_refresh()

func _slider(label_text: String, y: float, value: float) -> HSlider:
	var label := Label.new()
	label.text = label_text
	label.position = Vector2(54, y)
	label.size = Vector2(452, 22)
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color("eaf5ff"))
	panel.add_child(label)
	var slider := HSlider.new()
	slider.position = Vector2(54, y + 28)
	slider.size = Vector2(452, 20)
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = value
	panel.add_child(slider)
	return slider

func _on_master_changed(value: float) -> void:
	GameProfile.master_volume = value
	GameProfile.save_profile()
	_refresh()

func _on_effects_changed(value: float) -> void:
	GameProfile.effects_volume = value
	GameProfile.save_profile()
	_refresh()

func _on_fullscreen_toggled(value: bool) -> void:
	GameProfile.set_fullscreen(value)
	_refresh()

func _reset_campaign() -> void:
	GameProfile.reset_campaign()
	_refresh()

func _close() -> void:
	panel.visible = false
	get_tree().paused = false

func _refresh() -> void:
	if status == null:
		return
	status.text = "Campaign: %d completed operations.\nF10 toggles this settings console." % GameProfile.campaign_complete.size()
