extends Node
## MoonGoons Command Deck HUD with build, defense, and selected-producer controls.

var canvas: CanvasLayer
var root: Control
var game: Node
var resource_line: Label
var notice_line: Label
var dossier_title: Label
var dossier_body: Label
var objective_line: Label
var status_line: Label
var production_label: Label
var production_primary: Button
var production_secondary: Button

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_hud()

func _process(_delta: float) -> void:
	var current_scene: Node = get_tree().current_scene
	if current_scene == null or not current_scene.has_method("_entity") or not current_scene.has_method("_begin_build"):
		canvas.visible = false
		game = null
		return
	game = current_scene
	canvas.visible = true
	_refresh()

func _build_hud() -> void:
	canvas = CanvasLayer.new()
	canvas.layer = 42
	canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(canvas)
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(root)

	var top_bar: Panel = _panel(Rect2(0.0, 0.0, 1600.0, 70.0), Color("07172d"), Color("5fbfff"), 2)
	root.add_child(top_bar)
	var title: Label = _label("MOONGOONS // COMMAND DECK", Rect2(22.0, 16.0, 380.0, 28.0), 19, Color("8fe9ff"))
	top_bar.add_child(title)
	resource_line = _label("", Rect2(400.0, 17.0, 720.0, 28.0), 18, Color("ecf7ff"))
	resource_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top_bar.add_child(resource_line)
	notice_line = _label("", Rect2(1135.0, 10.0, 440.0, 50.0), 12, Color("ffc46b"))
	notice_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	notice_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	top_bar.add_child(notice_line)

	var objective_panel: Panel = _panel(Rect2(18.0, 92.0, 405.0, 100.0), Color("08182e"), Color("8fe9ff"), 2)
	root.add_child(objective_panel)
	var objective_title: Label = _label("OPERATION BREAKWATER // CW-001", Rect2(14.0, 12.0, 377.0, 20.0), 14, Color("8fe9ff"))
	objective_panel.add_child(objective_title)
	objective_line = _label("", Rect2(14.0, 39.0, 377.0, 53.0), 13, Color("eaf5ff"))
	objective_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	objective_panel.add_child(objective_line)

	var deck: Panel = _panel(Rect2(0.0, 650.0, 1600.0, 250.0), Color("071326"), Color("31567d"), 2)
	root.add_child(deck)
	_build_dossier(deck)
	_build_command_panel(deck)
	_build_help_panel(deck)

func _build_dossier(deck: Panel) -> void:
	var dossier: Panel = _panel(Rect2(18.0, 14.0, 430.0, 218.0), Color("0c2038"), Color("6ecbff"), 2)
	deck.add_child(dossier)
	dossier_title = _label("NO ACTIVE DOSSIER", Rect2(16.0, 15.0, 400.0, 27.0), 18, Color("8fe9ff"))
	dossier.add_child(dossier_title)
	dossier_body = _label("Select a unit or building to inspect its integrity and orders.", Rect2(16.0, 51.0, 400.0, 74.0), 14, Color("d7eaff"))
	dossier_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dossier.add_child(dossier_body)
	production_label = _label("", Rect2(16.0, 126.0, 400.0, 18.0), 12, Color("ffd16a"))
	production_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	production_label.visible = false
	dossier.add_child(production_label)
	production_primary = _production_button(Vector2(16.0, 148.0))
	production_primary.pressed.connect(_train_from_primary)
	production_primary.visible = false
	dossier.add_child(production_primary)
	production_secondary = _production_button(Vector2(210.0, 148.0))
	production_secondary.pressed.connect(_train_from_secondary)
	production_secondary.visible = false
	dossier.add_child(production_secondary)
	status_line = _label("COMMAND STATUS // READY", Rect2(16.0, 194.0, 400.0, 16.0), 12, Color("a4c9e9"))
	dossier.add_child(status_line)

func _build_command_panel(deck: Panel) -> void:
	var command_panel: Panel = _panel(Rect2(468.0, 14.0, 706.0, 218.0), Color("0b1c31"), Color("536f92"), 2)
	deck.add_child(command_panel)
	var command_title: Label = _label("TACTICAL COMMANDS // BUILD, DEFEND, PRODUCE", Rect2(14.0, 12.0, 675.0, 20.0), 14, Color("b9d9f7"))
	command_panel.add_child(command_title)

	_add_compact_button(command_panel, "ARMORY\n[1]", "Build Tactical Armory", Vector2(14.0, 42.0), _begin_build.bind("armory"), Color("1b3658"), Color("6fa8dc"))
	_add_compact_button(command_panel, "RELAY\n[2]", "Build Power Relay", Vector2(124.0, 42.0), _begin_build.bind("relay"), Color("1b3658"), Color("6fa8dc"))
	_add_compact_button(command_panel, "MEDBAY\n[3]", "Build Field Medbay", Vector2(234.0, 42.0), _begin_build.bind("medbay"), Color("1b3658"), Color("6fa8dc"))
	_add_compact_button(command_panel, "DRONE BAY\n[4]", "Build Drone Bay", Vector2(344.0, 42.0), _begin_build.bind("bay"), Color("1b3658"), Color("6fa8dc"))
	_add_compact_button(command_panel, "CELLS\n[5]", "Build Containment Block", Vector2(454.0, 42.0), _begin_build.bind("cells"), Color("1b3658"), Color("6fa8dc"))
	_add_compact_button(command_panel, "RALLY\n[Y]", "Set selected producer rally point", Vector2(564.0, 42.0), _begin_rally_mode, Color("2a2350"), Color("d9c4ff"))

	_add_compact_button(command_panel, "TURRET\n[6]", "Build Sentry Turret", Vector2(14.0, 98.0), _begin_build.bind("sentry_turret"), Color("173c50"), Color("78d8ff"))
	_add_compact_button(command_panel, "PULSE CANNON\n[7]", "Build Pulse Cannon", Vector2(124.0, 98.0), _begin_build.bind("pulse_cannon"), Color("4a3422"), Color("ffc46b"))
	_add_compact_button(command_panel, "MACHINE SHOP\n[8]", "Build Machine Shop", Vector2(234.0, 98.0), _begin_build.bind("machine_shop"), Color("332754"), Color("b9a4ff"))
	_add_compact_button(command_panel, "HEAL\n[M]", "Move selected troops to a completed Medbay", Vector2(344.0, 98.0), _send_to_medbay, Color("164449"), Color("72f2bd"))
	_add_compact_button(command_panel, "HOME\n[Space]", "Center camera on Command Nexus", Vector2(454.0, 98.0), _home_camera, Color("253348"), Color("a4c9e9"))
	_add_compact_button(command_panel, "CANCEL\n[Esc]", "Cancel build or rally mode", Vector2(564.0, 98.0), _cancel_active_mode, Color("3d2735"), Color("ff9bb3"))

	_add_compact_button(command_panel, "DEPUTY\n[Q]", "Train Patrol Deputy from Nexus", Vector2(14.0, 154.0), _train.bind("deputy"), Color("233b68"), Color("9cb6ff"))
	_add_compact_button(command_panel, "DRONE\n[E]", "Train Builder Drone from Nexus", Vector2(124.0, 154.0), _train.bind("drone"), Color("174452"), Color("8deaff"))
	_add_compact_button(command_panel, "SHIELD\n[R]", "Train Shield Deputy from Armory", Vector2(234.0, 154.0), _train.bind("shield"), Color("3e285b"), Color("d9a2ff"))
	_add_compact_button(command_panel, "ROVER\n[T]", "Train Bulwark Rover from Machine Shop", Vector2(344.0, 154.0), _train.bind("bulwark_rover"), Color("382e55"), Color("d9c4ff"))
	_add_compact_button(command_panel, "ATTACK\n[A]", "Arm attack-move", Vector2(454.0, 154.0), _attack_move, Color("4e2933"), Color("ff9aa9"))
	_add_compact_button(command_panel, "HOLD\n[H]", "Hold selected position", Vector2(564.0, 154.0), _hold_position, Color("3a424c"), Color("d7eaff"))

func _build_help_panel(deck: Panel) -> void:
	var help_panel: Panel = _panel(Rect2(1192.0, 14.0, 388.0, 218.0), Color("07152a"), Color("efc75e"), 2)
	deck.add_child(help_panel)
	var help_title: Label = _label("FIELD CONTROLS", Rect2(16.0, 15.0, 356.0, 22.0), 16, Color("efc75e"))
	help_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	help_panel.add_child(help_title)
	var help_text: Label = _label("LEFT-DRAG  Select squad or building\nRIGHT-CLICK  Move, attack, harvest, build, repair\nMIDDLE-DRAG  Pan camera\nW A S D / EDGE  Move camera\nWHEEL  Zoom\nY  Set selected producer rally\nP  Patrol mode\nF2  Pause and War Room", Rect2(24.0, 49.0, 338.0, 150.0), 13, Color("d7eaff"))
	help_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	help_panel.add_child(help_text)

func _refresh() -> void:
	resource_line.text = "CREDITS  %04d     SUPPLIES  %03d     INTEL  %03d" % [int(game.get("credits")), int(game.get("supplies")), int(game.get("intel"))]
	notice_line.text = str(game.get("note"))
	objective_line.text = _objective_text()
	_refresh_dossier()

func _objective_text() -> String:
	if bool(game.get("finished")):
		return "Operation concluded. Press R to restart the mission."
	var armory_ready: bool = false
	for building: Dictionary in game.get("buildings") as Array:
		if str(building.get("team", "")) == "authority" and str(building.get("kind", "")) == "armory" and bool(building.get("done", false)):
			armory_ready = true
	if not armory_ready:
		return "Build defenses, gather resources, and finish a Tactical Armory to unlock Shield Deputies."
	return "Armory online. Build defenses, train a force, and eliminate the Syndicate Relay."

func _refresh_dossier() -> void:
	var entity: Dictionary = {}
	if int(game.get("selected_building")) != -1:
		entity = game.call("_entity", int(game.get("selected_building"))) as Dictionary
	else:
		var selected_ids: Array = game.get("selected") as Array
		if selected_ids.size() == 1:
			entity = game.call("_entity", int(selected_ids[0])) as Dictionary
	if entity.is_empty():
		dossier_title.text = "NO ACTIVE DOSSIER"
		dossier_body.text = "Select a Builder Drone to build, harvest, or repair. Select Nexus, Armory, or Machine Shop to view its production options."
		status_line.text = "COMMAND STATUS // READY"
		_clear_production()
		return
	var hp: float = float(entity.get("hp", 0.0))
	var maximum: float = maxf(1.0, float(entity.get("max", 1.0)))
	var integrity: int = int(round(hp / maximum * 100.0))
	var classification: String = "STRUCTURE" if entity.has("size") else "UNIT"
	dossier_title.text = str(entity.get("name", "Unknown")).to_upper() + " // " + classification
	dossier_body.text = "INTEGRITY: %d%%\nTEAM: %s\nROLE: %s\nORDER: %s" % [integrity, str(entity.get("team", "authority")).to_upper(), _role_for(entity), str(entity.get("order", "ONLINE")).to_upper()]
	status_line.text = "COMMAND STATUS // " + classification
	_refresh_production_for(entity)

func _refresh_production_for(entity: Dictionary) -> void:
	_clear_production()
	if not entity.has("size") or str(entity.get("team", "")) != "authority" or not bool(entity.get("done", false)):
		return
	match str(entity.get("kind", "")):
		"nexus":
			_show_production("COMMAND NEXUS PRODUCTION", "DEPUTY\n85 CREDITS [Q]", "deputy", "DRONE\n65 CREDITS [E]", "drone")
		"armory":
			_show_production("TACTICAL ARMORY PRODUCTION", "SHIELD DEPUTY\n145 CREDITS [R]", "shield", "", "")
		"machine_shop":
			_show_production("MACHINE SHOP PRODUCTION", "BULWARK ROVER\n255 CREDITS [T]", "bulwark_rover", "", "")

func _show_production(caption: String, primary_text: String, primary_kind: String, secondary_text: String, secondary_kind: String) -> void:
	production_label.text = caption
	production_label.visible = true
	production_primary.text = primary_text
	production_primary.set_meta("unit_kind", primary_kind)
	production_primary.visible = not primary_kind.is_empty()
	production_secondary.text = secondary_text
	production_secondary.set_meta("unit_kind", secondary_kind)
	production_secondary.visible = not secondary_kind.is_empty()

func _clear_production() -> void:
	production_label.visible = false
	production_primary.visible = false
	production_secondary.visible = false

func _role_for(entity: Dictionary) -> String:
	match str(entity.get("kind", "")):
		"drone": return "Builder, repair crew, and resource courier"
		"deputy": return "Ranged police infantry"
		"shield": return "Heavy close defense and breach control"
		"bulwark_rover": return "Armored heavy vehicle"
		"hero": return "Command leader and heavy support"
		"raider": return "Fast Cartel attacker"
		"hacker": return "Long-range disruption unit"
		"nexus": return "Command and Deputy/Drone production"
		"armory": return "Shield Deputy production"
		"machine_shop": return "Bulwark Rover production"
		"sentry_turret": return "Automatic perimeter defense"
		"pulse_cannon": return "Long-range heavy ground defense"
		"relay": return "Power and map presence"
		"medbay": return "Nearby unit recovery"
		"bay": return "Drone logistics"
		"cells": return "Containment support"
		"syndicate_relay": return "Primary hostile objective"
		_: return "Lunar operations asset"

func _begin_build(kind: String) -> void:
	if game == null:
		return
	var support: Node = get_node_or_null("/root/FieldSupport")
	if support != null and support.has_method("_arm_blueprint"):
		support.call("_arm_blueprint", game, kind)
	else:
		game.call("_begin_build", kind)

func _train(kind: String) -> void:
	if game == null:
		return
	var support: Node = get_node_or_null("/root/FieldSupport")
	if support != null and support.has_method("_train"):
		support.call("_train", game, kind)
	else:
		game.call("_train", kind)

func _train_from_primary() -> void:
	if production_primary != null:
		_train_from_selected(str(production_primary.get_meta("unit_kind", "")))

func _train_from_secondary() -> void:
	if production_secondary != null:
		_train_from_selected(str(production_secondary.get_meta("unit_kind", "")))

func _train_from_selected(kind: String) -> void:
	if game != null and not kind.is_empty():
		game.call("_train", kind)

func _begin_rally_mode() -> void:
	if game == null:
		return
	var support: Node = get_node_or_null("/root/FieldSupport")
	if support != null and support.has_method("_begin_rally_mode"):
		support.call("_begin_rally_mode", game)

func _send_to_medbay() -> void:
	if game == null:
		return
	var support: Node = get_node_or_null("/root/FieldSupport")
	if support != null and support.has_method("_send_to_medbay"):
		support.call("_send_to_medbay", game)

func _cancel_active_mode() -> void:
	if game == null:
		return
	var support: Node = get_node_or_null("/root/FieldSupport")
	if support != null and support.has_method("_cancel_rally_mode"):
		support.call("_cancel_rally_mode", game)
	if support != null and support.has_method("_cancel_blueprint"):
		support.call("_cancel_blueprint", game)

func _attack_move() -> void:
	if game != null:
		game.set("attack_move_pending", true)
		game.call("flash", "Attack-move armed. Right-click a destination.", 2.0)

func _hold_position() -> void:
	if game != null:
		game.call("_set_hold_position")

func _home_camera() -> void:
	if game == null:
		return
	var nexus: Dictionary = game.call("_home_nexus") as Dictionary
	if not nexus.is_empty():
		game.set("camera_goal", nexus.get("pos", Vector2.ZERO))

func _add_compact_button(parent: Control, label_text: String, tooltip_text: String, position_value: Vector2, action: Callable, background: Color, border: Color) -> void:
	var button: Button = Button.new()
	button.text = label_text
	button.tooltip_text = tooltip_text
	button.position = position_value
	button.size = Vector2(98.0, 50.0)
	button.add_theme_font_size_override("font_size", 10)
	button.add_theme_stylebox_override("normal", _button_style(background, border))
	button.add_theme_stylebox_override("hover", _button_style(background.lightened(0.18), Color("ffffff")))
	button.add_theme_stylebox_override("pressed", _button_style(background.darkened(0.16), Color("ffd16a")))
	button.add_theme_color_override("font_color", Color("f3f8ff"))
	button.pressed.connect(action)
	parent.add_child(button)

func _production_button(position_value: Vector2) -> Button:
	var button: Button = Button.new()
	button.position = position_value
	button.size = Vector2(190.0, 36.0)
	button.add_theme_font_size_override("font_size", 10)
	button.add_theme_stylebox_override("normal", _button_style(Color("253d63"), Color("8fe9ff")))
	button.add_theme_stylebox_override("hover", _button_style(Color("315786"), Color("ffffff")))
	button.add_theme_stylebox_override("pressed", _button_style(Color("193251"), Color("ffd16a")))
	button.add_theme_color_override("font_color", Color("f3f8ff"))
	return button

func _button_style(background: Color, border: Color) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(2)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.content_margin_left = 4.0
	style.content_margin_right = 4.0
	style.content_margin_top = 3.0
	style.content_margin_bottom = 3.0
	return style

func _panel(rect: Rect2, background: Color, border: Color, border_width: int) -> Panel:
	var panel: Panel = Panel.new()
	panel.position = rect.position
	panel.size = rect.size
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(border_width)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	panel.add_theme_stylebox_override("panel", style)
	return panel

func _label(text_value: String, rect: Rect2, font_size: int, color: Color) -> Label:
	var label: Label = Label.new()
	label.text = text_value
	label.position = rect.position
	label.size = rect.size
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label
