extends Control
## Local-network lobby for MoonGoons: Crime Wars.
## Host uses UDP port 24571 by default. Joiners enter the host's LAN IPv4 address.

const MAX_PLAYERS := 8

var peer: ENetMultiplayerPeer
var name_input: LineEdit
var ip_input: LineEdit
var port_input: LineEdit
var roster_label: RichTextLabel
var chat_log: RichTextLabel
var chat_input: LineEdit
var status_label: Label
var host_button: Button
var join_button: Button
var start_button: Button

func _ready() -> void:
	_build_ui()
	multiplayer.peer_connected.connect(_peer_connected)
	multiplayer.peer_disconnected.connect(_peer_disconnected)
	multiplayer.connected_to_server.connect(_connected_to_server)
	multiplayer.connection_failed.connect(_connection_failed)
	multiplayer.server_disconnected.connect(_server_disconnected)

func _exit_tree() -> void:
	if multiplayer.multiplayer_peer != null:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color("071022")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var title := Label.new()
	title.text = "CRIME WARS // LAN PARTY"
	title.position = Vector2(70, 54)
	title.size = Vector2(1460, 48)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", Color("ffbf76"))
	add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Host a local recon party, join from the same Wi-Fi/router, then explore and capture beacons together. F2 returns to the mode hub."
	subtitle.position = Vector2(110, 108)
	subtitle.size = Vector2(1380, 28)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 15)
	subtitle.add_theme_color_override("font_color", Color("b9cae1"))
	add_child(subtitle)

	var left := _panel(Vector2(120, 190), Vector2(580, 470), Color("273d6a"))
	var right := _panel(Vector2(825, 190), Vector2(655, 470), Color("6a4531"))
	add_child(left)
	add_child(right)

	var setup_title := _label("SESSION SETUP", Vector2(22, 18), Vector2(530, 28), 19, Color("a7d8ff"))
	left.add_child(setup_title)
	left.add_child(_label("Callsign", Vector2(22, 64), Vector2(160, 23), 14, Color("c4d5eb")))
	name_input = LineEdit.new()
	name_input.position = Vector2(22, 88)
	name_input.size = Vector2(520, 36)
	name_input.text = LanSession.display_name
	name_input.placeholder_text = "Commander name"
	left.add_child(name_input)

	left.add_child(_label("Host IP", Vector2(22, 140), Vector2(160, 23), 14, Color("c4d5eb")))
	ip_input = LineEdit.new()
	ip_input.position = Vector2(22, 164)
	ip_input.size = Vector2(350, 36)
	ip_input.placeholder_text = "192.168.x.x"
	left.add_child(ip_input)
	var local_hint := _best_local_ip()
	ip_input.text = local_hint

	left.add_child(_label("Port", Vector2(392, 140), Vector2(100, 23), 14, Color("c4d5eb")))
	port_input = LineEdit.new()
	port_input.position = Vector2(392, 164)
	port_input.size = Vector2(150, 36)
	port_input.text = str(LanSession.port)
	left.add_child(port_input)

	host_button = Button.new()
	host_button.text = "HOST PARTY"
	host_button.position = Vector2(22, 220)
	host_button.size = Vector2(250, 45)
	host_button.pressed.connect(_host)
	left.add_child(host_button)
	join_button = Button.new()
	join_button.text = "JOIN PARTY"
	join_button.position = Vector2(292, 220)
	join_button.size = Vector2(250, 45)
	join_button.pressed.connect(_join)
	left.add_child(join_button)

	start_button = Button.new()
	start_button.text = "HOST: START CO-OP RECON"
	start_button.position = Vector2(22, 281)
	start_button.size = Vector2(520, 48)
	start_button.disabled = true
	start_button.pressed.connect(_start_recon)
	left.add_child(start_button)

	status_label = _label("Not connected. Host a session or enter the host IP and join.", Vector2(22, 350), Vector2(520, 90), 14, Color("ffe0b5"))
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	left.add_child(status_label)

	var roster_title := _label("PARTY ROSTER", Vector2(20, 18), Vector2(600, 28), 19, Color("ffcf9a"))
	right.add_child(roster_title)
	roster_label = RichTextLabel.new()
	roster_label.position = Vector2(20, 52)
	roster_label.size = Vector2(300, 245)
	roster_label.bbcode_enabled = true
	roster_label.add_theme_font_size_override("normal_font_size", 16)
	right.add_child(roster_label)

	var chat_title := _label("LOCAL COMMS", Vector2(350, 52), Vector2(250, 24), 15, Color("ffcf9a"))
	right.add_child(chat_title)
	chat_log = RichTextLabel.new()
	chat_log.position = Vector2(350, 80)
	chat_log.size = Vector2(280, 220)
	chat_log.bbcode_enabled = true
	chat_log.add_theme_font_size_override("normal_font_size", 13)
	right.add_child(chat_log)
	chat_input = LineEdit.new()
	chat_input.position = Vector2(20, 332)
	chat_input.size = Vector2(610, 36)
	chat_input.placeholder_text = "Type a LAN message and press Enter"
	chat_input.text_submitted.connect(_send_chat)
	right.add_child(chat_input)

	var how := _label("HOSTING: Share the Host IP shown above. Windows Firewall may ask about Godot: allow Private networks only. Joiners must be on the same home network.", Vector2(125, 700), Vector2(1350, 48), 14, Color("a8c1df"))
	how.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	how.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(how)
	_update_roster()

func _panel(position: Vector2, size: Vector2, border: Color) -> Panel:
	var panel := Panel.new()
	panel.position = position
	panel.size = size
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.028, 0.05, 0.12, 0.94)
	style.border_color = border
	style.set_border_width_all(2)
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_left = 14
	style.corner_radius_bottom_right = 14
	panel.add_theme_stylebox_override("panel", style)
	return panel

func _label(text: String, position: Vector2, size: Vector2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.position = position
	label.size = size
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label

func _host() -> void:
	if _is_connected():
		status_label.text = "Already connected. Leave or start the co-op session."
		return
	LanSession.display_name = _safe_name()
	LanSession.port = _safe_port()
	peer = ENetMultiplayerPeer.new()
	var error := peer.create_server(LanSession.port, MAX_PLAYERS)
	if error != OK:
		status_label.text = "Could not host on port %d. Another app may already be using it." % LanSession.port
		return
	multiplayer.multiplayer_peer = peer
	LanSession.is_host = true
	LanSession.roster = {1: LanSession.display_name}
	start_button.disabled = false
	status_label.text = "Hosting on %s:%d. Share this local IP with friends." % [_best_local_ip(), LanSession.port]
	_chat("[color=#8fe9ff]HOST[/color] " + LanSession.display_name + " opened the party.")
	_update_roster()

func _join() -> void:
	if _is_connected():
		status_label.text = "Already connected."
		return
	LanSession.display_name = _safe_name()
	LanSession.port = _safe_port()
	var host_ip := ip_input.text.strip_edges()
	if host_ip.is_empty():
		status_label.text = "Enter the host computer's local IP address first."
		return
	peer = ENetMultiplayerPeer.new()
	var error := peer.create_client(host_ip, LanSession.port)
	if error != OK:
		status_label.text = "Could not start connection to %s:%d." % [host_ip, LanSession.port]
		return
	multiplayer.multiplayer_peer = peer
	LanSession.is_host = false
	status_label.text = "Connecting to %s:%d..." % [host_ip, LanSession.port]

func _connected_to_server() -> void:
	status_label.text = "Connected. Waiting for the host to launch co-op recon."
	_register_player.rpc_id(1, LanSession.display_name)

func _connection_failed() -> void:
	status_label.text = "Connection failed. Check the host IP, same-network connection, and firewall Private-network permission."
	_reset_connection()

func _server_disconnected() -> void:
	status_label.text = "Host disconnected. The party signal went quiet."
	_reset_connection()

func _peer_connected(peer_id: int) -> void:
	if multiplayer.is_server():
		status_label.text = "Player %d connected. Waiting for callsign..." % peer_id

func _peer_disconnected(peer_id: int) -> void:
	if multiplayer.is_server():
		LanSession.roster.erase(peer_id)
		_sync_roster.rpc(LanSession.roster)
		_chat("[color=#ffbb80]SYSTEM[/color] player %d left the party." % peer_id)
	_update_roster()

@rpc("any_peer", "reliable")
func _register_player(callsign: String) -> void:
	if not multiplayer.is_server():
		return
	var peer_id := multiplayer.get_remote_sender_id()
	LanSession.roster[peer_id] = callsign.left(20)
	_sync_roster.rpc(LanSession.roster)
	_chat("[color=#7dffad]JOIN[/color] " + str(LanSession.roster[peer_id]) + " entered the party.")

@rpc("authority", "call_local", "reliable")
func _sync_roster(new_roster: Dictionary) -> void:
	LanSession.roster = new_roster.duplicate(true)
	_update_roster()

func _send_chat(text: String) -> void:
	var message := text.strip_edges()
	chat_input.clear()
	if message.is_empty():
		return
	if not _is_connected():
		_chat("[color=#ffbb80]LOCAL[/color] connect to a party before sending messages.")
		return
	if multiplayer.is_server():
		_relay_chat.rpc(LanSession.display_name, message.left(160))
	else:
		_send_chat_to_host.rpc_id(1, message.left(160))

@rpc("any_peer", "reliable")
func _send_chat_to_host(message: String) -> void:
	if not multiplayer.is_server():
		return
	var peer_id := multiplayer.get_remote_sender_id()
	_relay_chat.rpc(str(LanSession.roster.get(peer_id, "Guest")), message)

@rpc("authority", "call_local", "reliable")
func _relay_chat(sender_name: String, message: String) -> void:
	_chat("[color=#c8d9ee]%s:[/color] %s" % [sender_name, message])

func _start_recon() -> void:
	if not multiplayer.is_server():
		return
	_start_party_scene.rpc()

@rpc("authority", "call_local", "reliable")
func _start_party_scene() -> void:
	get_tree().change_scene_to_file("res://lan_party.tscn")

func _update_roster() -> void:
	if roster_label == null:
		return
	roster_label.clear()
	roster_label.append_text("[color=#ffcf9a]%d / %d CREW SLOTS[/color]\n\n" % [LanSession.roster.size(), MAX_PLAYERS])
	for peer_id in LanSession.roster.keys():
		var prefix := "HOST" if int(peer_id) == 1 else "CREW"
		roster_label.append_text("[color=#8fe9ff]%s[/color]  %s\n" % [prefix, str(LanSession.roster[peer_id])])

func _chat(message: String) -> void:
	chat_log.append_text(message + "\n")
	chat_log.scroll_to_line(chat_log.get_line_count())

func _safe_name() -> String:
	var name := name_input.text.strip_edges()
	return name.left(20) if not name.is_empty() else "Commander"

func _safe_port() -> int:
	return clampi(port_input.text.to_int(), 1024, 65535) if port_input.text.is_valid_int() else 24571

func _is_connected() -> bool:
	return multiplayer.multiplayer_peer != null

func _reset_connection() -> void:
	if multiplayer.multiplayer_peer != null:
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = null
	LanSession.is_host = false
	LanSession.roster.clear()
	start_button.disabled = true
	_update_roster()

func _best_local_ip() -> String:
	for address in IP.get_local_addresses():
		if address.contains(".") and not address.begins_with("127.") and not address.begins_with("169.254"):
			return address
	return "192.168.x.x"
