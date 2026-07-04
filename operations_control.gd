extends "res://command_surface.gd"
## Input bridge for targetable air support.

var air_support_targeting: bool = false

func _input(event: InputEvent) -> void:
	if air_support_targeting:
		var scene: Node = _scene()
		if scene == null:
			air_support_targeting = false
		elif event is InputEventMouseButton:
			var mouse: InputEventMouseButton = event as InputEventMouseButton
			if mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT:
				if not _over_support_panel(mouse.position) and not _over_industry_panel(mouse.position):
					scene.call("_request_air_strike", scene.call("_screen_to_world", mouse.position) as Vector2)
					air_support_targeting = false
					get_viewport().set_input_as_handled()
					return
		elif event is InputEventKey:
			var target_key: InputEventKey = event as InputEventKey
			if target_key.pressed and not target_key.echo and target_key.keycode == KEY_ESCAPE:
				_cancel_air_support(scene)
				get_viewport().set_input_as_handled()
				return
	super._input(event)
	if _picker_open() or not (event is InputEventKey):
		return
	var key: InputEventKey = event as InputEventKey
	if not key.pressed or key.echo:
		return
	var active_scene: Node = _scene()
	if active_scene == null:
		return
	if key.keycode == KEY_Z:
		_begin_air_support(active_scene)
		get_viewport().set_input_as_handled()

func _begin_air_support(scene: Node) -> void:
	if not scene.has_method("_request_air_strike"):
		return
	if not build_kind.is_empty():
		_cancel_blueprint(scene)
	if rally_mode_producer_id >= 0:
		_cancel_rally_mode(scene)
	air_support_targeting = true
	scene.call("flash", "AIR STRIKE TARGETING // Left-click hostile ground. Esc cancels. Cost: 25 Intel.", 4.0)
	_play("order")

func _cancel_air_support(scene: Node) -> void:
	if not air_support_targeting:
		return
	air_support_targeting = false
	if scene != null:
		scene.call("flash", "Air support targeting cancelled.", 1.5)

func _cancel_all_targeting(scene: Node) -> void:
	_cancel_air_support(scene)
	_cancel_rally_mode(scene)
	_cancel_blueprint(scene)
