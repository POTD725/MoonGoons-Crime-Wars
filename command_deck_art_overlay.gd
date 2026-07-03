extends Node
## Places imported MoonGoons / Dark Side artwork into the live Command Deck.
## Kept separate from PlayerGUI so visual upgrades do not disturb tactical controls.

var canvas: CanvasLayer
var root: Control
var logo: TextureRect
var enemy_sigil: TextureRect
var structure_art: TextureRect
var art_tag: Label
var art_active := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_overlay()

func _process(_delta: float) -> void:
	if PlayerGUI == null or PlayerGUI.canvas == null:
		canvas.visible = false
		return
	canvas.visible = PlayerGUI.canvas.visible and PlayerGUI.game != null
	if not canvas.visible:
		return
	_sync_top_bar()
	_sync_dossier_art()

func _build_overlay() -> void:
	canvas = CanvasLayer.new()
	canvas.layer = 43
	canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(canvas)
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(root)

	logo = TextureRect.new()
	logo.texture = GameArtLibrary.MOONGOONS_LOGO
	logo.position = Vector2(82, 5)
	logo.size = Vector2(286, 60)
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(logo)

	enemy_sigil = TextureRect.new()
	enemy_sigil.texture = GameArtLibrary.DARKSIDE_MOON_SIGIL
	enemy_sigil.position = Vector2(1176, 13)
	enemy_sigil.size = Vector2(48, 48)
	enemy_sigil.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	enemy_sigil.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	enemy_sigil.tooltip_text = "Dark Side hostile-network signature"
	enemy_sigil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(enemy_sigil)

	structure_art = TextureRect.new()
	structure_art.position = Vector2(34, 708)
	structure_art.size = Vector2(104, 145)
	structure_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	structure_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	structure_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	structure_art.visible = false
	root.add_child(structure_art)

	art_tag = Label.new()
	art_tag.position = Vector2(34, 838)
	art_tag.size = Vector2(104, 14)
	art_tag.text = "LIVE ART"
	art_tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	art_tag.add_theme_font_size_override("font_size", 9)
	art_tag.add_theme_color_override("font_color", Color("8fe9ff"))
	art_tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art_tag.visible = false
	root.add_child(art_tag)

func _sync_top_bar() -> void:
	if PlayerGUI.top_bar == null:
		return
	for child in PlayerGUI.top_bar.get_children():
		if child is Label and str(child.text).begins_with("MOONGOONS AUTHORITY // COMMAND DECK"):
			child.visible = false
	if PlayerGUI.mission_label != null:
		PlayerGUI.mission_label.position = Vector2(382, 39)
		PlayerGUI.mission_label.size = Vector2(225, 22)
		PlayerGUI.mission_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

func _sync_dossier_art() -> void:
	var entity := _selected_entity()
	var should_show := GameArtLibrary.has_structure_art(entity)
	structure_art.visible = should_show
	art_tag.visible = should_show
	if should_show:
		structure_art.texture = GameArtLibrary.structure_texture(entity)
	if PlayerGUI.portrait != null:
		PlayerGUI.portrait.visible = not should_show
	art_active = should_show

func _selected_entity() -> Dictionary:
	var game: Node = PlayerGUI.game
	if game == null:
		return {}
	if int(game.get("selected_building")) != -1:
		return game.call("_entity", int(game.get("selected_building")))
	var selected: Array = game.get("selected")
	if selected.size() == 1:
		return game.call("_entity", int(selected[0]))
	return {}
