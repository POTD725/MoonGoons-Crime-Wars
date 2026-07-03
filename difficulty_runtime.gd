extends Node

var watched_scene_id: int = -1

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(_delta: float) -> void:
	var scene: Node = get_tree().current_scene
	if scene == null or not scene.has_method("_spawn_unit"):
		return
	if scene.get_instance_id() != watched_scene_id:
		watched_scene_id = scene.get_instance_id()
		_apply_scene_scale(scene)

func _apply_scene_scale(scene: Node) -> void:
	if bool(scene.get_meta("difficulty_applied", false)):
		return
	var start_scale: float = GameDifficulty.multiplier("start_multiplier")
	scene.set("credits", int(round(float(scene.get("credits")) * start_scale)))
	scene.set("supplies", int(round(float(scene.get("supplies")) * start_scale)))
	scene.set("intel", int(round(float(scene.get("intel")) * start_scale)))
	scene.set_meta("difficulty_applied", true)
	if scene.has_method("flash"):
		scene.call("flash", "DIFFICULTY // " + GameDifficulty.label(), 2.0)
