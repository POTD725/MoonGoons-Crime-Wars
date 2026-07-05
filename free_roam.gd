extends Node2D
## Free Roam is not yet a playable mode. It clearly returns the player to the RTS instead of opening a silent dead end.

func _ready() -> void:
	var canvas: CanvasLayer = CanvasLayer.new()
	add_child(canvas)
	var background: ColorRect = ColorRect.new()
	background.color = Color("071021")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(background)
	var label: Label = Label.new()
	label.text = "FREE ROAM // UNDER DEVELOPMENT\nReturning to Operation Breakwater..."
	label.position = Vector2(250.0, 390.0)
	label.size = Vector2(1100.0, 80.0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", Color("8fe9ff"))
	canvas.add_child(label)
	get_tree().create_timer(3.0).timeout.connect(_return_to_main)

func _return_to_main() -> void:
	get_tree().change_scene_to_file("res://main.tscn")
