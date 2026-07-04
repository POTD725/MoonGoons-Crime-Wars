extends "res://moonfront_rts.gd"

func _draw_resources() -> void:
	for resource: Dictionary in nodes:
		if int(resource.get("amount", 0)) <= 0:
			continue
		var position: Vector2 = resource["pos"] as Vector2
		var evidence: bool = str(resource.get("type", "ore")) == "evidence"
		var color: Color = Color("ffca69") if evidence else Color("65eaff")
		draw_circle(position, 34.0, Color(color.r, color.g, color.b, 0.15))
		for index in range(5):
			var angle: float = float(index) * TAU / 5.0 + mission_clock * 0.12
			var outer: Vector2 = position + Vector2.from_angle(angle) * (24.0 + float(index % 2) * 7.0)
			draw_line(position, outer, Color(color.r, color.g, color.b, 0.70), 3.0)
			draw_circle(outer, 5.0, Color(color.r, color.g, color.b, 0.82))
			draw_circle(outer, 2.0, Color("ecffff"))
		draw_arc(position, 35.0, 0.0, TAU, 18, Color(color.r, color.g, color.b, 0.60), 1.5)
