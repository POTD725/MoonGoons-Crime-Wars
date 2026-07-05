extends Node
## Runtime safety guard implemented as composition.
## Prevents stale hidden focus from swallowing controls and bounds short-lived visual arrays.

const MAX_EFFECTS: int = 180
const MAX_PROJECTILES: int = 160

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(_delta: float) -> void:
	_release_hidden_focus()
	var scene: Node = get_tree().current_scene
	if scene == null:
		return
	_trim_array_property(scene, "effects", MAX_EFFECTS)
	_trim_array_property(scene, "projectiles", MAX_PROJECTILES)

func _release_hidden_focus() -> void:
	var focus_owner: Control = get_viewport().gui_get_focus_owner()
	if focus_owner != null and not focus_owner.is_visible_in_tree():
		focus_owner.release_focus()

func _trim_array_property(scene: Node, property_name: String, limit: int) -> void:
	var value: Variant = scene.get(property_name)
	if not (value is Array):
		return
	var entries: Array = value as Array
	while entries.size() > limit:
		entries.remove_at(0)
