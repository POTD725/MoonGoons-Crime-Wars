extends "res://operations_control.gd"
## Production routing for the expanded troop, vehicle, transport, and air roster.
## Uses _request_train so controller calls cannot collide with the scene's _train(kind) queue API.

const ARMORY_UNITS: Array[String] = ["shield", "breacher", "ranger", "medic", "engineer", "recon", "warden"]
const SHOP_UNITS: Array[String] = ["bulwark_rover", "siege_crawler", "arc_lancer", "pursuit_skimmer", "bastion_tank", "troop_carrier", "mech_mover"]
const AIR_UNITS: Array[String] = ["sky_lifter", "specter_flyer", "lunar_bomber"]

func _request_train(scene: Node, kind: String) -> void:
	var producer_kind: String = _producer_kind_for(kind)
	if producer_kind.is_empty():
		super._request_train(scene, kind)
		return
	var producer: Dictionary = _producer(scene, producer_kind)
	if producer.is_empty():
		scene.call("flash", _missing_producer_message(producer_kind), 3.0)
		return
	_request_from_producer(scene, kind, producer)

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
