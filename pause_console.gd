extends Node
## P toggles a pause panel without colliding with RTS build hotkeys.

var canvas: CanvasLayer
var panel: Panel

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_P:
		panel.visible = not panel.visible
		get_tree().paused = panel.visible
		get_viewport().set_input_as_handled()

func _build() -> void:
	canvas = CanvasLayer.new()
	canvas.layer = 57
	canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(canvas)
	panel = Panel.new()
	panel.position = Vector2(590, 260)
	panel.size = Vector2(420, 340)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.015, 0.035, 0.085, 0.98)
	style.border_color = Color("efc75e")
	style.set_border_width_all(3)
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_left = 14
	style.corner_radius_bottom_right = 14
	panel.add_theme_stylebox_override("panel", style)
	canvas.add_child(panel)
	var title := Label.new()
	title.text = "PAUSED // COMMAND HOLD"
	title.position = Vector2(30, 30)
	title.size = Vector2(360, 34)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color("efc75e"))
	panel.add_child(title)
	_add_button("RESUME", 94, func(): panel.visible = false; get_tree().paused = false)
	_add_button("RESTART CURRENT MODE", 150, func(): panel.visible = false; get_tree().paused = false; get_tree().reload_current_scene())
	_add_button("OPEN MODE HUB", 206, func(): panel.visible = false; get_tree().paused = false; ModeHub.get("overlay").visible = true; get_tree().paused = true)
	_add_button("SETTINGS", 262, func(): panel.visible = false; get_tree().paused = false; SettingsConsole.get("panel").visible = true; get_tree().paused = true)
	panel.visible = false

func _add_button(text: String, y: float, action: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.position = Vector2(44, y)
	button.size = Vector2(332, 44)
	button.pressed.connect(action)
	panel.add_child(button)
