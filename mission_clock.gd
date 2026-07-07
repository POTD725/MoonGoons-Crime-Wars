extends Node
## Controls the first hostile assault window for RTS missions and displays the countdown.

const ASSAULT_INTERVAL_SECONDS: float = 600.0
const HOLD_CLOCK_VALUE: float = -10000.0
const TRIGGER_CLOCK_VALUE: float = 10000.0

var watched_scene_id: int = -1
var next_assault_at: float = ASSAULT_INTERVAL_SECONDS
var canvas: CanvasLayer
var panel: Panel
var headline: Label
var countdown: Label
var status_line: Label

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_overlay()

func _process(_delta: float) -> void:
	var scene: Node = get_tree().current_scene
	if scene == null or not scene.has_method("_spawn_enemy_wave"):
		canvas.visible = false
		watched_scene_id = -1
		return
	if bool(scene.get_meta("faction_picker_active", false)) or bool(scene.get_meta("campaign_debrief_active", false)):
		canvas.visible = false
		return
	if scene.get("enemy_wave_clock") == null or scene.get("mission_clock") == null:
		canvas.visible = false
		return
	if scene.get_instance_id() != watched_scene_id:
		watched_scene_id = scene.get_instance_id()
		next_assault_at = ASSAULT_INTERVAL_SECONDS
	canvas.visible = true
	if bool(scene.get("finished")):
		_update_display(0.0, "MISSION CONCLUDED", Color("8fe9ff"))
		return
	var deployed: bool = bool(scene.get_meta("race_selected", false)) or bool(scene.get_meta("custom_match", false))
	if not deployed:
		scene.set("enemy_wave_clock", HOLD_CLOCK_VALUE)
		canvas.visible = false
		return
	var elapsed: float = float(scene.get("mission_clock"))
	if elapsed >= next_assault_at:
		scene.set("enemy_wave_clock", TRIGGER_CLOCK_VALUE)
		next_assault_at += ASSAULT_INTERVAL_SECONDS
		scene.call("flash", "HOSTILE ASSAULT WINDOW OPEN // DEFEND THE COMMAND NEXUS.", 4.0)
		var audio_service: Node = get_node_or_null("/root/RtsAudio")
		if audio_service != null:
			audio_service.call("play_cue", "alert")
	else:
		scene.set("enemy_wave_clock", HOLD_CLOCK_VALUE)
	var remaining: float = maxf(0.0, next_assault_at - elapsed)
	var color: Color = Color("72f2bd")
	var label: String = "NEXT HOSTILE ASSAULT"
	if remaining <= 60.0:
		color = Color("ff7187")
		label = "HOSTILE ASSAULT IMMINENT"
	elif remaining <= 180.0:
		color = Color("ffc46b")
	_update_display(remaining, label, color)

func _build_overlay() -> void:
	canvas = CanvasLayer.new()
	canvas.layer = 55
	canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(canvas)
	panel = Panel.new()
	panel.position = Vector2(1280.0, 84.0)
	panel.size = Vector2(294.0, 88.0)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.018, 0.055, 0.115, 0.95)
	style.border_color = Color("72f2bd")
	style.set_border_width_all(2)
	style.corner_radius_top_left = 9
	style.corner_radius_top_right = 9
	style.corner_radius_bottom_left = 9
	style.corner_radius_bottom_right = 9
	panel.add_theme_stylebox_override("panel", style)
	canvas.add_child(panel)
	headline = Label.new()
	headline.position = Vector2(12.0, 9.0)
	headline.size = Vector2(270.0, 18.0)
	headline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	headline.add_theme_font_size_override("font_size", 12)
	panel.add_child(headline)
	countdown = Label.new()
	countdown.position = Vector2(12.0, 25.0)
	countdown.size = Vector2(270.0, 35.0)
	countdown.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	countdown.add_theme_font_size_override("font_size", 28)
	panel.add_child(countdown)
	status_line = Label.new()
	status_line.position = Vector2(12.0, 62.0)
	status_line.size = Vector2(270.0, 16.0)
	status_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_line.add_theme_font_size_override("font_size", 11)
	status_line.add_theme_color_override("font_color", Color("b9d5ed"))
	status_line.text = "10:00 BUILD AND DEFEND WINDOW"
	panel.add_child(status_line)

func _update_display(seconds_remaining: float, label: String, color: Color) -> void:
	var total_seconds: int = maxi(0, int(ceil(seconds_remaining)))
	var minutes: int = total_seconds / 60
	var seconds: int = total_seconds % 60
	headline.text = label
	headline.add_theme_color_override("font_color", color)
	countdown.text = "%02d:%02d" % [minutes, seconds]
	countdown.add_theme_color_override("font_color", color.lightened(0.18))
	var panel_style: StyleBoxFlat = panel.get_theme_stylebox("panel") as StyleBoxFlat
	if panel_style != null:
		panel_style.border_color = color
