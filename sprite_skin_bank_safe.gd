extends Node
## Safe runtime art bank for MoonGoons: Crime Wars.
## Creates one transparent SVG file per gameplay type, caches textures, and avoids preloaded SVGs.

const ROOT: String = "user://moongoons_crime_wars/graphics/"

const CATALOG: Dictionary = {
	"drone":{"group":"troops","body":"245575","accent":"8fe9ff","kind":"drone"},
	"deputy":{"group":"troops","body":"245575","accent":"8fe9ff","kind":"troop"},
	"shield":{"group":"troops","body":"44366d","accent":"d9c4ff","kind":"shield"},
	"hero":{"group":"troops","body":"5a4c29","accent":"ffd56d","kind":"hero"},
	"breacher":{"group":"troops","body":"6a3e2d","accent":"ffad78","kind":"troop"},
	"ranger":{"group":"troops","body":"315b78","accent":"b4e5ff","kind":"troop"},
	"medic":{"group":"troops","body":"1e6055","accent":"7dffd0","kind":"troop"},
	"engineer":{"group":"troops","body":"665722","accent":"ffd66e","kind":"troop"},
	"recon":{"group":"troops","body":"164e67","accent":"8deaff","kind":"troop"},
	"warden":{"group":"troops","body":"4c3670","accent":"d7b6ff","kind":"shield"},
	"raider":{"group":"syndicate","body":"6a2247","accent":"ff8fc0","kind":"troop"},
	"hacker":{"group":"syndicate","body":"51255f","accent":"df98ff","kind":"troop"},
	"bulwark_rover":{"group":"vehicles","body":"483b68","accent":"d9c4ff","kind":"vehicle"},
	"siege_crawler":{"group":"vehicles","body":"714929","accent":"ffc072","kind":"vehicle"},
	"arc_lancer":{"group":"vehicles","body":"1e5871","accent":"79e8ff","kind":"vehicle"},
	"pursuit_skimmer":{"group":"vehicles","body":"244f78","accent":"9dcbff","kind":"vehicle"},
	"bastion_tank":{"group":"vehicles","body":"713d42","accent":"ffb18b","kind":"vehicle"},
	"troop_carrier":{"group":"vehicles","body":"27584e","accent":"9ce0c0","kind":"carrier"},
	"mech_mover":{"group":"vehicles","body":"635939","accent":"f3d88d","kind":"mech"},
	"sky_lifter":{"group":"air","body":"20566c","accent":"a2efff","kind":"air"},
	"specter_flyer":{"group":"air","body":"483770","accent":"b49cff","kind":"air"},
	"lunar_bomber":{"group":"air","body":"714a2d","accent":"ffbf82","kind":"air"},
	"nexus":{"group":"structures","body":"21466b","accent":"8fe9ff","kind":"nexus"},
	"armory":{"group":"structures","body":"392557","accent":"c7a8ff","kind":"building"},
	"relay":{"group":"structures","body":"1b595d","accent":"72f2bd","kind":"relay"},
	"medbay":{"group":"structures","body":"1d574d","accent":"72f2bd","kind":"building"},
	"bay":{"group":"structures","body":"244875","accent":"7aa8ff","kind":"building"},
	"cells":{"group":"structures","body":"60472b","accent":"f3b85e","kind":"building"},
	"sentry_turret":{"group":"defenses","body":"173e58","accent":"78d8ff","kind":"turret"},
	"pulse_cannon":{"group":"defenses","body":"603d28","accent":"ffc46b","kind":"turret"},
	"machine_shop":{"group":"structures","body":"302454","accent":"b9a4ff","kind":"building"},
	"air_support_pad":{"group":"structures","body":"1e4d6a","accent":"77c8ff","kind":"airpad"},
	"o2_generator":{"group":"structures","body":"1d5a51","accent":"77f7d8","kind":"building"},
	"thermal_regulator":{"group":"structures","body":"684727","accent":"ffbf7c","kind":"building"},
	"radiation_array":{"group":"structures","body":"493269","accent":"c09cff","kind":"building"},
	"syndicate_relay":{"group":"syndicate","body":"60213d","accent":"ff74aa","kind":"relay"},
	"ore":{"group":"resources","body":"1d5f78","accent":"65eaff","kind":"resource"},
	"evidence":{"group":"resources","body":"6a4c24","accent":"ffca69","kind":"evidence"}
}

var texture_cache: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	ensure_all_assets()

func ensure_all_assets() -> void:
	for entry in CATALOG.keys():
		_ensure_asset(str(entry))

func get_skin_path(kind_name: String) -> String:
	if not CATALOG.has(kind_name):
		return ""
	var info: Dictionary = CATALOG[kind_name] as Dictionary
	return ROOT + str(info.get("group", "misc")) + "/" + kind_name + ".svg"

func get_texture(kind_name: String) -> Texture2D:
	if texture_cache.has(kind_name):
		return texture_cache[kind_name] as Texture2D
	var asset_path: String = _ensure_asset(kind_name)
	if asset_path.is_empty():
		return null
	var file: FileAccess = FileAccess.open(asset_path, FileAccess.READ)
	if file == null:
		return null
	var svg_data: String = file.get_as_text()
	file.close()
	var image: Image = Image.new()
	if image.load_svg_from_string(svg_data, 1.0) != OK:
		push_warning("Could not rasterize graphics skin: " + kind_name)
		return null
	var texture: Texture2D = ImageTexture.create_from_image(image)
	texture_cache[kind_name] = texture
	return texture

func _ensure_asset(kind_name: String) -> String:
	if not CATALOG.has(kind_name):
		return ""
	var asset_path: String = get_skin_path(kind_name)
	if FileAccess.file_exists(asset_path):
		return asset_path
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(asset_path.get_base_dir()))
	var file: FileAccess = FileAccess.open(asset_path, FileAccess.WRITE)
	if file == null:
		return ""
	file.store_string(_svg_for(kind_name))
	file.close()
	return asset_path

func _svg_for(kind_name: String) -> String:
	var info: Dictionary = CATALOG[kind_name] as Dictionary
	var group_name: String = str(info.get("group", "troops"))
	var art_kind: String = str(info.get("kind", "troop"))
	var body_color: String = "#" + str(info.get("body", "315b78"))
	var accent_color: String = "#" + str(info.get("accent", "8fe9ff"))
	if group_name == "troops" or (group_name == "syndicate" and art_kind != "relay"):
		return _troop_svg(body_color, accent_color, art_kind)
	if group_name == "vehicles":
		return _vehicle_svg(body_color, accent_color, art_kind)
	if group_name == "air":
		return _air_svg(body_color, accent_color)
	if group_name == "resources":
		return _resource_svg(body_color, accent_color, art_kind)
	return _structure_svg(body_color, accent_color, art_kind)

func _start_svg() -> String:
	return "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 256 256'>"

func _troop_svg(body_color: String, accent_color: String, art_kind: String) -> String:
	if art_kind == "drone":
		return _start_svg() + "<ellipse cx='128' cy='219' rx='72' ry='13' fill='#06101b' opacity='.45'/><path d='M72 121l29-44h55l29 44-21 57H92z' fill='" + body_color + "' stroke='" + accent_color + "' stroke-width='7'/><circle cx='128' cy='119' r='26' fill='" + accent_color + "'/><path d='M93 108L45 80M163 108l48-28M87 151l-45 25M169 151l45 25' stroke='" + accent_color + "' stroke-width='8' stroke-linecap='round'/><g fill='#effcff'><circle cx='42' cy='78' r='10'/><circle cx='214' cy='78' r='10'/><circle cx='40' cy='178' r='10'/><circle cx='216' cy='178' r='10'/></g></svg>"
	var shield_shape: String = ""
	if art_kind == "shield":
		shield_shape = "<path d='M68 107L31 131v67l37 27 29-23v-81z' fill='" + accent_color + "' opacity='.8' stroke='#effcff' stroke-width='6'/><path d='M78 125v71M49 145h28' stroke='#effcff' stroke-width='5'/>"
	return _start_svg() + "<ellipse cx='128' cy='221' rx='56' ry='13' fill='#05101c' opacity='.42'/><circle cx='128' cy='65' r='29' fill='#effcff' stroke='" + accent_color + "' stroke-width='6'/><circle cx='128' cy='65' r='8' fill='" + accent_color + "'/><path d='M78 114l50-23 46 23 14 84H68z' fill='" + body_color + "' stroke='" + accent_color + "' stroke-width='6'/><path d='M102 196l-12 33M153 196l12 33' stroke='#effcff' stroke-width='12' stroke-linecap='round'/>" + shield_shape + "<path d='M143 129l62 16-7 18-61-13z' fill='#effcff' stroke='" + body_color + "' stroke-width='5'/></svg>"

func _vehicle_svg(body_color: String, accent_color: String, art_kind: String) -> String:
	if art_kind == "mech":
		return _start_svg() + "<ellipse cx='128' cy='217' rx='79' ry='14' fill='#05101d' opacity='.43'/><path d='M85 95l43-34 49 34 10 67-41 18-52-18z' fill='" + body_color + "' stroke='" + accent_color + "' stroke-width='7'/><path d='M96 168l-25 49h32l18-40M157 176l19 40h33l-30-53' fill='" + body_color + "' stroke='" + accent_color + "' stroke-width='7'/><path d='M81 122l-34 31M179 122l35 29' stroke='#fff3c5' stroke-width='16' stroke-linecap='round'/><circle cx='132' cy='111' r='14' fill='" + accent_color + "'/></svg>"
	var cargo: String = ""
	if art_kind == "carrier":
		cargo = "<rect x='107' y='113' width='47' height='28' rx='4' fill='" + accent_color + "' opacity='.78'/><path d='M130 118v18M121 127h18' stroke='#effff8' stroke-width='4'/>"
	return _start_svg() + "<ellipse cx='128' cy='211' rx='91' ry='16' fill='#05101d' opacity='.43'/><path d='M45 151l26-51 98-27 47 35-20 61-116 14z' fill='" + body_color + "' stroke='" + accent_color + "' stroke-width='7'/><path d='M65 174l-19 24h55l12-22M167 169l12 22h48l-24-31' stroke='#0b1522' stroke-width='14' stroke-linecap='round'/><path d='M94 113l46-19 34 19-12 31H97z' fill='#effcff' opacity='.68'/><path d='M127 119l63-20' stroke='#effcff' stroke-width='10' stroke-linecap='round'/><circle cx='190' cy='99' r='7' fill='" + accent_color + "'/>" + cargo + "</svg>"

func _air_svg(body_color: String, accent_color: String) -> String:
	return _start_svg() + "<ellipse cx='128' cy='213' rx='73' ry='13' fill='#05101d' opacity='.38'/><path d='M31 144l74-33 27-43 22 43 71 33-20 21-68-14-72 14z' fill='" + body_color + "' stroke='" + accent_color + "' stroke-width='7'/><path d='M129 54l24 64-24 66-22-66z' fill='#effcff' opacity='.72'/><path d='M105 118h49' stroke='" + accent_color + "' stroke-width='6'/><circle cx='129' cy='103' r='10' fill='" + accent_color + "'/></svg>"

func _structure_svg(body_color: String, accent_color: String, art_kind: String) -> String:
	if art_kind == "turret":
		return _start_svg() + "<ellipse cx='128' cy='193' rx='70' ry='22' fill='" + body_color + "' stroke='" + accent_color + "' stroke-width='7'/><rect x='92' y='129' width='72' height='55' rx='11' fill='" + body_color + "' stroke='#effcff' stroke-width='6'/><path d='M128 133l72-49' stroke='#effcff' stroke-width='10' stroke-linecap='round'/><circle cx='202' cy='82' r='9' fill='" + accent_color + "'/></svg>"
	if art_kind == "airpad":
		return _start_svg() + "<ellipse cx='128' cy='150' rx='94' ry='64' fill='" + body_color + "' stroke='" + accent_color + "' stroke-width='8'/><path d='M58 150h140M128 91v118' stroke='#eaffff' stroke-width='7'/><circle cx='128' cy='150' r='27' fill='" + accent_color + "' opacity='.45'/><path d='M113 150h30M128 135v30' stroke='#eaffff' stroke-width='6'/></svg>"
	if art_kind == "relay":
		return _start_svg() + "<ellipse cx='128' cy='213' rx='76' ry='14' fill='#050d18' opacity='.4'/><path d='M128 52l56 126H72z' fill='" + body_color + "' stroke='" + accent_color + "' stroke-width='7'/><circle cx='128' cy='91' r='19' fill='#effff8'/><path d='M128 28v45M89 69l25 25M167 69l-25 25' stroke='" + accent_color + "' stroke-width='6'/><path d='M57 188h142' stroke='#effff8' stroke-width='8'/></svg>"
	if art_kind == "nexus":
		return _start_svg() + "<ellipse cx='128' cy='213' rx='96' ry='16' fill='#050d18' opacity='.4'/><path d='M25 189l28-83 45-35h60l45 35 28 83z' fill='" + body_color + "' stroke='" + accent_color + "' stroke-width='8'/><path d='M74 172h108M84 137h88' stroke='#effbff' stroke-width='7'/><circle cx='128' cy='93' r='32' fill='" + accent_color + "' opacity='.34'/><circle cx='128' cy='93' r='14' fill='#effbff'/></svg>"
	return _start_svg() + "<ellipse cx='128' cy='213' rx='91' ry='15' fill='#050d18' opacity='.4'/><path d='M37 183l16-76 42-36h68l40 36 16 76z' fill='" + body_color + "' stroke='" + accent_color + "' stroke-width='7'/><path d='M59 173h139' stroke='#effcff' stroke-width='6' opacity='.7'/><rect x='102' y='105' width='52' height='47' rx='5' fill='#effcff' opacity='.6'/><circle cx='128' cy='85' r='14' fill='" + accent_color + "'/></svg>"

func _resource_svg(body_color: String, accent_color: String, art_kind: String) -> String:
	if art_kind == "evidence":
		return _start_svg() + "<circle cx='128' cy='128' r='90' fill='" + accent_color + "' opacity='.12'/><path d='M63 104l65-45 65 45v76l-65 34-65-34z' fill='" + body_color + "' stroke='" + accent_color + "' stroke-width='7'/><circle cx='128' cy='132' r='32' fill='" + accent_color + "' opacity='.45'/><path d='M128 104v55M101 132h54' stroke='#fff0c6' stroke-width='7'/></svg>"
	return _start_svg() + "<circle cx='128' cy='128' r='88' fill='" + accent_color + "' opacity='.13'/><path d='M126 31l29 72-27 22-28-22zM51 128l53-28 22 29-28 32zM203 128l-53-28-22 29 28 32zM93 199l35-70 35 70-35 28z' fill='" + accent_color + "' stroke='#eaffff' stroke-width='5'/><circle cx='128' cy='128' r='13' fill='#eaffff'/></svg>"
