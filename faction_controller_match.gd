extends Node

const CARD_ART: Script = preload("res://faction_card_art.gd")

var root: Node
var root_id: int = -1
var chosen_race: String = "authority"
var chosen_rival: String = "lunar_cartel"
var picker_resolved: bool = false
var picker: Control
var detail_panel: Panel
var detail_title: Label
var detail_body: Label

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_picker()

func _process(_delta: float) -> void:
	var current: Node = get_tree().current_scene
	if current == null or not current.has_method("_spawn_unit") or not current.has_method("_spawn_building"):
		root = null
		return
	if current.get_instance_id() == root_id:
		return
	root = current
	root_id = current.get_instance_id()
	if MatchState.take_ready():
		chosen_race = MatchState.player_race
		chosen_rival = MatchState.opposing_race
		GameDifficulty.set_level(MatchState.level_id)
		root.set_meta("custom_match", true)
		root.set_meta("race_selected", true)
		root.set_meta("faction_picker_active", false)
		picker_resolved = true
		picker.visible = false
		_tag_entities()
		root.call("flash", "CUSTOM MATCH // " + MatchState.selected_map + " // " + MatchState.selected_mode, 4.0)
		return
	if picker_resolved:
		root.set_meta("race_selected", true)
		root.set_meta("faction_picker_active", false)
		picker.visible = false
		_tag_entities()
		return
	chosen_race = "authority"
	chosen_rival = "lunar_cartel"
	_show_picker()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F1 and root != null:
		_show_picker()
		get_viewport().set_input_as_handled()

func _show_picker() -> void:
	if root == null:
		return
	root.set_meta("faction_picker_active", true)
	picker.visible = true
	get_tree().paused = true

func _choose(race_id: String) -> void:
	chosen_race = race_id
	chosen_rival = RaceCatalog.get_rival(race_id)
	picker_resolved = true
	_tag_entities()
	root.set_meta("race_selected", true)
	root.set_meta("faction_picker_active", false)
	root.call("flash", "FACTION // " + RaceCatalog.label_for(race_id), 3.0)
	picker.visible = false
	get_tree().paused = false

func _tag_entities() -> void:
	if root == null:
		return
	for entity: Dictionary in root.get("units"):
		entity["race"] = chosen_race if str(entity.get("team", "")) == "authority" else chosen_rival
	for entity: Dictionary in root.get("buildings"):
		entity["race"] = chosen_race if str(entity.get("team", "")) == "authority" else chosen_rival

func _reset_mission(race_id: String, rival_id: String) -> void:
	chosen_race = race_id
	chosen_rival = rival_id
	picker_resolved = true
	_tag_entities()

func _build_picker() -> void:
	var canvas: CanvasLayer = CanvasLayer.new()
	canvas.layer = 35
	canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(canvas)
	picker = Control.new()
	picker.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	picker.mouse_filter = Control.MOUSE_FILTER_STOP
	canvas.add_child(picker)

	var shade: ColorRect = ColorRect.new()
	shade.color = Color(0.004, 0.010, 0.030, 0.98)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	picker.add_child(shade)

	var title: Label = Label.new()
	title.text = "MOONGOONS: CRIME WARS"
	title.position = Vector2(80, 28)
	title.size = Vector2(1440, 44)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", Color("eaf5ff"))
	picker.add_child(title)

	var subtitle: Label = Label.new()
	subtitle.text = "SELECT YOUR FACTION // HOVER A CARD FOR COMMAND INTELLIGENCE"
	subtitle.position = Vector2(80, 75)
	subtitle.size = Vector2(1440, 26)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 16)
	subtitle.add_theme_color_override("font_color", Color("9ec6ed"))
	picker.add_child(subtitle)

	var hint: Label = Label.new()
	hint.text = "Each faction has a unique economy, construction method, commander, and battlefield rhythm. Click a card to deploy."
	hint.position = Vector2(80, 102)
	hint.size = Vector2(1440, 22)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 13)
	hint.add_theme_color_override("font_color", Color("b8cadf"))
	picker.add_child(hint)

	var ids: Array[String] = ["authority", "lunar_cartel", "null_choir", "hollow_fang"]
	for index in range(ids.size()):
		_add_faction_card(ids[index], index)
	_build_detail_panel()
	_show_detail("authority")
	picker.visible = false

func _add_faction_card(race_id: String, index: int) -> void:
	var data: Dictionary = RaceCatalog.RACES[race_id]
	var accent: Color = Color(str(data.get("accent", "#8fe9ff")))
	var card: Button = Button.new()
	card.position = Vector2(26.0 + float(index) * 388.0, 150.0)
	card.size = Vector2(366.0, 500.0)
	card.tooltip_text = _tooltip_for(race_id)
	card.add_theme_stylebox_override("normal", _card_style(accent, 0.14, 2))
	card.add_theme_stylebox_override("hover", _card_style(accent, 0.27, 4))
	card.add_theme_stylebox_override("pressed", _card_style(accent, 0.34, 5))
	card.pressed.connect(_choose.bind(race_id))
	card.mouse_entered.connect(_show_detail.bind(race_id))
	card.focus_entered.connect(_show_detail.bind(race_id))
	picker.add_child(card)

	var name_label: Label = Label.new()
	name_label.text = str(data.get("name", race_id)).to_upper()
	name_label.position = Vector2(14, 13)
	name_label.size = Vector2(338, 30)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.add_theme_color_override("font_color", accent.lightened(0.22))
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(name_label)

	var motto_label: Label = Label.new()
	motto_label.text = str(data.get("subtitle", ""))
	motto_label.position = Vector2(16, 46)
	motto_label.size = Vector2(334, 38)
	motto_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	motto_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	motto_label.add_theme_font_size_override("font_size", 13)
	motto_label.add_theme_color_override("font_color", Color("d6e6f5"))
	motto_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(motto_label)

	var art: Control = CARD_ART.new()
	art.position = Vector2(18, 96)
	art.size = Vector2(330, 198)
	art.call("configure", race_id, accent)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(art)

	var commander_label: Label = Label.new()
	commander_label.text = "COMMANDER // " + str(data.get("hero", "Unknown"))
	commander_label.position = Vector2(16, 307)
	commander_label.size = Vector2(334, 24)
	commander_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	commander_label.add_theme_font_size_override("font_size", 14)
	commander_label.add_theme_color_override("font_color", Color("f4fbff"))
	commander_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(commander_label)

	var method_label: Label = Label.new()
	method_label.text = "BUILD METHOD\n" + str(data.get("construction", ""))
	method_label.position = Vector2(22, 342)
	method_label.size = Vector2(322, 82)
	method_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	method_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	method_label.add_theme_font_size_override("font_size", 12)
	method_label.add_theme_color_override("font_color", Color("bbcee1"))
	method_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(method_label)

	var deploy_label: Label = Label.new()
	deploy_label.text = "HOVER FOR DETAILS  •  CLICK TO DEPLOY"
	deploy_label.position = Vector2(12, 454)
	deploy_label.size = Vector2(342, 25)
	deploy_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	deploy_label.add_theme_font_size_override("font_size", 12)
	deploy_label.add_theme_color_override("font_color", accent)
	deploy_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(deploy_label)

func _build_detail_panel() -> void:
	detail_panel = Panel.new()
	detail_panel.position = Vector2(72, 682)
	detail_panel.size = Vector2(1456, 160)
	detail_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	picker.add_child(detail_panel)
	detail_title = Label.new()
	detail_title.position = Vector2(24, 16)
	detail_title.size = Vector2(1408, 28)
	detail_title.add_theme_font_size_override("font_size", 20)
	detail_panel.add_child(detail_title)
	detail_body = Label.new()
	detail_body.position = Vector2(24, 49)
	detail_body.size = Vector2(1408, 92)
	detail_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_body.add_theme_font_size_override("font_size", 15)
	detail_body.add_theme_color_override("font_color", Color("eaf5ff"))
	detail_panel.add_child(detail_body)

func _show_detail(race_id: String) -> void:
	if detail_panel == null:
		return
	var data: Dictionary = RaceCatalog.RACES[race_id]
	var accent: Color = Color(str(data.get("accent", "#8fe9ff")))
	detail_panel.add_theme_stylebox_override("panel", _detail_style(accent))
	detail_title.text = str(data.get("name", race_id)).to_upper() + " // FIELD INTELLIGENCE"
	detail_title.add_theme_color_override("font_color", accent.lightened(0.18))
	detail_body.text = _detail_for(race_id)

func _detail_for(race_id: String) -> String:
	match race_id:
		"authority":
			return "ROLE: Balanced defense and stable growth.  ECONOMY: Completed precinct rooms provide Supplies.  SIGNATURE: Chief Nova, Shield Deputies, Medbay recovery.  STRENGTH: Durable positions and forgiving rebuilds.  WATCH OUT: Early attacks are steadier than explosive.  RECOMMENDED: First-time commanders."
		"lunar_cartel":
			return "ROLE: High-tempo harassment and fast income.  ECONOMY: Hideouts supply extra Credits and Intel.  SIGNATURE: Vexa Null, Contraband Riggers, rapid raiders.  STRENGTH: Cheap expansion and map pressure.  WATCH OUT: Light structures collapse if caught out.  RECOMMENDED: Players who enjoy speed."
		"null_choir":
			return "ROLE: Intel control and long-range scaling.  ECONOMY: Connected signal sites generate Intel.  SIGNATURE: Nyx Relay, Signal Seeds, the Harmonic Core.  STRENGTH: Recon power and advanced late operations.  WATCH OUT: Slow beginnings and fragile forward nodes.  RECOMMENDED: Planners."
		"hollow_fang":
			return "ROLE: Armored close-range pushes.  ECONOMY: Salvage generates Supplies and Credits.  SIGNATURE: Nash Vanta, Scrapwrights, the War-Rig assault line.  STRENGTH: Tough troops and durable camps.  WATCH OUT: Needs distance closed before its power peaks.  RECOMMENDED: Direct fighters."
		_:
			return "Hover a faction card to review its command profile."

func _tooltip_for(race_id: String) -> String:
	var data: Dictionary = RaceCatalog.RACES[race_id]
	return str(data.get("name", race_id)) + "\n\n" + _detail_for(race_id)

func _card_style(accent: Color, intensity: float, width: int) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(accent.r * intensity, accent.g * intensity, accent.b * intensity, 0.98)
	style.border_color = accent
	style.set_border_width_all(width)
	style.corner_radius_top_left = 15
	style.corner_radius_top_right = 15
	style.corner_radius_bottom_left = 15
	style.corner_radius_bottom_right = 15
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.52)
	style.shadow_size = 8
	return style

func _detail_style(accent: Color) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.018, 0.050, 0.105, 0.98)
	style.border_color = accent
	style.set_border_width_all(3)
	style.corner_radius_top_left = 13
	style.corner_radius_top_right = 13
	style.corner_radius_bottom_left = 13
	style.corner_radius_bottom_right = 13
	return style
