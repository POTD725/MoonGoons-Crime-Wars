extends Node
## Displays a low-poly 3D preview for the selected mobile game entity.
## Buildings keep the imported SVG dossier artwork.

var canvas: CanvasLayer
var display: TextureRect
var viewport_3d: SubViewport
var scene_root: Node3D
var model_anchor: Node3D
var current_id := -1
var current_kind := ""
var current_race := ""

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_preview()

func _process(delta: float) -> void:
	if PlayerGUI == null or PlayerGUI.canvas == null or PlayerGUI.game == null:
		canvas.visible = false
		return
	canvas.visible = PlayerGUI.canvas.visible
	if not canvas.visible:
		return
	var entity: Dictionary = _selected_entity()
	var show_mesh: bool = not entity.is_empty() and not entity.has("size")
	display.visible = show_mesh
	if show_mesh:
		if PlayerGUI.portrait != null:
			PlayerGUI.portrait.visible = false
		var entity_id: int = int(entity.get("id", -1))
		var kind: String = str(entity.get("kind", "deputy"))
		var race_id: String = str(entity.get("race", "authority"))
		if entity_id != current_id or kind != current_kind or race_id != current_race:
			_rebuild_model(kind, race_id)
		model_anchor.rotation_degrees.y += delta * 28.0
	else:
		if PlayerGUI.portrait != null and not _structure_selected():
			PlayerGUI.portrait.visible = true

func _build_preview() -> void:
	canvas = CanvasLayer.new()
	canvas.layer = 44
	canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(canvas)
	var root: Control = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(root)

	viewport_3d = SubViewport.new()
	viewport_3d.size = Vector2i(320, 320)
	viewport_3d.transparent_bg = true
	viewport_3d.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	canvas.add_child(viewport_3d)

	scene_root = Node3D.new()
	viewport_3d.add_child(scene_root)
	model_anchor = Node3D.new()
	scene_root.add_child(model_anchor)

	var camera: Camera3D = Camera3D.new()
	camera.position = Vector3(0.0, 1.25, 4.8)
	camera.look_at_from_position(camera.position, Vector3(0.0, 0.88, 0.0), Vector3.UP)
	camera.current = true
	scene_root.add_child(camera)

	var key_light: DirectionalLight3D = DirectionalLight3D.new()
	key_light.light_energy = 1.30
	key_light.rotation_degrees = Vector3(-48.0, -32.0, 0.0)
	scene_root.add_child(key_light)
	var rim_light: OmniLight3D = OmniLight3D.new()
	rim_light.position = Vector3(-1.8, 1.6, 1.4)
	rim_light.light_color = Color("8fe9ff")
	rim_light.light_energy = 2.0
	rim_light.omni_range = 6.0
	scene_root.add_child(rim_light)

	display = TextureRect.new()
	display.position = Vector2(34, 708)
	display.size = Vector2(104, 145)
	display.texture = viewport_3d.get_texture()
	display.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	display.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	display.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(display)
	display.visible = false

func _selected_entity() -> Dictionary:
	var game: Node = PlayerGUI.game
	if int(game.get("selected_building")) != -1:
		return game.call("_entity", int(game.get("selected_building")))
	var selected: Array = game.get("selected")
	if selected.size() == 1:
		return game.call("_entity", int(selected[0]))
	return {}

func _structure_selected() -> bool:
	var entity: Dictionary = _selected_entity()
	return not entity.is_empty() and entity.has("size")

func _rebuild_model(kind: String, race_id: String) -> void:
	for child in model_anchor.get_children():
		child.queue_free()
	var model: Node3D = TacticalMeshCatalog.build_model(kind, race_id)
	model_anchor.add_child(model)
	current_id = int(_selected_entity().get("id", -1))
	current_kind = kind
	current_race = race_id
