extends "res://operations_control.gd"
## Production routing for the expanded troop, vehicle, transport, and air roster.

const ARMORY_UNITS: Array[String] = ["shield", "breacher", "ranger", "medic", "engineer", "recon", "warden"]
const SHOP_UNITS: Array[String] = ["bulwark_rover", "siege_crawler", "arc_lancer", "pursuit_skimmer", "bastion_tank", "troop_carrier", "mech_mover"]
const AIR_UNITS: Array[String] = ["sky_lifter", "specter_flyer", "lunar_bomber"]

func _train(scene: Node, kind: String) -> void:
	var producer_kind: String = _producer_kind_for(kind)
	if producer_kind.is_empty():
		super._train(scene, kind)
		return
	var producer: Dictionary = _producer(scene, producer_kind)
	if producer.is_empty():
		scene.call("flash", _missing_producer_message(producer_kind), 3.0)
		return
	var specs: Dictionary = scene.get("unit_specs") as Dictionary
	if not specs.has(kind):
		return
	var spec: Dictionary = specs[kind] as Dictionary
	if int(scene.get("credits")) < int(spec.get("cost", 0)):
		scene.call("flash", "Insufficient Credits for " + str(spec.get("name", "this unit")) + ".", 2.2)
		return
	var before: int = (scene.get("units") as Array).size()
	scene.set("selected", [])
	scene.set("selected_building", int(producer.get("id", -1)))
	scene.call("_train", kind)
	var units: Array = scene.get("units") as Array
	if units.size() <= before:
		return
	var new_unit: Dictionary = units[units.size() - 1] as Dictionary
	var fallback: Vector2 = producer.get("pos", Vector2.ZERO) as Vector2
	fallback += Vector2(170.0, 68.0)
	new_unit["rally_target"] = producer.get("rally_point", fallback) as Vector2
	new_unit["rally_pending"] = true

func _producer_kind_for(kind: String) -> String:
	if kind == "deputy" or kind == "drone":
		return "nexus"
	if kind in ARMORY_UNITS:
		return "armory"
	if kind in SHOP_UNITS:
		return "machine_shop"
	if kind in AIR_UNITS:
		return "air_support_pad"
	return ""

func _missing_producer_message(kind: String) -> String:
	match kind:
		"armory": return "Build and finish a Tactical Armory to train advanced troops."
		"machine_shop": return "Build and finish a Machine Shop to produce assault vehicles and the troop carrier."
		"air_support_pad": return "Build and finish an Air Support Pad to deploy transports, stealth flyers, and bombers."
		_: return "Required production building unavailable."
