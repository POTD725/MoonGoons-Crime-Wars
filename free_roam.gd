extends Node2D
## Playable open-sector exploration mode: The Fracture Belt.
## Move with WASD, scan recon beacons with E, and use F2 for the mode hub.

const SECTOR := Rect2(-1320, -820, 2640, 1640)
const SPEED := 290.0

var explorer := Vector2(-560, 260)
var faction := "authority"
var intel := 0
var credits := 0
var recon_sites: Array[Dictionary] = []
var patrols: Array[Dictionary] = []
var scan_site := -1
var scan_progress := 0.0
var note := "Explore the Fracture Belt. Approach a beacon and hold E to scan it."
var note_timer := 8.0
var font: Font
var info_label: Label
var detail_label: Label

func _ready() -> void:
	font = ThemeDB.fallback_font
	_seed_sector()
	_build_hud()
	queue_redraw()

func _seed_sector() -> void:
	var positions := [Vector2(-720, 170), Vector2(-360, -300), Vector2(45, 250), Vector2(350, -150), Vector2(700, 265), Vector2(910, -310), Vector2(150, -520), Vector2(-720, -430)]
	for index in CampaignData.RECON_SITES.size():
		var source: Dictionary = CampaignData.RECON_SITES[index]
		recon_sites.append({"data":source, "pos":positions[index], "complete":false})
	for position in [Vector2(-150, -120), Vector2(485, 120), Vector2(760, -460), Vector2(-880, -170)]:
		patrols.append({"pos":position, "phase":randf_range(0.0, TAU), "color":Color("ff7f98")})

func _process(delta: float) -> void:
	var motion := Vector2.ZERO
	if Input.is_key_pressed(KEY_W): motion.y -= 1.0
	if Input.is_key_pressed(KEY_S): motion.y += 1.0
	if Input.is_key_pressed(KEY_A): motion.x -= 1.0
	if Input.is_key_pressed(KEY_D): motion.x += 1.0
	if motion.length_squared() > 0.0:
		explorer += motion.normalized() * SPEED * delta
		explorer.x = clampf(explorer.x, SECTOR.position.x + 34.0, SECTOR.end.x - 34.0)
		explorer.y = clampf(explorer.y, SECTOR.position.y + 34.0, SECTOR.end.y - 34.0)
	for patrol in patrols:
		patrol["phase"] = float(patrol["phase"]) + delta
		patrol["pos"] += Vector2(cos(float(patrol["phase"]) * 0.8), sin(float(patrol["phase"]) * 0.53)) * delta * 22.0
	_update_scan(delta)
	note_timer = maxf(0.0, note_timer - delta)
	_update_hud()
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1: _set_faction("authority")
			KEY_2: _set_faction("lunar_cartel")
			KEY_3: _set_faction("null_choir")
			KEY_4: _set_faction("hollow_fang")
			KEY_ENTER: get_tree().change_scene_to_file("res://main.tscn")

func _set_faction(new_faction: String) -> void:
	faction = new_faction
	flash("Recon vessel style set to " + RaceCatalog.get_name(faction) + ".", 3.0)

func _update_scan(delta: float) -> void:
	var nearest := _nearest_site()
	if nearest < 0:
		scan_site = -1
		scan_progress = 0.0
		return
	if Input.is_key_pressed(KEY_E):
		if scan_site != nearest:
			scan_site = nearest
			scan_progress = 0.0
		scan_progress += delta
		if scan_progress >= 2.0:
			_complete_recon(nearest)
	else:
		scan_site = -1
		scan_progress = 0.0

func _nearest_site() -> int:
	var closest := -1
	var distance := 100.0
	for index in recon_sites.size():
		var site := recon_sites[index]
		if bool(site["complete"]):
			continue
		var candidate := explorer.distance_to(site["pos"])
		if candidate < distance:
			distance = candidate
			closest = index
	return closest

func _complete_recon(index: int) -> void:
	var site := recon_sites[index]
	if bool(site["complete"]):
		return
	site["complete"] = true
	scan_site = -1
	scan_progress = 0.0
	intel += 12
	credits += 80
	var data: Dictionary = site["data"]
	flash("RECON COMPLETE // " + str(data["name"]) + "\n" + str(data["reveal"]), 7.0)

func _draw() -> void:
	var view := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, view), Color("070d1e"), true)
	draw_set_transform(view * 0.5 - explorer, 0.0, Vector2.ONE)
	_draw_sector()
	_draw_sites()
	_draw_patrols()
	_draw_explorer()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_sector() -> void:
	draw_rect(SECTOR, Color("111d35"), true)
	for x in range(int(SECTOR.position.x), int(SECTOR.end.x), 120):
		draw_line(Vector2(x, SECTOR.position.y), Vector2(x, SECTOR.end.y), Color(0.20, 0.31, 0.53, 0.24), 1.0)
	for y in range(int(SECTOR.position.y), int(SECTOR.end.y), 120):
		draw_line(Vector2(SECTOR.position.x, y), Vector2(SECTOR.end.x, y), Color(0.20, 0.31, 0.53, 0.24), 1.0)
	for crater in [Vector2(-990, 430), Vector2(-170, -540), Vector2(530, 410), Vector2(1020, -90), Vector2(780, -620)]:
		draw_circle(crater, 86.0, Color("0c1427"))
		draw_arc(crater, 86.0, 0.0, TAU, 28, Color(0.30, 0.43, 0.65, 0.35), 2.0)
	draw_rect(SECTOR, Color("637ba8"), false, 4.0)

func _draw_sites() -> void:
	for index in recon_sites.size():
		var site := recon_sites[index]
		var complete := bool(site["complete"])
		var pos: Vector2 = site["pos"]
		var color := Color("63f0c1") if complete else Color("ffc46a")
		draw_circle(pos, 34.0, Color(color, 0.13))
		draw_arc(pos, 28.0, 0.0, TAU, 20, color, 2.5)
		draw_line(pos + Vector2(0, 25), pos + Vector2(0, -34), color, 3.0)
		draw_circle(pos + Vector2(0, -38), 7.0, color)
		draw_string(font, pos + Vector2(-75, 55), str(site["data"]["name"]), HORIZONTAL_ALIGNMENT_CENTER, 150, 12, color)
		if scan_site == index:
			draw_arc(pos, 42.0, -PI * 0.5, -PI * 0.5 + TAU * scan_progress / 2.0, 26, Color("f4fff9"), 4.0)

func _draw_patrols() -> void:
	for patrol in patrols:
		var pos: Vector2 = patrol["pos"]
		var triangle := PackedVector2Array([pos + Vector2(0, -16), pos + Vector2(14, 12), pos + Vector2(-14, 12)])
		draw_colored_polygon(triangle, patrol["color"])
		draw_arc(pos, 25.0, 0.0, TAU, 14, Color(patrol["color"], 0.25), 1.0)

func _draw_explorer() -> void:
	var accent := Color(str(RaceCatalog.RACES[faction]["accent"]))
	var ship := PackedVector2Array([explorer + Vector2(0, -23), explorer + Vector2(17, 17), explorer + Vector2(0, 10), explorer + Vector2(-17, 17)])
	draw_colored_polygon(ship, accent)
	draw_polyline(ship, Color("ecf8ff"), 2.0, true)
	draw_circle(explorer + Vector2(0, 2), 5.0, Color("0a1427"))
	draw_string(font, explorer + Vector2(-90, 42), RaceCatalog.get_name(faction), HORIZONTAL_ALIGNMENT_CENTER, 180, 12, accent)

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var panel := Panel.new()
	panel.position = Vector2(18, 18)
	panel.size = Vector2(560, 164)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.025, 0.05, 0.12, 0.90)
	style.border_color = Color("4c73aa")
	style.set_border_width_all(2)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	panel.add_theme_stylebox_override("panel", style)
	layer.add_child(panel)

	var title := Label.new()
	title.text = "FREE ROAM // THE FRACTURE BELT"
	title.position = Vector2(14, 10)
	title.size = Vector2(530, 24)
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color("b7d5ff"))
	panel.add_child(title)
	info_label = Label.new()
	info_label.position = Vector2(14, 39)
	info_label.size = Vector2(530, 30)
	info_label.add_theme_font_size_override("font_size", 15)
	info_label.add_theme_color_override("font_color", Color("eff8ff"))
	panel.add_child(info_label)
	detail_label = Label.new()
	detail_label.position = Vector2(14, 71)
	detail_label.size = Vector2(530, 78)
	detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_label.add_theme_font_size_override("font_size", 13)
	detail_label.add_theme_color_override("font_color", Color("c0d2e7"))
	panel.add_child(detail_label)

func _update_hud() -> void:
	var done := 0
	for site in recon_sites:
		if bool(site["complete"]): done += 1
	info_label.text = "INTEL %d    CREDITS %d    RECON %d / %d    [1-4] faction skin" % [intel, credits, done, recon_sites.size()]
	var near := _nearest_site()
	if near >= 0:
		var data: Dictionary = recon_sites[near]["data"]
		detail_label.text = "HOLD E TO SCAN: " + str(data["name"]) + "\n" + str(data["task"]) + "\nRisk: " + str(data["risk"])
	elif note_timer > 0.0:
		detail_label.text = note
	else:
		detail_label.text = "WASD move  •  Explore beacons  •  F2 mode hub  •  Enter returns to operations"

func flash(text: String, duration: float) -> void:
	note = text
	note_timer = duration
