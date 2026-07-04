extends "res://production_queue_hud.gd"
## Dossier spacing pass: queue information gets its own line and never covers the producer details.

func _build_dossier(deck: Panel) -> void:
	super._build_dossier(deck)
	dossier_body.position = Vector2(16.0, 48.0)
	dossier_body.size = Vector2(400.0, 64.0)
	dossier_body.add_theme_font_size_override("font_size", 13)
	production_label.position = Vector2(16.0, 116.0)
	production_label.size = Vector2(400.0, 18.0)
	production_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	production_label.add_theme_font_size_override("font_size", 11)
	production_primary.position = Vector2(16.0, 139.0)
	production_primary.size = Vector2(190.0, 45.0)
	production_secondary.position = Vector2(210.0, 139.0)
	production_secondary.size = Vector2(190.0, 45.0)
	status_line.position = Vector2(16.0, 191.0)
	status_line.size = Vector2(400.0, 17.0)
	status_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_line.add_theme_font_size_override("font_size", 11)

func _refresh_production_for(entity: Dictionary) -> void:
	super._refresh_production_for(entity)
	if game == null or not entity.has("size") or not game.has_method("_get_production_queue_status"):
		return
	var producer_id: int = int(entity.get("id", -1))
	var queue_status: Dictionary = game.call("_get_production_queue_status", producer_id) as Dictionary
	var queue_count: int = int(queue_status.get("count", 0))
	if queue_count <= 0:
		return
	var next_name: String = str(queue_status.get("name", "Unit")).to_upper()
	var seconds_left: int = int(ceil(float(queue_status.get("remaining", 0.0))))
	production_label.text = "PRODUCTION QUEUE  //  %d WAITING" % queue_count
	status_line.text = "NEXT: %s  |  DEPLOYS IN: %02ds" % [next_name, seconds_left]
