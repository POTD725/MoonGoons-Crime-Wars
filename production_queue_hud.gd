extends "res://minimap_hud.gd"
## Shows resource deposits, live queues, and live core-art validation without crowding the command deck.

func _refresh() -> void:
	super._refresh()
	if game == null:
		return
	var total_queued: int = int(game.call("_get_total_pending_spawns")) if game.has_method("_get_total_pending_spawns") else 0
	var ore_remaining: int = int(game.call("_get_total_resource_amount", "ore")) if game.has_method("_get_total_resource_amount") else 0
	var intel_remaining: int = int(game.call("_get_total_resource_amount", "evidence")) if game.has_method("_get_total_resource_amount") else 0
	var art_status: String = CoreArtBank.status_text() if CoreArtBank != null else "CORE PNG ART OFFLINE"
	resource_line.text = "CREDITS %04d  SUPPLIES %03d  INTEL %03d  O2 %03d%%  QUEUE %02d  %s" % [int(game.get("credits")), int(game.get("supplies")), int(game.get("intel")), int(round(float(game.get("oxygen_reserve")))), total_queued, art_status]
	objective_line.text = _objective_text() + "\nFIELD DEPOSITS // ORE %d  INTEL %d" % [ore_remaining, intel_remaining]

func _refresh_production_for(entity: Dictionary) -> void:
	super._refresh_production_for(entity)
	if game == null or not entity.has("size"):
		return
	var producer_id: int = int(entity.get("id", -1))
	if not game.has_method("_get_production_queue_status"):
		return
	var status: Dictionary = game.call("_get_production_queue_status", producer_id) as Dictionary
	var count: int = int(status.get("count", 0))
	if count <= 0:
		return
	var name_value: String = str(status.get("name", "Unit"))
	var remaining: int = int(ceil(float(status.get("remaining", 0.0))))
	if production_label.visible:
		production_label.text += " // QUEUE %d" % count
	else:
		production_label.text = "PRODUCTION QUEUE // %d ITEM(S)" % count
		production_label.visible = true
	status_line.text = "QUEUE %d // NEXT: %s // DEPLOYS IN %02ds" % [count, name_value.to_upper(), remaining]
