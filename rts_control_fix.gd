extends Node
## Reliable RTS controls: protected prep time, construction placement, rally points, and Medbay healing.

const PREP_SECONDS: float = 600.0
const FREEZE_CLOCK: float = -10000.0
const HEAL_RADIUS: float = 170.0
const HEAL_PER_SECOND: float = 26.0
const BUILD_GRID: float = 20.0
const BUILD_RADIUS: float = 340.0

var active_scene_id: int = -1
var build_kind: String = ""
var support_canvas: CanvasLayer
var support_panel: Panel
var prep_text: Label
var rally_label: Label
var help_text: Label
var healing_notice: float = 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()

func _process(delta: float) -> void:
	healing_notice = maxf(0.0, healing_notice - delta)
	var scene: Node = _scene()
	if scene == null:
		support_canvas.visible = false
		active_scene_id = -1
		build_kind = ""
		return
	support_canvas.visible = not _picker_open()
	if scene.get_instance_id() != active_scene_id:
		active_scene_id = scene.get_instance_id()
		build_kind = ""
		_setup_scene(scene)
	_update_protection(scene)
	_update_rallies(scene)
	_heal_units(scene, delta)
	_refresh_ui(scene)

func _input(event: InputEvent) -> void:
	if _picker_open():
		return
	var scene: Node = _scene()
	if scene == null:
		return
	if event is InputEventMouseButton:
		var mouse: InputEventMouseButton = event as InputEventMouseButton
		if mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT and not build_kind.is_empty():
			if not _over_support_panel(mouse.position):
				_place_structure(scene, mouse.position)
				get_viewport().set_input_as_handled()
			return
		if mouse.pressed and mouse.button_index == MOUSE_BUTTON_RIGHT and build_kind.is_empty():
			if _set_rally_from_selection(scene, mouse.position):
				get_viewport().set_input_as_handled()
				return
	if not (event is InputEventKey):
		return
	var key: InputEventKey = event as InputEventKey
	if not key.pressed or key.echo:
		return
	match key.keycode:
		KEY_ESCAPE:
			if not build_kind.is_empty():
				_cancel_blueprint(scene)
				get_viewport().set_input_as_handled()
		KEY_1:
			_arm_blueprint(scene, "armory")
			get_viewport().set_input_as_handled()
		KEY_2:
			_arm_blueprint(scene, "relay")
			get_viewport().set_input_as_handled()
		KEY_3:
			_arm_blueprint(scene, "medbay")
			get_viewport().set_input_as_handled()
		KEY_4:
			_arm_blueprint(scene, "bay")
			get_viewport().set_input_as_handled()
		KEY_5:
			_arm_blueprint(scene, "cells")
			get_viewport().set_input_as_handled()
		KEY_Q:
			_train(scene, "deputy")
			get_viewport().set_input_as_handled()
		KEY_E:
			_train(scene, "drone")
			get_viewport().set_input_as_handled()
		KEY_R:
			_train(scene, "shield")
			get_viewport().set_input_as_handled()
		KEY_M:
			_send_to_medbay(scene)
			get_viewport().set_input_as_handled()

func _scene() -> Node:
	var scene: Node = get_tree().current_scene
	if scene == null:
		return null
	if not scene.has_method("_spawn_building") or not scene.has_method("_train") or not scene.has_method("_screen_to_world"):
		return null
	return scene

func _picker_open() -> bool:
	return RaceMode != null and RaceMode.picker != null and RaceMode.picker.visible

func _setup_scene(scene: Node) -> void:
	scene.set("enemy_wave_clock", FREEZE_CLOCK)
	scene.set_meta("protected_prep", true)
	_lock_enemy_units(scene)
	for building: Dictionary in scene.get("buildings") as Array:
		if str(building.get("team", "")) == "authority" and (str(building.get("kind", "")) == "nexus" or str(building.get("kind", "")) == "armory"):
			if not building.has("rally_point"):
				var building_position: Vector2 = building.get("pos", Vector2.ZERO) as Vector2
				building["rally_point"] = building_position + Vector2(150.0, 65.0)
	scene.call("flash", "PREPARATION WINDOW // Build, train, set rally points, and defend for 10:00.", 4.0)

func _update_protection(scene: Node) -> void:
	var deployed: bool = bool(scene.get_meta("race_selected", false)) or bool(scene.get_meta("custom_match", false))
	if not deployed or float(scene.get("mission_clock")) < PREP_SECONDS:
		scene.set("enemy_wave_clock", FREEZE_CLOCK)
		scene.set_meta("protected_prep", true)
		_lock_enemy_units(scene)
		return
	if bool(scene.get_meta("protected_prep", false)):
		scene.set_meta("protected_prep", false)
		_unlock_enemy_units(scene)
		scene.set("enemy_wave_clock", 10000.0)
		scene.call("flash", "HOSTILE ASSAULT ACTIVE // Defend the Command Nexus.", 4.0)
		_play("alert")

func _lock_enemy_units(scene: Node) -> void:
	for unit: Dictionary in scene.get("units") as Array:
		if str(unit.get("team", "")) != "syndicate":
			continue
		if not bool(unit.get("prep_locked", false)):
			unit["prep_locked"] = true
			unit["saved_speed"] = float(unit.get("speed", 0.0))
			unit["saved_range"] = float(unit.get("range", 0.0))
			unit["saved_damage"] = float(unit.get("damage", 0.0))
		unit["speed"] = 0.0
		unit["range"] = 0.0
		unit["damage"] = 0.0
		unit["order"] = "holding"

func _unlock_enemy_units(scene: Node) -> void:
	for unit: Dictionary in scene.get("units") as Array:
		if str(unit.get("team", "")) != "syndicate" or not bool(unit.get("prep_locked", false)):
			continue
		unit["speed"] = float(unit.get("saved_speed", 0.0))
		unit["range"] = float(unit.get("saved_range", 0.0))
		unit["damage"] = float(unit.get("saved_damage", 0.0))
		unit["prep_locked"] = false
		unit["order"] = "idle"

func _arm_blueprint(scene: Node, kind: String) -> void:
	var specs: Dictionary = scene.get("building_specs") as Dictionary
	if not specs.has(kind):
		return
	if _first_unit(scene, "drone").is_empty():
		scene.call("flash", "No Builder Drone ready. Press E to train one from the Command Nexus.", 3.0)
		return
	var spec: Dictionary = specs[kind] as Dictionary
	if int(scene.get("credits")) < int(spec.get("cost", 0)):
		scene.call("flash", "Insufficient Credits for " + str(spec.get("name", "this structure")) + ".", 2.5)
		return
	build_kind = kind
	scene.set("build_kind", kind)
	scene.call("flash", "BLUEPRINT ARMED // " + str(spec.get("name", "Structure")) + ". Left-click open terrain. Esc cancels.", 3.5)
	_play("build")

func _cancel_blueprint(scene: Node) -> void:
	build_kind = ""
	scene.set("build_kind", "")
	scene.call("flash", "Blueprint cancelled.", 1.4)

func _place_structure(scene: Node, screen_point: Vector2) -> void:
	var kind: String = build_kind
	var specs: Dictionary = scene.get("building_specs") as Dictionary
	if not specs.has(kind):
		_cancel_blueprint(scene)
		return
	var spec: Dictionary = specs[kind] as Dictionary
	if int(scene.get("credits")) < int(spec.get("cost", 0)):
		scene.call("flash", "Insufficient Credits. Blueprint cancelled.", 2.0)
		_cancel_blueprint(scene)
		return
	var requested: Vector2 = scene.call("_screen_to_world", screen_point) as Vector2
	var size: Vector2 = spec.get("size", Vector2(80.0, 60.0)) as Vector2
	var site: Vector2 = _valid_site_near(scene, requested, size)
	if site.x > 900000.0:
		scene.call("flash", "Construction zone blocked. Click clear terrain away from rooms, props, and deposits.", 3.0)
		return
	scene.set("credits", int(scene.get("credits")) - int(spec.get("cost", 0)))
	var building: Dictionary = scene.call("_spawn_building", kind, "authority", site, false) as Dictionary
	if kind == "armory" or kind == "nexus":
		building["rally_point"] = site + Vector2(150.0, 65.0)
	build_kind = ""
	scene.set("build_kind", "")
	scene.call("flash", str(spec.get("name", "Structure")) + " construction started.", 2.0)
	_play("build")

func _valid_site_near(scene: Node, requested: Vector2, size: Vector2) -> Vector2:
	var snapped: Vector2 = _snap(requested)
	if bool(scene.call("_valid_build_site", snapped, size)):
		return snapped
	for radius in range(40, int(BUILD_RADIUS) + 1, 40):
		for index in range(16):
			var angle: float = TAU * float(index) / 16.0
			var candidate: Vector2 = _snap(snapped + Vector2.from_angle(angle) * float(radius))
			if bool(scene.call("_valid_build_site", candidate, size)):
				return candidate
	return Vector2(999999.0, 999999.0)

func _snap(point: Vector2) -> Vector2:
	return Vector2(roundf(point.x / BUILD_GRID) * BUILD_GRID, roundf(point.y / BUILD_GRID) * BUILD_GRID)

func _train(scene: Node, kind: String) -> void:
	var producer_kind: String = "armory" if kind == "shield" else "nexus"
	var producer: Dictionary = _producer(scene, producer_kind)
	if producer.is_empty():
		var hint: String = "Build and finish a Tactical Armory before training Shield Deputies." if kind == "shield" else "Command Nexus unavailable."
		scene.call("flash", hint, 3.0)
		return
	var before: int = (scene.get("units") as Array).size()
	scene.set("selected", [])
	scene.set("selected_building", int(producer.get("id", -1)))
	scene.call("_train", kind)
	var units: Array = scene.get("units") as Array
	if units.size() > before:
		var new_unit: Dictionary = units[units.size() - 1] as Dictionary
		var fallback_rally: Vector2 = producer.get("pos", Vector2.ZERO) as Vector2
		fallback_rally += Vector2(150.0, 65.0)
		new_unit["rally_target"] = producer.get("rally_point", fallback_rally) as Vector2
		new_unit["rally_pending"] = true

func _set_rally_from_selection(scene: Node, screen_point: Vector2) -> bool:
	var selected_building: int = int(scene.get("selected_building"))
	if selected_building < 0:
		return false
	var producer: Dictionary = scene.call("_entity", selected_building) as Dictionary
	if producer.is_empty() or str(producer.get("team", "")) != "authority":
		return false
	if str(producer.get("kind", "")) != "nexus" and str(producer.get("kind", "")) != "armory":
		return false
	var point: Vector2 = scene.call("_screen_to_world", screen_point) as Vector2
	producer["rally_point"] = point
	scene.call("flash", "RALLY POINT SET // New units from " + str(producer.get("name", "producer")) + " will assemble here.", 3.0)
	scene.call("_spawn_effect", "construct", point, Color("72f2bd"), 0.8)
	_play("order")
	return true

func _update_rallies(scene: Node) -> void:
	for unit: Dictionary in scene.get("units") as Array:
		if not bool(unit.get("rally_pending", false)) or not bool(unit.get("ready", true)):
			continue
		unit["order"] = "move"
		unit["target"] = unit.get("rally_target", unit.get("pos", Vector2.ZERO)) as Vector2
		unit["rally_pending"] = false

func _send_to_medbay(scene: Node) -> void:
	var medbay: Dictionary = _producer(scene, "medbay")
	if medbay.is_empty():
		scene.call("flash", "No completed Field Medbay. Press 3, then left-click open terrain to construct one.", 3.0)
		return
	var selected_ids: Array = scene.get("selected") as Array
	if selected_ids.is_empty():
		scene.call("flash", "Select wounded units, then press M to move them into the Medbay healing field.", 3.0)
		return
	var center: Vector2 = medbay.get("pos", Vector2.ZERO) as Vector2
	var moved: int = 0
	for index in range(selected_ids.size()):
		var unit: Dictionary = scene.call("_entity", int(selected_ids[index])) as Dictionary
		if unit.is_empty() or str(unit.get("team", "")) != "authority" or unit.has("size"):
			continue
		unit["order"] = "move"
		unit["target"] = center + _formation(index)
		moved += 1
	if moved > 0:
		scene.call("flash", "MEDBAY ROUTE // %d unit(s) moving to treatment." % moved, 2.0)
		_play("order")

func _formation(index: int) -> Vector2:
	var column: int = index % 3 - 1
	var row: int = index / 3 - 1
	return Vector2(float(column) * 25.0, float(row) * 25.0)

func _heal_units(scene: Node, delta: float) -> void:
	var medbays: Array[Dictionary] = []
	for building: Dictionary in scene.get("buildings") as Array:
		if str(building.get("team", "")) == "authority" and str(building.get("kind", "")) == "medbay" and bool(building.get("done", false)):
			medbays.append(building)
	if medbays.is_empty():
		return
	var healing_count: int = 0
	for unit: Dictionary in scene.get("units") as Array:
		if str(unit.get("team", "")) != "authority" or not bool(unit.get("ready", true)):
			continue
		var hp: float = float(unit.get("hp", 0.0))
		var maximum: float = float(unit.get("max", 0.0))
		if hp >= maximum:
			continue
		var position: Vector2 = unit.get("pos", Vector2.ZERO) as Vector2
		for medbay: Dictionary in medbays:
			if position.distance_to(medbay.get("pos", Vector2.ZERO) as Vector2) <= HEAL_RADIUS:
				unit["hp"] = minf(maximum, hp + HEAL_PER_SECOND * delta)
				healing_count += 1
				break
	if healing_count > 0 and healing_notice <= 0.0:
		healing_notice = 2.0
		scene.call("flash", "FIELD MEDBAY // Healing %d unit(s)." % healing_count, 1.3)

func _first_unit(scene: Node, kind: String) -> Dictionary:
	for unit: Dictionary in scene.get("units") as Array:
		if str(unit.get("team", "")) == "authority" and str(unit.get("kind", "")) == kind and bool(unit.get("ready", true)):
			return unit
	return {}

func _producer(scene: Node, kind: String) -> Dictionary:
	for building: Dictionary in scene.get("buildings") as Array:
		if str(building.get("team", "")) == "authority" and str(building.get("kind", "")) == kind and bool(building.get("done", false)):
			return building
	return {}

func _build_ui() -> void:
	support_canvas = CanvasLayer.new()
	support_canvas.layer = 58
	support_canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(support_canvas)
	support_panel = Panel.new()
	support_panel.position = Vector2(18.0, 205.0)
	support_panel.size = Vector2(405.0, 170.0)
	support_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.018, 0.055, 0.115, 0.94)
	style.border_color = Color("72f2bd")
	style.set_border_width_all(2)
	style.corner_radius_top_left = 9
	style.corner_radius_top_right = 9
	style.corner_radius_bottom_left = 9
	style.corner_radius_bottom_right = 9
	support_panel.add_theme_stylebox_override("panel", style)
	support_canvas.add_child(support_panel)
	prep_text = Label.new()
	prep_text.position = Vector2(12.0, 8.0)
	prep_text.size = Vector2(381.0, 22.0)
	prep_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prep_text.add_theme_font_size_override("font_size", 14)
	support_panel.add_child(prep_text)
	_add_button("ARMORY [1]", Vector2(10.0, 38.0), _button_build_armory)
	_add_button("MEDBAY [3]", Vector2(205.0, 38.0), _button_build_medbay)
	_add_button("DEPUTY [Q]", Vector2(10.0, 76.0), _button_train_deputy)
	_add_button("HEAL [M]", Vector2(205.0, 76.0), _button_heal)
	rally_label = Label.new()
	rally_label.position = Vector2(12.0, 113.0)
	rally_label.size = Vector2(381.0, 22.0)
	rally_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rally_label.add_theme_font_size_override("font_size", 11)
	rally_label.add_theme_color_override("font_color", Color("ffd16a"))
	support_panel.add_child(rally_label)
	help_text = Label.new()
	help_text.position = Vector2(12.0, 137.0)
	help_text.size = Vector2(381.0, 22.0)
	help_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	help_text.add_theme_font_size_override("font_size", 11)
	help_text.add_theme_color_override("font_color", Color("c3dcef"))
	support_panel.add_child(help_text)

func _add_button(text_value: String, position_value: Vector2, action: Callable) -> void:
	var button: Button = Button.new()
	button.text = text_value
	button.position = position_value
	button.size = Vector2(184.0, 30.0)
	button.add_theme_font_size_override("font_size", 11)
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.pressed.connect(action)
	support_panel.add_child(button)

func _button_build_armory() -> void:
	var scene: Node = _scene()
	if scene != null:
		_arm_blueprint(scene, "armory")

func _button_build_medbay() -> void:
	var scene: Node = _scene()
	if scene != null:
		_arm_blueprint(scene, "medbay")

func _button_train_deputy() -> void:
	var scene: Node = _scene()
	if scene != null:
		_train(scene, "deputy")

func _button_heal() -> void:
	var scene: Node = _scene()
	if scene != null:
		_send_to_medbay(scene)

func _refresh_ui(scene: Node) -> void:
	var remaining: float = maxf(0.0, PREP_SECONDS - float(scene.get("mission_clock")))
	var total: int = int(ceil(remaining))
	if remaining > 0.0:
		prep_text.text = "PREPARATION WINDOW // %02d:%02d" % [total / 60, total % 60]
		prep_text.add_theme_color_override("font_color", Color("72f2bd"))
	else:
		prep_text.text = "HOSTILE ASSAULT ACTIVE"
		prep_text.add_theme_color_override("font_color", Color("ff7187"))
	if not build_kind.is_empty():
		rally_label.text = "BLUEPRINT ACTIVE // Left-click terrain to place. Esc cancels."
	else:
		rally_label.text = "RALLY: select Nexus or Armory, then right-click terrain."
	if _producer(scene, "medbay").is_empty():
		help_text.text = "Build a Medbay, then select wounded units and press M."
	else:
		help_text.text = "Completed Medbay heals units automatically in its cyan field."

func _over_support_panel(point: Vector2) -> bool:
	return Rect2(support_panel.position, support_panel.size).has_point(point)

func _play(cue: String) -> void:
	var audio: Node = get_node_or_null("/root/RtsAudio")
	if audio != null:
		audio.call("play_cue", cue)
