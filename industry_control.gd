extends "res://rts_control_fix.gd"

var industry_panel: Panel
var industry_status: Label
var rally_button: Button
var rally_mode_producer_id: int = -1

func _ready() -> void:
	super._ready()
	_build_industry_console()

func _input(event: InputEvent) -> void:
	super._input(event)
	if _picker_open():
		return
	var scene: Node = _scene()
	if scene == null:
		return
	if event is InputEventMouseButton:
		var mouse: InputEventMouseButton = event as InputEventMouseButton
		if mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT and rally_mode_producer_id >= 0 and build_kind.is_empty():
			if not _over_industry_panel(mouse.position) and not _over_support_panel(mouse.position):
				_commit_rally_point(scene, mouse.position)
				get_viewport().set_input_as_handled()
			return
	if not (event is InputEventKey):
		return
	var key: InputEventKey = event as InputEventKey
	if not key.pressed or key.echo:
		return
	match key.keycode:
		KEY_6:
			_arm_blueprint(scene, "sentry_turret")
			get_viewport().set_input_as_handled()
		KEY_7:
			_arm_blueprint(scene, "pulse_cannon")
			get_viewport().set_input_as_handled()
		KEY_8:
			_arm_blueprint(scene, "machine_shop")
			get_viewport().set_input_as_handled()
		KEY_T:
			_train(scene, "bulwark_rover")
			get_viewport().set_input_as_handled()
		KEY_Y:
			_begin_rally_mode(scene)
			get_viewport().set_input_as_handled()
		KEY_ESCAPE:
			if rally_mode_producer_id >= 0:
				_cancel_rally_mode(scene)
				get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	super._process(delta)
	var scene: Node = _scene()
	if industry_panel == null:
		return
	if scene == null:
		industry_panel.visible = false
		rally_mode_producer_id = -1
		return
	industry_panel.visible = not _picker_open()
	if rally_mode_producer_id >= 0 and _rally_producer(scene, rally_mode_producer_id).is_empty():
		rally_mode_producer_id = -1
	_refresh_industry_console(scene)

func _train(scene: Node, kind: String) -> void:
	if kind != "bulwark_rover":
		super._train(scene, kind)
		return
	var shop: Dictionary = _producer(scene, "machine_shop")
	if shop.is_empty():
		scene.call("flash", "Build and finish a Machine Shop before producing Bulwark Rovers.", 3.0)
		return
	var before: int = (scene.get("units") as Array).size()
	scene.set("selected", [])
	scene.set("selected_building", int(shop.get("id", -1)))
	scene.call("_train", kind)
	var units: Array = scene.get("units") as Array
	if units.size() > before:
		var new_unit: Dictionary = units[units.size() - 1] as Dictionary
		var fallback: Vector2 = shop.get("pos", Vector2.ZERO) as Vector2
		fallback += Vector2(168.0, 68.0)
		new_unit["rally_target"] = shop.get("rally_point", fallback) as Vector2
		new_unit["rally_pending"] = true

func _set_rally_from_selection(scene: Node, screen_point: Vector2) -> bool:
	var producer_id: int = int(scene.get("selected_building"))
	var producer: Dictionary = _rally_producer(scene, producer_id)
	if producer.is_empty():
		return false
	_set_rally_point(scene, producer, screen_point)
	return true

func _begin_rally_mode(scene: Node) -> void:
	var producer_id: int = int(scene.get("selected_building"))
	var producer: Dictionary = _rally_producer(scene, producer_id)
	if producer.is_empty():
		scene.call("flash", "Select a Command Nexus, Tactical Armory, or Machine Shop before setting a rally point.", 3.0)
		return
	if not build_kind.is_empty():
		_cancel_blueprint(scene)
	rally_mode_producer_id = producer_id
	if rally_button != null:
		rally_button.text = "CLICK DESTINATION..."
	scene.call("flash", "RALLY MODE // Left-click ground to set a new rally point for " + str(producer.get("name", "this producer")) + ".", 4.0)
	_play("order")

func _commit_rally_point(scene: Node, screen_point: Vector2) -> void:
	var producer: Dictionary = _rally_producer(scene, rally_mode_producer_id)
	if producer.is_empty():
		rally_mode_producer_id = -1
		return
	_set_rally_point(scene, producer, screen_point)
	rally_mode_producer_id = -1
	if rally_button != null:
		rally_button.text = "SET RALLY [Y]"

func _cancel_rally_mode(scene: Node) -> void:
	rally_mode_producer_id = -1
	if rally_button != null:
		rally_button.text = "SET RALLY [Y]"
	scene.call("flash", "Rally mode cancelled.", 1.4)

func _set_rally_point(scene: Node, producer: Dictionary, screen_point: Vector2) -> void:
	var point: Vector2 = scene.call("_screen_to_world", screen_point) as Vector2
	producer["rally_point"] = point
	producer["rally_marker_clock"] = 1.0
	scene.call("flash", "RALLY POINT UPDATED // New units from " + str(producer.get("name", "producer")) + " will assemble at the beacon.", 3.0)
	scene.call("_spawn_effect", "construct", point, Color("72f2bd"), 0.8)
	_play("order")

func _rally_producer(scene: Node, producer_id: int) -> Dictionary:
	if producer_id < 0:
		return {}
	var producer: Dictionary = scene.call("_entity", producer_id) as Dictionary
	if producer.is_empty() or str(producer.get("team", "")) != "authority" or not bool(producer.get("done", false)):
		return {}
	var kind: String = str(producer.get("kind", ""))
	if kind != "nexus" and kind != "armory" and kind != "machine_shop":
		return {}
	return producer

func _build_industry_console() -> void:
	industry_panel = Panel.new()
	industry_panel.position = Vector2(18.0, 382.0)
	industry_panel.size = Vector2(405.0, 202.0)
	industry_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.055, 0.035, 0.105, 0.95)
	style.border_color = Color("b9a4ff")
	style.set_border_width_all(2)
	style.corner_radius_top_left = 9
	style.corner_radius_top_right = 9
	style.corner_radius_bottom_left = 9
	style.corner_radius_bottom_right = 9
	industry_panel.add_theme_stylebox_override("panel", style)
	support_canvas.add_child(industry_panel)
	var title: Label = Label.new()
	title.text = "DEFENSE & VEHICLE WORKS"
	title.position = Vector2(10.0, 8.0)
	title.size = Vector2(385.0, 22.0)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color("d9c4ff"))
	industry_panel.add_child(title)
	_add_industry_button("TURRET [6]", Vector2(10.0, 38.0), _button_turret)
	_add_industry_button("PULSE CANNON [7]", Vector2(205.0, 38.0), _button_cannon)
	_add_industry_button("MACHINE SHOP [8]", Vector2(10.0, 76.0), _button_shop)
	_add_industry_button("BULWARK ROVER [T]", Vector2(205.0, 76.0), _button_rover)
	rally_button = Button.new()
	rally_button.text = "SET RALLY [Y]"
	rally_button.position = Vector2(10.0, 114.0)
	rally_button.size = Vector2(385.0, 30.0)
	rally_button.add_theme_font_size_override("font_size", 12)
	rally_button.mouse_filter = Control.MOUSE_FILTER_STOP
	rally_button.pressed.connect(_button_rally)
	industry_panel.add_child(rally_button)
	industry_status = Label.new()
	industry_status.position = Vector2(12.0, 151.0)
	industry_status.size = Vector2(381.0, 41.0)
	industry_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	industry_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	industry_status.add_theme_font_size_override("font_size", 11)
	industry_status.add_theme_color_override("font_color", Color("d9e6fb"))
	industry_panel.add_child(industry_status)

func _add_industry_button(text_value: String, position_value: Vector2, action: Callable) -> void:
	var button: Button = Button.new()
	button.text = text_value
	button.position = position_value
	button.size = Vector2(184.0, 30.0)
	button.add_theme_font_size_override("font_size", 11)
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.pressed.connect(action)
	industry_panel.add_child(button)

func _button_turret() -> void:
	var scene: Node = _scene()
	if scene != null:
		_arm_blueprint(scene, "sentry_turret")

func _button_cannon() -> void:
	var scene: Node = _scene()
	if scene != null:
		_arm_blueprint(scene, "pulse_cannon")

func _button_shop() -> void:
	var scene: Node = _scene()
	if scene != null:
		_arm_blueprint(scene, "machine_shop")

func _button_rover() -> void:
	var scene: Node = _scene()
	if scene != null:
		_train(scene, "bulwark_rover")

func _button_rally() -> void:
	var scene: Node = _scene()
	if scene != null:
		_begin_rally_mode(scene)

func _refresh_industry_console(scene: Node) -> void:
	if not build_kind.is_empty():
		industry_status.text = "Blueprint armed. Left-click clear terrain to place it."
		return
	if rally_mode_producer_id >= 0:
		industry_status.text = "RALLY MODE ACTIVE: left-click the map to move this producer's assembly point. Esc cancels."
		return
	var selected_producer: Dictionary = _rally_producer(scene, int(scene.get("selected_building")))
	if not selected_producer.is_empty():
		industry_status.text = "Selected " + str(selected_producer.get("name", "producer")) + ". Press Y or SET RALLY, then left-click the map."
		return
	if _producer(scene, "machine_shop").is_empty():
		industry_status.text = "Select Nexus, Armory, or Shop to move its rally. Builders repair damaged structures with right-click."
	else:
		industry_status.text = "Machine Shop online. Set individual rally points for Nexus, Armory, and Shop."

func _over_industry_panel(point: Vector2) -> bool:
	return Rect2(industry_panel.position, industry_panel.size).has_point(point)
