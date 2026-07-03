extends "res://race_runtime.gd"
## Visual faction selector, passive economy, and compatibility hooks.

var picker: Control
var status_label: Label

func _show_picker() -> void:
	if root == null:
		return
	root.set_meta("race_selecting", true)
	get_tree().paused = true
	picker.visible = true
	status_label.text = "SELECT A FACTION  //  F1 REOPENS THIS SCREEN DURING TESTING"

func _hide_picker() -> void:
	picker.visible = false

func _apply_passive_income() -> void:
	if root == null or chosen_race.is_empty():
		return
	var finished_structures := 0
	for building in root.get("buildings"):
		if building.get("team", "") == PLAYER_TEAM and building.get("race", "") == chosen_race and bool(building.get("done", false)):
			finished_structures += 1
	var multiplier := max(1, finished_structures)
	var gains := RaceCatalog.get_passive(chosen_race)
	if gains.has("credits"):
		root.set("credits", int(root.get("credits")) + int(gains["credits"]) * multiplier)
	if gains.has("supplies"):
		root.set("supplies", int(root.get("supplies")) + int(gains["supplies"]) * multiplier)
	if gains.has("intel"):
		root.set("intel", int(root.get("intel")) + int(gains["intel"]) * multiplier)

func _install_visual_layer() -> void:
	var layer := root.get_node_or_null("RaceVisuals")
	if layer == null:
		var visual_script := load("res://race_visuals.gd")
		layer = visual_script.new()
		layer.name = "RaceVisuals"
		root.add_child(layer)
	layer.set("mission_root", root)

func _start_faction_briefing(race_id: String, rival_id: String) -> void:
	var director := get_node_or_null("/root/CutsceneDirector")
	if director == null:
		return
	if bool(director.get("is_playing")):
		director.call("_end_sequence")
	var player_name := str(RaceCatalog.RACES[race_id]["hero"])
	var rival_name := str(RaceCatalog.RACES[rival_id]["hero"])
	var lines := [
		{"name":player_name, "faction":RaceCatalog.get_name(race_id), "side":"authority", "text":player_name + " enters Breakwater. " + RaceCatalog.get_construction(race_id)},
		{"name":rival_name, "faction":RaceCatalog.get_name(rival_id), "side":"syndicate", "text":rival_name + ": a side has been chosen. The moon will remember the cost."}
	]
	director.call("_play_sequence", lines, "res://audio/mission_deploy.wav")

func _build_picker() -> void:
	var canvas := CanvasLayer.new()
	canvas.layer = 35
	canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(canvas)
	picker = Control.new()
	picker.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	picker.mouse_filter = Control.MOUSE_FILTER_STOP
	canvas.add_child(picker)

	var backdrop := ColorRect.new()
	backdrop.color = Color(0.008, 0.012, 0.035, 0.96)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	picker.add_child(backdrop)

	var title := Label.new()
	title.text = "MOONGOONS: CRIME WARS"
	title.position = Vector2(80, 54)
	title.size = Vector2(1440, 48)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 38)
	title.add_theme_color_override("font_color", Color("ecf4ff"))
	picker.add_child(title)

	status_label = Label.new()
	status_label.position = Vector2(80, 112)
	status_label.size = Vector2(1440, 28)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 15)
	status_label.add_theme_color_override("font_color", Color("a8c7ef"))
	picker.add_child(status_label)

	var race_ids := ["authority", "lunar_cartel", "null_choir", "hollow_fang"]
	for index in race_ids.size():
		var race_id: String = race_ids[index]
		var race: Dictionary = RaceCatalog.RACES[race_id]
		var card := Button.new()
		card.position = Vector2(85 + index * 380, 185)
		card.size = Vector2(330, 440)
		card.text = "%s\n\n%s\n\n%s\n\nBUILD METHOD\n%s\n\nHERO // %s\n\nCLICK TO DEPLOY" % [race["name"], race["subtitle"], race["style"], race["construction"], race["hero"]]
		card.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		card.alignment = HORIZONTAL_ALIGNMENT_CENTER
		card.add_theme_font_size_override("font_size", 15)
		card.add_theme_color_override("font_color", Color("f2f7ff"))
		var style := StyleBoxFlat.new()
		style.bg_color = Color(str(race["accent"])).darkened(0.72)
		style.border_color = Color(str(race["accent"]))
		style.set_border_width_all(3)
		style.corner_radius_top_left = 16
		style.corner_radius_top_right = 16
		style.corner_radius_bottom_left = 16
		style.corner_radius_bottom_right = 16
		card.add_theme_stylebox_override("normal", style)
		card.pressed.connect(_choose.bind(race_id))
		picker.add_child(card)

	var footer := Label.new()
	footer.text = "THE AUTHORITY BUILDS ORDER.  THE CARTEL BUILDS OPPORTUNITY.  THE CHOIR GROWS SIGNAL.  THE FANG BUILDS WAR."
	footer.position = Vector2(80, 670)
	footer.size = Vector2(1440, 28)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.add_theme_font_size_override("font_size", 14)
	footer.add_theme_color_override("font_color", Color("c4d4e9"))
	picker.add_child(footer)
	picker.visible = false
