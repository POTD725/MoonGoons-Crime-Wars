extends Node
## Imported art catalog holder.
## This Godot installation does not expose SVG files as preloadable Texture2D resources
## immediately after a clean .godot rebuild, so artwork is deliberately kept out of
## the startup path until converted to PNG assets. This prevents editor startup errors.

const ORBIT_ART_PATH: String = "res://assets/graphics/darkside/hero_orbit.svg"
const DERELICT_ART_PATH: String = "res://assets/graphics/darkside/derelict_field.svg"
const DEPOT_ART_PATH: String = "res://assets/graphics/darkside/hideout_blueprint.svg"
const CARTEL_SIGIL_PATH: String = "res://assets/graphics/darkside/moon_sigil.svg"

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func has_source_art() -> bool:
	return FileAccess.file_exists(ORBIT_ART_PATH) and FileAccess.file_exists(DERELICT_ART_PATH) and FileAccess.file_exists(DEPOT_ART_PATH) and FileAccess.file_exists(CARTEL_SIGIL_PATH)
