extends Node
## MoonGoons: Crime Wars cinematic dialogue director.
## Watches the RTS mission and presents briefing, raid, victory, and failure scenes.
## Uses safe audio loading: it still runs if the optional WAV files have not been copied yet.

const AUTHORITY := "authority"
const SYNDICATE := "syndicate"

var layer: CanvasLayer
var shade: ColorRect
var frame: Panel
var portrait: PortraitGlyph
var name_label: Label
var faction_label: Label
var dialogue_label: Label
var continue_label: Label
var music: AudioStreamPlayer
var voice: AudioStreamPlayer

var mission_root: Node
var watched_instance := -1
var sequence: Array[Dictionary] = []
var sequence_index := 0
var is_playing := false
var opening_played := false
var raid_played := false
var result_played := false
var last_syndicate_count := 0
var typewriter_text := ""
var typewriter_visible := 0
var typewriter_clock := 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	music = AudioStreamPlayer.new()
	voice = AudioStreamPlayer.new()
	add_child(music)
	add_child(voice)

func _process(delta: float) -> void:
	var root := _find_mission()
	if root == null:
		return
	if root.get_instance_id() != watched_instance:
		mission_root = root
		watched_instance = root.get_instance_id()
		opening_played = false
		raid_played = false
		result_played = false
		last_syndicate_count = _count_team(root, SYNDICATE)
		await get_tree().process_frame
		if not opening_played:
			opening_played = true
			play_intro()
		return

	if is_playing:
		_update_typewriter(delta)
		return

	if bool(root.get("finished")) and not result_played:
		result_played = true
		if bool(root.get("victory")):
			play_victory()
		else:
			play_defeat()
		return

	var current_syndicate_count := _count_team(root, SYNDICATE)
	if not raid_played and current_syndicate_count >= last_syndicate_count + 3:
		raid_played = true
		play_raid()
	last_syndicate_count = current_syndicate_count

func _input(event: InputEvent) -> void:
	if not is_playing:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER]:
			_advance()
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_advance()
		get_viewport().set_input_as_handled()

func play_intro() -> void:
	_play_sequence([
		_line("Chief Nova", "MOONGOONS AUTHORITY // COMMAND", AUTHORITY, "Breakwater is not a raid. It is a lifeline. Build the precinct, secure the dockyard, and keep the civilians out of the crossfire."),
		_line("Captain Luna", "MOONGOONS AUTHORITY // FIELD LEAD", AUTHORITY, "Patrol teams are green. Builder Drones are fueled. Give me an Armory and I will give this moon a fighting chance."),
		_line("Mox Vell", "DARK SIDE // LUNAR CARTEL", SYNDICATE, "They brought a courthouse to a dockyard. Let them hang the sign. We will tear it down with the bolts still warm.")
	], "res://audio/mission_deploy.wav")

func play_raid() -> void:
	_play_sequence([
		_line("Vexa Null", "DARK SIDE // GLASS NETWORK", SYNDICATE, "Authority comms are bright, predictable, and very breakable. Raiders are through the maintenance throat."),
		_line("Captain Luna", "MOONGOONS AUTHORITY // FIELD LEAD", AUTHORITY, "Incoming contacts. Hold the line, deputies. Nobody gets past our civilians.")
	], "res://audio/mission_alert.wav")

func play_victory() -> void:
	_play_sequence([
		_line("Chief Nova", "MOONGOONS AUTHORITY // COMMAND", AUTHORITY, "Relay destroyed. Breakwater belongs to the people who live here again. Catalog the evidence and bring every survivor home."),
		_line("Mox Vell", "DARK SIDE // LUNAR CARTEL", SYNDICATE, "A relay is only a relay. Remember that when the next moon calls for help.")
	], "res://audio/mission_victory.wav")

func play_defeat() -> void:
	_play_sequence([
		_line("Vexa Null", "DARK SIDE // GLASS NETWORK", SYNDICATE, "Their Nexus went dark. Clean the logs, move the cargo, and leave them wondering which airlock betrayed them."),
		_line("Chief Nova", "MOONGOONS AUTHORITY // COMMAND", AUTHORITY, "Breakwater is lost. This is not the end of the case. It is the beginning of the hunt.")
	], "res://audio/mission_failure.wav")

func _line(character_name: String, faction: String, side: String, text: String) -> Dictionary:
	return {"name": character_name, "faction": faction, "side": side, "text": text}

func _play_sequence(lines: Array[Dictionary], cue_path: String) -> void:
	if lines.is_empty():
		return
	sequence = lines
	sequence_index = 0
	is_playing = true
	get_tree().paused = true
	_play_audio(cue_path, music, -8.0)
	_play_audio("res://audio/cutscene_ambience.wav", music, -18.0)
	_show_line()

func _show_line() -> void:
	if sequence_index >= sequence.size():
		_end_sequence()
		return
	var line := sequence[sequence_index]
	var side: String = line["side"]
	var accent := Color("8fe9ff") if side == AUTHORITY else Color("ff79c6")
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.025, 0.045, 0.10, 0.96)
	panel_style.border_color = accent
	panel_style.set_border_width_all(2)
	panel_style.corner_radius_top_left = 18
	panel_style.corner_radius_top_right = 18
	panel_style.corner_radius_bottom_left = 18
	panel_style.corner_radius_bottom_right = 18
	frame.add_theme_stylebox_override("panel", panel_style)

	var is_authority := side == AUTHORITY
	frame.position = Vector2(74, 585) if is_authority else Vector2(570, 585)
	portrait.position = Vector2(92, 606) if is_authority else Vector2(1055, 606)
	portrait.configure(str(line["name"]), side, accent)
	name_label.position = Vector2(234, 612) if is_authority else Vector2(590, 612)
	faction_label.position = Vector2(234, 640) if is_authority else Vector2(590, 640)
	dialogue_label.position = Vector2(234, 672) if is_authority else Vector2(590, 672)
	continue_label.position = Vector2(820, 810) if is_authority else Vector2(1115, 810)
	name_label.text = line["name"]
	faction_label.text = line["faction"]
	dialogue_label.text = ""
	typewriter_text = line["text"]
	typewriter_visible = 0
	typewriter_clock = 0.0
	name_label.add_theme_color_override("font_color", accent)
	faction_label.add_theme_color_override("font_color", accent.lightened(0.18))
	continue_label.add_theme_color_override("font_color", accent)
	shade.visible = true
	frame.visible = true
	portrait.visible = true
	_play_audio("res://audio/voice_authority_bleep.wav" if is_authority else "res://audio/voice_syndicate_bleep.wav", voice, -10.0)

func _update_typewriter(delta: float) -> void:
	if typewriter_visible >= typewriter_text.length():
		return
	typewriter_clock += delta
	var letters := int(typewriter_clock * 58.0)
	if letters <= 0:
		return
	typewriter_clock = 0.0
	typewriter_visible = mini(typewriter_text.length(), typewriter_visible + letters)
	dialogue_label.text = typewriter_text.left(typewriter_visible)

func _advance() -> void:
	if not is_playing:
		return
	if typewriter_visible < typewriter_text.length():
		typewriter_visible = typewriter_text.length()
		dialogue_label.text = typewriter_text
		return
	sequence_index += 1
	_show_line()

func _end_sequence() -> void:
	is_playing = false
	shade.visible = false
	frame.visible = false
	portrait.visible = false
	music.stop()
	voice.stop()
	get_tree().paused = false

func _play_audio(path: String, player: AudioStreamPlayer, volume_db: float) -> void:
	if ResourceLoader.exists(path):
		var stream := load(path) as AudioStream
		if stream != null:
			player.stream = stream
			player.volume_db = volume_db
			player.play()

func _find_mission() -> Node:
	var root := get_tree().current_scene
	if root != null and root.has_method("_relay") and root.has_method("_spawn_unit"):
		return root
	return null

func _count_team(root: Node, team: String) -> int:
	var count := 0
	for unit in root.get("units"):
		if unit.get("team", "") == team:
			count += 1
	return count

func _build_ui() -> void:
	layer = CanvasLayer.new()
	layer.layer = 15
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(layer)

	shade = ColorRect.new()
	shade.color = Color(0.0, 0.0, 0.02, 0.38)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(shade)

	frame = Panel.new()
	frame.size = Vector2(620, 255)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(frame)

	portrait = PortraitGlyph.new()
	portrait.size = Vector2(132, 170)
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(portrait)

	name_label = _label(Vector2(234, 612), Vector2(430, 28), 22, Color.WHITE)
	faction_label = _label(Vector2(234, 640), Vector2(430, 23), 12, Color.WHITE)
	dialogue_label = _label(Vector2(234, 672), Vector2(430, 120), 18, Color("eff6ff"))
	dialogue_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	continue_label = _label(Vector2(820, 810), Vector2(180, 20), 12, Color.WHITE)
	continue_label.text = "CLICK / SPACE  •  NEXT"

	shade.visible = false
	frame.visible = false
	portrait.visible = false
	name_label.visible = true
	faction_label.visible = true
	dialogue_label.visible = true
	continue_label.visible = true

func _label(position: Vector2, size: Vector2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.position = position
	label.size = size
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(label)
	return label

class PortraitGlyph extends Control:
	var title := ""
	var side := AUTHORITY
	var accent := Color("8fe9ff")

	func configure(new_title: String, new_side: String, new_accent: Color) -> void:
		title = new_title
		side = new_side
		accent = new_accent
		queue_redraw()

	func _draw() -> void:
		var panel_rect := Rect2(Vector2.ZERO, size)
		draw_rect(panel_rect, Color("071126"), true)
		draw_rect(panel_rect, accent, false, 3.0)
		var center := Vector2(size.x * 0.5, 70)
		if side == AUTHORITY:
			draw_circle(center, 38, accent.darkened(0.25))
			draw_circle(center + Vector2(0, -5), 24, Color("d8f4ff"))
			draw_circle(center + Vector2(-9, -5), 4, Color("071126"))
			draw_circle(center + Vector2(9, -5), 4, Color("071126"))
			draw_arc(center + Vector2(0, 8), 12, 0.15, PI - 0.15, 16, Color("071126"), 3)
			draw_rect(Rect2(28, 108, 76, 42), accent.darkened(0.12), true)
			draw_rect(Rect2(46, 98, 40, 18), Color("d8f4ff"), true)
		else:
			draw_circle(center, 39, accent.darkened(0.18))
			draw_circle(center + Vector2(0, -4), 25, Color("231233"))
			draw_circle(center + Vector2(-10, -5), 5, Color("5dfff1"))
			draw_circle(center + Vector2(10, -5), 5, Color("5dfff1"))
			draw_line(center + Vector2(-14, 12), center + Vector2(14, 12), accent, 3)
			draw_colored_polygon(PackedVector2Array([Vector2(24, 151), Vector2(108, 151), Vector2(94, 104), Vector2(38, 104)]), accent.darkened(0.08))
		draw_string(ThemeDB.fallback_font, Vector2(10, 163), title.to_upper(), HORIZONTAL_ALIGNMENT_CENTER, 112, 11, accent)
