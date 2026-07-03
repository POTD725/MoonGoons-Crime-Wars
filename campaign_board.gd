extends Node
## F5 campaign board. CW-001 is the first fully playable campaign slice.

var canvas: CanvasLayer
var panel: Control

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F5:
		panel.visible = not panel.visible
		get_tree().paused = panel.visible
		get_viewport().set_input_as_handled()

func _build() -> void:
	canvas = CanvasLayer.new()
	canvas.layer = 59
	canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(canvas)
	panel = Control.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	canvas.add_child(panel)
	var shade := ColorRect.new()
	shade.color = Color(0.005, 0.012, 0.035, 0.97)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.add_child(shade)
	var title := Label.new()
	title.text = "CAMPAIGN BOARD // THE BROKEN DOCKS"
	title.position = Vector2(160, 65)
	title.size = Vector2(1280, 42)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color("8fe9ff"))
	panel.add_child(title)
	var mission := CampaignData.get_mission("CW-001")
	var card := Button.new()
	card.position = Vector2(260, 160)
	card.size = Vector2(1080, 360)
	var state := "COMPLETED" if GameProfile.is_complete("CW-001") else "AVAILABLE"
	card.text = "%s // %s\n\n%s\n\nOBJECTIVE: %s\n\nREWARD: %s\n\nSTATUS: %s\n\nCLICK TO DEPLOY" % [mission["id"], mission["title"], mission["brief"], mission["authority"], mission["reward"], state]
	card.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card.alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_theme_font_size_override("font_size", 18)
	card.pressed.connect(_launch)
	panel.add_child(card)
	var next := Label.new()
	next.text = "CW-002 through CW-012 are mapped in the campaign library and remain locked until their missions receive unique playable objectives. Free Roam is available now as the next exploration layer."
	next.position = Vector2(300, 560)
	next.size = Vector2(1000, 70)
	next.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	next.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	next.add_theme_font_size_override("font_size", 15)
	next.add_theme_color_override("font_color", Color("c6d8e9"))
	panel.add_child(next)
	var close := Button.new()
	close.text = "RETURN"
	close.position = Vector2(620, 700)
	close.size = Vector2(360, 48)
	close.pressed.connect(func(): panel.visible = false; get_tree().paused = false)
	panel.add_child(close)
	panel.visible = false

func _launch() -> void:
	panel.visible = false
	get_tree().paused = false
	get_tree().change_scene_to_file("res://main.tscn")
