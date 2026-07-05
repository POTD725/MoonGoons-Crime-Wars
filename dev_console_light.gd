extends Node
## Optional local developer console.
## Plain F9 is deliberately left untouched so it can never capture gameplay input.
## Open only with Ctrl+Alt+F9, then click the command field when you want to type.

var canvas: CanvasLayer
var panel: Panel
var input: LineEdit
var output: Label

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()

func _input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var key_event: InputEventKey = event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
	if key_event.keycode == KEY_F9 and key_event.ctrl_pressed and key_event.alt_pressed:
		_set_console_visible(not panel.visible)
		get_viewport().set_input_as_handled()
		return
	if key_event.keycode == KEY_ESCAPE and panel.visible:
		_set_console_visible(false)
		get_viewport().set_input_as_handled()

func _set_console_visible(should_show: bool) -> void:
	if panel == null:
		return
	panel.visible = should_show
	if not should_show and input != null:
		input.release_focus()
		input.clear()

func _build() -> void:
	canvas = CanvasLayer.new()
	canvas.layer = 70
	canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(canvas)
	panel = Panel.new()
	panel.position = Vector2(30.0, 360.0)
	panel.size = Vector2(520.0, 220.0)
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	canvas.add_child(panel)
	var title: Label = Label.new()
	title.text = "DEV CONSOLE // CTRL + ALT + F9"
	title.position = Vector2(16.0, 14.0)
	title.size = Vector2(488.0, 24.0)
	title.add_theme_font_size_override("font_size", 16)
	panel.add_child(title)
	output = Label.new()
	output.position = Vector2(16.0, 46.0)
	output.size = Vector2(488.0, 84.0)
	output.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	output.text = "Developer commands: give, wave, win, lose, clear. Click the field below to type. Esc closes this panel."
	panel.add_child(output)
	input = LineEdit.new()
	input.position = Vector2(16.0, 150.0)
	input.size = Vector2(488.0, 38.0)
	input.placeholder_text = "enter developer command"
	input.mouse_filter = Control.MOUSE_FILTER_STOP
	input.text_submitted.connect(_run)
	panel.add_child(input)
	panel.visible = false

func _run(command_text: String) -> void:
	var game: Node = get_tree().current_scene
	if game == null or not game.has_method("flash"):
		return
	var command: String = command_text.strip_edges().to_lower()
	if command == "give":
		game.set("credits", int(game.get("credits")) + 500)
		game.set("supplies", int(game.get("supplies")) + 250)
		game.set("intel", int(game.get("intel")) + 50)
		output.text = "Resources granted."
	elif command == "wave":
		game.call("_spawn_enemy_wave")
		output.text = "Enemy wave created."
	elif command == "win":
		for building: Dictionary in game.get("buildings"):
			if str(building.get("kind", "")) == "syndicate_relay":
				building["hp"] = 0.0
		output.text = "Relay marked for removal."
	elif command == "lose":
		for building: Dictionary in game.get("buildings"):
			if str(building.get("kind", "")) == "nexus":
				building["hp"] = 0.0
		output.text = "Nexus marked for removal."
	elif command == "clear":
		game.get("units").clear()
		output.text = "Units cleared."
	else:
		output.text = "Unknown command. Use give, wave, win, lose, or clear."
	input.clear()
