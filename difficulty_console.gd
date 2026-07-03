extends Node

var canvas: CanvasLayer
var panel: Panel

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F4:
		panel.visible = not panel.visible
		get_tree().paused = panel.visible
		get_viewport().set_input_as_handled()

func _build() -> void:
	canvas = CanvasLayer.new()
	canvas.layer = 56
	canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(canvas)
	panel = Panel.new()
	panel.position = Vector2(540, 230)
	panel.size = Vector2(520, 360)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	canvas.add_child(panel)
	var title := Label.new()
	title.text = "GLOBAL DIFFICULTY"
	title.position = Vector2(30, 24)
	title.size = Vector2(460, 32)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	panel.add_child(title)
	var ids: Array[String] = GameDifficulty.all_ids()
	for index: int in ids.size():
		var id: String = ids[index]
		var button := Button.new()
		button.text = str(GameDifficulty.LEVELS[id].get("name", id))
		button.position = Vector2(70 + (index % 2) * 200, 90 + (index / 2) * 78)
		button.size = Vector2(180, 58)
		button.pressed.connect(_choose.bind(id))
		panel.add_child(button)
	var close := Button.new()
	close.text = "RETURN"
	close.position = Vector2(150, 278)
	close.size = Vector2(220, 44)
	close.pressed.connect(func(): panel.visible = false; get_tree().paused = false)
	panel.add_child(close)
	panel.visible = false

func _choose(level_id: String) -> void:
	GameDifficulty.set_level(level_id)
	var game: Node = get_tree().current_scene
	if game != null and game.has_method("flash"):
		game.call("flash", "Difficulty set to " + GameDifficulty.label(), 2.0)
	panel.visible = false
	get_tree().paused = false
