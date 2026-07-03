extends Control
## Custom battle submenu: team size, battlefield, scenario, faction, and CPU slots.

var team_size_menu: OptionButton
var map_menu: OptionButton
var scenario_menu: OptionButton
var difficulty_menu: OptionButton
var summary_label: Label
var slots_box: VBoxContainer
var slot_controls: Array[Dictionary] = []
var map_ids: Array[String] = []
var scenario_ids: Array[String] = []

func _ready() -> void:
	_build_ui()
	_populate_options()
	_rebuild_slots()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode in [KEY_ESCAPE, KEY_F2]:
			get_tree().change_scene_to_file("res://main.tscn")

func _build_ui() -> void:
	var background := ColorRect.new()
	background.color = Color("071022")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var title := Label.new()
	title.text = "CUSTOM GAME // WAR ROOM"
	title.position = Vector2(60, 28)
	title.size = Vector2(1480, 46)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", Color("c7e7ff"))
	add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Choose team size, map, scenario, every faction, and CPU roster. The moon does not care whether the brackets are fair."
	subtitle.position = Vector2(80, 76)
	subtitle.size = Vector2(1440, 28)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 15)
	subtitle.add_theme_color_override("font_color", Color("a9c2df"))
	add_child(subtitle)

	var settings := _panel(Vector2(55, 132), Vector2(475, 590), Color("4f86bd"))
	add_child(settings)
	var roster := _panel(Vector2(555, 132), Vector2(930, 590), Color("9a6d49"))
	add_child(roster)

	settings.add_child(_label("MATCH SETTINGS", Vector2(20, 16), Vector2(430, 28), 20, Color("b9dcff")))
	settings.add_child(_label("Team size", Vector2(20, 62), Vector2(180, 20), 14, Color("cddcf0")))
	team_size_menu = _option(Vector2(20, 84), Vector2(435, 36))
	team_size_menu.item_selected.connect(_on_team_size_changed)
	settings.add_child(team_size_menu)

	settings.add_child(_label("Battlefield", Vector2(20, 138), Vector2(180, 20), 14, Color("cddcf0")))
	map_menu = _option(Vector2(20, 160), Vector2(435, 36))
	map_menu.item_selected.connect(func(_index: int): _refresh_summary())
	settings.add_child(map_menu)

	settings.add_child(_label("Scenario", Vector2(20, 214), Vector2(180, 20), 14, Color("cddcf0")))
	scenario_menu = _option(Vector2(20, 236), Vector2(435, 36))
	scenario_menu.item_selected.connect(func(_index: int): _refresh_summary())
	settings.add_child(scenario_menu)

	settings.add_child(_label("Computer difficulty", Vector2(20, 290), Vector2(210, 20), 14, Color("cddcf0")))
	difficulty_menu = _option(Vector2(20, 312), Vector2(435, 36))
	for difficulty in ["Cadet", "Enforcer", "Marshal", "Nightmare"]:
		difficulty_menu.add_item(difficulty)
	difficulty_menu.select(1)
	settings.add_child(difficulty_menu)

	var randomize := Button.new()
	randomize.text = "RANDOMIZE CPU RACES"
	randomize.position = Vector2(20, 374)
	randomize.size = Vector2(210, 42)
	randomize.pressed.connect(_randomize_cpu_races)
	settings.add_child(randomize)

	var launch := Button.new()
	launch.text = "LAUNCH CUSTOM BATTLE"
	launch.position = Vector2(20, 430)
	launch.size = Vector2(435, 58)
	launch.add_theme_font_size_override("font_size", 18)
	launch.pressed.connect(_launch)
	settings.add_child(launch)

	summary_label = _label("", Vector2(20, 504), Vector2(435, 70), 13, Color("d8e8f7"))
	summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	settings.add_child(summary_label)

	roster.add_child(_label("PLAYER / CPU SLOTS", Vector2(20, 16), Vector2(850, 28), 20, Color("ffd2a0")))
	var help := _label("A1 is the local commander. Additional Human slots are reserved for LAN RTS handoff; CPU slots run automated bases in the current build.", Vector2(20, 47), Vector2(850, 38), 13, Color("c9d8e9"))
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	roster.add_child(help)

	var header := _label("SLOT                         CONTROLLER                         RACE", Vector2(28, 92), Vector2(820, 22), 13, Color("a9c3df"))
	roster.add_child(header)
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(18, 118)
	scroll.size = Vector2(890, 455)
	roster.add_child(scroll)
	slots_box = VBoxContainer.new()
	slots_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slots_box.add_theme_constant_override("separation", 7)
	scroll.add_child(slots_box)

func _populate_options() -> void:
	for size in [2, 4, 6, 8]:
		team_size_menu.add_item("%dv%d" % [size, size], size)
	team_size_menu.select(0)

	for map_id in PvpMaps.MAPS.keys():
		map_ids.append(str(map_id))
		map_menu.add_item(str(PvpMaps.MAPS[map_id]["name"]))
	var default_index := map_ids.find("prisoner_exchange")
	map_menu.select(maxi(0, default_index))

	for scenario_id in CustomMatchConfig.SCENARIOS.keys():
		scenario_ids.append(str(scenario_id))
		scenario_menu.add_item(str(CustomMatchConfig.SCENARIOS[scenario_id]["name"]))
	scenario_menu.select(0)

func _on_team_size_changed(_index: int) -> void:
	var team_size := int(team_size_menu.get_selected_id())
	var preferred := "prisoner_exchange" if team_size == 2 else ("second_siren" if team_size >= 4 else "sunspear_pass")
	var map_index := map_ids.find(preferred)
	if map_index >= 0:
		map_menu.select(map_index)
	_rebuild_slots()

func _rebuild_slots() -> void:
	for child in slots_box.get_children():
		child.queue_free()
	slot_controls.clear()
	var team_size := int(team_size_menu.get_selected_id())
	for team_index in 2:
		var team_name := "TEAM A" if team_index == 0 else "TEAM B"
		for member in team_size:
			var row := HBoxContainer.new()
			row.custom_minimum_size = Vector2(850, 36)
			slots_box.add_child(row)
			var slot_number := member + 1
			var slot_label := Label.new()
			slot_label.text = "%s-%02d" % [team_name, slot_number]
			slot_label.custom_minimum_size = Vector2(145, 36)
			slot_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			slot_label.add_theme_font_size_override("font_size", 15)
			slot_label.add_theme_color_override("font_color", Color("8fe9ff") if team_index == 0 else Color("ff9b62"))
			row.add_child(slot_label)

			var controller := OptionButton.new()
			controller.custom_minimum_size = Vector2(245, 36)
			controller.add_item("Human")
			controller.add_item("Computer")
			controller.add_item("Closed")
			if team_index == 0 and member == 0:
				controller.select(0)
			else:
				controller.select(1)
			controller.item_selected.connect(func(_selected: int): _refresh_summary())
			row.add_child(controller)

			var race := OptionButton.new()
			race.custom_minimum_size = Vector2(385, 36)
			for race_id in ["authority", "lunar_cartel", "null_choir", "hollow_fang"]:
				race.add_item(RaceCatalog.get_name(race_id))
			race.select((team_index + member) % 4)
			race.item_selected.connect(func(_selected: int): _refresh_summary())
			row.add_child(race)
			slot_controls.append({"team":"A" if team_index == 0 else "B", "index":member, "controller":controller, "race":race})
	_refresh_summary()

func _randomize_cpu_races() -> void:
	for slot in slot_controls:
		var controller: OptionButton = slot["controller"]
		if controller.get_selected() == 1:
			var race: OptionButton = slot["race"]
			race.select(randi_range(0, 3))
	_refresh_summary()

func _launch() -> void:
	var slots: Array[Dictionary] = []
	var human_count := 0
	for slot in slot_controls:
		var controller: OptionButton = slot["controller"]
		var race: OptionButton = slot["race"]
		var controller_id := ["human", "cpu", "closed"][controller.get_selected()]
		if controller_id == "human":
			human_count += 1
		slots.append({
			"team":slot["team"],
			"controller":controller_id,
			"race":["authority", "lunar_cartel", "null_choir", "hollow_fang"][race.get_selected()],
			"name":"%s-%02d" % [slot["team"], int(slot["index"]) + 1]
		})
	if human_count == 0:
		slots[0]["controller"] = "human"
	CustomMatchConfig.configure(
		int(team_size_menu.get_selected_id()),
		map_ids[map_menu.get_selected()],
		scenario_ids[scenario_menu.get_selected()],
		slots,
		difficulty_menu.get_item_text(difficulty_menu.get_selected())
	)
	PvpMaps.choose(CustomMatchConfig.map_id)
	get_tree().change_scene_to_file("res://main.tscn")

func _refresh_summary() -> void:
	if summary_label == null or map_menu == null or scenario_menu == null:
		return
	var team_size := int(team_size_menu.get_selected_id())
	var map_data := PvpMaps.get_map(map_ids[map_menu.get_selected()])
	var scenario: Dictionary = CustomMatchConfig.SCENARIOS[scenario_ids[scenario_menu.get_selected()]]
	var cpu_count := 0
	var human_count := 0
	for slot in slot_controls:
		var controller: OptionButton = slot["controller"]
		if controller.get_selected() == 0: human_count += 1
		if controller.get_selected() == 1: cpu_count += 1
	summary_label.text = "%dv%d • %s • %s\nHumans: %d  CPU: %d  •  Starting Credits: %d\n%s" % [team_size, team_size, map_data["name"], scenario["name"], human_count, cpu_count, scenario["credits"], scenario["description"]]

func _panel(position: Vector2, size: Vector2, border_color: Color) -> Panel:
	var panel := Panel.new()
	panel.position = position
	panel.size = size
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.025, 0.05, 0.12, 0.94)
	style.border_color = border_color
	style.set_border_width_all(2)
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_left = 14
	style.corner_radius_bottom_right = 14
	panel.add_theme_stylebox_override("panel", style)
	return panel

func _option(position: Vector2, size: Vector2) -> OptionButton:
	var option := OptionButton.new()
	option.position = position
	option.size = size
	return option

func _label(text: String, position: Vector2, size: Vector2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.position = position
	label.size = size
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label
