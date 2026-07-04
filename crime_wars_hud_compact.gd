extends "res://crime_wars_hud.gd"
## Keeps the extended four-resource / Command Capacity readout inside the top command bar.

func _ready() -> void:
	super._ready()
	if resource_line != null:
		resource_line.position = Vector2(385.0, 20.0)
		resource_line.size = Vector2(745.0, 22.0)
		resource_line.add_theme_font_size_override("font_size", 12)
