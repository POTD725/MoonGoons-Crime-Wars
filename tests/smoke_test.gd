extends SceneTree

const CHECKS: Array[String] = [
	"res://main.tscn",
	"res://main_safe.gd",
	"res://dev_console_light.gd",
	"res://game_profile.gd",
	"res://faction_catalog.gd",
	"res://match_state.gd",
	"res://faction_controller_match.gd",
	"res://difficulty_profile.gd",
	"res://difficulty_console.gd",
	"res://hud.gd",
	"res://custom_game_safe.gd",
	"res://skirmish_screen.tscn"
]

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	for path: String in CHECKS:
		var resource: Resource = load(path)
		if resource == null:
			failures.append(path)
	var scene: PackedScene = load("res://main.tscn")
	if scene != null:
		var instance: Node = scene.instantiate()
		root.add_child(instance)
		await process_frame
		instance.queue_free()
		await process_frame
	if failures.is_empty():
		print("SMOKE TEST PASSED")
		quit(0)
	push_error("SMOKE TEST FAILED: " + ", ".join(failures))
	quit(1)
