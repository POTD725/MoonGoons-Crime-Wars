extends "res://faction_controller_match.gd"
## Three-force faction picker: Lunar Peacekeepers, The Syndicate, and The Nullborn.
## The Custom Game War Room is intentionally visible on this first screen.

func _build_picker() -> void:
	var canvas: CanvasLayer = CanvasLayer.new()
	canvas.layer = 35
	canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(canvas)
	picker = Control.new()
	picker.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	picker.mouse_filter = Control.MOUSE_FILTER_STOP
	canvas.add_child(picker)

	var shade: ColorRect = ColorRect.new()
	shade.color = Color(0.004, 0.010, 0.030, 0.98)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	picker.add_child(shade)

	var title: Label = Label.new()
	title.text = "MOONGOONS: CRIME WARS"
	title.position = Vector2(80.0, 28.0)
	title.size = Vector2(1440.0, 44.0)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", Color("eaf5ff"))
	picker.add_child(title)

	var subtitle: Label = Label.new()
	subtitle.text = "CHOOSE A MAJOR FORCE // PEACEKEEPERS, SYNDICATE, OR NULLBORN"
	subtitle.position = Vector2(80.0, 75.0)
	subtitle.size = Vector2(1440.0, 26.0)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 16)
	subtitle.add_theme_color_override("font_color", Color("9ec6ed"))
	picker.add_child(subtitle)

	var hint: Label = Label.new()
	hint.text = "Campaign: click a force to deploy.  Custom Game: open the War Room below to choose a map, CPU force, difficulty, and scenario."
	hint.position = Vector2(80.0, 102.0)
	hint.size = Vector2(1440.0, 22.0)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 13)
	hint.add_theme_color_override("font_color", Color("b8cadf"))
	picker.add_child(hint)

	var ids: Array[String] = ["authority", "lunar_cartel", "null_choir"]
	for index in range(ids.size()):
		_add_three_force_card(ids[index], index)
	_build_detail_panel()
	_add_custom_game_button()
	_show_detail("authority")
	picker.visible = false

func _add_custom_game_button() -> void:
	var button: Button = Button.new()
	button.text = "OPEN CUSTOM GAME WAR ROOM"
	button.position = Vector2(525.0, 850.0)
	button.size = Vector2(550.0, 38.0)
	button.tooltip_text = "Choose a battlefield, CPU force, difficulty, bot count, and scenario."
	button.add_theme_font_size_override("font_size", 15)
	button.add_theme_color_override("font_color", Color("eaf5ff"))
	button.add_theme_stylebox_override("normal", _card_style(Color("efc75e"), 0.20, 2))
	button.add_theme_stylebox_override("hover", _card_style(Color("ffdc77"), 0.34, 3))
	button.add_theme_stylebox_override("pressed", _card_style(Color("ffdc77"), 0.44, 4))
	button.pressed.connect(_open_custom_game)
	picker.add_child(button)

func _open_custom_game() -> void:
	if MatchState != null:
		MatchState.clear_custom_match()
	picker_resolved = false
	picker.visible = false
	get_tree().paused = false
	get_tree().change_scene_to_file("res://custom_game.tscn")

func _choose(race_id: String) -> void:
	if MatchState != null:
		MatchState.clear_custom_match()
	super._choose(race_id)

func _add_three_force_card(race_id: String, index: int) -> void:
	var data: Dictionary = RaceCatalog.RACES[race_id] as Dictionary
	var accent: Color = Color(str(data.get("accent", "#8fe9ff")))
	var card: Button = Button.new()
	card.position = Vector2(190.0 + float(index) * 410.0, 150.0)
	card.size = Vector2(390.0, 500.0)
	card.tooltip_text = _tooltip_for(race_id)
	card.add_theme_stylebox_override("normal", _card_style(accent, 0.14, 2))
	card.add_theme_stylebox_override("hover", _card_style(accent, 0.27, 4))
	card.add_theme_stylebox_override("pressed", _card_style(accent, 0.34, 5))
	card.pressed.connect(_choose.bind(race_id))
	card.mouse_entered.connect(_show_detail.bind(race_id))
	card.focus_entered.connect(_show_detail.bind(race_id))
	picker.add_child(card)

	var name_label: Label = Label.new()
	name_label.text = str(data.get("name", race_id)).to_upper()
	name_label.position = Vector2(14.0, 13.0)
	name_label.size = Vector2(362.0, 30.0)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.add_theme_color_override("font_color", accent.lightened(0.22))
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(name_label)

	var motto_label: Label = Label.new()
	motto_label.text = str(data.get("subtitle", ""))
	motto_label.position = Vector2(16.0, 46.0)
	motto_label.size = Vector2(358.0, 38.0)
	motto_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	motto_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	motto_label.add_theme_font_size_override("font_size", 13)
	motto_label.add_theme_color_override("font_color", Color("d6e6f5"))
	motto_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(motto_label)

	var art: Control = CARD_ART.new()
	art.position = Vector2(30.0, 98.0)
	art.size = Vector2(330.0, 198.0)
	art.call("configure", race_id, accent)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(art)

	var commander_label: Label = Label.new()
	commander_label.text = "COMMANDER // " + str(data.get("hero", "Unknown"))
	commander_label.position = Vector2(16.0, 308.0)
	commander_label.size = Vector2(358.0, 24.0)
	commander_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	commander_label.add_theme_font_size_override("font_size", 14)
	commander_label.add_theme_color_override("font_color", Color("f4fbff"))
	commander_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(commander_label)

	var method_label: Label = Label.new()
	method_label.text = "BUILD METHOD\n" + str(data.get("construction", ""))
	method_label.position = Vector2(26.0, 345.0)
	method_label.size = Vector2(338.0, 82.0)
	method_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	method_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	method_label.add_theme_font_size_override("font_size", 12)
	method_label.add_theme_color_override("font_color", Color("bbcee1"))
	method_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(method_label)

	var deploy_label: Label = Label.new()
	deploy_label.text = "HOVER FOR DETAILS  •  CLICK TO DEPLOY"
	deploy_label.position = Vector2(18.0, 454.0)
	deploy_label.size = Vector2(354.0, 25.0)
	deploy_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	deploy_label.add_theme_font_size_override("font_size", 12)
	deploy_label.add_theme_color_override("font_color", accent)
	deploy_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(deploy_label)

func _detail_for(race_id: String) -> String:
	match race_id:
		"authority":
			return "LUNAR PEACEKEEPERS // Balanced squads, strong security zones, repairs, arrests, investigation tools, and late-game orbital support. Their economy favors stable territory and coordinated response."
		"lunar_cartel":
			return "THE SYNDICATE // Fast raids, ambushes, sabotage, hacking, theft, hidden operations, and black-market upgrades. Their economy thrives on disruption and illicit logistics."
		"null_choir":
			return "THE NULLBORN // Corrupted territory, unstable energy weapons, infected infrastructure, environmental pressure, and escalating mutations. The longer a battle drags on, the stranger it gets."
		_:
			return "Choose a major force to review its command profile."
