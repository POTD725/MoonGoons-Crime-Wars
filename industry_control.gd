extends "res://rts_control_fix.gd"

var industry_panel: Panel
var industry_status: Label

func _ready() -> void:
	super._ready()
	_build_industry_console()

func _input(event: InputEvent) -> void:
	super._input(event)
	if _picker_open() or not (event is InputEventKey):
		return
	var key: InputEventKey = event as InputEventKey
	if not key.pressed or key.echo:
		return
	var scene: Node = _scene()
	if scene == null:
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

func _process(delta: float) -> void:
	super._process(delta)
	var scene: Node = _scene()
	if industry_panel == null:
		return
	if scene == null:
		industry_panel.visible = false
		return
	industry_panel.visible = not _picker_open()
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
	var selected_building: int = int(scene.get("selected_building"))
	if selected_building < 0:
		return false
	var producer: Dictionary = scene.call("_entity", selected_building) as Dictionary
	if producer.is_empty() or str(producer.get("team", "")) != "authority":
		return false
	var kind: String = str(producer.get("kind", ""))
	if kind != "nexus" and kind != "armory" and kind != "machine_shop":
		return false
	var point: Vector2 = scene.call("_screen_to_world", screen_point) as Vector2
	producer["rally_point"] = point
	scene.call("flash", "RALLY POINT SET // New units from " + str(producer.get("name", "producer")) + " will assemble here.", 3.0)
	scene.call("_spawn_effect", "construct", point, Color("72f2bd"), 0.8)
	_play("order")
	return true

func _build_industry_console() -> void:
	industry_panel = Panel.new()
	industry_panel.position = Vector2(18.0, 382.0)
	industry_panel.size = Vector2(405.0, 162.0)
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
	industry_status = Label.new()
	industry_status.position = Vector2(12.0, 119.0)
	industry_status.size = Vector2(381.0, 30.0)
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

func _refresh_industry_console(scene: Node) -> void:
	if not build_kind.is_empty():
		industry_status.text = "Blueprint armed. Left-click clear terrain to place it."
		return
	if _producer(scene, "machine_shop").is_empty():
		industry_status.text = "Build a Machine Shop to produce the armored Bulwark Rover."
	else:
		industry_status.text = "Machine Shop online. Select it, right-click terrain for a rally point, then press T."
