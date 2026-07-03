extends Node
## Runtime art bridge. SVG source files are rasterized inside Godot instead of preloaded,
## avoiding the SVG ResourceLoader issue seen after a clean .godot rebuild.

const ORBIT_ART_PATH: String = "res://assets/graphics/darkside/hero_orbit.svg"
const DERELICT_ART_PATH: String = "res://assets/graphics/darkside/derelict_field.svg"
const DEPOT_ART_PATH: String = "res://assets/graphics/darkside/hideout_blueprint.svg"
const CARTEL_SIGIL_PATH: String = "res://assets/graphics/darkside/moon_sigil.svg"

var orbit_texture: Texture2D
var derelict_texture: Texture2D
var depot_texture: Texture2D
var sigil_texture: Texture2D
var picker_art: TextureRect
var mission_canvas: CanvasLayer
var mission_art: TextureRect
var depot_card: TextureRect
var sigil: TextureRect
var last_picker: Control

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	orbit_texture = _load_svg_texture(ORBIT_ART_PATH)
	derelict_texture = _load_svg_texture(DERELICT_ART_PATH)
	depot_texture = _load_svg_texture(DEPOT_ART_PATH)
	sigil_texture = _load_svg_texture(CARTEL_SIGIL_PATH)
	_build_mission_layer()

func _process(_delta: float) -> void:
	_attach_selection_backdrop()
	_refresh_mission_layer()

func _load_svg_texture(path: String) -> Texture2D:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_warning("MoonGoons source art is unavailable: " + path)
		return null
	var svg_text: String = file.get_as_text()
	file.close()
	if svg_text.is_empty():
		return null
	var image: Image = Image.new()
	var result: Error = image.load_svg_from_string(svg_text, 1.0)
	if result != OK:
		push_warning("MoonGoons could not rasterize source art: " + path)
		return null
	return ImageTexture.create_from_image(image)

func _attach_selection_backdrop() -> void:
	if RaceMode == null or orbit_texture == null:
		return
	var picker: Control = RaceMode.picker
	if picker == null:
		return
	if picker == last_picker:
		return
	last_picker = picker
	picker_art = TextureRect.new()
	picker_art.texture = orbit_texture
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
	mission_art.position = Vector2(95.0, 112.0)
	mission_art.size = Vector2(1410.0, 520.0)
	mission_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	mission_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	mission_art.modulate = Color(0.88, 0.92, 1.0, 0.18)
	mission_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mission_art.texture = derelict_texture
	mission_canvas.add_child(mission_art)
	depot_card = TextureRect.new()
	depot_card.position = Vector2(1210.0, 195.0)
	depot_card.size = Vector2(352.0, 154.0)
	depot_card.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	depot_card.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	depot_card.modulate = Color(1.0, 1.0, 1.0, 0.82)
	depot_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	depot_card.texture = depot_texture
	mission_canvas.add_child(depot_card)
	sigil = TextureRect.new()
	sigil.position = Vector2(1505.0, 151.0)
	sigil.size = Vector2(52.0, 52.0)
	sigil.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sigil.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	sigil.modulate = Color(1.0, 1.0, 1.0, 0.95)
	sigil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sigil.texture = sigil_texture
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
	mission_canvas.visible = derelict_texture != null
	var cartel_present: bool = true
	if RaceMode != null:
		cartel_present = RaceMode.chosen_rival == "lunar_cartel" or RaceMode.chosen_race == "lunar_cartel"
	depot_card.visible = cartel_present and depot_texture != null
	sigil.visible = cartel_present and sigil_texture != null

func has_source_art() -> bool:
	return orbit_texture != null and derelict_texture != null and depot_texture != null and sigil_texture != null
