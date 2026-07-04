extends "res://hud.gd"
## Tabbed command deck: Build, Defense, Units, Orders, and Support.

var tab_buttons: Dictionary = {}
var command_stage: Panel
var active_tab: String = "BUILD"

func _build_command_panel(deck: Panel) -> void:
	var command_panel: Panel = _panel(Rect2(462.0, 14.0, 730.0, 218.0), Color("0b1c31"), Color("536f92"), 2)
	deck.add_child(command_panel)
	var title: Label = _label("TACTICAL COMMAND CONSOLE", Rect2(14.0, 10.0, 702.0, 18.0), 14, Color("b9d9f7"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	command_panel.add_child(title)
	_add_tab(command_panel, "BUILD", "BUILD", Vector2(14.0, 34.0))
	_add_tab(command_panel, "DEFENSE", "DEFENSE", Vector2(150.0, 34.0))
	_add_tab(command_panel, "UNITS", "UNITS", Vector2(286.0, 34.0))
	_add_tab(command_panel, "ORDERS", "ORDERS", Vector2(422.0, 34.0))
	_add_tab(command_panel, "SUPPORT", "SUPPORT", Vector2(558.0, 34.0))
	command_stage = _panel(Rect2(12.0, 67.0, 706.0, 138.0), Color("071526"), Color("31567d"), 1)
	command_panel.add_child(command_stage)
	_set_command_tab("BUILD")

func _build_help_panel(deck: Panel) -> void:
	var help_panel: Panel = _panel(Rect2(1204.0, 14.0, 376.0, 218.0), Color("07152a"), Color("efc75e"), 2)
	deck.add_child(help_panel)
	var help_title: Label = _label("FIELD CONTROLS", Rect2(16.0, 15.0, 344.0, 22.0), 16, Color("efc75e"))
	help_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	help_panel.add_child(help_title)
	var help_text: Label = _label("ARROW KEYS / W A S D  Move camera\nLEFT-DRAG  Select units or buildings\nRIGHT-CLICK  Move, attack, harvest, build, repair\nMIDDLE-DRAG  Pan camera\nWHEEL  Zoom\nP or ORDERS tab  Patrol\nY  Rally point    Z  Air Strike\nF9  Test console", Rect2(18.0, 48.0, 340.0, 154.0), 12, Color("d7eaff"))
	help_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	help_panel.add_child(help_text)

func _refresh() -> void:
	super._refresh()
	if game != null:
		var oxygen: int = int(round(float(game.get("oxygen_reserve"))))
		resource_line.text = "CREDITS  %04d     SUPPLIES  %03d     INTEL  %03d     O2  %03d%%" % [int(game.get("credits")), int(game.get("supplies")), int(game.get("intel")), oxygen]

func _add_tab(parent: Control, tab_id: String, label_text: String, position_value: Vector2) -> void:
	var button: Button = Button.new()
	button.text = label_text
	button.position = position_value
	button.size = Vector2(132.0, 26.0)
	button.add_theme_font_size_override("font_size", 11)
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.pressed.connect(_set_command_tab.bind(tab_id))
	parent.add_child(button)
	tab_buttons[tab_id] = button

func _set_command_tab(tab_id: String) -> void:
	active_tab = tab_id
	for key in tab_buttons:
		var tab: Button = tab_buttons[key] as Button
		var selected_here: bool = str(key) == active_tab
		var background: Color = Color("234466") if selected_here else Color("10263f")
		var border: Color = Color("8fe9ff") if selected_here else Color("4a6a8d")
		tab.add_theme_stylebox_override("normal", _tab_style(background, border))
		tab.add_theme_stylebox_override("hover", _tab_style(background.lightened(0.16), Color("ffffff")))
		tab.add_theme_color_override("font_color", Color("f3f9ff") if selected_here else Color("a9c6df"))
	if command_stage == null:
		return
	for child in command_stage.get_children():
		child.queue_free()
	match active_tab:
		"BUILD":
			_stage_button("TACTICAL ARMORY\n160 CREDITS [1]", Vector2(10.0, 9.0), _begin_build.bind("armory"), Color("1b3658"), Color("6fa8dc"))
			_stage_button("POWER RELAY\n60 CREDITS [2]", Vector2(247.0, 9.0), _begin_build.bind("relay"), Color("1b3658"), Color("6fa8dc"))
			_stage_button("FIELD MEDBAY\n120 CREDITS [3]", Vector2(484.0, 9.0), _begin_build.bind("medbay"), Color("164449"), Color("72f2bd"))
			_stage_button("DRONE BAY\n110 CREDITS [4]", Vector2(10.0, 72.0), _begin_build.bind("bay"), Color("203d68"), Color("7aa8ff"))
			_stage_button("CONTAINMENT CELLS\n170 CREDITS [5]", Vector2(247.0, 72.0), _begin_build.bind("cells"), Color("55432d"), Color("f3b85e"))
			_stage_button("SET RALLY POINT\nSelect producer, then [Y]", Vector2(484.0, 72.0), _begin_rally_mode, Color("2a2350"), Color("d9c4ff"))
		"DEFENSE":
			_stage_button("SENTRY TURRET\n95 CREDITS [6]", Vector2(10.0, 9.0), _begin_build.bind("sentry_turret"), Color("173c50"), Color("78d8ff"))
			_stage_button("PULSE CANNON\n180 CREDITS [7]", Vector2(247.0, 9.0), _begin_build.bind("pulse_cannon"), Color("4a3422"), Color("ffc46b"))
			_stage_button("MACHINE SHOP\n230 CREDITS [8]", Vector2(484.0, 9.0), _begin_build.bind("machine_shop"), Color("332754"), Color("b9a4ff"))
			_stage_button("RADIATION ARRAY\n210 CREDITS", Vector2(10.0, 72.0), _begin_build.bind("radiation_array"), Color("34234f"), Color("c09cff"))
			_stage_button("THERMAL REGULATOR\n135 CREDITS", Vector2(247.0, 72.0), _begin_build.bind("thermal_regulator"), Color("4b3425"), Color("ffbf7c"))
			_stage_button("O2 GENERATOR\n145 CREDITS", Vector2(484.0, 72.0), _begin_build.bind("o2_generator"), Color("1b4c45"), Color("77f7d8"))
		"UNITS":
			_stage_button("PATROL DEPUTY\n85 CREDITS [Q]", Vector2(10.0, 9.0), _train.bind("deputy"), Color("233b68"), Color("9cb6ff"))
			_stage_button("BUILDER DRONE\n65 CREDITS [E]", Vector2(247.0, 9.0), _train.bind("drone"), Color("174452"), Color("8deaff"))
			_stage_button("SHIELD DEPUTY\n145 CREDITS [R]", Vector2(484.0, 9.0), _train.bind("shield"), Color("3e285b"), Color("d9a2ff"))
			_stage_button("BULWARK ROVER\n255 CREDITS [T]", Vector2(10.0, 72.0), _train.bind("bulwark_rover"), Color("382e55"), Color("d9c4ff"))
			_stage_button("ARMORY UNLOCK\nShield Deputies", Vector2(247.0, 72.0), _focus_armory_note, Color("28344b"), Color("8faac8"))
			_stage_button("SHOP UNLOCK\nBulwark Rovers", Vector2(484.0, 72.0), _focus_machine_shop_note, Color("28344b"), Color("8faac8"))
		"ORDERS":
			_stage_button("ATTACK MOVE\n[A] then right-click", Vector2(10.0, 9.0), _attack_move, Color("4e2933"), Color("ff9aa9"))
			_stage_button("PATROL\n[P] then right-click", Vector2(247.0, 9.0), _patrol_order, Color("214660"), Color("7ad4ff"))
			_stage_button("HOLD POSITION\n[H]", Vector2(484.0, 9.0), _hold_position, Color("3a424c"), Color("d7eaff"))
			_stage_button("MEDBAY ROUTE\n[M] selected units", Vector2(10.0, 72.0), _send_to_medbay, Color("164449"), Color("72f2bd"))
			_stage_button("RALLY MODE\n[Y] selected producer", Vector2(247.0, 72.0), _begin_rally_mode, Color("2a2350"), Color("d9c4ff"))
			_stage_button("HOME CAMERA\n[SPACE]", Vector2(484.0, 72.0), _home_camera, Color("253348"), Color("a4c9e9"))
		"SUPPORT":
			_stage_button("AIR SUPPORT PAD\n260 CREDITS", Vector2(10.0, 9.0), _begin_build.bind("air_support_pad"), Color("183d59"), Color("77c8ff"))
			_stage_button("AIR STRIKE\n25 INTEL [Z]", Vector2(247.0, 9.0), _begin_air_support, Color("233d63"), Color("a3dcff"))
			_stage_button("O2 GENERATOR\nSafe zone + supplies", Vector2(484.0, 9.0), _begin_build.bind("o2_generator"), Color("1b4c45"), Color("77f7d8"))
			_stage_button("THERMAL REGULATOR\nFaster nearby builds", Vector2(10.0, 72.0), _begin_build.bind("thermal_regulator"), Color("4b3425"), Color("ffbf7c"))
			_stage_button("RADIATION ARRAY\nHostile-world shield", Vector2(247.0, 72.0), _begin_build.bind("radiation_array"), Color("34234f"), Color("c09cff"))
			_stage_button("CANCEL ACTIVE MODE\n[ESC]", Vector2(484.0, 72.0), _cancel_active_mode, Color("3d2735"), Color("ff9bb3"))

func _stage_button(label_text: String, position_value: Vector2, action: Callable, background: Color, border: Color) -> void:
	var button: Button = Button.new()
	button.text = label_text
	button.position = position_value
	button.size = Vector2(212.0, 54.0)
	button.add_theme_font_size_override("font_size", 11)
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.add_theme_stylebox_override("normal", _stage_style(background, border))
	button.add_theme_stylebox_override("hover", _stage_style(background.lightened(0.16), Color("ffffff")))
	button.add_theme_stylebox_override("pressed", _stage_style(background.darkened(0.16), Color("ffd16a")))
	button.add_theme_color_override("font_color", Color("f5faff"))
	button.pressed.connect(action)
	command_stage.add_child(button)

func _patrol_order() -> void:
	if game == null:
		return
	game.set("patrol_pending", true)
	game.set("attack_move_pending", false)
	game.call("flash", "Patrol armed. Right-click the second patrol point.", 2.0)

func _begin_air_support() -> void:
	if game == null:
		return
	var support: Node = get_node_or_null("/root/FieldSupport")
	if support != null and support.has_method("_begin_air_support"):
		support.call("_begin_air_support", game)

func _cancel_active_mode() -> void:
	if game == null:
		return
	var support: Node = get_node_or_null("/root/FieldSupport")
	if support != null and support.has_method("_cancel_all_targeting"):
		support.call("_cancel_all_targeting", game)
	else:
		super._cancel_active_mode()

func _focus_armory_note() -> void:
	if game != null:
		game.call("flash", "Tactical Armory unlocks Shield Deputies. Select it to use its dedicated production button.", 3.0)

func _focus_machine_shop_note() -> void:
	if game != null:
		game.call("flash", "Machine Shop unlocks Bulwark Rovers. Select it to use its dedicated production button.", 3.0)

func _tab_style(background: Color, border: Color) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(2)
	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 5
	style.corner_radius_bottom_left = 5
	style.corner_radius_bottom_right = 5
	return style

func _stage_style(background: Color, border: Color) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(2)
	style.corner_radius_top_left = 7
	style.corner_radius_top_right = 7
	style.corner_radius_bottom_left = 7
	style.corner_radius_bottom_right = 7
	style.content_margin_left = 6.0
	style.content_margin_right = 6.0
	style.content_margin_top = 3.0
	style.content_margin_bottom = 3.0
	return style
