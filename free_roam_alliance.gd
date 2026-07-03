extends Node2D
## Free-Roam alliance director. F6 opens the Alliance Console.
## One automated partner can follow, scout, guard, or salvage in the Fracture Belt.

const PARTNERS := {
	"authority": {"name":"Deputy Karr","group":"MoonGoons Mutual Aid","accent":"#8fe9ff","perk":"Patrol deterrence"},
	"lunar_cartel": {"name":"Mox Vell","group":"Cartel Defector Cell","accent":"#ff79c6","perk":"Salvage bonus"},
	"null_choir": {"name":"Echo N-7","group":"Null Choir Witnesses","accent":"#72f2bd","perk":"Recon speed"},
	"hollow_fang": {"name":"Sable Fang","group":"Hollow Fang Truceband","accent":"#ff9b62","perk":"Guard strength"}
}

var free_roam: Node
var companion_race := "authority"
var companion_pos := Vector2(-480, 310)
var companion_mode := "follow"
var companion_recruited := false
var alliance_rep := 0
var panel: Panel
var status: Label
var info: Label
var target_site := -1
var action_clock := 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	z_index = 10
	_build_console()

func _process(delta: float) -> void:
	var scene := get_tree().current_scene
	if scene == null or not scene.has_method("_nearest_site") or not scene.has_method("_complete_recon"):
		free_roam = null
		visible = false
		return
	free_roam = scene
	visible = companion_recruited
	if not companion_recruited:
		return
	_action(delta)
	queue_redraw()
	_refresh_text()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F6:
		if free_roam == null:
			return
		panel.visible = not panel.visible
		get_tree().paused = panel.visible
		get_viewport().set_input_as_handled()

func _action(delta: float) -> void:
	if free_roam == null:
		return
	var leader: Vector2 = free_roam.get("explorer")
	match companion_mode:
		"follow":
			companion_pos = companion_pos.move_toward(leader + Vector2(-55, 38), 210.0 * delta)
		"guard":
			var anchor := leader + Vector2(75, -30)
			companion_pos = companion_pos.move_toward(anchor, 185.0 * delta)
			_action_clock += delta
			if action_clock >= 8.0:
				action_clock = 0.0
				alliance_rep += 1
				free_roam.call("flash", "Alliance guard sweep complete. Patrol pressure reduced.", 3.0)
		"scout":
			var site_index := int(free_roam.call("_nearest_site"))
			if site_index < 0:
				site_index = _first_open_site()
			if site_index >= 0:
				target_site = site_index
				var site: Dictionary = free_roam.get("recon_sites")[site_index]
				companion_pos = companion_pos.move_toward(site["pos"], 245.0 * delta)
				if companion_pos.distance_to(site["pos"]) < 24.0:
					free_roam.call("_complete_recon", site_index)
					alliance_rep += 3
					free_roam.set("intel", int(free_roam.get("intel")) + 8)
					free_roam.call("flash", "Alliance scout completed recon and forwarded bonus Intel.", 4.0)
					target_site = -1
			else:
				companion_mode = "follow"
		"salvage":
			var salvage_target := leader + Vector2(140, 90)
			companion_pos = companion_pos.move_toward(salvage_target, 205.0 * delta)
			action_clock += delta
			if action_clock >= 6.0:
				action_clock = 0.0
				free_roam.set("credits", int(free_roam.get("credits")) + 55)
				alliance_rep += 1
				free_roam.call("flash", "Alliance salvage crew recovered 55 Credits.", 3.0)

func _first_open_site() -> int:
	if free_roam == null:
		return -1
	var sites: Array = free_roam.get("recon_sites")
	for index in sites.size():
		if not bool(sites[index]["complete"]):
			return index
	return -1

func _draw() -> void:
	if free_roam == null or not companion_recruited:
		return
	var view := get_viewport_rect().size
	var leader: Vector2 = free_roam.get("explorer")
	draw_set_transform(view * 0.5 - leader, 0.0, Vector2.ONE)
	var accent := Color(str(PARTNERS[companion_race]["accent"]))
	var ship := PackedVector2Array([companion_pos + Vector2(0,-19), companion_pos + Vector2(15,15), companion_pos + Vector2(0,8), companion_pos + Vector2(-15,15)])
	draw_colored_polygon(ship, accent)
	draw_polyline(ship, Color("f4fbff"), 2.0, true)
	draw_arc(companion_pos, 27.0, 0.0, TAU, 20, Color(accent, 0.65), 2.0)
	draw_string(ThemeDB.fallback_font, companion_pos + Vector2(-80, 42), str(PARTNERS[companion_race]["name"]) + " // " + companion_mode.to_upper(), HORIZONTAL_ALIGNMENT_CENTER, 160, 11, accent)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _build_console() -> void:
	var canvas := CanvasLayer.new()
	canvas.layer = 41
	canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(canvas)
	panel = Panel.new()
	panel.position = Vector2(1000, 18)
	panel.size = Vector2(540, 420)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.025, 0.05, 0.12, 0.96)
	style.border_color = Color("72f2bd")
	style.set_border_width_all(2)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	panel.add_theme_stylebox_override("panel", style)
	canvas.add_child(panel)

	var title := Label.new()
	title.text = "ALLIANCE CONSOLE // F6"
	title.position = Vector2(16, 14)
	title.size = Vector2(500, 26)
	title.add_theme_font_size_override("font_size", 19)
	title.add_theme_color_override("font_color", Color("9cf6d4"))
	panel.add_child(title)

	info = Label.new()
	info.position = Vector2(16, 48)
	info.size = Vector2(505, 74)
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_theme_font_size_override("font_size", 14)
	info.add_theme_color_override("font_color", Color("d5e8f7"))
	panel.add_child(info)

	var race_ids := ["authority", "lunar_cartel", "null_choir", "hollow_fang"]
	for index in race_ids.size():
		var race_id: String = race_ids[index]
		var button := Button.new()
		button.position = Vector2(16 + (index % 2) * 252, 140 + (index / 2) * 72)
		button.size = Vector2(240, 60)
		button.text = "RECRUIT " + str(PARTNERS[race_id]["name"]) + "\n" + str(PARTNERS[race_id]["group"])
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.pressed.connect(_recruit.bind(race_id))
		panel.add_child(button)

	var orders_title := Label.new()
	orders_title.text = "AUTOMATED PARTNER ORDERS"
	orders_title.position = Vector2(16, 295)
	orders_title.size = Vector2(500, 20)
	orders_title.add_theme_font_size_override("font_size", 14)
	orders_title.add_theme_color_override("font_color", Color("a9c8e8"))
	panel.add_child(orders_title)
	for index in ["follow", "scout", "guard", "salvage"].size():
		var mode: String = ["follow", "scout", "guard", "salvage"][index]
		var button := Button.new()
		button.text = mode.to_upper()
		button.position = Vector2(16 + index * 128, 327)
		button.size = Vector2(118, 44)
		button.pressed.connect(_set_mode.bind(mode))
		panel.add_child(button)

	status = Label.new()
	status.position = Vector2(16, 380)
	status.size = Vector2(505, 28)
	status.add_theme_font_size_override("font_size", 13)
	status.add_theme_color_override("font_color", Color("ffdc9e"))
	panel.add_child(status)
	panel.visible = false

func _recruit(race_id: String) -> void:
	companion_race = race_id
	companion_recruited = true
	companion_mode = "follow"
	if free_roam != null:
		companion_pos = free_roam.get("explorer") + Vector2(-80, 46)
		free_roam.call("flash", "Alliance partnership formed with " + str(PARTNERS[race_id]["name"]) + ".", 5.0)
	_refresh_text()

func _set_mode(mode: String) -> void:
	if not companion_recruited:
		return
	companion_mode = mode
	if free_roam != null:
		free_roam.call("flash", "Alliance order: " + mode.to_upper(), 3.0)
	_refresh_text()

func _refresh_text() -> void:
	if info == null:
		return
	if companion_recruited:
		info.text = "ACTIVE ALLIANCE: %s // %s\nPerk: %s\nAutomated partner mode: %s" % [PARTNERS[companion_race]["name"], PARTNERS[companion_race]["group"], PARTNERS[companion_race]["perk"], companion_mode.to_upper()]
	else:
		info.text = "Recruit one automated ally for this expedition. Alliances earn reputation through recon, salvage, and defensive work."
	status.text = "ALLIANCE REPUTATION: %d   •   F6 closes console" % alliance_rep
