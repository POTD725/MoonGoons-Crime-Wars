extends "res://rts_control_fix.gd"
## Transitional production request API.
## Controllers use _request_train(scene, kind); the scene owns _train(kind).
## _train(scene, kind) remains only as a compatibility bridge for older hotkeys and buttons.

func _train(scene: Node, kind: String) -> void:
	_request_train(scene, kind)

func _request_train(scene: Node, kind: String) -> void:
	var producer_kind: String = "armory" if kind == "shield" else "nexus"
	var producer: Dictionary = _producer(scene, producer_kind)
	if producer.is_empty():
		var hint: String = "Build and finish a Tactical Armory before training Shield Deputies." if kind == "shield" else "Command Nexus unavailable."
		scene.call("flash", hint, 3.0)
		return
	_request_from_producer(scene, kind, producer)

func _request_from_producer(scene: Node, kind: String, producer: Dictionary) -> bool:
	if producer.is_empty():
		return false
	var specs: Dictionary = scene.get("unit_specs") as Dictionary
	if not specs.has(kind):
		return false
	var spec: Dictionary = specs[kind] as Dictionary
	if int(scene.get("credits")) < int(spec.get("cost", 0)):
		scene.call("flash", "Insufficient Credits for " + str(spec.get("name", "this unit")) + ".", 2.2)
		return false
	var producer_id: int = int(producer.get("id", -1))
	var before_queue: int = _queue_count(scene, producer_id)
	var before_units: int = (scene.get("units") as Array).size()
	scene.set("selected", [])
	scene.set("selected_building", producer_id)
	scene.call("_train", kind)
	var after_queue: int = _queue_count(scene, producer_id)
	if after_queue > before_queue:
		return true
	var units: Array = scene.get("units") as Array
	if units.size() > before_units:
		var new_unit: Dictionary = units[units.size() - 1] as Dictionary
		var fallback: Vector2 = producer.get("pos", Vector2.ZERO) as Vector2
		fallback += Vector2(170.0, 68.0)
		new_unit["rally_target"] = producer.get("rally_point", fallback) as Vector2
		new_unit["rally_pending"] = true
		return true
	return false

func _queue_count(scene: Node, producer_id: int) -> int:
	if not scene.has_method("_get_production_queue_status"):
		return 0
	var status: Dictionary = scene.call("_get_production_queue_status", producer_id) as Dictionary
	return int(status.get("count", 0))
