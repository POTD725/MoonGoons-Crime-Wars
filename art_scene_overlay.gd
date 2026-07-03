extends Node
## Presents imported original MoonGoons/Dark Side SVG artwork in the active RTS screens.

const ORBIT_ART: Texture2D = preload("res://assets/graphics/darkside/hero_orbit.svg")
const DERELICT_ART: Texture2D = preload("res://assets/graphics/darkside/derelict_field.svg")
const DEPOT_ART: Texture2D = preload("res://assets/graphics/darkside/hideout_blueprint.svg")
const CARTEL_SIGIL: Texture2D = preload("res://assets/graphics/darkside/moon_sigil.svg")

var picker_art: TextureRect
var mission_canvas: CanvasLayer
var mission_art: TextureRect
var depot_card: TextureRect
var sigil: TextureRect
var last_picker: Control

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_mission_layer()

func _process(_delta: float) -> void:
	_attach_selection_backdrop()
	_refresh_mission_layer()

func _attach_selection_backdrop() -> void:
	if RaceMode == null:
		return
	var picker: Control = RaceMode.picker
	if picker == null:
		return
	if picker != last_picker:
		last_picker = picker
		picker_art = TextureRect.new()
		picker_art.texture = ORBIT_ART
		picker_art.position = Vector2(0.0, 0.0)
		picker_art.size = Vector2(1600.0, 600.0)
		picker_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		picker_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		picker_art.modulate = Color(1.0, 1.0, 1.0, 0.78)
		picker_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		picker.add_child(picker_art)
		picker.move_child(picker_art, 0)
		for child: Node in picker.get_children():
			if child is ColorRect:
				var shade: ColorRect = child as ColorRect
				shade.color = Color(0.004, 0.010, 0.030, 0.68)
				break

func _build_mission_layer() -> void:
	mission_canvas = CanvasLayer.new()
	mission_canvas.layer = 30
	mission_canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(mission_canvas)
	mission_art = TextureRect.new()
	mission_art.texture = DERELICT_ART
	mission_art.position = Vector2(95.0, 112.0)
	mission_art.size = Vector2(1410.0, 520.0)
	mission_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	mission_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	mission_art.modulate = Color(0.88, 0.92, 1.0, 0.18)
	mission_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mission_canvas.add_child(mission_art)
	depot_card = TextureRect.new()
	depot_card.texture = DEPOT_ART
	depot_card.position = Vector2(1210.0, 195.0)
	depot_card.size = Vector2(352.0, 154.0)
	depot_card.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	depot_card.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	depot_card.modulate = Color(1.0, 1.0, 1.0, 0.82)
	depot_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mission_canvas.add_child(depot_card)
	sigil = TextureRect.new()
	sigil.texture = CARTEL_SIGIL
	sigil.position = Vector2(1505.0, 151.0)
	sigil.size = Vector2(52.0, 52.0)
	sigil.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sigil.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	sigil.modulate = Color(1.0, 1.0, 1.0, 0.95)
	sigil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mission_canvas.add_child(sigil)
	mission_canvas.visible = false

func _refresh_mission_layer() -> void:
	var scene: Node = get_tree().current_scene
	if scene == null or not scene.has_method("_spawn_unit"):
		mission_canvas.visible = false
		return
	if RaceMode != null and RaceMode.picker != null and RaceMode.picker.visible:
		mission_canvas.visible = false
		return
	mission_canvas.visible = true
	var cartel_present: bool = true
	if RaceMode != null:
		cartel_present = RaceMode.chosen_rival == "lunar_cartel" or RaceMode.chosen_race == "lunar_cartel"
	depot_card.visible = cartel_present
	sigil.visible = cartel_present
