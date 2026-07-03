extends Node

var root: Node
var root_id: int = -1
var chosen_race: String = "authority"
var chosen_rival: String = "lunar_cartel"
var picker: Control

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
		_tag_entities()
		root.call("flash", "CUSTOM MATCH // " + MatchState.selected_map + " // " + MatchState.selected_mode, 4.0)
		return
	chosen_race = "authority"
	chosen_rival = "lunar_cartel"
	_show_picker()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F1 and root != null:
		_show_picker()
		get_viewport().set_input_as_handled()

func _show_picker() -> void:
	if root == null or picker.visible:
		return
	picker.visible = true
	get_tree().paused = true

func _choose(race_id: String) -> void:
	chosen_race = race_id
	chosen_rival = RaceCatalog.get_rival(race_id)
	_tag_entities()
	root.set_meta("race_selected", true)
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
	shade.color = Color(0.005, 0.01, 0.03, 0.96)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	picker.add_child(shade)
	var title: Label = Label.new()
	title.text = "SELECT FACTION"
	title.position = Vector2(100, 70)
	title.size = Vector2(1400, 44)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", Color("8fe9ff"))
	picker.add_child(title)
	var ids: Array[String] = ["authority", "lunar_cartel", "null_choir", "hollow_fang"]
	for index: int in ids.size():
		var race_id: String = ids[index]
		var data: Dictionary = RaceCatalog.RACES[race_id]
		var button: Button = Button.new()
		button.position = Vector2(95 + index * 385, 190)
		button.size = Vector2(330, 360)
		button.text = "%s\n\n%s\n\n%s\n\nHERO // %s\n\nDEPLOY" % [str(data.get("name", race_id)), str(data.get("style", "")), str(data.get("construction", "")), str(data.get("hero", ""))]
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.add_theme_font_size_override("font_size", 15)
		button.pressed.connect(_choose.bind(race_id))
		picker.add_child(button)
	picker.visible = false
