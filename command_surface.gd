extends "res://industry_control.gd"
## Visual polish for the support console so every option reads as a real clickable control.

func _ready() -> void:
	super._ready()
	if industry_panel != null:
		industry_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if rally_button != null:
		_apply_button_skin(rally_button, Color("39295f"), Color("d9c4ff"))

func _add_industry_button(text_value: String, position_value: Vector2, action: Callable) -> void:
	var button: Button = Button.new()
	button.text = text_value
	button.position = position_value
	button.size = Vector2(184.0, 30.0)
	button.tooltip_text = "Click to issue this command"
	button.add_theme_font_size_override("font_size", 11)
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	_apply_button_skin(button, Color("202744"), Color("8fe9ff"))
	button.pressed.connect(action)
	industry_panel.add_child(button)

func _apply_button_skin(button: Button, background: Color, border: Color) -> void:
	button.add_theme_stylebox_override("normal", _button_style(background, border, 6))
	button.add_theme_stylebox_override("hover", _button_style(background.lightened(0.18), Color("ffffff"), 6))
	button.add_theme_stylebox_override("pressed", _button_style(background.darkened(0.16), Color("ffd16a"), 6))
	button.add_theme_color_override("font_color", Color("eaf6ff"))

func _button_style(background: Color, border: Color, radius: int) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(2)
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.content_margin_left = 4.0
	style.content_margin_right = 4.0
	style.content_margin_top = 2.0
	style.content_margin_bottom = 2.0
	return style
