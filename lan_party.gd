extends Node2D
## Shared LAN reconnaissance party. Host is authoritative for beacon captures.

const WORLD := Rect2(-1200, -760, 2400, 1520)
const SPEED := 260.0
const PLAYER_COLORS := [Color("8fe9ff"), Color("ff9b62"), Color("72f2bd"), Color("ff79c6"), Color("dba6ff"), Color("ffd66d"), Color("a6baff"), Color("f0f4ff")]

var local_id := 1
var players: Dictionary = {}
var beacons: Array[Dictionary] = []
var team_intel := 0
var font: Font
var hud: Label
var detail: Label

func _ready() -> void:
	font = ThemeDB.fallback_font
	_seed_beacons()
	_build_hud()
	multiplayer.peer_disconnected.connect(_peer_left)
	local_id = multiplayer.get_unique_id() if multiplayer.multiplayer_peer != null else 1
	if multiplayer.multiplayer_peer == null:
		LanSession.roster = {1: LanSession.display_name}
		_server_add_player(1, LanSession.display_name)
	elif multiplayer.is_server():
		for peer_id in LanSession.roster.keys():
			_server_add_player(int(peer_id), str(LanSession.roster[peer_id]))
		_sync_state.rpc(players, beacons, team_intel)
	else:
		_request_join.rpc_id(1, LanSession.display_name)
	queue_redraw()

func _process(delta: float) -> void:
	if not players.has(local_id):
		return
	var direction := Vector2.ZERO
	if Input.is_key_pressed(KEY_W): direction.y -= 1.0
	if Input.is_key_pressed(KEY_S): direction.y += 1.0
	if Input.is_key_pressed(KEY_A): direction.x -= 1.0
	if Input.is_key_pressed(KEY_D): direction.x += 1.0
	if direction.length_squared() > 0.0:
		var position: Vector2 = players[local_id]["pos"] + direction.normalized() * SPEED * delta
		position.x = clampf(position.x, WORLD.position.x + 28.0, WORLD.end.x - 28.0)
		position.y = clampf(position.y, WORLD.position.y + 28.0, WORLD.end.y - 28.0)
		if multiplayer.multiplayer_peer == null or multiplayer.is_server():
			_set_position(local_id, position)
		else:
			_submit_position.rpc_id(1, position)
	if Input.is_key_pressed(KEY_E):
		var beacon_id := _nearby_beacon()
		if beacon_id >= 0:
			if multiplayer.multiplayer_peer == null or multiplayer.is_server():
				_capture_beacon(beacon_id)
			else:
				_request_capture.rpc_id(1, beacon_id)
	_update_hud()
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		get_tree().change_scene_to_file("res://lan_lobby.tscn")

func _seed_beacons() -> void:
	var sites := [
		{"name":"Breakwater Scan Array", "pos":Vector2(-580, 180), "clue":"Cartel containers carry altered evacuation codes."},
		{"name":"Ghostlight Transit Node", "pos":Vector2(-160, -330), "clue":"A missing detainee list points toward Kestrel Moon."},
		{"name":"Null Signal Prism", "pos":Vector2(340, 150), "clue":"The fracture pattern includes a route into the buried city."},
		{"name":"Fang Trophy Relay", "pos":Vector2(760, -260), "clue":"Hollow Fang is mobilizing a captured prison transport."}
	]
	for site in sites:
		site["complete"] = false
		beacons.append(site)

func _server_add_player(peer_id: int, callsign: String) -> void:
	if players.has(peer_id):
		return
	var index := players.size() % PLAYER_COLORS.size()
	players[peer_id] = {"name":callsign.left(20), "pos":Vector2(-810 + index * 56, 330 + index * 42), "color":PLAYER_COLORS[index]}

@rpc("any_peer", "reliable")
func _request_join(callsign: String) -> void:
	if not multiplayer.is_server():
		return
	var peer_id := multiplayer.get_remote_sender_id()
	LanSession.roster[peer_id] = callsign.left(20)
	_server_add_player(peer_id, callsign)
	_sync_state.rpc(players, beacons, team_intel)

@rpc("authority", "call_local", "reliable")
func _sync_state(new_players: Dictionary, new_beacons: Array, new_intel: int) -> void:
	players = new_players.duplicate(true)
	beacons = new_beacons.duplicate(true)
	team_intel = new_intel

@rpc("any_peer", "unreliable")
func _submit_position(position: Vector2) -> void:
	if not multiplayer.is_server():
		return
	var peer_id := multiplayer.get_remote_sender_id()
	_set_position(peer_id, position)

func _set_position(peer_id: int, position: Vector2) -> void:
	if not players.has(peer_id):
		return
	players[peer_id]["pos"] = position
	if multiplayer.multiplayer_peer != null and multiplayer.is_server():
		_sync_position.rpc(peer_id, position)

@rpc("authority", "call_local", "unreliable")
func _sync_position(peer_id: int, position: Vector2) -> void:
	if players.has(peer_id):
		players[peer_id]["pos"] = position

@rpc("any_peer", "reliable")
func _request_capture(beacon_id: int) -> void:
	if not multiplayer.is_server():
		return
	_capture_beacon(beacon_id)

func _capture_beacon(beacon_id: int) -> void:
	if beacon_id < 0 or beacon_id >= beacons.size() or bool(beacons[beacon_id]["complete"]):
		return
	beacons[beacon_id]["complete"] = true
	team_intel += 25
	if multiplayer.multiplayer_peer != null and multiplayer.is_server():
		_sync_beacon.rpc(beacon_id, team_intel)

@rpc("authority", "call_local", "reliable")
func _sync_beacon(beacon_id: int, total_intel: int) -> void:
	if beacon_id >= 0 and beacon_id < beacons.size():
		beacons[beacon_id]["complete"] = true
	team_intel = total_intel

func _peer_left(peer_id: int) -> void:
	players.erase(peer_id)
	LanSession.roster.erase(peer_id)

func _nearby_beacon() -> int:
	if not players.has(local_id):
		return -1
	var best := -1
	var distance := 90.0
	for index in beacons.size():
		if bool(beacons[index]["complete"]):
			continue
		var candidate := players[local_id]["pos"].distance_to(beacons[index]["pos"])
		if candidate < distance:
			distance = candidate
			best = index
	return best

func _draw() -> void:
	var view := get_viewport_rect().size
	var center := players[local_id]["pos"] if players.has(local_id) else Vector2.ZERO
	draw_rect(Rect2(Vector2.ZERO, view), Color("071022"), true)
	draw_set_transform(view * 0.5 - center, 0.0, Vector2.ONE)
	_draw_world()
	_draw_beacons()
	_draw_players()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_world() -> void:
	draw_rect(WORLD, Color("121e35"), true)
	for x in range(int(WORLD.position.x), int(WORLD.end.x), 120):
		draw_line(Vector2(x, WORLD.position.y), Vector2(x, WORLD.end.y), Color(0.25, 0.35, 0.54, 0.24), 1.0)
	for y in range(int(WORLD.position.y), int(WORLD.end.y), 120):
		draw_line(Vector2(WORLD.position.x, y), Vector2(WORLD.end.x, y), Color(0.25, 0.35, 0.54, 0.24), 1.0)
	draw_rect(WORLD, Color("6680ad"), false, 4.0)

func _draw_beacons() -> void:
	for beacon in beacons:
		var pos: Vector2 = beacon["pos"]
		var color := Color("72f2bd") if bool(beacon["complete"]) else Color("ffc46a")
		draw_circle(pos, 33.0, Color(color, 0.14))
		draw_arc(pos, 27.0, 0.0, TAU, 20, color, 3.0)
		draw_line(pos + Vector2(0, 25), pos + Vector2(0, -35), color, 3.0)
		draw_circle(pos + Vector2(0, -39), 7.0, color)
		draw_string(font, pos + Vector2(-88, 52), str(beacon["name"]), HORIZONTAL_ALIGNMENT_CENTER, 176, 12, color)

func _draw_players() -> void:
	for peer_id in players.keys():
		var player: Dictionary = players[peer_id]
		var pos: Vector2 = player["pos"]
		var color: Color = player["color"]
		var ship := PackedVector2Array([pos + Vector2(0,-20), pos + Vector2(16,16), pos + Vector2(0,9), pos + Vector2(-16,16)])
		draw_colored_polygon(ship, color)
		draw_polyline(ship, Color("f2f7ff"), 2.0, true)
		if int(peer_id) == local_id:
			draw_arc(pos, 28.0, 0.0, TAU, 20, Color("f8ffff"), 2.0)
		draw_string(font, pos + Vector2(-65, 40), str(player["name"]), HORIZONTAL_ALIGNMENT_CENTER, 130, 12, color)

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var panel := Panel.new()
	panel.position = Vector2(18, 18)
	panel.size = Vector2(560, 130)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.025, 0.05, 0.12, 0.90)
	style.border_color = Color("ff9b62")
	style.set_border_width_all(2)
	panel.add_theme_stylebox_override("panel", style)
	layer.add_child(panel)
	hud = Label.new()
	hud.position = Vector2(14, 12)
	hud.size = Vector2(530, 28)
	hud.add_theme_font_size_override("font_size", 16)
	hud.add_theme_color_override("font_color", Color("fff0da"))
	panel.add_child(hud)
	detail = Label.new()
	detail.position = Vector2(14, 46)
	detail.size = Vector2(530, 70)
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.add_theme_font_size_override("font_size", 13)
	detail.add_theme_color_override("font_color", Color("c4d7ed"))
	panel.add_child(detail)

func _update_hud() -> void:
	var complete := 0
	for beacon in beacons:
		if bool(beacon["complete"]): complete += 1
	hud.text = "LAN RECON PARTY  //  CREW %d  //  TEAM INTEL %d  //  BEACONS %d / %d" % [players.size(), team_intel, complete, beacons.size()]
	var nearby := _nearby_beacon()
	if nearby >= 0:
		detail.text = "PRESS E: " + str(beacons[nearby]["name"]) + "\n" + str(beacons[nearby]["clue"])
	else:
		detail.text = "WASD move  •  E capture nearby beacon  •  Esc return to the LAN lobby  •  F2 mode hub"
