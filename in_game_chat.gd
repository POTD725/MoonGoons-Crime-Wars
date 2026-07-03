extends Node
## F8 in-game chat for RTS, free roam, and LAN co-op sessions.
## LAN messages are relayed by the host. Solo messages remain local.

var canvas: CanvasLayer
var panel: Panel
var log: RichTextLabel
var entry: LineEdit
var unread_label: Label
var unread := 0
var open := false
var history: Array[String] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	post_system("Comms online. Press F8 or Enter to open chat. Type /help for commands.")

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F8:
			_toggle()
			get_viewport().set_input_as_handled()
			return
		if event.keycode == KEY_ENTER and not open:
			_toggle(true)
			get_viewport().set_input_as_handled()
			return
		if event.keycode == KEY_ESCAPE and open:
			_toggle(false)
			get_viewport().set_input_as_handled()

func _toggle(force_open: bool = false) -> void:
	open = true if force_open else not open
	panel.visible = open
	unread_label.visible = not open and unread > 0
	if open:
		unread = 0
		unread_label.text = ""
		entry.grab_focus()
	else:
		entry.release_focus()

func _build_ui() -> void:
	canvas = CanvasLayer.new()
	canvas.layer = 60
	canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(canvas)

	panel = Panel.new()
	panel.position = Vector2(18, 590)
	panel.size = Vector2(525, 280)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.02, 0.04, 0.10, 0.94)
	style.border_color = Color("76b5e9")
	style.set_border_width_all(2)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	panel.add_theme_stylebox_override("panel", style)
	canvas.add_child(panel)

	var heading := Label.new()
	heading.text = "COMMS // F8"
	heading.position = Vector2(14, 10)
	heading.size = Vector2(470, 24)
	heading.add_theme_font_size_override("font_size", 16)
	heading.add_theme_color_override("font_color", Color("a8d7ff"))
	panel.add_child(heading)

	log = RichTextLabel.new()
	log.position = Vector2(14, 39)
	log.size = Vector2(497, 185)
	log.bbcode_enabled = true
	log.scroll_active = true
	log.add_theme_font_size_override("normal_font_size", 13)
	log.add_theme_color_override("default_color", Color("e5effa"))
	panel.add_child(log)

	entry = LineEdit.new()
	entry.position = Vector2(14, 235)
	entry.size = Vector2(497, 34)
	entry.placeholder_text = "Message team...  /help for commands"
	entry.max_length = 180
	entry.text_submitted.connect(_submit)
	panel.add_child(entry)

	unread_label = Label.new()
	unread_label.position = Vector2(18, 552)
	unread_label.size = Vector2(525, 25)
	unread_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	unread_label.add_theme_font_size_override("font_size", 14)
	unread_label.add_theme_color_override("font_color", Color("ffd477"))
	canvas.add_child(unread_label)
	panel.visible = false
	unread_label.visible = false

func _submit(text: String) -> void:
	var message := _clean(text)
	entry.clear()
	if message.is_empty():
		return
	if message.begins_with("/"):
		_run_command(message)
		return
	var sender := _callsign()
	if _is_lan_active():
		if multiplayer.is_server():
			_broadcast_chat.rpc(sender, message)
		else:
			_send_chat_to_host.rpc_id(1, message)
	else:
		_append("[color=#8fe9ff]%s:[/color] %s" % [sender, message])

@rpc("any_peer", "reliable")
func _send_chat_to_host(message: String) -> void:
	if not multiplayer.is_server():
		return
	var peer_id := multiplayer.get_remote_sender_id()
	var sender := str(LanSession.roster.get(peer_id, "Crew %d" % peer_id))
	_broadcast_chat.rpc(sender, _clean(message))

@rpc("authority", "call_local", "reliable")
func _broadcast_chat(sender: String, message: String) -> void:
	_append("[color=#8fe9ff]%s:[/color] %s" % [_clean(sender), _clean(message)])

func post_system(message: String) -> void:
	_append("[color=#ffd477]SYSTEM:[/color] " + _clean(message))

func _run_command(command: String) -> void:
	var parts := command.to_lower().split(" ", false)
	match parts[0]:
		"/help":
			_append("[color=#c8d9ee]Commands:[/color] /help  /map  /roll  /clear")
		"/map":
			var data := PvpMaps.get_active()
			_append("[color=#c8d9ee]Battlefield:[/color] %s • %s • %s resources" % [data["name"], data["players"], data["resources"]])
		"/roll":
			_append("[color=#c8d9ee]%s rolled %d.[/color]" % [_callsign(), randi_range(1, 100)])
		"/clear":
			log.clear()
			history.clear()
		_:
			_append("[color=#ff8e9e]Unknown command.[/color] Try /help.")

func _append(message: String) -> void:
	if log == null:
		return
	history.append(message)
	if history.size() > 80:
		history.pop_front()
	log.append_text(message + "\n")
	log.scroll_to_line(log.get_line_count())
	if not open:
		unread += 1
		unread_label.text = "%d new comms message%s  •  F8" % [unread, "" if unread == 1 else "s"]
		unread_label.visible = true

func _clean(text: String) -> String:
	return text.strip_edges().replace("[", "(").replace("]", ")").left(180)

func _callsign() -> String:
	if LanSession.display_name.strip_edges().is_empty():
		return "Commander"
	return LanSession.display_name.left(20)

func _is_lan_active() -> bool:
	return multiplayer.multiplayer_peer != null and not (multiplayer.multiplayer_peer is OfflineMultiplayerPeer)
