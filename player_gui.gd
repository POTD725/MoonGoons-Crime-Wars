extends Node
## MoonGoons Command Deck
## Original RTS control interface: lunar alloy panels, Authority telemetry,
## resource banking, unit dossiers, tactical commands, and an interactive minimap.

const WORLD := Rect2(-1150, -760, 2500, 1500)
const MOON_NAVY := Color("071326")
const PANEL := Color("0b1c32")
const PANEL_DEEP := Color("07111f")
const AUTH_CYAN := Color("8fe9ff")
const EVIDENCE_GOLD := Color("ffc66d")
const ALERT_RED := Color("ff7187")
const TEXT := Color("eaf5ff")

var canvas: CanvasLayer
var root: Control
var game: Node
var top_bar: Panel
var bottom_bar: Panel
var resource_label: Label
var mission_label: Label
var alert_label: Label
var selection_title: Label
var selection_text: Label
var order_text: Label
var portrait: UnitPortrait
var minimap: MoonMiniMap
var command_buttons: Dictionary = {}
var last_note := ""
var last_entity_id := -2

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_command_deck()

func _process(_delta: float) -> void:
	game = _find_game()
	canvas.visible = game != null and not _modal_active()
	if game == null:
		return
	_update_display()

func _find_game() -> Node:
	var scene := get_tree().current_scene
	if scene != null and scene.has_method("_entity") and scene.has_method("_build") and scene.has_method("_train"):
		return scene
	return null

func _modal_active() -> bool:
	if CutsceneDirector != null and bool(CutsceneDirector.get("is_playing")):
		return true
	for global in [ModeHub, MapSelector, DifficultyMenu, RaceMode]:
		if global == null:
			continue
		var overlay := global.get("overlay")
		if overlay is CanvasItem and overlay.visible:
			return true
		var picker := global.get("picker")
		if picker is CanvasItem and picker.visible:
			return true
	if FreeRoamAlliance != null:
		var alliance_panel := FreeRoamAlliance.get("panel")
		if alliance_panel is CanvasItem and alliance_panel.visible:
			return true
	return false

func _build_command_deck() -> void:
	canvas = CanvasLayer.new()
	canvas.layer = 42
	canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(canvas)
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(root)

	# Top telemetry bar.
	top_bar = _panel(Vector2(0, 0), Vector2(1600, 76), AUTH_CYAN, 0.92)
	root.add_child(top_bar)
	var crest := DeckCrest.new()
	crest.position = Vector2(18, 10)
	crest.size = Vector2(56, 56)
	top_bar.add_child(crest)
	var title := _label("MOONGOONS AUTHORITY // COMMAND DECK", Vector2(88, 11), Vector2(480, 24), 17, TEXT)
	title.add_theme_color_override("font_shadow_color", Color("000000"))
	title.add_theme_constant_override("shadow_offset_x", 2)
	title.add_theme_constant_override("shadow_offset_y", 2)
	top_bar.add_child(title)
	mission_label = _label("OPERATION // STANDBY", Vector2(88, 39), Vector2(510, 22), 13, Color("b2d1ed"))
	top_bar.add_child(mission_label)
	resource_label = _label("", Vector2(615, 13), Vector2(610, 45), 19, AUTH_CYAN)
	resource_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top_bar.add_child(resource_label)
	alert_label = _label("", Vector2(1232, 16), Vector2(345, 44), 13, EVIDENCE_GOLD)
	alert_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	alert_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	top_bar.add_child(alert_label)

	# Lower command deck.
	bottom_bar = _panel(Vector2(0, 652), Vector2(1600, 248), AUTH_CYAN, 0.97)
	root.add_child(bottom_bar)
	_draw_rivets(bottom_bar)
	_build_dossier(bottom_bar)
	_build_command_grid(bottom_bar)
	_build_minimap(bottom_bar)

func _build_dossier(parent: Control) -> void:
	var panel := _panel(Vector2(18, 14), Vector2(365, 220), Color("5ea3c8"), 0.98)
	parent.add_child(panel)
	var heading := _label("ACTIVE DOSSIER", Vector2(16, 12), Vector2(325, 20), 14, AUTH_CYAN)
	panel.add_child(heading)
	portrait = UnitPortrait.new()
	portrait.position = Vector2(16, 42)
	portrait.size = Vector2(104, 145)
	panel.add_child(portrait)
	selection_title = _label("NO SELECTION", Vector2(132, 43), Vector2(216, 25), 18, TEXT)
	selection_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(selection_title)
	selection_text = _label("Select a unit or structure to inspect it.", Vector2(132, 72), Vector2(214, 77), 13, Color("c3d8eb"))
	selection_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(selection_text)
	order_text = _label("STATUS // AWAITING ORDERS", Vector2(132, 157), Vector2(214, 26), 12, EVIDENCE_GOLD)
	order_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(order_text)
	var hotkeys := _label("L-CLICK SELECT  •  R-CLICK ORDER", Vector2(16, 194), Vector2(332, 17), 11, Color("89a9c8"))
	hotkeys.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(hotkeys)

func _build_command_grid(parent: Control) -> void:
	var panel := _panel(Vector2(402, 14), Vector2(762, 220), Color("779bc3"), 0.98)
	parent.add_child(panel)
	var heading := _label("TACTICAL ORDERS", Vector2(16, 12), Vector2(380, 20), 14, AUTH_CYAN)
	panel.add_child(heading)
	var mode := _label("BUILD • DEPLOY • COMMAND", Vector2(414, 12), Vector2(330, 20), 12, Color("a8bed8"))
	mode.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	panel.add_child(mode)
	var commands := [
		["ARMORY", "1", "build:armory", "Build a tactical armory"],
		["RELAY", "2", "build:relay", "Deploy a power relay"],
		["MEDBAY", "3", "build:medbay", "Place a field medbay"],
		["DRONE BAY", "4", "build:bay", "Build a drone bay"],
		["CELLS", "5", "build:cells", "Construct holding cells"],
		["DEPUTY", "Q", "train:deputy", "Train a patrol deputy"],
		["DRONE", "E", "train:drone", "Train a builder drone"],
		["SHIELD", "R", "train:shield", "Train a shield deputy"],
		["FOCUS", "F", "focus", "Center camera on selection"],
		["CANCEL", "ESC", "cancel", "Cancel build placement"],
		["MAP", "F3", "map", "Open battlefield archive"],
		["DIFFICULTY", "F4", "difficulty", "Open difficulty console"]
	]
	for index in commands.size():
		var column := index % 4
		var row := index / 4
		var button := _command_button(commands[index], Vector2(16 + column * 184, 42 + row * 55))
		panel.add_child(button)
		command_buttons[str(commands[index][2])] = button

func _build_minimap(parent: Control) -> void:
	var panel := _panel(Vector2(1180, 14), Vector2(402, 220), EVIDENCE_GOLD, 0.98)
	parent.add_child(panel)
	var heading := _label("TACTICAL MAP", Vector2(16, 12), Vector2(180, 20), 14, EVIDENCE_GOLD)
	panel.add_child(heading)
	var hint := _label("CLICK TO REPOSITION CAMERA", Vector2(195, 12), Vector2(190, 20), 11, Color("d6c49b"))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	panel.add_child(hint)
	minimap = MoonMiniMap.new()
	minimap.position = Vector2(15, 39)
	minimap.size = Vector2(372, 164)
	minimap.gui_input.connect(_minimap_input)
	panel.add_child(minimap)

func _update_display() -> void:
	var difficulty_name := GameDifficulty.get_name() if GameDifficulty != null else "Standard"
	var map_name := str(game.get_meta("pvp_map_name", "Breakwater Dockyard"))
	mission_label.text = "MAP // %s    •    DIFFICULTY // %s" % [map_name.to_upper(), difficulty_name.to_upper()]
	resource_label.text = "◈  %04d CREDITS     ◒  %03d SUPPLIES     ◉  %03d INTEL" % [int(game.get("credits")), int(game.get("supplies")), int(game.get("intel"))]
	var message := str(game.get("note"))
	if message != last_note:
		last_note = message
	alert_label.text = "[ ALERT ]\n" + message if not message.is_empty() else "[ SYSTEM ]\nAll channels stable."
	var entity := _selected_entity()
	_update_dossier(entity)
	_update_command_states(entity)
	minimap.game = game
	minimap.queue_redraw()

func _selected_entity() -> Dictionary:
	if int(game.get("selected_building")) != -1:
		return game.call("_entity", int(game.get("selected_building")))
	var selected: Array = game.get("selected")
	if selected.size() == 1:
		return game.call("_entity", int(selected[0]))
	return {}

func _update_dossier(entity: Dictionary) -> void:
	var selected: Array = game.get("selected")
	if entity.is_empty():
		if selected.size() > 1:
			selection_title.text = "%d UNITS SELECTED" % selected.size()
			selection_text.text = "Squad selection active. Right-click terrain to move, a target to engage, or an ore cache to harvest with Builder Drones."
			order_text.text = "SQUAD LINK // FORMATION READY"
			portrait.configure("squad", "authority", AUTH_CYAN, 1.0)
		else:
			selection_title.text = "NO SELECTION"
			selection_text.text = "Select a unit or structure to inspect it. Builder Drones unlock construction commands."
			order_text.text = "STATUS // AWAITING ORDERS"
			portrait.configure("idle", "authority", AUTH_CYAN, 1.0)
		return
	var race_id := str(entity.get("race", "authority"))
	var accent := _race_color(race_id)
	var hp := float(entity.get("hp", 0.0))
	var max_hp := maxf(1.0, float(entity.get("max", 1.0)))
	var health := int(round(hp / max_hp * 100.0))
	selection_title.text = str(entity.get("name", "UNKNOWN")).to_upper()
	var category := "STRUCTURE" if entity.has("size") else "UNIT"
	var detail := "%s // %s\nINTEGRITY  %d%%\n" % [category, RaceCatalog.get_name(race_id), health]
	if entity.has("order"):
		detail += "ORDER  %s\n" % str(entity.get("order", "idle")).to_upper()
		if entity.has("damage"):
			detail += "DAMAGE  %d   RANGE  %d" % [int(entity.get("damage", 0)), int(entity.get("range", 0.0))]
	else:
		detail += "STATE  %s" % ("ONLINE" if bool(entity.get("done", true)) else "CONSTRUCTING")
	selection_text.text = detail
	order_text.text = "THREAT LINK // %s" % ("CPU CONTROLLED" if bool(entity.get("cpu", false)) else "PLAYER COMMAND")
	portrait.configure(str(entity.get("kind", "unit")), race_id, accent, hp / max_hp)
	last_entity_id = int(entity.get("id", -1))

func _update_command_states(entity: Dictionary) -> void:
	var has_drone := false
	for unit_id in game.get("selected"):
		var unit: Dictionary = game.call("_entity", int(unit_id))
		if not unit.is_empty() and str(unit.get("kind", "")) == "drone":
			has_drone = true
	var building_selected := not entity.is_empty() and entity.has("size") and bool(entity.get("done", true))
	for key in command_buttons.keys():
		var button: Button = command_buttons[key]
		if key.begins_with("build:"):
			button.disabled = not has_drone
		elif key == "train:shield":
			button.disabled = not building_selected or str(entity.get("kind", "")) != "armory"
		elif key.begins_with("train:"):
			button.disabled = not building_selected or str(entity.get("kind", "")) != "nexus"
		elif key == "focus":
			button.disabled = entity.is_empty()
		else:
			button.disabled = false

func _command_button(data: Array, position: Vector2) -> Button:
	var button := Button.new()
	button.position = position
	button.size = Vector2(172, 47)
	button.text = "%s  [%s]" % [str(data[0]), str(data[1])]
	button.tooltip_text = str(data[3])
	button.add_theme_font_size_override("font_size", 12)
	button.add_theme_color_override("font_color", TEXT)
	button.add_theme_stylebox_override("normal", _button_style(Color("183555"), AUTH_CYAN))
	button.add_theme_stylebox_override("hover", _button_style(Color("234d75"), Color("d8f7ff")))
	button.add_theme_stylebox_override("pressed", _button_style(Color("091424"), EVIDENCE_GOLD))
	button.add_theme_stylebox_override("disabled", _button_style(Color("111a29"), Color("40546e")))
	button.pressed.connect(_run_command.bind(str(data[2])))
	return button

func _run_command(command: String) -> void:
	if game == null:
		return
	if command.begins_with("build:"):
		game.call("_build", command.trim_prefix("build:"))
	elif command.begins_with("train:"):
		game.call("_train", command.trim_prefix("train:"))
	elif command == "cancel":
		game.set("build_kind", "")
		game.call("flash", "Build order cancelled.", 2.0)
	elif command == "focus":
		var entity := _selected_entity()
		if not entity.is_empty():
			game.set("cam", entity.get("pos", game.get("cam")))
	elif command == "map":
		_open_modal(MapSelector)
	elif command == "difficulty":
		_open_modal(DifficultyMenu)

func _open_modal(global: Node) -> void:
	if global == null:
		return
	var overlay := global.get("overlay")
	if overlay is CanvasItem:
		overlay.visible = true
		get_tree().paused = true

func _minimap_input(event: InputEvent) -> void:
	if game == null:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var local_position := minimap.get_local_mouse_position()
		game.set("cam", minimap.to_world(local_position))

func _panel(position: Vector2, size: Vector2, border_color: Color, alpha: float) -> Panel:
	var panel := Panel.new()
	panel.position = position
	panel.size = size
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(PANEL.r, PANEL.g, PANEL.b, alpha)
	style.border_color = border_color
	style.set_border_width_all(2)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.55)
	style.shadow_size = 5
	style.shadow_offset = Vector2(2, 3)
	panel.add_theme_stylebox_override("panel", style)
	return panel

func _button_style(background: Color, border_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border_color
	style.set_border_width_all(1)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	return style

func _label(text: String, position: Vector2, size: Vector2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.position = position
	label.size = size
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label

func _draw_rivets(panel: Control) -> void:
	var rivets := DeckRivets.new()
	rivets.position = Vector2.ZERO
	rivets.size = panel.size
	panel.add_child(rivets)

func _race_color(race_id: String) -> Color:
	match race_id:
		"lunar_cartel": return Color("ff79c6")
		"null_choir": return Color("72f2bd")
		"hollow_fang": return Color("ff9b62")
		_: return AUTH_CYAN

class DeckCrest extends Control:
	func _draw() -> void:
		var center := size * 0.5
		draw_circle(center, 26.0, Color("0a203a"))
		draw_circle(center, 24.0, Color("75dfff"), false, 2.0)
		draw_arc(center, 17.0, 0.25, PI - 0.25, 18, Color("eaf8ff"), 3.0)
		draw_circle(center + Vector2(0, 3), 7.0, Color("ffc66d"))
		draw_line(center + Vector2(-15, 14), center + Vector2(15, 14), Color("8fe9ff"), 3.0)

class DeckRivets extends Control:
	func _draw() -> void:
		for x in range(12, int(size.x), 28):
			draw_circle(Vector2(x, 7), 2.0, Color("42627c"))
			draw_circle(Vector2(x, size.y - 7), 2.0, Color("42627c"))

class UnitPortrait extends Control:
	var unit_kind := "idle"
	var race := "authority"
	var accent := AUTH_CYAN
	var integrity := 1.0

	func configure(new_kind: String, new_race: String, new_accent: Color, new_integrity: float) -> void:
		unit_kind = new_kind
		race = new_race
		accent = new_accent
		integrity = clampf(new_integrity, 0.0, 1.0)
		queue_redraw()

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color("06101e"), true)
		draw_rect(Rect2(Vector2.ZERO, size), accent, false, 2.0)
		for y in range(14, int(size.y), 16):
			draw_line(Vector2(5, y), Vector2(size.x - 5, y), Color(accent.r, accent.g, accent.b, 0.10), 1.0)
		var center := Vector2(size.x * 0.5, 66)
		if unit_kind in ["nexus", "syndicate_relay"]:
			draw_circle(center, 35.0, Color(accent.r, accent.g, accent.b, 0.45))
			draw_arc(center, 41.0, 0.0, TAU, 24, accent, 3.0)
			draw_rect(Rect2(center + Vector2(-27, 34), Vector2(54, 27)), Color("0f2440"), true)
		elif unit_kind in ["drone", "signal_seed", "scrapwright"]:
			draw_circle(center, 25.0, Color(accent.r, accent.g, accent.b, 0.52))
			for angle in [0.2, 2.2, 4.2]:
				draw_line(center, center + Vector2.from_angle(angle) * 37.0, accent, 3.0)
		elif unit_kind == "squad":
			for x in [-22.0, 0.0, 22.0]:
				draw_circle(center + Vector2(x, 0), 12.0, accent)
				draw_rect(Rect2(center + Vector2(x - 10, 13), Vector2(20, 25)), Color("173b58"), true)
		else:
			draw_circle(center + Vector2(0, -8), 24.0, Color(accent.r, accent.g, accent.b, 0.55))
			draw_circle(center + Vector2(-8, -10), 4.0, Color("06101e"))
			draw_circle(center + Vector2(8, -10), 4.0, Color("06101e"))
			draw_rect(Rect2(center + Vector2(-28, 19), Vector2(56, 36)), Color("183b59"), true)
			draw_line(center + Vector2(-25, 25), center + Vector2(25, 25), accent, 2.0)
		draw_rect(Rect2(9, size.y - 18, size.x - 18, 8), Color("15243a"), true)
		draw_rect(Rect2(9, size.y - 18, (size.x - 18) * integrity, 8), Color("73f3b6") if integrity > 0.35 else Color("ff7187"), true)

class MoonMiniMap extends Control:
	var game: Node

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP

	func _process(_delta: float) -> void:
		queue_redraw()

	func to_world(local: Vector2) -> Vector2:
		var clamped := Vector2(clampf(local.x, 0.0, size.x), clampf(local.y, 0.0, size.y))
		return WORLD.position + Vector2(clamped.x / size.x * WORLD.size.x, clamped.y / size.y * WORLD.size.y)

	func _map_point(world: Vector2) -> Vector2:
		return (world - WORLD.position) / WORLD.size * size

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color("050b15"), true)
		draw_rect(Rect2(Vector2.ZERO, size), Color("d7b469"), false, 2.0)
		for x in range(0, int(size.x), 32):
			draw_line(Vector2(x, 0), Vector2(x, size.y), Color(0.28, 0.36, 0.50, 0.22), 1.0)
		for y in range(0, int(size.y), 26):
			draw_line(Vector2(0, y), Vector2(size.x, y), Color(0.28, 0.36, 0.50, 0.22), 1.0)
		if game == null:
			return
		for node in game.get("nodes"):
			if int(node.get("amount", 0)) > 0:
				var resource_color := Color("65e6ff") if str(node.get("type", "ore")) == "ore" else Color("ffc66d")
				draw_circle(_map_point(node["pos"]), 3.0, resource_color)
		for building in game.get("buildings"):
			var point := _map_point(building["pos"])
			var color := Color("8fe9ff") if str(building.get("team", "authority")) == "authority" else Color("ff7187")
			draw_rect(Rect2(point - Vector2(4, 4), Vector2(8, 8)), color, true)
		for unit in game.get("units"):
			var point := _map_point(unit["pos"])
			var color := Color("b7edff") if str(unit.get("team", "authority")) == "authority" else Color("ff9aab")
			draw_circle(point, 2.2, color)
		var cam: Vector2 = game.get("cam")
		var zoom: float = game.get("zoom")
		var view := game.get_viewport_rect().size / maxf(zoom, 0.1)
		var rect_size := view / WORLD.size * size
		draw_rect(Rect2(_map_point(cam) - rect_size * 0.5, rect_size), Color("f3fbff"), false, 1.5)
