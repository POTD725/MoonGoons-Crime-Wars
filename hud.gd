extends Node
## MoonGoons Command Deck HUD for the polished RTS slice.

var canvas: CanvasLayer
var root: Control
var game: Node
var resource_line: Label
var alert_line: Label
var dossier_title: Label
var dossier_body: Label
var objective_line: Label
var queue_line: Label
var minimap: TacticalMiniMap
var faction_chip: Label
var buttons: Array[Button] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_hud()

func _process(_delta: float) -> void:
	var current: Node = get_tree().current_scene
	if current == null or not current.has_method("_entity") or not current.has_method("_begin_build"):
		canvas.visible = false
		game = null
		return
	game = current
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

	var top: Panel = _panel(Rect2(0.0, 0.0, 1600.0, 70.0), Color("07172d"), Color("5fbfff"), 2)
	root.add_child(top)
	var title: Label = _label("MOONGOONS // COMMAND DECK", Rect2(20.0, 16.0, 400.0, 30.0), 20, Color("8fe9ff"))
	top.add_child(title)
	resource_line = _label("", Rect2(430.0, 15.0, 620.0, 30.0), 18, Color("eaf5ff"))
	resource_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top.add_child(resource_line)
	faction_chip = _label("AUTHORITY", Rect2(1085.0, 18.0, 165.0, 24.0), 13, Color("0b1528"))
	faction_chip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var chip_style: StyleBoxFlat = StyleBoxFlat.new()
	chip_style.bg_color = Color("8fe9ff")
	chip_style.corner_radius_top_left = 8
	chip_style.corner_radius_top_right = 8
	chip_style.corner_radius_bottom_left = 8
	chip_style.corner_radius_bottom_right = 8
	faction_chip.add_theme_stylebox_override("normal", chip_style)
	top.add_child(faction_chip)
	alert_line = _label("", Rect2(1270.0, 10.0, 310.0, 48.0), 12, Color("ffc46b"))
	alert_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	alert_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	top.add_child(alert_line)

	var objective_panel: Panel = _panel(Rect2(18.0, 91.0, 400.0, 100.0), Color("08182e"), Color("8fe9ff"), 2)
	root.add_child(objective_panel)
	var objective_title: Label = _label("OPERATION BREAKWATER // CW-001", Rect2(14.0, 12.0, 370.0, 20.0), 14, Color("8fe9ff"))
	objective_panel.add_child(objective_title)
	objective_line = _label("", Rect2(14.0, 38.0, 370.0, 52.0), 13, Color("eaf5ff"))
	objective_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	objective_panel.add_child(objective_line)

	var deck: Panel = _panel(Rect2(0.0, 650.0, 1600.0, 250.0), Color("071326"), Color("31567d"), 2)
	root.add_child(deck)
	var dossier: Panel = _panel(Rect2(18.0, 15.0, 458.0, 215.0), Color("0c2038"), Color("6ecbff"), 2)
	deck.add_child(dossier)
	dossier_title = _label("NO ACTIVE DOSSIER", Rect2(16.0, 16.0, 420.0, 28.0), 19, Color("8fe9ff"))
	dossier.add_child(dossier_title)
	dossier_body = _label("Select a unit or building to inspect its integrity, role, and active order.", Rect2(16.0, 52.0, 420.0, 115.0), 14, Color("d5eaff"))
	dossier_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dossier.add_child(dossier_body)
	queue_line = _label("COMMAND STATUS // READY", Rect2(16.0, 180.0, 420.0, 20.0), 12, Color("a4c9e9"))
	dossier.add_child(queue_line)

	var command_panel: Panel = _panel(Rect2(495.0, 15.0, 700.0, 215.0), Color("0b1c31"), Color("536f92"), 2)
	deck.add_child(command_panel)
	var command_title: Label = _label("TACTICAL COMMANDS", Rect2(14.0, 12.0, 660.0, 20.0), 14, Color("b9d9f7"))
	command_panel.add_child(command_title)
	_add_command_button(command_panel, "ARMORY\n[1]", "Build Tactical Armory", Vector2(14.0, 43.0), _begin_build.bind("armory"))
	_add_command_button(command_panel, "RELAY\n[2]", "Build Power Relay", Vector2(124.0, 43.0), _begin_build.bind("relay"))
	_add_command_button(command_panel, "MEDBAY\n[3]", "Build Field Medbay", Vector2(234.0, 43.0), _begin_build.bind("medbay"))
	_add_command_button(command_panel, "DRONE BAY\n[4]", "Build Drone Bay", Vector2(344.0, 43.0), _begin_build.bind("bay"))
	_add_command_button(command_panel, "CELLS\n[5]", "Build Containment Block", Vector2(454.0, 43.0), _begin_build.bind("cells"))
	_add_command_button(command_panel, "DEPUTY\n[Q]", "Train Patrol Deputy from Command Nexus", Vector2(14.0, 132.0), _train.bind("deputy"))
	_add_command_button(command_panel, "DRONE\n[E]", "Train Builder Drone from Command Nexus", Vector2(124.0, 132.0), _train.bind("drone"))
	_add_command_button(command_panel, "SHIELD\n[R]", "Train Shield Deputy from Tactical Armory", Vector2(234.0, 132.0), _train.bind("shield"))
	_add_command_button(command_panel, "ATTACK\n[A]", "Arm attack-move, then right-click a location", Vector2(344.0, 132.0), _attack_move)
	_add_command_button(command_panel, "HOLD\n[H]", "Order selected troops to hold position", Vector2(454.0, 132.0), _hold_position)
	_add_command_button(command_panel, "HOME\n[Space]", "Center camera on Command Nexus", Vector2(564.0, 132.0), _home_camera)

	var mini_panel: Panel = _panel(Rect2(1215.0, 15.0, 365.0, 215.0), Color("07152a"), Color("efc75e"), 2)
	deck.add_child(mini_panel)
	var mini_label: Label = _label("TACTICAL MAP // CLICK TO MOVE CAMERA", Rect2(12.0, 12.0, 340.0, 20.0), 12, Color("efc75e"))
	mini_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mini_panel.add_child(mini_label)
	minimap = TacticalMiniMap.new()
	minimap.position = Vector2(18.0, 39.0)
	minimap.size = Vector2(329.0, 158.0)
	minimap.hud_owner = self
	mini_panel.add_child(minimap)

func _refresh() -> void:
	resource_line.text = "CREDITS  %04d     SUPPLIES  %03d     INTEL  %03d" % [int(game.get("credits")), int(game.get("supplies")), int(game.get("intel"))]
	alert_line.text = str(game.get("note"))
	var faction: String = "AUTHORITY"
	if RaceMode != null:
		faction = RaceMode.chosen_race.to_upper().replace("_", " ")
	faction_chip.text = faction
	objective_line.text = _objective_text()
	_refresh_dossier()
	if minimap != null:
		minimap.queue_redraw()

func _objective_text() -> String:
	if bool(game.get("finished")):
		return "Operation concluded. Review the battlefield result and press R to restart the mission."
	var armory_ready: bool = false
	var relay_alive: bool = false
	for building: Dictionary in game.get("buildings"):
		if str(building.get("team", "")) == "authority" and str(building.get("kind", "")) == "armory" and bool(building.get("done", false)):
			armory_ready = true
		if str(building.get("kind", "")) == "syndicate_relay":
			relay_alive = true
	if not armory_ready:
		return "Select a Builder Drone, press 1, and place a Tactical Armory on open lunar ground."
	if relay_alive:
		return "Armory online. Expand your force, secure resources, and eliminate the Syndicate Relay."
	return "Relay neutralized. Secure the dockyard perimeter."

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
		dossier_body.text = "Select a unit or building. Builder Drones construct, Patrol Deputies defend, and Shield Deputies absorb close-range pressure."
		queue_line.text = "COMMAND STATUS // READY"
		return
	var hp: float = float(entity.get("hp", 0.0))
	var maximum: float = maxf(1.0, float(entity.get("max", 1.0)))
	var percent: int = int(round(hp / maximum * 100.0))
	var category: String = "STRUCTURE" if entity.has("size") else "UNIT"
	dossier_title.text = str(entity.get("name", "Unknown")).to_upper() + " // " + category
	dossier_body.text = "INTEGRITY: %d%%\nTEAM: %s\nROLE: %s\nORDER: %s" % [percent, str(entity.get("team", "authority")).to_upper(), _role_text(entity), str(entity.get("order", "ONLINE")).to_upper()]
	queue_line.text = "COMMAND STATUS // " + ("BUILDING" if entity.has("size") else "MOBILE")

func _role_text(entity: Dictionary) -> String:
	match str(entity.get("kind", "")):
		"drone": return "Builder and resource courier"
		"deputy": return "Ranged police infantry"
		"shield": return "Close defense and breach control"
		"hero": return "Command aura and heavy support"
		"raider": return "Fast Cartel attack unit"
		"hacker": return "Long-range disruption unit"
		"nexus": return "Primary production and command"
		"armory": return "Shield Deputy production"
		"relay": return "Power and map presence"
		"medbay": return "Nearby unit recovery"
		"bay": return "Drone logistics"
		"cells": return "Containment and mission support"
		"syndicate_relay": return "Primary hostile objective"
		_: return "Lunar operations asset"

func _begin_build(kind: String) -> void:
	if game != null:
		game.call("_begin_build", kind)

func _train(kind: String) -> void:
	if game != null:
		game.call("_train", kind)

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
		game.set("camera_goal", nexus["pos"])

func _add_command_button(parent: Control, text_value: String, tooltip: String, position: Vector2, action: Callable) -> void:
	var button: Button = Button.new()
	button.text = text_value
	button.tooltip_text = tooltip
	button.position = position
	button.size = Vector2(98.0, 76.0)
	button.add_theme_font_size_override("font_size", 12)
	button.add_theme_stylebox_override("normal", _button_style(Color("1b3658"), Color("6fa8dc")))
	button.add_theme_stylebox_override("hover", _button_style(Color("28527f"), Color("bceeff")))
	button.add_theme_stylebox_override("pressed", _button_style(Color("102843"), Color("ffd16a")))
	button.pressed.connect(action)
	parent.add_child(button)
	buttons.append(button)

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

class TacticalMiniMap extends Control:
	var hud_owner: Node

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton:
			var mouse_event: InputEventMouseButton = event
			if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed and hud_owner != null:
				var current_game: Node = hud_owner.get("game") as Node
				if current_game != null:
					var local_position: Vector2 = get_local_mouse_position()
					var world_position: Vector2 = Vector2(-1150.0 + local_position.x / size.x * 2500.0, -760.0 + local_position.y / size.y * 1500.0)
					current_game.set("camera_goal", world_position)

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color("050c18"), true)
		draw_rect(Rect2(Vector2.ZERO, size), Color("efc75e"), false, 2.0)
		if hud_owner == null:
			return
		var current_game: Node = hud_owner.get("game") as Node
		if current_game == null:
			return
		for resource: Dictionary in current_game.get("nodes") as Array:
			var pos: Vector2 = resource.get("pos", Vector2.ZERO) as Vector2
			var point: Vector2 = _map_point(pos)
			draw_circle(point, 2.0, Color("ffc66d") if str(resource.get("type", "ore")) == "evidence" else Color("65eaff"))
		for building: Dictionary in current_game.get("buildings") as Array:
			var pos: Vector2 = building.get("pos", Vector2.ZERO) as Vector2
			var point: Vector2 = _map_point(pos)
			var color: Color = Color("8fe9ff") if str(building.get("team", "")) == "authority" else Color("ff7187")
			draw_rect(Rect2(point - Vector2(3.5, 3.5), Vector2(7.0, 7.0)), color, true)
		for unit: Dictionary in current_game.get("units") as Array:
			var pos: Vector2 = unit.get("pos", Vector2.ZERO) as Vector2
			var point: Vector2 = _map_point(pos)
			var color: Color = Color("b7efff") if str(unit.get("team", "")) == "authority" else Color("ff8cb3")
			draw_circle(point, 2.2, color)
		var camera: Vector2 = current_game.get("camera_position") as Vector2
		var camera_point: Vector2 = _map_point(camera)
		draw_rect(Rect2(camera_point - Vector2(16.0, 10.0), Vector2(32.0, 20.0)), Color("f5fbff"), false, 1.2)

	func _map_point(world_position: Vector2) -> Vector2:
		return Vector2((world_position.x + 1150.0) / 2500.0 * size.x, (world_position.y + 760.0) / 1500.0 * size.y)
