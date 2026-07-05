extends "res://crime_wars_hud_compact.gd"
## Routes all HUD production requests through FieldSupport's explicit request API.

func _train(kind: String) -> void:
	if game == null:
		return
	var support: Node = get_node_or_null("/root/FieldSupport")
	if support != null and support.has_method("_request_train"):
		support.call("_request_train", game, kind)
	else:
		game.call("_train", kind)

func _train_from_selected(kind: String) -> void:
	if not kind.is_empty():
		_train(kind)
