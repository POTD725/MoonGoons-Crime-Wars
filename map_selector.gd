extends Node
## F3 PvP map browser. Selecting a map reloads the current RTS faction match.

var overlay: Control
var detail: Label
var selected_id := "breakwater_split"

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	selected_id = PvpMaps.active_map_id
	_build_overlay()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F3:
		overlay.visible = not overlay.visible
		get_tree().paused = overlay.visible
		get_viewport().set_input_as_handled()

func _build_overlay() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 45
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(layer)
	overlay = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(overlay)

	var shade := ColorRect.new()
	shade.color = Color(0.005, 0.01, 0.035, 0.96)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(shade)

	var title := Label.new()
	title.text = "PVP BATTLEFIELD ARCHIVE"
	title.position = Vector2(80, 34)
	title.size = Vector2(1440, 42)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color("a8d7ff"))
	overlay.add_child(title)

	var sub := Label.new()
	sub.text = "15 maps • resource economies • terrain routes • team-size recommendations • F3 closes"
	sub.position = Vector2(80, 78)
	sub.size = Vector2(1440, 24)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 14)
	sub.add_theme_color_override("font_color", Color("c3d5e9"))
	overlay.add_child(sub)

	var scroll := ScrollContainer.new()
	scroll.position = Vector2(65, 125)
	scroll.size = Vector2(1020, 650)
	overlay.add_child(scroll)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(grid)

	for map_id in PvpMaps.MAPS.keys():
		var data: Dictionary = PvpMaps.MAPS[map_id]
		var button := Button.new()
		button.custom_minimum_size = Vector2(315, 132)
		button.text = "%s\n%s  •  %s resources  •  %s\n%s" % [data["name"], data["players"], data["resources"], data["pace"], data["terrain"]]
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.add_theme_font_size_override("font_size", 14)
		button.tooltip_text = str(data["feature"])
		button.pressed.connect(_select_map.bind(map_id))
		grid.add_child(button)

	var info_panel := Panel.new()
	info_panel.position = Vector2(1110, 155)
	info_panel.size = Vector2(410, 470)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.07, 0.15, 0.94)
	style.border_color = Color("6aa8dc")
	style.set_border_width_all(2)
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_left = 14
	style.corner_radius_bottom_right = 14
	info_panel.add_theme_stylebox_override("panel", style)
	overlay.add_child(info_panel)

	var info_title := Label.new()
	info_title.text = "MAP BRIEFING"
	info_title.position = Vector2(16, 16)
	info_title.size = Vector2(375, 26)
	info_title.add_theme_font_size_override("font_size", 18)
	info_title.add_theme_color_override("font_color", Color("a8d7ff"))
	info_panel.add_child(info_title)
	detail = Label.new()
	detail.position = Vector2(16, 52)
	detail.size = Vector2(375, 300)
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.add_theme_font_size_override("font_size", 15)
	detail.add_theme_color_override("font_color", Color("e6f2ff"))
	info_panel.add_child(detail)

	var launch := Button.new()
	launch.text = "LOAD SELECTED BATTLEFIELD"
	launch.position = Vector2(16, 375)
	launch.size = Vector2(375, 52)
	launch.pressed.connect(_load_selected)
	info_panel.add_child(launch)

	_refresh_detail()
	overlay.visible = false

func _select_map(map_id: String) -> void:
	selected_id = map_id
	_refresh_detail()

func _refresh_detail() -> void:
	var data := PvpMaps.get_map(selected_id)
	detail.text = "%s\n\nRECOMMENDED: %s\nTERRAIN: %s\nPACE: %s\nRESOURCES: %s\n\n%s\n\nSpawn slots: %d\nResource deposits: %d" % [data["name"], data["players"], data["terrain"], data["pace"], data["resources"], data["feature"], data["spawns"].size(), data["nodes"].size()]

func _load_selected() -> void:
	PvpMaps.choose(selected_id)
	var game := get_tree().current_scene
	if game != null and game.has_method("_spawn_unit") and not RaceMode.chosen_race.is_empty():
		RaceMode._reset_mission(RaceMode.chosen_race, RaceMode.chosen_rival)
		game.call("flash", "BATTLEFIELD LOADED // " + str(PvpMaps.get_active()["name"]), 5.0)
	overlay.visible = false
	get_tree().paused = false
