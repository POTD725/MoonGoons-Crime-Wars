extends Node
## Mission preparation, quick production, and Medbay support for the playable RTS slice.

const PREPARATION_SECONDS: float = 600.0
const FROZEN_WAVE_CLOCK: float = -10000.0
const MEDBAY_RADIUS: float = 170.0
const MEDBAY_HEAL_PER_SECOND: float = 24.0

var scene_id: int = -1
var canvas: CanvasLayer
var panel: Panel
var prep_label: Label
var support_label: Label
var heal_notice_cooldown: float = 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_support_panel()

func _process(delta: float) -> void:
	heal_notice_cooldown = maxf(0.0, heal_notice_cooldown - delta)
	var scene: Node = _active_rts_scene()
	if scene == null:
		canvas.visible = false
		scene_id = -1
		return
	canvas.visible = not _picker_is_open()
	if scene.get_instance_id() != scene_id:
		scene_id = scene.get_instance_id()
		_prepare_new_mission(scene)
	_update_preparation_lock(scene)
	_apply_medbay_healing(scene, delta)
	_refresh_support_panel(scene)

func _input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var key_event: InputEventKey = event as InputEventKey
	if not key_event.pressed or key_event.echo or _picker_is_open():
		return
	var scene: Node = _active_rts_scene()
	if scene == null:
		return
	match key_event.keycode:
		KEY_1:
			_quick_build("armory")
			get_viewport().set_input_as_handled()
		KEY_2:
			_quick_build("relay")
			get_viewport().set_input_as_handled()
		KEY_3:
			_quick_build("medbay")
			get_viewport().set_input_as_handled()
		KEY_4:
			_quick_build("bay")
			get_viewport().set_input_as_handled()
		KEY_5:
			_quick_build("cells")
			get_viewport().set_input_as_handled()
		KEY_Q:
			_quick_train("deputy")
			get_viewport().set_input_as_handled()
		KEY_E:
			_quick_train("drone")
			get_viewport().set_input_as_handled()
		KEY_R:
			_quick_train("shield")
			get_viewport().set_input_as_handled()
		KEY_M:
			_send_selected_to_medbay()
			get_viewport().set_input_as_handled()

func _active_rts_scene() -> Node:
	var scene: Node = get_tree().current_scene
	if scene == null:
		return null
	if not scene.has_method("_spawn_enemy_wave") or not scene.has_method("_begin_build") or not scene.has_method("_train"):
		return null
	return scene

func _picker_is_open() -> bool:
	return RaceMode != null and RaceMode.picker != null and RaceMode.picker.visible

func _prepare_new_mission(scene: Node) -> void:
	scene.set("enemy_wave_clock", FROZEN_WAVE_CLOCK)
	scene.set_meta("preparation_active", true)
	_lock_hostiles(scene)
	scene.call("flash", "PREPARATION WINDOW // You have 10:00 to build, train, and set your defense.", 5.0)

func _update_preparation_lock(scene: Node) -> void:
	var deployed: bool = bool(scene.get_meta("race_selected", false)) or bool(scene.get_meta("custom_match", false))
	if not deployed:
		scene.set("enemy_wave_clock", FROZEN_WAVE_CLOCK)
		_lock_hostiles(scene)
		return
	var elapsed: float = float(scene.get("mission_clock"))
	if elapsed < PREPARATION_SECONDS:
		scene.set("enemy_wave_clock", FROZEN_WAVE_CLOCK)
		scene.set_meta("preparation_active", true)
		_lock_hostiles(scene)
		return
	if bool(scene.get_meta("preparation_active", false)):
		scene.set_meta("preparation_active", false)
		_unlock_hostiles(scene)
		scene.set("enemy_wave_clock", 10000.0)
		scene.call("flash", "HOSTILE ASSAULT ACTIVE // Initial Cartel force released. Defend the Command Nexus.", 4.0)
		var audio_service: Node = get_node_or_null("/root/RtsAudio")
		if audio_service != null:
			audio_service.call("play_cue", "alert")

func _lock_hostiles(scene: Node) -> void:
	for unit: Dictionary in scene.get("units") as Array:
		if str(unit.get("team", "")) != "syndicate":
			continue
		if not bool(unit.get("prep_locked", false)):
			unit["prep_locked"] = true
			unit["prep_speed"] = float(unit.get("speed", 0.0))
			unit["prep_range"] = float(unit.get("range", 0.0))
			unit["prep_damage"] = float(unit.get("damage", 0.0))
		unit["speed"] = 0.0
		unit["range"] = 0.0
		unit["damage"] = 0.0
		unit["order"] = "holding"

func _unlock_hostiles(scene: Node) -> void:
	for unit: Dictionary in scene.get("units") as Array:
		if str(unit.get("team", "")) != "syndicate" or not bool(unit.get("prep_locked", false)):
			continue
		unit["speed"] = float(unit.get("prep_speed", unit.get("speed", 0.0)))
		unit["range"] = float(unit.get("prep_range", unit.get("range", 0.0)))
		unit["damage"] = float(unit.get("prep_damage", unit.get("damage", 0.0)))
		unit["prep_locked"] = false
		unit["order"] = "idle"

func _quick_build(kind: String) -> void:
	var scene: Node = _active_rts_scene()
	if scene == null:
		return
	var drone: Dictionary = _first_authority_unit(scene, "drone")
	if drone.is_empty():
		scene.call("flash", "No Builder Drone is available. Train one from the Command Nexus with E.", 3.0)
		return
	scene.set("selected", [int(drone.get("id", -1))])
	scene.set("selected_building", -1)
	scene.call("_begin_build", kind)

func _quick_train(kind: String) -> void:
	var scene: Node = _active_rts_scene()
	if scene == null:
		return
	var producer_kind: String = "armory" if kind == "shield" else "nexus"
	var producer: Dictionary = _first_completed_building(scene, producer_kind)
	if producer.is_empty():
		var hint: String = "Build a Tactical Armory with 1 before training Shield Deputies." if kind == "shield" else "Your Command Nexus is unavailable."
		scene.call("flash", hint, 3.0)
		return
	scene.set("selected", [])
	scene.set("selected_building", int(producer.get("id", -1)))
	scene.call("_train", kind)

func _send_selected_to_medbay() -> void:
	var scene: Node = _active_rts_scene()
	if scene == null:
		return
	var medbay: Dictionary = _first_completed_building(scene, "medbay")
	if medbay.is_empty():
		scene.call("flash", "No Field Medbay online. Press 3, then click clear terrain to build one.", 3.5)
		return
	var selected_ids: Array = scene.get("selected") as Array
	if selected_ids.is_empty():
		scene.call("flash", "Select wounded troops, then press M to send them to the Field Medbay.", 3.0)
		return
	var medbay_position: Vector2 = medbay.get("pos", Vector2.ZERO) as Vector2
	var moved: int = 0
	for index: int in selected_ids.size():
		var entity: Dictionary = scene.call("_entity", int(selected_ids[index])) as Dictionary
		if entity.is_empty() or str(entity.get("team", "")) != "authority" or entity.has("size"):
			continue
		entity["order"] = "move"
		entity["target"] = medbay_position + _formation_offset(index)
		moved += 1
	if moved > 0:
		scene.call("flash", "MEDBAY ROUTE // %d unit(s) moving to Field Medbay. Healing starts inside the cyan ring." % moved, 3.0)
		var audio_service: Node = get_node_or_null("/root/RtsAudio")
		if audio_service != null:
			audio_service.call("play_cue", "order")

func _formation_offset(index: int) -> Vector2:
	var column: int = index % 3 - 1
	var row: int = index / 3 - 1
	return Vector2(float(column) * 26.0, float(row) * 26.0)

func _apply_medbay_healing(scene: Node, delta: float) -> void:
	var medbays: Array[Dictionary] = []
	for building: Dictionary in scene.get("buildings") as Array:
		if str(building.get("team", "")) == "authority" and str(building.get("kind", "")) == "medbay" and bool(building.get("done", false)):
			medbays.append(building)
	if medbays.is_empty():
		return
	var healed_units: int = 0
	for unit: Dictionary in scene.get("units") as Array:
		if str(unit.get("team", "")) != "authority" or not bool(unit.get("ready", true)):
			continue
		var maximum: float = float(unit.get("max", 0.0))
		var current: float = float(unit.get("hp", 0.0))
		if current >= maximum:
			continue
		var unit_position: Vector2 = unit.get("pos", Vector2.ZERO) as Vector2
		for medbay: Dictionary in medbays:
			var medbay_position: Vector2 = medbay.get("pos", Vector2.ZERO) as Vector2
			if unit_position.distance_to(medbay_position) <= MEDBAY_RADIUS:
				unit["hp"] = minf(maximum, current + MEDBAY_HEAL_PER_SECOND * delta)
				unit["hit_flash"] = 0.0
				healed_units += 1
				break
	if healed_units > 0 and heal_notice_cooldown <= 0.0:
		heal_notice_cooldown = 2.0
		scene.call("flash", "FIELD MEDBAY // Restoring %d unit(s)." % healed_units, 1.5)

func _first_authority_unit(scene: Node, kind: String) -> Dictionary:
	for unit: Dictionary in scene.get("units") as Array:
		if str(unit.get("team", "")) == "authority" and str(unit.get("kind", "")) == kind and bool(unit.get("ready", true)):
			return unit
	return {}

func _first_completed_building(scene: Node, kind: String) -> Dictionary:
	for building: Dictionary in scene.get("buildings") as Array:
		if str(building.get("team", "")) == "authority" and str(building.get("kind", "")) == kind and bool(building.get("done", false)):
			return building
	return {}

func _build_support_panel() -> void:
	canvas = CanvasLayer.new()
	canvas.layer = 56
	canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(canvas)
	panel = Panel.new()
	panel.position = Vector2(18.0, 205.0)
	panel.size = Vector2(405.0, 148.0)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.018, 0.055, 0.115, 0.94)
	style.border_color = Color("72f2bd")
	style.set_border_width_all(2)
	style.corner_radius_top_left = 9
	style.corner_radius_top_right = 9
	style.corner_radius_bottom_left = 9
	style.corner_radius_bottom_right = 9
	panel.add_theme_stylebox_override("panel", style)
	canvas.add_child(panel)
	prep_label = Label.new()
	prep_label.position = Vector2(12.0, 10.0)
	prep_label.size = Vector2(381.0, 22.0)
	prep_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prep_label.add_theme_font_size_override("font_size", 14)
	prep_label.add_theme_color_override("font_color", Color("72f2bd"))
	panel.add_child(prep_label)
	_add_support_button("BUILD ARMORY [1]", Vector2(10.0, 40.0), _quick_build.bind("armory"))
	_add_support_button("BUILD MEDBAY [3]", Vector2(205.0, 40.0), _quick_build.bind("medbay"))
	_add_support_button("TRAIN DEPUTY [Q]", Vector2(10.0, 78.0), _quick_train.bind("deputy"))
	_add_support_button("HEAL SELECTED [M]", Vector2(205.0, 78.0), _send_selected_to_medbay)
	support_label = Label.new()
	support_label.position = Vector2(12.0, 119.0)
	support_label.size = Vector2(381.0, 18.0)
	support_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	support_label.add_theme_font_size_override("font_size", 11)
	support_label.add_theme_color_override("font_color", Color("c3dcef"))
	panel.add_child(support_label)

func _add_support_button(label_text: String, position_value: Vector2, action: Callable) -> void:
	var button: Button = Button.new()
	button.text = label_text
	button.position = position_value
	button.size = Vector2(184.0, 30.0)
	button.add_theme_font_size_override("font_size", 11)
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.pressed.connect(action)
	panel.add_child(button)

func _refresh_support_panel(scene: Node) -> void:
	var elapsed: float = float(scene.get("mission_clock"))
	var remaining: float = maxf(0.0, PREPARATION_SECONDS - elapsed)
	var total: int = int(ceil(remaining))
	prep_label.text = "PREPARATION WINDOW // %02d:%02d" % [total / 60, total % 60]
	if elapsed >= PREPARATION_SECONDS:
		prep_label.text = "HOSTILE ASSAULT ACTIVE"
		prep_label.add_theme_color_override("font_color", Color("ff7187"))
	else:
		prep_label.add_theme_color_override("font_color", Color("72f2bd"))
	var medbay: Dictionary = _first_completed_building(scene, "medbay")
	if medbay.is_empty():
		support_label.text = "Build a Medbay, then select wounded units and press M."
	else:
		support_label.text = "Medbay online: units heal automatically in its cyan field."
