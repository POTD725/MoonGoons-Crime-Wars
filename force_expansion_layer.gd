extends "res://campaign_map_router.gd"
## Expanded Authority roster, ground-building collision, transport deployment, and procedural action animation overlays.

const INFANTRY_KINDS: Array[String] = ["breacher", "ranger", "medic", "engineer", "recon", "warden"]
const VEHICLE_KINDS: Array[String] = ["bulwark_rover", "siege_crawler", "arc_lancer", "pursuit_skimmer", "bastion_tank", "troop_carrier", "mech_mover"]
const AIR_KINDS: Array[String] = ["sky_lifter", "specter_flyer", "lunar_bomber"]
const TRANSPORT_KINDS: Array[String] = ["troop_carrier", "sky_lifter"]

func _ready() -> void:
	_install_force_specs()
	super._ready()

func _install_force_specs() -> void:
	unit_specs["breacher"] = {"name":"Breach Deputy", "hp":245.0, "speed":108.0, "range":92.0, "damage":34.0, "cool":0.90, "radius":21.0, "accent":Color("ffad78"), "cost":145, "time":8.0, "role":"close"}
	unit_specs["ranger"] = {"name":"Lunar Ranger", "hp":145.0, "speed":126.0, "range":295.0, "damage":28.0, "cool":1.10, "radius":18.0, "accent":Color("b4e5ff"), "cost":165, "time":9.0, "role":"range"}
	unit_specs["medic"] = {"name":"Combat Medic", "hp":135.0, "speed":122.0, "range":0.0, "damage":0.0, "cool":0.0, "radius":18.0, "accent":Color("7dffd0"), "cost":130, "time":8.0, "role":"medic"}
	unit_specs["engineer"] = {"name":"Combat Engineer", "hp":175.0, "speed":114.0, "range":110.0, "damage":11.0, "cool":0.85, "radius":19.0, "accent":Color("ffd66e"), "cost":145, "time":8.0, "role":"engineer"}
	unit_specs["recon"] = {"name":"Recon Specialist", "hp":120.0, "speed":165.0, "range":205.0, "damage":16.0, "cool":0.56, "radius":16.0, "accent":Color("8deaff"), "cost":150, "time":8.0, "role":"recon"}
	unit_specs["warden"] = {"name":"Riot Warden", "hp":355.0, "speed":90.0, "range":145.0, "damage":27.0, "cool":0.76, "radius":25.0, "accent":Color("d7b6ff"), "cost":190, "time":11.0, "role":"warden"}

	unit_specs["siege_crawler"] = {"name":"Siege Crawler", "hp":1050.0, "speed":54.0, "range":410.0, "damage":74.0, "cool":1.90, "radius":36.0, "accent":Color("ffc072"), "cost":390, "time":18.0, "role":"vehicle"}
	unit_specs["arc_lancer"] = {"name":"Arc Lancer", "hp":670.0, "speed":91.0, "range":270.0, "damage":46.0, "cool":0.94, "radius":28.0, "accent":Color("79e8ff"), "cost":330, "time":16.0, "role":"vehicle"}
	unit_specs["pursuit_skimmer"] = {"name":"Pursuit Skimmer", "hp":480.0, "speed":152.0, "range":210.0, "damage":31.0, "cool":0.62, "radius":24.0, "accent":Color("9dcbff"), "cost":275, "time":13.0, "role":"vehicle"}
	unit_specs["bastion_tank"] = {"name":"Bastion Tank", "hp":1280.0, "speed":63.0, "range":245.0, "damage":58.0, "cool":1.24, "radius":38.0, "accent":Color("ffb18b"), "cost":440, "time":21.0, "role":"vehicle"}
	unit_specs["troop_carrier"] = {"name":"Aegis Troop Carrier", "hp":960.0, "speed":88.0, "range":165.0, "damage":22.0, "cool":0.78, "radius":34.0, "accent":Color("9ce0c0"), "cost":360, "time":18.0, "role":"transport"}
	unit_specs["mech_mover"] = {"name":"Atlas Mech Mover", "hp":1600.0, "speed":66.0, "range":285.0, "damage":82.0, "cool":1.36, "radius":43.0, "accent":Color("f3d88d"), "cost":560, "time":25.0, "role":"mech"}

	unit_specs["sky_lifter"] = {"name":"Sky Lifter Transport", "hp":690.0, "speed":178.0, "range":0.0, "damage":0.0, "cool":0.0, "radius":30.0, "accent":Color("a2efff"), "cost":390, "time":20.0, "role":"air_transport", "airborne":true}
	unit_specs["specter_flyer"] = {"name":"Specter Stealth Flyer", "hp":420.0, "speed":220.0, "range":310.0, "damage":43.0, "cool":0.88, "radius":24.0, "accent":Color("b49cff"), "cost":440, "time":20.0, "role":"air", "airborne":true, "stealth":true}
	unit_specs["lunar_bomber"] = {"name":"Lunar Bomber", "hp":850.0, "speed":145.0, "range":350.0, "damage":96.0, "cool":2.05, "radius":34.0, "accent":Color("ffbf82"), "cost":520, "time":24.0, "role":"air", "airborne":true}

func _spawn_building(kind: String, team: String, position: Vector2, done: bool) -> Dictionary:
	var building: Dictionary = super._spawn_building(kind, team, position, done)
	if kind == "air_support_pad":
		building["rally_point"] = position + Vector2(188.0, 70.0)
	return building

func _spawn_unit(kind: String, team: String, position: Vector2) -> Dictionary:
	var unit: Dictionary = super._spawn_unit(kind, team, position)
	var spec: Dictionary = unit_specs.get(kind, {}) as Dictionary
	unit["airborne"] = bool(spec.get("airborne", false))
	unit["stealth"] = bool(spec.get("stealth", false))
	unit["role"] = str(spec.get("role", ""))
	unit["action_state"] = "idle"
	unit["action_flash"] = 0.0
	unit["support_clock"] = 0.0
	unit["altitude_phase"] = float(unit.get("id", 0)) * 0.61
	if kind == "troop_carrier":
		unit["payload"] = ["deputy", "breacher", "medic", "engineer"]
		unit["capacity"] = 4
	return unit
