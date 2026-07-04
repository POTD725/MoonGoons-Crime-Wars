extends Node
## Loads the isolated PNG core-art package when installed under res://assets/graphics.
## Missing files fall back to the legacy SkinBank so the game stays playable.

const CORE_PATHS: Dictionary = {
	"nexus":"res://assets/graphics/structures/command_nexus.png",
	"armory":"res://assets/graphics/structures/tactical_armory.png",
	"machine_shop":"res://assets/graphics/structures/machine_shop.png",
	"drone":"res://assets/graphics/troops/builder_drone.png",
	"deputy":"res://assets/graphics/troops/patrol_deputy.png",
	"shield":"res://assets/graphics/troops/shield_deputy.png",
	"sentry_turret":"res://assets/graphics/defenses/sentry_turret.png",
	"pulse_cannon":"res://assets/graphics/defenses/pulse_cannon.png",
	"ore":"res://assets/graphics/resources/ore_deposit.png",
	"evidence":"res://assets/graphics/resources/evidence_cache.png",
	"cargo_crate":"res://assets/graphics/environment/cargo_crate.png",
	"wrecked_shuttle":"res://assets/graphics/environment/wrecked_shuttle.png",
	"cargo_wall":"res://assets/graphics/environment/cargo_wall.png",
	"crater":"res://assets/graphics/environment/crater.png"
}

var texture_cache: Dictionary = {}
var missing_assets: Array[String] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	validate_assets()

func get_texture(kind_name: String) -> Texture2D:
	if texture_cache.has(kind_name):
		return texture_cache[kind_name] as Texture2D
	if CORE_PATHS.has(kind_name):
		var asset_path: String = str(CORE_PATHS[kind_name])
		if ResourceLoader.exists(asset_path):
			var core_texture: Texture2D = load(asset_path) as Texture2D
			if core_texture != null:
				texture_cache[kind_name] = core_texture
				return core_texture
	if SkinBank != null:
		return SkinBank.get_texture(kind_name) as Texture2D
	return null

func validate_assets() -> void:
	missing_assets.clear()
	texture_cache.clear()
	for kind_value in CORE_PATHS.keys():
		var kind_name: String = str(kind_value)
		var asset_path: String = str(CORE_PATHS[kind_name])
		if not ResourceLoader.exists(asset_path):
			missing_assets.append(kind_name)
			continue
		var loaded_texture: Texture2D = load(asset_path) as Texture2D
		if loaded_texture == null or loaded_texture.get_size().x < 8.0 or loaded_texture.get_size().y < 8.0:
			missing_assets.append(kind_name)
		else:
			texture_cache[kind_name] = loaded_texture

func core_assets_ready() -> bool:
	return missing_assets.is_empty()

func status_text() -> String:
	var ready_count: int = CORE_PATHS.size() - missing_assets.size()
	return "CORE PNG ART %d/%d" % [ready_count, CORE_PATHS.size()]

func list_missing() -> String:
	return ", ".join(missing_assets)
