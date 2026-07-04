extends Node
## Runtime skin bank. Every active game type receives its own transparent SVG skin.
## The files are generated once under user:// and rasterized safely at runtime.

const ROOT: String = "user://moongoons_crime_wars/graphics/"

const CATALOG: Dictionary = {
	"drone":{"group":"troops","shape":"drone","body":"245575","accent":"8fe9ff","ink":"effcff"},
	"deputy":{"group":"troops","shape":"troop","body":"245575","accent":"8fe9ff","ink":"effcff"},
	"shield":{"group":"troops","shape":"shield","body":"44366d","accent":"d9c4ff","ink":"f4edff"},
	"hero":{"group":"troops","shape":"hero","body":"5a4c29","accent":"ffd56d","ink":"fff3bf"},
	"breacher":{"group":"troops","shape":"breacher","body":"6a3e2d","accent":"ffad78","ink":"fff1de"},
	"ranger":{"group":"troops","shape":"ranger","body":"315b78","accent":"b4e5ff","ink":"effaff"},
	"medic":{"group":"troops","shape":"medic","body":"1e6055","accent":"7dffd0","ink":"effff8"},
	"engineer":{"group":"troops","shape":"engineer","body":"665722","accent":"ffd66e","ink":"fff3bc"},
	"recon":{"group":"troops","shape":"recon","body":"164e67","accent":"8deaff","ink":"edffff"},
	"warden":{"group":"troops","shape":"warden","body":"4c3670","accent":"d7b6ff","ink":"f5ecff"},
	"raider":{"group":"syndicate","shape":"raider","body":"6a2247","accent":"ff8fc0","ink":"ffe3ef"},
	"hacker":{"group":"syndicate","shape":"hacker","body":"51255f","accent":"df98ff","ink":"fff0ff"},
	"bulwark_rover":{"group":"vehicles","shape":"rover","body":"483b68","accent":"d9c4ff","ink":"eee6ff"},
	"siege_crawler":{"group":"vehicles","shape":"crawler","body":"714929","accent":"ffc072","ink":"fff0cc"},
	"arc_lancer":{"group":"vehicles","shape":"lancer","body":"1e5871","accent":"79e8ff","ink":"e8fcff"},
	"pursuit_skimmer":{"group":"vehicles","shape":"skimmer","body":"244f78","accent":"9dcbff","ink":"edfbff"},
	"bastion_tank":{"group":"vehicles","shape":"tank","body":"713d42","accent":"ffb18b","ink":"fff0df"},
	"troop_carrier":{"group":"vehicles","shape":"carrier","body":"27584e","accent":"9ce0c0","ink":"effff8"},
	"mech_mover":{"group":"vehicles","shape":"mech","body":"635939","accent":"f3d88d","ink":"fff3c5"},
	"sky_lifter":{"group":"air","shape":"lifter","body":"20566c","accent":"a2efff","ink":"edffff"},
	"specter_flyer":{"group":"air","shape":"specter","body":"483770","accent":"b49cff","ink":"f2ebff"},
	"lunar_bomber":{"group":"air","shape":"bomber","body":"714a2d","accent":"ffbf82","ink":"fff0dc"},
	"nexus":{"group":"structures","shape":"nexus","body":"21466b","accent":"8fe9ff","ink":"effbff"},
	"armory":{"group":"structures","shape":"armory","body":"392557","accent":"c7a8ff","ink":"f4ebff"},
	"relay":{"group":"structures","shape":"relay","body":"1b595d","accent":"72f2bd","ink":"effff8"},
	"medbay":{"group":"structures","shape":"medbay","body":"1d574d","accent":"72f2bd","ink":"effff8"},
	"bay":{"group":"structures","shape":"bay","body":"244875","accent":"7aa8ff","ink":"eaf4ff"},
	"cells":{"group":"structures","shape":"cells","body":"60472b","accent":"f3b85e","ink":"fff0c9"},
	"sentry_turret":{"group":"defenses","shape":"turret","body":"173e58","accent":"78d8ff","ink":"e8fbff"},
	"pulse_cannon":{"group":"defenses","shape":"cannon","body":"603d28","accent":"ffc46b","ink":"fff4d6"},
	"machine_shop":{"group":"structures","shape":"shop","body":"302454","accent":"b9a4ff","ink":"eeeaff"},
	"air_support_pad":{"group":"structures","shape":"airpad","body":"1e4d6a","accent":"77c8ff","ink":"eaffff"},
	"o2_generator":{"group":"structures","shape":"oxygen","body":"1d5a51","accent":"77f7d8","ink":"effff8"},
	"thermal_regulator":{"group":"structures","shape":"thermal","body":"684727","accent":"ffbf7c","ink":"fff0d7"},
	"radiation_array":{"group":"structures","shape":"radiation","body":"493269","accent":"c09cff","ink":"f3eaff"},
	"syndicate_relay":{"group":"syndicate","shape":"relay","body":"60213d","accent":"ff74aa","ink":"ffe4f0"},
	"ore":{"group":"resources","shape":"ore","body":"1d5f78","accent":"65eaff","ink":"eaffff"},
	"evidence":{"group":"resources","shape":"evidence","body":"6a4c24","accent":"ffca69","ink":"fff0c6"}
}

var texture_cache: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	ensure_all_assets()

func ensure_all_assets() -> void:
	for item_key in CATALOG.keys():
		_ensure_asset(str(item_key))

func get_skin_path(kind: String) -> String:
	if not CATALOG.has(kind):
		return ""
	var info: Dictionary = CATALOG[kind] as Dictionary
	return ROOT + str(info.get("group", "misc")) + "/" + kind + ".svg"

func get_texture(kind: String) -> Texture2D:
	if texture_cache.has(kind):
		return texture_cache[kind] as Texture2D
	if not CATALOG.has(kind):
		return null
	var path_value: String = _ensure_asset(kind)
	var source_file: FileAccess = FileAccess.open(path_value, FileAccess.READ)
	if source_file == null:
		return null
	var svg_text: String = source_file.get_as_text()
	source_file.close()
	var image: Image = Image.new()
	if image.load_svg_from_string(svg_text, 1.0) != OK:
		return null
	var created_texture: Texture2D = ImageTexture.create_from_image(image)
	texture_cache[kind] = created_texture
	return created_texture

func _ensure_asset(kind: String) -> String:
	var path_value: String = get_skin_path(kind)
	if path_value.is_empty() or FileAccess.file_exists(path_value):
		return path_value
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path_value.get_base_dir()))
	var target_file: FileAccess = FileAccess.open(path_value, FileAccess.WRITE)
	if target_file != null:
		target_file.store_string(_make_svg(kind))
		target_file.close()
	return path_value

func _make_svg(kind: String) -> String:
	var info: Dictionary = CATALOG[kind] as Dictionary
	var group_name: String = str(info.get("group", "troops"))
	var shape_name: String = str(info.get("shape", "troop"))
	var body_color: String = "#" + str(info.get("body", "315b78"))
	var accent_color: String = "#" + str(info.get("accent", "8fe9ff"))
	var ink_color: String = "#" + str(info.get("ink", "effaff"))
	if group_name == "troops" or (group_name == "syndicate" and shape_name != "relay"):
		return _make_troop_svg(shape_name, body_color, accent_color, ink_color)
	if group_name == "vehicles":
		return _make_vehicle_svg(shape_name, body_color, accent_color, ink_color)
	if group_name == "air":
		return _make_air_svg(shape_name, body_color, accent_color, ink_color)
	if group_name == "resources":
		return _make_resource_svg(shape_name, body_color, accent_color, ink_color)
	return _make_structure_svg(shape_name, body_color, accent_color, ink_color)

func _svg_prefix() -> String:
	return "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 256 256'>"

func _make_troop_svg(shape_name: String, body_color: String, accent_color: String, ink_color: String) -> String:
	if shape_name == "drone":
		return _svg_prefix() + "<ellipse cx='128' cy='218' rx='70' ry='14' fill='#06111e' opacity='.42'/><path d='M70 123l29-44h58l29 44-21 55H91z' fill='" + body_color + "' stroke='" + accent_color + "' stroke-width='6'/><circle cx='128' cy='120' r='28' fill='" + accent_color + "' opacity='.72'/><path d='M93 106L46 80M163 106l47-26M86 151l-43 23M170 151l43 23' stroke='" + accent_color + "' stroke-width='8' stroke-linecap='round'/><g fill='" + ink_color + "'><circle cx='42' cy='78' r='11'/><circle cx='214' cy='78' r='11'/><circle cx='40' cy='176' r='11'/><circle cx='216' cy='176' r='11'/></g></svg>"
	var extra: String = "<path d='M144 129l61 16-7 18-61-13z' fill='" + ink_color + "' stroke='" + body_color + "' stroke-width='5'/>"
	if shape_name == "shield" or shape_name == "warden":
		extra = "<path d='M70 104L31 129v70l39 27 30-24v-83z' fill='" + accent_color + "' opacity='.76' stroke='" + ink_color + "' stroke-width='6'/><path d='M78 124v73M48 146h29' stroke='" + ink_color + "' stroke-width='5'/>"
	elif shape_name == "medic":
		extra = "<rect x='151' y='127' width='38' height='38' rx='6' fill='" + ink_color + "'/><path d='M170 135v23M158 147h24' stroke='" + accent_color + "' stroke-width='6'/>"
	elif shape_name == "engineer":
		extra = "<path d='M145 125l47 14-10 18-46-12z' fill='" + ink_color + "'/><path d='M172 143l20-25' stroke='" + accent_color + "' stroke-width='7'/>"
	elif shape_name == "ranger":
		extra = "<path d='M140 127l77 17-5 12-77-12z' fill='" + ink_color + "' stroke='" + body_color + "' stroke-width='4'/><circle cx='211' cy='150' r='7' fill='" + accent_color + "'/>"
	elif shape_name == "recon" or shape_name == "hacker":
		extra = "<rect x='148' y='125' width='39' height='36' rx='5' fill='" + body_color + "' stroke='" + accent_color + "' stroke-width='5'/><path d='M167 108l20-21' stroke='" + accent_color + "' stroke-width='5'/><circle cx='190' cy='85' r='7' fill='" + ink_color + "'/>"
	elif shape_name == "hero":
		extra = "<path d='M128 18l10 22 24 4-17 17 5 24-22-12-22 12 5-24-17-17 24-4z' fill='" + accent_color + "' opacity='.78'/><path d='M144 129l61 16-7 18-61-13z' fill='" + ink_color + "' stroke='" + body_color + "' stroke-width='5'/>"
	elif shape_name == "raider" or shape_name == "breacher":
		extra = "<path d='M140 126l66 18-18 23-54-15z' fill='" + ink_color + "' stroke='" + accent_color + "' stroke-width='5'/>"
	return _svg_prefix() + "<ellipse cx='128' cy='221' rx='56' ry='13' fill='#05101c' opacity='.42'/><circle cx='128' cy='66' r='29' fill='" + ink_color + "' stroke='" + accent_color + "' stroke-width='6'/><circle cx='128' cy='66' r='8' fill='" + accent_color + "'/><path d='M78 114l50-23 46 23 14 84H68z' fill='" + body_color + "' stroke='" + accent_color + "' stroke-width='6'/><path d='M102 196l-12 33M153 196l12 33' stroke='" + ink_color + "' stroke-width='12' stroke-linecap='round'/>" + extra + "</svg>"

func _make_vehicle_svg(shape_name: String, body_color: String, accent_color: String, ink_color: String) -> String:
	if shape_name == "mech":
		return _svg_prefix() + "<ellipse cx='128' cy='217' rx='79' ry='14' fill='#05101d' opacity='.43'/><path d='M85 95l43-34 49 34 10 67-41 18-52-18z' fill='" + body_color + "' stroke='" + accent_color + "' stroke-width='7'/><path d='M96 168l-25 49h32l18-40M157 176l19 40h33l-30-53' fill='" + body_color + "' stroke='" + accent_color + "' stroke-width='7'/><path d='M81 122l-34 31M179 122l35 29' stroke='" + ink_color + "' stroke-width='16' stroke-linecap='round'/><circle cx='132' cy='111' r='14' fill='" + accent_color + "'/><path d='M170 130l44-5' stroke='" + ink_color + "' stroke-width='9'/></svg>"
	var body_shape: String = "<path d='M45 151l26-51 98-27 47 35-20 61-116 14z' fill='" + body_color + "' stroke='" + accent_color + "' stroke-width='7'/><path d='M65 174l-19 24h55l12-22M167 169l12 22h48l-24-31' stroke='#0b1522' stroke-width='14' stroke-linecap='round'/><path d='M94 113l46-19 34 19-12 31H97z' fill='" + ink_color + "' opacity='.7'/>"
	var detail: String = "<path d='M127 119l63-20' stroke='" + ink_color + "' stroke-width='10' stroke-linecap='round'/><circle cx='190' cy='99' r='7' fill='" + accent_color + "'/>"
	if shape_name == "skimmer":
		body_shape = "<path d='M42 157l52-54 86-13 35 29-44 50-94 18z' fill='" + body_color + "' stroke='" + accent_color + "' stroke-width='7'/><path d='M62 183h42M153 171h43' stroke='" + accent_color + "' stroke-width='8' stroke-linecap='round'/>"
		detail = "<path d='M108 121l74-16' stroke='" + ink_color + "' stroke-width='7'/><circle cx='75' cy='190' r='10' fill='" + accent_color + "'/><circle cx='181' cy='176' r='10' fill='" + accent_color + "'/>"
	elif shape_name == "carrier":
		body_shape = "<path d='M29 153l26-61 126-11 45 42-18 64-144 6z' fill='" + body_color + "' stroke='" + accent_color + "' stroke-width='7'/><path d='M100 104h67v48h-67z' fill='" + ink_color + "' opacity='.62'/><path d='M42 191h57M160 190h57' stroke='#0b1522' stroke-width='15'/>"
		detail = "<rect x='112' y='116' width='43' height='22' rx='4' fill='" + accent_color + "' opacity='.75'/><path d='M126 120v14M120 127h13' stroke='" + ink_color + "' stroke-width='3'/>"
	elif shape_name == "crawler":
		detail = "<path d='M120 116l83-39' stroke='" + ink_color + "' stroke-width='13' stroke-linecap='round'/><circle cx='207' cy='75' r='8' fill='" + accent_color + "'/>"
	elif shape_name == "lancer":
		detail = "<path d='M123 114l78-25' stroke='" + ink_color + "' stroke-width='8'/><path d='M195 84l22 13-16 17' fill='none' stroke='" + accent_color + "' stroke-width='7'/>"
	elif shape_name == "tank":
		detail = "<path d='M122 114l72-18' stroke='" + ink_color + "' stroke-width='12'/><circle cx='116' cy='117' r='20' fill='" + body_color + "' stroke='" + accent_color + "' stroke-width='5'/>"
	return _svg_prefix() + "<ellipse cx='128' cy='211' rx='91' ry='16' fill='#05101d' opacity='.43'/>" + body_shape + detail + "</svg>"

func _make_air_svg(shape_name: String, body_color: String, accent_color: String, ink_color: String) -> String:
	var wing_shape: String = "<path d='M31 144l74-33 27-43 22 43 71 33-20 21-68-14-72 14z' fill='" + body_color + "' stroke='" + accent_color + "' stroke-width='7'/><path d='M129 54l24 64-24 66-22-66z' fill='" + ink_color + "' opacity='.72'/><path d='M105 118h49' stroke='" + accent_color + "' stroke-width='6'/>"
	var detail: String = "<circle cx='129' cy='103' r='10' fill='" + accent_color + "'/><path d='M53 174l-18 19M202 174l18 19' stroke='" + accent_color + "' stroke-width='6'/>"
	if shape_name == "lifter":
		wing_shape = "<path d='M39 142l45-35h91l45 35-23 36H60z' fill='" + body_color + "' stroke='" + accent_color + "' stroke-width='7'/><path d='M70 111l-25-31M185 111l25-31' stroke='" + ink_color + "' stroke-width='11'/><path d='M99 164v39h58v-39' fill='" + body_color + "' stroke='" + accent_color + "' stroke-width='6'/>"
		detail = "<circle cx='44' cy='77' r='12' fill='" + accent_color + "'/><circle cx='212' cy='77' r='12' fill='" + accent_color + "'/>"
	elif shape_name == "specter":
		wing_shape = "<path d='M26 142l83-44 19-52 24 52 78 44-36 20-66-13-65 13z' fill='" + body_color + "' stroke='" + accent_color + "' stroke-width='6'/><path d='M128 49l19 67-19 61-19-61z' fill='" + ink_color + "' opacity='.62'/>"
		detail = "<circle cx='128' cy='98' r='9' fill='" + accent_color + "'/><path d='M61 177l-25 8M194 177l26 8' stroke='" + accent_color + "' stroke-width='4'/>"
	elif shape_name == "bomber":
		wing_shape = "<path d='M32 144l68-39 27-54 29 54 69 39-18 29-79-16-77 16z' fill='" + body_color + "' stroke='" + accent_color + "' stroke-width='8'/><path d='M106 104h44v60h-44z' fill='" + ink_color + "' opacity='.58'/><path d='M100 167l-10 25M156 167l10 25' stroke='" + accent_color + "' stroke-width='8'/>"
	return _svg_prefix() + "<ellipse cx='128' cy='213' rx='73' ry='13' fill='#05101d' opacity='.38'/>" + wing_shape + detail + "</svg>"

func _make_structure_svg(shape_name: String, body_color: String, accent_color: String, ink_color: String) -> String:
	var building_shape: String = "<path d='M37 183l16-76 42-36h68l40 36 16 76z' fill='" + body_color + "' stroke='" + accent_color + "' stroke-width='7'/><path d='M59 173h139' stroke='" + ink_color + "' stroke-width='6' opacity='.7'/><rect x='102' y='105' width='52' height='47' rx='5' fill='" + ink_color + "' opacity='.65'/><circle cx='128' cy='85' r='14' fill='" + accent_color + "'/>"
	if shape_name == "nexus":
		building_shape = "<path d='M25 189l28-83 45-35h60l45 35 28 83z' fill='" + body_color + "' stroke='" + accent_color + "' stroke-width='8'/><path d='M74 172h108M84 137h88' stroke='" + ink_color + "' stroke-width='7'/><circle cx='128' cy='93' r='32' fill='" + accent_color + "' opacity='.34'/><circle cx='128' cy='93' r='14' fill='" + ink_color + "'/><path d='M128 45v36M94 72l22 21M162 72l-22 21' stroke='" + accent_color + "' stroke-width='5'/>"
	elif shape_name == "turret" or shape_name == "cannon":
		var barrel_width: String = "12" if shape_name == "cannon" else "8"
		building_shape = "<ellipse cx='128' cy='193' rx='70' ry='22' fill='" + body_color + "' stroke='" + accent_color + "' stroke-width='7'/><rect x='92' y='129' width='72' height='55' rx='11' fill='" + body_color + "' stroke='" + ink_color + "' stroke-width='6'/><path d='M128 133l72-49' stroke='" + ink_color + "' stroke-width='" + barrel_width + "' stroke-linecap='round'/><circle cx='202' cy='82' r='9' fill='" + accent_color + "'/></svg>"
	elif shape_name == "shop":
		building_shape = "<path d='M32 188l16-78 34-28h92l34 28 16 78z' fill='" + body_color + "' stroke='" + accent_color + "' stroke-width='7'/><path d='M58 130h140M75 169h106' stroke='" + ink_color + "' stroke-width='7'/><circle cx='79' cy='160' r='14' fill='" + accent_color + "'/><circle cx='177' cy='160' r='14' fill='" + accent_color + "'/><path d='M112 102h32v45h-32z' fill='" + ink_color + "' opacity='.65'/>"
	elif shape_name == "airpad":
		building_shape = "<ellipse cx='128' cy='150' rx='94' ry='64' fill='" + body_color + "' stroke='" + accent_color + "' stroke-width='8'/><path d='M58 150h140M128 91v118' stroke='" + ink_color + "' stroke-width='7'/><circle cx='128' cy='150' r='27' fill='" + accent_color + "' opacity='.45'/><path d='M113 150h30M128 135v30' stroke='" + ink_color + "' stroke-width='6'/>"
	elif shape_name == "oxygen":
		building_shape = "<path d='M53 190l22-87h106l22 87z' fill='" + body_color + "' stroke='" + accent_color + "' stroke-width='7'/><circle cx='128' cy='108' r='35' fill='" + accent_color + "' opacity='.33'/><circle cx='128' cy='108' r='18' fill='" + ink_color + "'/><path d='M112 108h32M128 92v32' stroke='" + accent_color + "' stroke-width='5'/>"
	elif shape_name == "thermal":
		building_shape = "<ellipse cx='128' cy='157' rx='84' ry='55' fill='" + body_color + "' stroke='" + accent_color + "' stroke-width='7'/><circle cx='128' cy='134' r='31' fill='" + accent_color + "' opacity='.35'/><path d='M128 78v112M79 106l98 57M79 163l98-57' stroke='" + ink_color + "' stroke-width='6'/>"
	elif shape_name == "radiation":
		building_shape = "<path d='M55 193l21-86h104l21 86z' fill='" + body_color + "' stroke='" + accent_color + "' stroke-width='7'/><path d='M128 58l41 71-41 71-41-71z' fill='" + accent_color + "' opacity='.35' stroke='" + ink_color + "' stroke-width='6'/><circle cx='128' cy='129' r='13' fill='" + ink_color + "'/></svg>"
	elif shape_name == "cells":
		building_shape = "<path d='M44 189l15-78h138l15 78z' fill='" + body_color + "' stroke='" + accent_color + "' stroke-width='7'/><path d='M82 112v76M108 112v76M134 112v76M160 112v76' stroke='" + ink_color + "' stroke-width='6'/><path d='M58 153h140' stroke='" + accent_color + "' stroke-width='5'/>"
	elif shape_name == "relay":
		building_shape = "<path d='M128 52l56 126H72z' fill='" + body_color + "' stroke='" + accent_color + "' stroke-width='7'/><circle cx='128' cy='91' r='19' fill='" + ink_color + "'/><path d='M128 28v45M89 69l25 25M167 69l-25 25' stroke='" + accent_color + "' stroke-width='6'/><path d='M57 188h142' stroke='" + ink_color + "' stroke-width='8'/>"
	return _svg_prefix() + "<ellipse cx='128' cy='213' rx='91' ry='15' fill='#050d18' opacity='.40'/>" + building_shape + "</svg>"

func _make_resource_svg(shape_name: String, body_color: String, accent_color: String, ink_color: String) -> String:
	if shape_name == "evidence":
		return _svg_prefix() + "<circle cx='128' cy='128' r='90' fill='" + accent_color + "' opacity='.12'/><path d='M63 104l65-45 65 45v76l-65 34-65-34z' fill='" + body_color + "' stroke='" + accent_color + "' stroke-width='7'/><circle cx='128' cy='132' r='32' fill='" + accent_color + "' opacity='.45'/><path d='M128 104v55M101 132h54' stroke='" + ink_color + "' stroke-width='7'/></svg>"
	return _svg_prefix() + "<circle cx='128' cy='128' r='88' fill='" + accent_color + "' opacity='.13'/><path d='M126 31l29 72-27 22-28-22zM51 128l53-28 22 29-28 32zM203 128l-53-28-22 29 28 32zM93 199l35-70 35 70-35 28z' fill='" + accent_color + "' stroke='" + ink_color + "' stroke-width='5'/><circle cx='128' cy='128' r='13' fill='" + ink_color + "'/></svg>"
