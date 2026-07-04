extends Node
## Runtime skin bank. Each gameplay type owns a generated transparent SVG file under user://,
## then the renderer rasterizes it into a Godot texture. This avoids preloading SVGs.

const ROOT: String = "user://moongoons_crime_wars/graphics/"

const CATALOG: Dictionary = {
	"drone":{"group":"troops","class":"drone","base":"245575","accent":"8fe9ff","mark":"72f2bd"},
	"deputy":{"group":"troops","class":"troop","base":"245575","accent":"8fe9ff","mark":"dff8ff"},
	"shield":{"group":"troops","class":"shield","base":"44366d","accent":"d9c4ff","mark":"f2eaff"},
	"hero":{"group":"troops","class":"hero","base":"5a4c29","accent":"ffd56d","mark":"fff3bf"},
	"breacher":{"group":"troops","class":"breacher","base":"6a3e2d","accent":"ffad78","mark":"fff1de"},
	"ranger":{"group":"troops","class":"ranger","base":"315b78","accent":"b4e5ff","mark":"effaff"},
	"medic":{"group":"troops","class":"medic","base":"1e6055","accent":"7dffd0","mark":"effff8"},
	"engineer":{"group":"troops","class":"engineer","base":"665722","accent":"ffd66e","mark":"fff3bc"},
	"recon":{"group":"troops","class":"recon","base":"164e67","accent":"8deaff","mark":"edffff"},
	"warden":{"group":"troops","class":"warden","base":"4c3670","accent":"d7b6ff","mark":"f5ecff"},
	"raider":{"group":"syndicate","class":"raider","base":"6a2247","accent":"ff8fc0","mark":"ffe3ef"},
	"hacker":{"group":"syndicate","class":"hacker","base":"51255f","accent":"df98ff","mark":"fff0ff"},
	"bulwark_rover":{"group":"vehicles","class":"rover","base":"483b68","accent":"d9c4ff","mark":"eee6ff"},
	"siege_crawler":{"group":"vehicles","class":"crawler","base":"714929","accent":"ffc072","mark":"fff0cc"},
	"arc_lancer":{"group":"vehicles","class":"lancer","base":"1e5871","accent":"79e8ff","mark":"e8fcff"},
	"pursuit_skimmer":{"group":"vehicles","class":"skimmer","base":"244f78","accent":"9dcbff","mark":"edfbff"},
	"bastion_tank":{"group":"vehicles","class":"tank","base":"713d42","accent":"ffb18b","mark":"fff0df"},
	"troop_carrier":{"group":"vehicles","class":"carrier","base":"27584e","accent":"9ce0c0","mark":"effff8"},
	"mech_mover":{"group":"vehicles","class":"mech","base":"635939","accent":"f3d88d","mark":"fff3c5"},
	"sky_lifter":{"group":"air","class":"lifter","base":"20566c","accent":"a2efff","mark":"edffff"},
	"specter_flyer":{"group":"air","class":"specter","base":"483770","accent":"b49cff","mark":"f2ebff"},
	"lunar_bomber":{"group":"air","class":"bomber","base":"714a2d","accent":"ffbf82","mark":"fff0dc"},
	"nexus":{"group":"structures","class":"nexus","base":"21466b","accent":"8fe9ff","mark":"effbff"},
	"armory":{"group":"structures","class":"armory","base":"392557","accent":"c7a8ff","mark":"f4ebff"},
	"relay":{"group":"structures","class":"relay","base":"1b595d","accent":"72f2bd","mark":"effff8"},
	"medbay":{"group":"structures","class":"medbay","base":"1d574d","accent":"72f2bd","mark":"effff8"},
	"bay":{"group":"structures","class":"bay","base":"244875","accent":"7aa8ff","mark":"eaf4ff"},
	"cells":{"group":"structures","class":"cells","base":"60472b","accent":"f3b85e","mark":"fff0c9"},
	"sentry_turret":{"group":"defenses","class":"turret","base":"173e58","accent":"78d8ff","mark":"e8fbff"},
	"pulse_cannon":{"group":"defenses","class":"cannon","base":"603d28","accent":"ffc46b","mark":"fff4d6"},
	"machine_shop":{"group":"structures","class":"shop","base":"302454","accent":"b9a4ff","mark":"eeeaff"},
	"air_support_pad":{"group":"structures","class":"airpad","base":"1e4d6a","accent":"77c8ff","mark":"eaffff"},
	"o2_generator":{"group":"structures","class":"oxygen","base":"1d5a51","accent":"77f7d8","mark":"effff8"},
	"thermal_regulator":{"group":"structures","class":"thermal","base":"684727","accent":"ffbf7c","mark":"fff0d7"},
	"radiation_array":{"group":"structures","class":"radiation","base":"493269","accent":"c09cff","mark":"f3eaff"},
	"syndicate_relay":{"group":"syndicate","class":"relay","base":"60213d","accent":"ff74aa","mark":"ffe4f0"},
	"ore":{"group":"resources","class":"ore","base":"1d5f78","accent":"65eaff","mark":"eaffff"},
	"evidence":{"group":"resources","class":"evidence","base":"6a4c24","accent":"ffca69","mark":"fff0c6"}
}

var texture_cache: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	ensure_all_assets()

func ensure_all_assets() -> void:
	for kind_value in CATALOG.keys():
		_ensure_asset(str(kind_value))

func get_texture(kind: String) -> Texture2D:
	if texture_cache.has(kind):
		return texture_cache[kind] as Texture2D
	if not CATALOG.has(kind):
		return null
	var path: String = _ensure_asset(kind)
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	var svg_text: String = file.get_as_text()
	file.close()
	var image: Image = Image.new()
	if image.load_svg_from_string(svg_text, 1.0) != OK:
		return null
	var texture: Texture2D = ImageTexture.create_from_image(image)
	texture_cache[kind] = texture
	return texture

func get_path(kind: String) -> String:
	if not CATALOG.has(kind):
		return ""
	var info: Dictionary = CATALOG[kind] as Dictionary
	return ROOT + str(info.get("group", "misc")) + "/" + kind + ".svg"

func _ensure_asset(kind: String) -> String:
	var path: String = get_path(kind)
	if path.is_empty() or FileAccess.file_exists(path):
		return path
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file != null:
		file.store_string(_svg_for(kind))
		file.close()
	return path

func _svg_for(kind: String) -> String:
	var info: Dictionary = CATALOG.get(kind, {}) as Dictionary
	var class_name: String = str(info.get("class", "troop"))
	var base: String = "#" + str(info.get("base", "315b78"))
	var accent: String = "#" + str(info.get("accent", "8fe9ff"))
	var mark: String = "#" + str(info.get("mark", "effaff"))
	if str(info.get("group", "")) == "troops" or str(info.get("group", "")) == "syndicate" and class_name != "relay":
		return _troop_svg(class_name, base, accent, mark)
	if str(info.get("group", "")) == "vehicles":
		return _vehicle_svg(class_name, base, accent, mark)
	if str(info.get("group", "")) == "air":
		return _air_svg(class_name, base, accent, mark)
	if str(info.get("group", "")) == "resources":
		return _resource_svg(class_name, base, accent, mark)
	return _structure_svg(class_name, base, accent, mark)

func _svg_open(base: String, accent: String) -> String:
	return "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 256 256'><defs><linearGradient id='g' x1='0' y1='0' x2='1' y2='1'><stop stop-color='" + accent + "'/><stop offset='1' stop-color='" + base + "'/></linearGradient><filter id='glow'><feGaussianBlur stdDeviation='4' result='b'/><feMerge><feMergeNode in='b'/><feMergeNode in='SourceGraphic'/></feMerge></filter></defs>"

func _troop_svg(class_name: String, base: String, accent: String, mark: String) -> String:
	var shield: String = ""
	var tool: String = "<path d='M143 129l62 16-7 18-61-13z' fill='" + mark + "' stroke='" + base + "' stroke-width='5'/>"
	var badge: String = "<circle cx='128' cy='66' r='8' fill='" + accent + "' filter='url(#glow)'/>"
	if class_name == "drone":
		return _svg_open(base, accent) + "<ellipse cx='128' cy='218' rx='70' ry='14' fill='#06111e' opacity='.42'/><path d='M70 123l29-44h58l29 44-21 55H91z' fill='" + base + "' stroke='" + accent + "' stroke-width='6'/><circle cx='128' cy='120' r='28' fill='url(#g)' stroke='" + mark + "' stroke-width='5'/><path d='M93 106L46 80M163 106l47-26M86 151l-43 23M170 151l43 23' stroke='" + accent + "' stroke-width='8' stroke-linecap='round'/><g fill='" + mark + "'><circle cx='42' cy='78' r='11'/><circle cx='214' cy='78' r='11'/><circle cx='40' cy='176' r='11'/><circle cx='216' cy='176' r='11'/></g></svg>"
	if class_name == "shield" or class_name == "warden":
		shield = "<path d='M69 104L31 129v70l38 27 31-24v-83z' fill='" + accent + "' opacity='.8' stroke='" + mark + "' stroke-width='6'/><path d='M77 124v73M48 146h29' stroke='" + mark + "' stroke-width='5'/>"
	if class_name == "medic":
		tool = "<path d='M145 127l38 12-8 34-34-8z' fill='" + mark + "'/><path d='M161 140v22M150 151h22' stroke='" + accent + "' stroke-width='6'/>"
	if class_name == "engineer":
		tool = "<path d='M145 125l47 14-10 18-46-12z' fill='" + mark + "'/><path d='M172 143l20-25' stroke='" + accent + "' stroke-width='7'/>"
	if class_name == "ranger":
		tool = "<path d='M140 127l77 17-5 12-77-12z' fill='" + mark + "' stroke='" + base + "' stroke-width='4'/><circle cx='211' cy='150' r='7' fill='" + accent + "'/>"
	if class_name == "recon":
		tool = "<path d='M145 125l50 13-8 17-49-11z' fill='" + mark + "'/><path d='M165 109l22-20' stroke='" + accent + "' stroke-width='5'/><circle cx='190' cy='85' r='7' fill='" + accent + "' filter='url(#glow)'/>"
	if class_name == "hacker":
		tool = "<path d='M145 125l43 9-5 31-43-9z' fill='" + base + "' stroke='" + accent + "' stroke-width='5'/><path d='M157 143h20M167 133v20' stroke='" + mark + "' stroke-width='4'/>"
	if class_name == "hero":
		badge = "<circle cx='128' cy='66' r='10' fill='" + accent + "' filter='url(#glow)'/><path d='M128 23l9 19 21 3-15 15 4 21-19-10-19 10 4-21-15-15 21-3z' fill='" + accent + "' opacity='.65'/>"
	if class_name == "raider":
		tool = "<path d='M140 126l66 18-18 23-54-15z' fill='" + mark + "' stroke='" + accent + "' stroke-width='5'/>"
	return _svg_open(base, accent) + "<ellipse cx='128' cy='221' rx='56' ry='13' fill='#05101c' opacity='.42'/><circle cx='128' cy='66' r='29' fill='" + mark + "' stroke='" + accent + "' stroke-width='6'/>" + badge + "<path d='M78 114l50-23 46 23 14 84H68z' fill='" + base + "' stroke='" + accent + "' stroke-width='6'/><path d='M102 196l-12 33M153 196l12 33' stroke='" + mark + "' stroke-width='12' stroke-linecap='round'/>" + shield + tool + "</svg>"

func _vehicle_svg(class_name: String, base: String, accent: String, mark: String) -> String:
	var body: String = "<path d='M45 151l26-51 98-27 47 35-20 61-116 14z' fill='" + base + "' stroke='" + accent + "' stroke-width='7'/><path d='M65 174l-19 24h55l12-22M167 169l12 22h48l-24-31' stroke='#0b1522' stroke-width='14' stroke-linecap='round'/><path d='M94 113l46-19 34 19-12 31H97z' fill='" + mark + "' opacity='.7'/>"
	var detail: String = "<path d='M127 119l63-20' stroke='" + mark + "' stroke-width='10' stroke-linecap='round'/><circle cx='190' cy='99' r='7' fill='" + accent + "' filter='url(#glow)'/>"
	if class_name == "skimmer":
		body = "<path d='M42 157l52-54 86-13 35 29-44 50-94 18z' fill='" + base + "' stroke='" + accent + "' stroke-width='7'/><path d='M62 183h42M153 171h43' stroke='" + accent + "' stroke-width='8' stroke-linecap='round' filter='url(#glow)'/>"
		detail = "<path d='M108 121l74-16' stroke='" + mark + "' stroke-width='7'/><circle cx='75' cy='190' r='10' fill='" + accent + "' opacity='.7'/><circle cx='181' cy='176' r='10' fill='" + accent + "' opacity='.7'/>"
	if class_name == "carrier":
		body = "<path d='M29 153l26-61 126-11 45 42-18 64-144 6z' fill='" + base + "' stroke='" + accent + "' stroke-width='7'/><path d='M100 104h67v48h-67z' fill='" + mark + "' opacity='.62'/><path d='M74 175h115' stroke='" + accent + "' stroke-width='6'/><path d='M42 191h57M160 190h57' stroke='#0b1522' stroke-width='15'/>"
		detail = "<rect x='112' y='116' width='43' height='22' rx='4' fill='" + accent + "' opacity='.75'/><path d='M126 120v14M120 127h13' stroke='" + mark + "' stroke-width='3'/>"
	if class_name == "mech":
		body = "<path d='M85 95l43-34 49 34 10 67-41 18-52-18z' fill='" + base + "' stroke='" + accent + "' stroke-width='7'/><path d='M96 168l-25 49h32l18-40M157 176l19 40h33l-30-53' fill='" + base + "' stroke='" + accent + "' stroke-width='7'/><path d='M81 122l-34 31M179 122l35 29' stroke='" + mark + "' stroke-width='16' stroke-linecap='round'/>"
		detail = "<circle cx='132' cy='111' r='14' fill='" + accent + "' filter='url(#glow)'/><path d='M170 130l44-5' stroke='" + mark + "' stroke-width='9'/>"
	if class_name == "crawler":
		detail = "<path d='M120 116l83-39' stroke='" + mark + "' stroke-width='13' stroke-linecap='round'/><circle cx='207' cy='75' r='8' fill='" + accent + "'/>"
	if class_name == "lancer":
		detail = "<path d='M123 114l78-25' stroke='" + mark + "' stroke-width='8'/><path d='M195 84l22 13-16 17' fill='none' stroke='" + accent + "' stroke-width='7'/>"
	if class_name == "tank":
		detail = "<path d='M122 114l72-18' stroke='" + mark + "' stroke-width='12'/><circle cx='116' cy='117' r='20' fill='" + base + "' stroke='" + accent + "' stroke-width='5'/>"
	return _svg_open(base, accent) + "<ellipse cx='128' cy='211' rx='91' ry='16' fill='#05101d' opacity='.43'/>" + body + detail + "</svg>"

func _air_svg(class_name: String, base: String, accent: String, mark: String) -> String:
	var wings: String = "<path d='M31 144l74-33 27-43 22 43 71 33-20 21-68-14-72 14z' fill='" + base + "' stroke='" + accent + "' stroke-width='7'/><path d='M129 54l24 64-24 66-22-66z' fill='" + mark + "' opacity='.72'/><path d='M105 118l49 0' stroke='" + accent + "' stroke-width='6'/>"
	var detail: String = "<circle cx='129' cy='103' r='10' fill='" + accent + "' filter='url(#glow)'/><path d='M53 174l-18 19M202 174l18 19' stroke='" + accent + "' stroke-width='6'/>"
	if class_name == "lifter":
		wings = "<path d='M39 142l45-35h91l45 35-23 36H60z' fill='" + base + "' stroke='" + accent + "' stroke-width='7'/><path d='M70 111l-25-31M185 111l25-31' stroke='" + mark + "' stroke-width='11'/><path d='M85 157h87' stroke='" + mark + "' stroke-width='8'/><path d='M99 164v39h58v-39' fill='" + base + "' stroke='" + accent + "' stroke-width='6'/>"
		detail = "<circle cx='44' cy='77' r='12' fill='" + accent + "' opacity='.7'/><circle cx='212' cy='77' r='12' fill='" + accent + "' opacity='.7'/>"
	if class_name == "specter":
		wings = "<path d='M26 142l83-44 19-52 24 52 78 44-36 20-66-13-65 13z' fill='" + base + "' stroke='" + accent + "' stroke-width='6'/><path d='M128 49l19 67-19 61-19-61z' fill='" + mark + "' opacity='.62'/>"
		detail = "<circle cx='128' cy='98' r='9' fill='" + accent + "' filter='url(#glow)'/><path d='M61 177l-25 8M194 177l26 8' stroke='" + accent + "' stroke-width='4'/>"
	if class_name == "bomber":
		wings = "<path d='M32 144l68-39 27-54 29 54 69 39-18 29-79-16-77 16z' fill='" + base + "' stroke='" + accent + "' stroke-width='8'/><path d='M106 104h44v60h-44z' fill='" + mark + "' opacity='.58'/><path d='M100 167l-10 25M156 167l10 25' stroke='" + accent + "' stroke-width='8'/>"
	return _svg_open(base, accent) + "<ellipse cx='128' cy='213' rx='73' ry='13' fill='#05101d' opacity='.38'/>" + wings + detail + "</svg>"

func _structure_svg(class_name: String, base: String, accent: String, mark: String) -> String:
	var building: String = "<path d='M37 183l16-76 42-36h68l40 36 16 76z' fill='" + base + "' stroke='" + accent + "' stroke-width='7'/><path d='M59 173h139' stroke='" + mark + "' stroke-width='6' opacity='.7'/><rect x='102' y='105' width='52' height='47' rx='5' fill='" + mark + "' opacity='.65'/><circle cx='128' cy='85' r='14' fill='" + accent + "' filter='url(#glow)'/>"
	if class_name == "nexus":
		building = "<path d='M25 189l28-83 45-35h60l45 35 28 83z' fill='" + base + "' stroke='" + accent + "' stroke-width='8'/><path d='M74 172h108M84 137h88' stroke='" + mark + "' stroke-width='7'/><circle cx='128' cy='93' r='32' fill='" + accent + "' opacity='.34'/><circle cx='128' cy='93' r='14' fill='" + mark + "' filter='url(#glow)'/><path d='M128 45v36M94 72l22 21M162 72l-22 21' stroke='" + accent + "' stroke-width='5'/>"
	elif class_name == "turret" or class_name == "cannon":
		var width: String = "12" if class_name == "cannon" else "8"
		building = "<ellipse cx='128' cy='193' rx='70' ry='22' fill='" + base + "' stroke='" + accent + "' stroke-width='7'/><rect x='92' y='129' width='72' height='55' rx='11' fill='" + base + "' stroke='" + mark + "' stroke-width='6'/><path d='M128 133l72-49' stroke='" + mark + "' stroke-width='" + width + "' stroke-linecap='round'/><circle cx='202' cy='82' r='9' fill='" + accent + "' filter='url(#glow)'/>"
	elif class_name == "shop":
		building = "<path d='M32 188l16-78 34-28h92l34 28 16 78z' fill='" + base + "' stroke='" + accent + "' stroke-width='7'/><path d='M58 130h140M75 169h106' stroke='" + mark + "' stroke-width='7'/><circle cx='79' cy='160' r='14' fill='" + accent + "'/><circle cx='177' cy='160' r='14' fill='" + accent + "'/><path d='M112 102h32v45h-32z' fill='" + mark + "' opacity='.65'/>"
	elif class_name == "airpad":
		building = "<ellipse cx='128' cy='150' rx='94' ry='64' fill='" + base + "' stroke='" + accent + "' stroke-width='8'/><path d='M58 150h140M128 91v118' stroke='" + mark + "' stroke-width='7'/><circle cx='128' cy='150' r='27' fill='" + accent + "' opacity='.45'/><path d='M113 150h30M128 135v30' stroke='" + mark + "' stroke-width='6'/>"
	elif class_name == "oxygen":
		building = "<path d='M53 190l22-87h106l22 87z' fill='" + base + "' stroke='" + accent + "' stroke-width='7'/><circle cx='128' cy='108' r='35' fill='" + accent + "' opacity='.33'/><circle cx='128' cy='108' r='18' fill='" + mark + "' filter='url(#glow)'/><path d='M112 108h32M128 92v32' stroke='" + accent + "' stroke-width='5'/>"
	elif class_name == "thermal":
		building = "<ellipse cx='128' cy='157' rx='84' ry='55' fill='" + base + "' stroke='" + accent + "' stroke-width='7'/><circle cx='128' cy='134' r='31' fill='" + accent + "' opacity='.35'/><path d='M128 78v112M79 106l98 57M79 163l98-57' stroke='" + mark + "' stroke-width='6'/>"
	elif class_name == "radiation":
		building = "<path d='M55 193l21-86h104l21 86z' fill='" + base + "' stroke='" + accent + "' stroke-width='7'/><path d='M128 58l41 71-41 71-41-71z' fill='" + accent + "' opacity='.35' stroke='" + mark + "' stroke-width='6'/><circle cx='128' cy='129' r='13' fill='" + mark + "' filter='url(#glow)'/>"
	elif class_name == "cells":
		building = "<path d='M44 189l15-78h138l15 78z' fill='" + base + "' stroke='" + accent + "' stroke-width='7'/><path d='M82 112v76M108 112v76M134 112v76M160 112v76' stroke='" + mark + "' stroke-width='6'/><path d='M58 153h140' stroke='" + accent + "' stroke-width='5'/>"
	elif class_name == "relay":
		building = "<path d='M128 52l56 126H72z' fill='" + base + "' stroke='" + accent + "' stroke-width='7'/><circle cx='128' cy='91' r='19' fill='" + mark + "' filter='url(#glow)'/><path d='M128 28v45M89 69l25 25M167 69l-25 25' stroke='" + accent + "' stroke-width='6'/><path d='M57 188h142' stroke='" + mark + "' stroke-width='8'/>"
	return _svg_open(base, accent) + "<ellipse cx='128' cy='213' rx='91' ry='15' fill='#050d18' opacity='.40'/>" + building + "</svg>"

func _resource_svg(class_name: String, base: String, accent: String, mark: String) -> String:
	var shards: String = "<path d='M126 31l29 72-27 22-28-22zM51 128l53-28 22 29-28 32zM203 128l-53-28-22 29 28 32zM93 199l35-70 35 70-35 28z' fill='" + accent + "' stroke='" + mark + "' stroke-width='5'/>"
	if class_name == "evidence":
		shards = "<path d='M63 104l65-45 65 45v76l-65 34-65-34z' fill='" + base + "' stroke='" + accent + "' stroke-width='7'/><circle cx='128' cy='132' r='32' fill='" + accent + "' opacity='.45'/><path d='M128 104v55M101 132h54' stroke='" + mark + "' stroke-width='7'/>"
	return _svg_open(base, accent) + "<circle cx='128' cy='128' r='88' fill='" + accent + "' opacity='.13'/>" + shards + "<circle cx='128' cy='128' r='13' fill='" + mark + "' filter='url(#glow)'/></svg>"
