extends Node
## Campaign debrief and next-operation transition for the first playable campaign arc.

const PLAYABLE_STAGES: Array[String] = ["CW-001", "CW-002", "CW-003"]

var canvas: CanvasLayer
var panel: Control
var title_label: Label
var body_label: Label
var continue_button: Button
var handled_scene_id: int = -1

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_panel()

func _process(_delta: float) -> void:
	var current_scene: Node = get_tree().current_scene
	if current_scene == null or not current_scene.has_meta("campaign_mission_id"):
		panel.visible = false
		return
	if not bool(current_scene.get("finished")) or not bool(current_scene.get("victory")):
		return
	var scene_id: int = current_scene.get_instance_id()
	if scene_id == handled_scene_id:
		return
	handled_scene_id = scene_id
	_show_debrief(current_scene)

func _build_panel() -> void:
	canvas = CanvasLayer.new()
	canvas.layer = 60
	canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(canvas)
	panel = Control.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	canvas.add_child(panel)

	var shade: ColorRect = ColorRect.new()
	shade.color = Color(0.004, 0.012, 0.032, 0.96)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.add_child(shade)

	var frame: Panel = Panel.new()
	frame.position = Vector2(320.0, 195.0)
	frame.size = Vector2(960.0, 470.0)
	frame.add_theme_stylebox_override("panel", _frame_style())
	panel.add_child(frame)

	title_label = Label.new()
	title_label.position = Vector2(44.0, 46.0)
	title_label.size = Vector2(872.0, 48.0)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 31)
	title_label.add_theme_color_override("font_color", Color("8fe9ff"))
	frame.add_child(title_label)

	body_label = Label.new()
	body_label.position = Vector2(86.0, 126.0)
	body_label.size = Vector2(788.0, 180.0)
	body_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_label.add_theme_font_size_override("font_size", 18)
	body_label.add_theme_color_override("font_color", Color("eaf5ff"))
	frame.add_child(body_label)

	continue_button = Button.new()
	continue_button.position = Vector2(230.0, 352.0)
	continue_button.size = Vector2(500.0, 62.0)
	continue_button.add_theme_font_size_override("font_size", 18)
	continue_button.add_theme_stylebox_override("normal", _button_style(Color("183d59"), Color("8fe9ff")))
	continue_button.add_theme_stylebox_override("hover", _button_style(Color("235a80"), Color("ffffff")))
	continue_button.pressed.connect(_continue_campaign)
	frame.add_child(continue_button)
	panel.visible = false

func _show_debrief(scene: Node) -> void:
	var mission_id: String = str(scene.get_meta("campaign_mission_id", "CW-001"))
	var mission: Dictionary = CampaignData.get_mission(mission_id)
	var score: int = int(scene.get("credits")) + int(scene.get("supplies")) * 2 + int(scene.get("intel")) * 3
	GameProfile.complete_mission(mission_id, score)
	var stage_index: int = PLAYABLE_STAGES.find(mission_id)
	var has_next: bool = stage_index >= 0 and stage_index < PLAYABLE_STAGES.size() - 1
	var next_id: String = PLAYABLE_STAGES[stage_index + 1] if has_next else "CAMPAIGN ARC COMPLETE"
	var next_mission: Dictionary = CampaignData.get_mission(next_id) if has_next else {}
	title_label.text = "%s COMPLETE" % mission_id
	body_label.text = "%s\n\nSCORE: %d\n\n%s" % [str(mission.get("title", "Operation")), score, "NEXT OPERATION // %s: %s" % [next_id, str(next_mission.get("title", ""))] if has_next else "THE BROKEN DOCKS ARC IS COMPLETE. You can replay the chapter or continue through the campaign board."]
	continue_button.text = "DEPLOY %s" % next_id if has_next else "REPLAY CHAPTER"
	scene.set_meta("campaign_debrief_active", true)
	panel.visible = true
	get_tree().paused = true

func _continue_campaign() -> void:
	panel.visible = false
	get_tree().paused = false
	get_tree().reload_current_scene()

func _frame_style() -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color("091a31")
	style.border_color = Color("65cfff")
	style.set_border_width_all(3)
	style.corner_radius_top_left = 18
	style.corner_radius_top_right = 18
	style.corner_radius_bottom_left = 18
	style.corner_radius_bottom_right = 18
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.55)
	style.shadow_size = 18
	return style

func _button_style(background: Color, border: Color) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(2)
	style.corner_radius_top_left = 9
	style.corner_radius_top_right = 9
	style.corner_radius_bottom_left = 9
	style.corner_radius_bottom_right = 9
	return style
