extends Node
## Converts the RTS sandbox into a clear first playable mission.

var mission: Node
var mission_id := -1
var canvas: CanvasLayer
var objective_box: Panel
var objective_title: Label
var objective_text: Label
var result_panel: Panel
var result_title: Label
var result_text: Label
var result_saved := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()

func _process(_delta: float) -> void:
	var current := get_tree().current_scene
	if current == null or not current.has_method("_spawn_unit") or not current.has_method("_spawn_building"):
		mission = null
		canvas.visible = false
		return
	if current.get_instance_id() != mission_id:
		mission = current
		mission_id = current.get_instance_id()
		result_saved = false
	canvas.visible = true
	_update_objective()
	_update_result()

func _update_objective() -> void:
	if mission == null:
		return
	var is_custom := bool(mission.get_meta("custom_match", false))
	var armory_online := false
	var relay_alive := false
	for building in mission.get("buildings"):
		if building.get("team", "") == "authority" and building.get("kind", "") == "armory" and bool(building.get("done", false)):
			armory_online = true
		if building.get("team", "") == "syndicate" and building.get("kind", "") == "syndicate_relay":
			relay_alive = true
	if is_custom:
		objective_title.text = "CUSTOM BATTLE OBJECTIVE"
		objective_text.text = "Establish your economy, command your squad, and destroy every hostile command structure. Scenario: %s." % str(mission.get_meta("custom_scenario", "standard")).replace("_", " ").to_upper()
		return
	objective_title.text = "OPERATION BREAKWATER // CW-001"
	if not armory_online:
		objective_text.text = "1. Select a Builder Drone.  2. Press 1 or use the Command Deck.  3. Build a Tactical Armory."
	elif relay_alive:
		objective_text.text = "Armory online. Train Shield Deputies, secure resources, then destroy the Syndicate Relay."
	else:
		objective_text.text = "Relay neutralized. Secure the dockyard and prepare your report."

func _update_result() -> void:
	if mission == null:
		return
	var finished := bool(mission.get("finished"))
	result_panel.visible = finished
	if not finished:
		return
	var won := bool(mission.get("victory"))
	if won:
		result_title.text = "MISSION COMPLETE // BREAKWATER SECURED"
		result_text.text = "The Syndicate Relay is silent. Armory plans recovered. 300 Credits and the next operation are now available."
		if not result_saved:
			GameProfile.complete_mission("CW-001", int(mission.get("credits")) + int(mission.get("intel")) * 10)
			result_saved = true
	else:
		result_title.text = "MISSION FAILED // COMMAND NEXUS LOST"
		result_text.text = "The dockyard fell, but the case remains open. Rebuild the response and return with a stronger squad."

func _restart() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://main.tscn")

func _open_hub() -> void:
	get_tree().paused = false
	if ModeHub != null and ModeHub.get("overlay") != null:
		ModeHub.get("overlay").visible = true
		get_tree().paused = true

func _build_ui() -> void:
	canvas = CanvasLayer.new()
	canvas.layer = 46
	canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(canvas)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(root)

	objective_box = Panel.new()
	objective_box.position = Vector2(18, 92)
	objective_box.size = Vector2(430, 96)
	var objective_style := StyleBoxFlat.new()
	objective_style.bg_color = Color(0.02, 0.07, 0.13, 0.94)
	objective_style.border_color = Color("8fe9ff")
	objective_style.set_border_width_all(2)
	objective_style.corner_radius_top_left = 8
	objective_style.corner_radius_top_right = 8
	objective_style.corner_radius_bottom_left = 8
	objective_style.corner_radius_bottom_right = 8
	objective_box.add_theme_stylebox_override("panel", objective_style)
	root.add_child(objective_box)
	objective_title = Label.new()
	objective_title.position = Vector2(14, 10)
	objective_title.size = Vector2(400, 20)
	objective_title.add_theme_font_size_override("font_size", 14)
	objective_title.add_theme_color_override("font_color", Color("8fe9ff"))
	objective_box.add_child(objective_title)
	objective_text = Label.new()
	objective_text.position = Vector2(14, 34)
	objective_text.size = Vector2(400, 52)
	objective_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	objective_text.add_theme_font_size_override("font_size", 13)
	objective_text.add_theme_color_override("font_color", Color("e8f5ff"))
	objective_box.add_child(objective_text)

	result_panel = Panel.new()
	result_panel.position = Vector2(390, 250)
	result_panel.size = Vector2(820, 350)
	result_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var result_style := StyleBoxFlat.new()
	result_style.bg_color = Color(0.02, 0.04, 0.10, 0.97)
	result_style.border_color = Color("efc75e")
	result_style.set_border_width_all(3)
	result_style.corner_radius_top_left = 16
	result_style.corner_radius_top_right = 16
	result_style.corner_radius_bottom_left = 16
	result_style.corner_radius_bottom_right = 16
	result_panel.add_theme_stylebox_override("panel", result_style)
	root.add_child(result_panel)
	result_title = Label.new()
	result_title.position = Vector2(30, 48)
	result_title.size = Vector2(760, 46)
	result_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_title.add_theme_font_size_override("font_size", 26)
	result_title.add_theme_color_override("font_color", Color("efc75e"))
	result_panel.add_child(result_title)
	result_text = Label.new()
	result_text.position = Vector2(90, 110)
	result_text.size = Vector2(640, 84)
	result_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result_text.add_theme_font_size_override("font_size", 16)
	result_text.add_theme_color_override("font_color", Color("eaf5ff"))
	result_panel.add_child(result_text)
	var restart := Button.new()
	restart.text = "RETRY OPERATION"
	restart.position = Vector2(150, 250)
	restart.size = Vector2(235, 52)
	restart.pressed.connect(_restart)
	result_panel.add_child(restart)
	var hub := Button.new()
	hub.text = "MODE HUB"
	hub.position = Vector2(435, 250)
	hub.size = Vector2(235, 52)
	hub.pressed.connect(_open_hub)
	result_panel.add_child(hub)
	result_panel.visible = false
