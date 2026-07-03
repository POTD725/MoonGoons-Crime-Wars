extends Node
## First screen shown when the game opens. The faction picker follows Story launch.

var canvas: CanvasLayer
var screen: Control
var shown_for_scene := -1

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()

func _process(_delta: float) -> void:
	var current: Node = get_tree().current_scene
	if current == null:
		return
	if current.has_method("_spawn_unit") and current.get_instance_id() != shown_for_scene:
		shown_for_scene = current.get_instance_id()
		screen.visible = true
		get_tree().paused = true

func _build() -> void:
	canvas = CanvasLayer.new()
	canvas.layer = 60
	canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(canvas)
	screen = Control.new()
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.mouse_filter = Control.MOUSE_FILTER_STOP
	canvas.add_child(screen)
	var background := ColorRect.new()
	background.color = Color("050b18")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.add_child(background)
	var logo := TextureRect.new()
	logo.texture = GameArtLibrary.MOONGOONS_LOGO
	logo.position = Vector2(360, 72)
	logo.size = Vector2(880, 190)
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen.add_child(logo)
	var subtitle := Label.new()
	subtitle.text = "CRIME WARS // LUNAR CIVIC COMMAND"
	subtitle.position = Vector2(200, 260)
	subtitle.size = Vector2(1200, 30)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 20)
	subtitle.add_theme_color_override("font_color", Color("8fe9ff"))
	screen.add_child(subtitle)
	var brief := Label.new()
	brief.text = "Choose a first response, build your precinct, and decide whose version of lunar justice survives the next siren."
	brief.position = Vector2(250, 302)
	brief.size = Vector2(1100, 32)
	brief.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	brief.add_theme_font_size_override("font_size", 16)
	brief.add_theme_color_override("font_color", Color("c7d9ec"))
	screen.add_child(brief)
	_add_button("START OPERATION BREAKWATER", 385, _start_story)
	_add_button("CUSTOM GAME WAR ROOM", 452, _open_custom)
	_add_button("FREE ROAM // FRACTURE BELT", 519, _open_roam)
	_add_button("SETTINGS", 586, _open_settings)
	var footer := Label.new()
	footer.text = "F2 Mode Hub  •  F4 Difficulty  •  F7 Officer Roster  •  F8 Chat  •  P Pause"
	footer.position = Vector2(260, 722)
	footer.size = Vector2(1080, 26)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.add_theme_font_size_override("font_size", 14)
	footer.add_theme_color_override("font_color", Color("8ba4c0"))
	screen.add_child(footer)
	screen.visible = false

func _add_button(text: String, y: float, action: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.position = Vector2(520, y)
	button.size = Vector2(560, 52)
	button.add_theme_font_size_override("font_size", 18)
	button.pressed.connect(action)
	screen.add_child(button)

func _start_story() -> void:
	screen.visible = false
	get_tree().paused = false

func _open_custom() -> void:
	screen.visible = false
	get_tree().paused = false
	get_tree().change_scene_to_file("res://custom_game.tscn")

func _open_roam() -> void:
	screen.visible = false
	get_tree().paused = false
	get_tree().change_scene_to_file("res://free_roam.tscn")

func _open_settings() -> void:
	SettingsConsole.get("panel").visible = true
