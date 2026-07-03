extends Node

var canvas: CanvasLayer
var line: Label
var details: Label

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	canvas = CanvasLayer.new()
	canvas.layer = 42
	canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(canvas)
	var root: Control = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(root)
	var bar: ColorRect = ColorRect.new()
	bar.position = Vector2(0, 0)
	bar.size = Vector2(1600, 64)
	bar.color = Color("071a30")
	root.add_child(bar)
	line = Label.new()
	line.position = Vector2(22, 15)
	line.size = Vector2(1550, 32)
	line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	line.add_theme_font_size_override("font_size", 19)
	line.add_theme_color_override("font_color", Color("8fe9ff"))
	root.add_child(line)
	details = Label.new()
	details.position = Vector2(20, 700)
	details.size = Vector2(1120, 150)
	details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details.add_theme_font_size_override("font_size", 16)
	details.add_theme_color_override("font_color", Color("eaf5ff"))
	root.add_child(details)

func _process(_delta: float) -> void:
	var game: Node = get_tree().current_scene
	if game == null or not game.has_method("_entity"):
		canvas.visible = false
		return
	canvas.visible = true
	line.text = "MOONGOONS COMMAND DECK     CREDITS %04d     SUPPLIES %03d     INTEL %03d     %s" % [int(game.get("credits")), int(game.get("supplies")), int(game.get("intel")), str(game.get("note"))]
	var ids: Array = game.get("selected")
	if int(game.get("selected_building")) != -1:
		var building: Dictionary = game.call("_entity", int(game.get("selected_building")))
		details.text = _describe(building)
	elif ids.size() == 1:
		details.text = _describe(game.call("_entity", int(ids[0])))
	else:
		details.text = "1 Armory  2 Relay  3 Medbay  4 Drone Bay  5 Cells\nQ Deputy  E Drone  R Shield\nF2 Hub  F4 Difficulty  F7 Roster  F8 Chat  F9 Dev"

func _describe(entity: Dictionary) -> String:
	if entity.is_empty():
		return "NO SELECTION"
	var hp: float = float(entity.get("hp", 0.0))
	var maximum: float = maxf(1.0, float(entity.get("max", 1.0)))
	return "%s // %d%% integrity" % [str(entity.get("name", "Unknown")).to_upper(), int(round(hp / maximum * 100.0))]
