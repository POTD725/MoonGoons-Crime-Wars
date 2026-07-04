extends "res://grouped_command_hud.gd"
## Expanded roster tabs for troops, ground assets, and air assets.

var force_tabs: Dictionary = {}

func _build_command_panel(deck: Panel) -> void:
	var panel: Panel = _panel(Rect2(462.0, 14.0, 730.0, 218.0), Color("0b1c31"), Color("536f92"), 2)
	deck.add_child(panel)
	var title: Label = _label("TACTICAL COMMAND CONSOLE // FORCE ROSTER", Rect2(14.0, 10.0, 702.0, 18.0), 13, Color("b9d9f7"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(title)
	_add_force_tab(panel, "BUILD", Vector2(14.0, 34.0))
	_add_force_tab(panel, "DEFENSE", Vector2(130.0, 34.0))
	_add_force_tab(panel, "TROOPS", Vector2(246.0, 34.0))
	_add_force_tab(panel, "VEHICLES", Vector2(362.0, 34.0))
	_add_force_tab(panel, "ORDERS", Vector2(478.0, 34.0))
	_add_force_tab(panel, "SUPPORT", Vector2(594.0, 34.0))
	command_stage = _panel(Rect2(12.0, 67.0, 706.0, 138.0), Color("071526"), Color("31567d"), 1)
	panel.add_child(command_stage)
	_set_command_tab("BUILD")

func _add_force_tab(parent: Control, tab_id: String, point: Vector2) -> void:
	var button: Button = Button.new()
	button.text = tab_id
	button.position = point
	button.size = Vector2(112.0, 26.0)
	button.add_theme_font_size_override("font_size", 10)
	button.pressed.connect(_set_command_tab.bind(tab_id))
	parent.add_child(button)
	force_tabs[tab_id] = button

func _set_command_tab(tab_id: String) -> void:
	active_tab = tab_id
	for key in force_tabs:
		var tab: Button = force_tabs[key] as Button
		var active: bool = str(key) == tab_id
		tab.add_theme_stylebox_override("normal", _force_style(Color("234466") if active else Color("10263f"), Color("8fe9ff") if active else Color("4a6a8d")))
		tab.add_theme_color_override("font_color", Color("f3f9ff") if active else Color("a9c6df"))
	for child in command_stage.get_children():
		child.queue_free()
	match tab_id:
		"BUILD":
			_add_actions([["ARMORY\n160 C [1]", "build", "armory", "1b3658", "6fa8dc"], ["POWER RELAY\n60 C [2]", "build", "relay", "1b3658", "6fa8dc"], ["MEDBAY\n120 C [3]", "build", "medbay", "164449", "72f2bd"], ["DRONE BAY\n110 C [4]", "build", "bay", "203d68", "7aa8ff"], ["CELLS\n170 C [5]", "build", "cells", "55432d", "f3b85e"], ["SET RALLY\n[Y]", "rally", "", "2a2350", "d9c4ff"]])
		"DEFENSE":
			_add_actions([["SENTRY TURRET\n95 C [6]", "build", "sentry_turret", "173c50", "78d8ff"], ["PULSE CANNON\n180 C [7]", "build", "pulse_cannon", "4a3422", "ffc46b"], ["MACHINE SHOP\n230 C [8]", "build", "machine_shop", "332754", "b9a4ff"], ["O2 GENERATOR\n145 C", "build", "o2_generator", "1b4c45", "77f7d8"], ["THERMAL REGULATOR\n135 C", "build", "thermal_regulator", "4b3425", "ffbf7c"], ["RADIATION ARRAY\n210 C", "build", "radiation_array", "34234f", "c09cff"]])
		"TROOPS":
			_add_actions([["PATROL DEPUTY\n85 C [Q]", "train", "deputy", "233b68", "9cb6ff"], ["SHIELD DEPUTY\n145 C [R]", "train", "shield", "3e285b", "d9a2ff"], ["BREACH DEPUTY\n145 C", "train", "breacher", "543529", "ffad78"], ["LUNAR RANGER\n165 C", "train", "ranger", "25445e", "b4e5ff"], ["COMBAT MEDIC\n130 C", "train", "medic", "1d554a", "7dffd0"], ["COMBAT ENGINEER\n145 C", "train", "engineer", "5d4b21", "ffd66e"], ["RECON SPECIALIST\n150 C", "train", "recon", "174a62", "8deaff"], ["RIOT WARDEN\n190 C", "train", "warden", "432f62", "d7b6ff"], ["BUILDER DRONE\n65 C [E]", "train", "drone", "174452", "8deaff"]])
		"VEHICLES":
			_add_actions([["BULWARK ROVER\n255 C [T]", "train", "bulwark_rover", "382e55", "d9c4ff"], ["SIEGE CRAWLER\n390 C", "train", "siege_crawler", "5f3d24", "ffc072"], ["ARC LANCER\n330 C", "train", "arc_lancer", "173f58", "79e8ff"], ["PURSUIT SKIMMER\n275 C", "train", "pursuit_skimmer", "234972", "9dcbff"], ["BASTION TANK\n440 C", "train", "bastion_tank", "5a3034", "ffb18b"], ["AEGIS CARRIER\n360 C", "train", "troop_carrier", "25554c", "9ce0c0"], ["ATLAS MECH\n560 C", "train", "mech_mover", "605430", "f3d88d"], ["TRANSPORT DROP\nSelect, then right-click", "hint", "", "27394e", "a9c6df"]])
		"ORDERS":
			_add_actions([["ATTACK MOVE\n[A]", "attack", "", "4e2933", "ff9aa9"], ["PATROL\n[P]", "patrol", "", "214660", "7ad4ff"], ["HOLD\n[H]", "hold", "", "3a424c", "d7eaff"], ["MEDBAY ROUTE\n[M]", "heal", "", "164449", "72f2bd"], ["RALLY MODE\n[Y]", "rally", "", "2a2350", "d9c4ff"], ["HOME CAMERA\n[SPACE]", "home", "", "253348", "a4c9e9"], ["CANCEL MODE\n[ESC]", "cancel", "", "3d2735", "ff9bb3"]])
		"SUPPORT":
			_add_actions([["AIR SUPPORT PAD\n260 C", "build", "air_support_pad", "183d59", "77c8ff"], ["AIR STRIKE\n25 INTEL [Z]", "airstrike", "", "233d63", "a3dcff"], ["SKY LIFTER\n390 C", "train", "sky_lifter", "205269", "a2efff"], ["SPECTER FLYER\n440 C", "train", "specter_flyer", "3a2f61", "b49cff"], ["LUNAR STRIKECRAFT\n520 C", "train", "lunar_bomber", "5d3f29", "ffbf82"], ["AIR DROP\nSelect, then right-click", "hint", "", "205269", "a2efff"], ["O2 GENERATOR\nSafe zone", "build", "o2_generator", "1b4c45", "77f7d8"]])

func _add_actions(actions: Array) -> void:
	for index in range(actions.size()):
		var item: Array = actions[index] as Array
		var button: Button = Button.new()
		button.text = str(item[0])
		button.position = Vector2(8.0 + float(index % 3) * 233.0, 6.0 + float(index / 3) * 43.0)
		button.size = Vector2(224.0, 38.0)
		button.add_theme_font_size_override("font_size", 9)
		button.add_theme_stylebox_override("normal", _force_style(Color(str(item[3])), Color(str(item[4]))))
		button.add_theme_stylebox_override("hover", _force_style(Color(str(item[3])).lightened(0.16), Color("ffffff")))
		button.add_theme_stylebox_override("pressed", _force_style(Color(str(item[3])).darkened(0.16), Color("ffd16a")))
		button.add_theme_color_override("font_color", Color("f5faff"))
		button.pressed.connect(_run_force_action.bind(str(item[1]), str(item[2])))
		command_stage.add_child(button)

func _run_force_action(action: String, value: String) -> void:
	match action:
		"build": _begin_build(value)
		"train": _train(value)
		"rally": _begin_rally_mode()
		"attack": _attack_move()
		"patrol": _patrol_order()
		"hold": _hold_position()
		"heal": _send_to_medbay()
		"home": _home_camera()
		"cancel": _cancel_active_mode()
		"airstrike": _begin_air_support()
		"hint": _transport_hint()

func _transport_hint() -> void:
	if game != null:
		game.call("flash", "TRANSPORT DROP // Select an Aegis Carrier or Sky Lifter with cargo, then right-click open ground to deploy its squad.", 4.0)

func _role_for(entity: Dictionary) -> String:
	match str(entity.get("kind", "")):
		"breacher": return "Close assault infantry"
		"ranger": return "Long-range precision infantry"
		"medic": return "Automatic nearby unit healing"
		"engineer": return "Automatic nearby structure repair"
		"recon": return "Fast scouting and extended vision"
		"warden": return "Heavy crowd-control infantry"
		"siege_crawler": return "Long-range armored siege vehicle"
		"arc_lancer": return "Arc weapon assault vehicle"
		"pursuit_skimmer": return "Fast hover assault vehicle"
		"bastion_tank": return "Heavy armored assault vehicle"
		"troop_carrier": return "Ground transport with deployable squad"
		"mech_mover": return "Heavy walking assault mech"
		"sky_lifter": return "Air transport with deployable squad"
		"specter_flyer": return "Stealth strike aircraft"
		"lunar_bomber": return "Heavy strike aircraft"
		_: return super._role_for(entity)

func _force_style(background: Color, border: Color) -> StyleBoxFlat:
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
	style.content_margin_top = 1.0
	style.content_margin_bottom = 1.0
	return style
