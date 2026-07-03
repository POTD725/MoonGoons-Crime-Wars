extends SceneTree

const CHECKS := [
	"res://main.tscn",
	"res://main.gd",
	"res://race_mode.gd",
	"res://custom_game.tscn",
	"res://custom_game.gd",
	"res://custom_match_runtime.gd",
	"res://custom_match_ai.gd",
	"res://strategic_ai_director.gd",
	"res://mission_rule_guard.gd",
	"res://free_roam.tscn",
	"res://lan_lobby.tscn",
	"res://player_gui.gd",
	"res://command_deck_art_overlay.gd",
	"res://world_silhouette_layer.gd",
	"res://combat_feedback.gd",
	"res://audio_feedback.gd",
	"res://game_profile.gd",
	"res://settings_console.gd",
	"res://pause_console.gd",
	"res://launch_screen.gd",
	"res://campaign_board.gd",
	"res://demo_mission_director.gd",
	"res://game_art_library.gd",
	"res://tactical_mesh_catalog.gd",
	"res://dossier_mesh_preview.gd",
	"res://officer_roster_texture.gd",
	"res://officer_roster.gd",
	"res://assets/graphics/moongoons_logo.svg",
	"res://assets/graphics/darkside_moon_sigil.svg"
]

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	for path in CHECKS:
		var resource: Resource = load(path)
		if resource == null:
			failures.append(path)
	var main_scene: PackedScene = load("res://main.tscn")
	if main_scene != null:
		var instance: Node = main_scene.instantiate()
		root.add_child(instance)
		await process_frame
		instance.queue_free()
		await process_frame
	if failures.is_empty():
		print("SMOKE TEST PASSED")
		quit(0)
	push_error("SMOKE TEST FAILED: " + ", ".join(failures))
	quit(1)
