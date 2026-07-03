extends Node
## F9 light developer console for local testing.

var canvas: CanvasLayer
var panel: Panel
var input: LineEdit
var output: Label

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F9:
		panel.visible = not panel.visible
		if panel.visible:
			input.grab_focus()
		get_viewport().set_input_as_handled()

func _build() -> void:
	canvas = CanvasLayer.new()
	canvas.layer = 70
	canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(canvas)
	panel = Panel.new()
	panel.position = Vector2(30, 360)
	panel.size = Vector2(520, 220)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	canvas.add_child(panel)
	var title := Label.new()
	title.text = "DEV CONSOLE // F9"
	title.position = Vector2(16, 14)
	title.size = Vector2(480, 24)
	title.add_theme_font_size_override("font_size", 16)
	panel.add_child(title)
	output = Label.new()
	output.position = Vector2(16, 46)
	output.size = Vector2(488, 84)
	output.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	output.text = "Commands: give, wave, win, lose, clear"
	panel.add_child(output)
	input = LineEdit.new()
	input.position = Vector2(16, 150)
	input.size = Vector2(488, 38)
	input.placeholder_text = "enter command"
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
		output.text = "Unknown command. Use give, wave, win, lose, clear."
	input.clear()
