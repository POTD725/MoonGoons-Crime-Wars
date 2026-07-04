extends "res://force_control.gd"
## Canonical build controls for the MoonGoons economy and Command Capacity systems.

const PREP_WINDOW_SECONDS: float = 45.0

func _setup_scene(scene: Node) -> void:
	super._setup_scene(scene)
	scene.call("flash", "PREPARATION WINDOW // 00:45 to establish a precinct before hostile operations activate.", 4.0)

func _update_protection(scene: Node) -> void:
	var deployed: bool = bool(scene.get_meta("race_selected", false)) or bool(scene.get_meta("custom_match", false))
	if not deployed or float(scene.get("mission_clock")) < PREP_WINDOW_SECONDS:
		scene.set("enemy_wave_clock", FREEZE_CLOCK)
		scene.set_meta("protected_prep", true)
		_lock_enemy_units(scene)
		return
	if bool(scene.get_meta("protected_prep", false)):
		scene.set_meta("protected_prep", false)
		_unlock_enemy_units(scene)
		scene.set("enemy_wave_clock", 10000.0)
		scene.call("flash", "HOSTILE ASSAULT ACTIVE // Secure districts and protect the Command Nexus.", 4.0)
		_play("alert")

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
		KEY_9:
			_arm_blueprint(scene, "evidence_vault")
			get_viewport().set_input_as_handled()
		KEY_0:
			_arm_blueprint(scene, "orbital_watchtower")
			get_viewport().set_input_as_handled()
		KEY_U:
			if scene.has_method("_upgrade_command_nexus"):
				scene.call("_upgrade_command_nexus")
			get_viewport().set_input_as_handled()
		KEY_L:
			if scene.has_method("_research_leadership"):
				scene.call("_research_leadership")
			get_viewport().set_input_as_handled()

func _arm_blueprint(scene: Node, kind: String) -> void:
	if scene.has_method("_can_begin_structure") and not bool(scene.call("_can_begin_structure", kind)):
		return
	super._arm_blueprint(scene, kind)

func _place_structure(scene: Node, screen_point: Vector2) -> void:
	var pending_kind: String = build_kind
	var before_count: int = (scene.get("buildings") as Array).size()
	super._place_structure(scene, screen_point)
	var after_count: int = (scene.get("buildings") as Array).size()
	if after_count > before_count and scene.has_method("_consume_structure_alloy"):
		scene.call("_consume_structure_alloy", pending_kind)
