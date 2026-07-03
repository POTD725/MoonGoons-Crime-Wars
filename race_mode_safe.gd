extends "res://race_runtime.gd"

var picker: Control
var status_label: Label
var custom_launch_queued: bool = false

func _show_picker() -> void:
	if root == null:
		return
	if CustomMatchConfig.is_pending():
		if not custom_launch_queued:
			custom_launch_queued = true
			call_deferred("_launch_custom_match")
		return
	root.set_meta("race_selecting", true)
	get_tree().paused = true
	picker.visible = true
	status_label.text = "SELECT A FACTION"

func _hide_picker() -> void:
	picker.visible = false

func _apply_passive_income() -> void:
	if root == null or chosen_race.is_empty():
		return
	var count: int = 0
	for building: Dictionary in root.get("buildings"):
		if building.get("team", "") == PLAYER_TEAM and building.get("race", "") == chosen_race and bool(building.get("done", false)):
			count += 1
	var gains: Dictionary = RaceCatalog.get_passive(chosen_race)
	var multiplier: int = maxi(1, count)
	for key: String in ["credits", "supplies", "intel"]:
		if gains.has(key):
			root.set(key, int(root.get(key)) + int(gains[key]) * multiplier)

func _install_visual_layer() -> void:
	if root == null:
		return
	var layer: Node = root.get_node_or_null("RaceVisuals")
	if layer == null:
		var script: Script = load("res://race_visuals.gd")
		if script == null:
			return
		layer = script.new()
		layer.name = "RaceVisuals"
		root.add_child(layer)
	layer.set("mission_root", root)

func _start_faction_briefing(_race_id: String, _rival_id: String) -> void:
	pass

func _launch_custom_match() -> void:
	custom_launch_queued = false
	if root == null or not CustomMatchConfig.consume():
		return
	chosen_race = CustomMatchConfig.local_race
	chosen_rival = RaceCatalog.get_rival(chosen_race)
	picker.visible = false
	get_tree().paused = false
	CustomMatchRuntime.launch(root)
	_install_visual_layer()

func _build_picker() -> void:
	var canvas: CanvasLayer = CanvasLayer.new()
	canvas.layer = 35
	canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(canvas)
	picker = Control.new()
	picker.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	picker.mouse_filter = Control.MOUSE_FILTER_STOP
	canvas.add_child(picker)
	var backdrop: ColorRect = ColorRect.new()
	backdrop.color = Color(0.008, 0.012, 0.035, 0.96)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	picker.add_child(backdrop)
	var title: Label = Label.new()
	title.text = "MOONGOONS: CRIME WARS"
	title.position = Vector2(80, 54)
	title.size = Vector2(1440, 48)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 38)
	picker.add_child(title)
	status_label = Label.new()
	status_label.position = Vector2(80, 112)
	status_label.size = Vector2(1440, 28)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	picker.add_child(status_label)
	var ids: Array[String] = ["authority", "lunar_cartel", "null_choir", "hollow_fang"]
	for index: int in ids.size():
		var race_id: String = ids[index]
		var data: Dictionary = RaceCatalog.RACES[race_id]
		var card: Button = Button.new()
		card.position = Vector2(85 + index * 380, 185)
		card.size = Vector2(330, 440)
		card.text = "%s\n\n%s\n\n%s\n\nHERO // %s\n\nCLICK TO DEPLOY" % [str(data["name"]), str(data["style"]), str(data["construction"]), str(data["hero"])]
		card.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		card.add_theme_font_size_override("font_size", 15)
		card.pressed.connect(_choose.bind(race_id))
		picker.add_child(card)
	picker.visible = false
