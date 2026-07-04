extends "res://force_collision_guard.gd"
## Texture-driven replacement renderer. Keeps gameplay logic intact while skins, action motion,
## and state effects are rendered from the individual transparent SVG files in SkinBank.

func _ready() -> void:
	super._ready()
	if SkinBank != null:
		SkinBank.ensure_all_assets()

func _draw_resources() -> void:
	for resource: Dictionary in nodes:
		if int(resource.get("amount", 0)) <= 0:
			continue
		var position: Vector2 = resource.get("pos", Vector2.ZERO) as Vector2
		var kind: String = str(resource.get("type", "ore"))
		var texture: Texture2D = SkinBank.get_texture(kind)
		if texture != null:
			var pulse: float = 1.0 + sin(mission_clock * 2.4 + float(resource.get("id", 0))) * 0.06
			var sprite_size: Vector2 = Vector2(86.0, 86.0) * pulse
			draw_texture_rect(texture, Rect2(position - sprite_size * 0.5, sprite_size), false)
		else:
			draw_circle(position, 28.0, Color("65eaff"))
		var tag_color: Color = Color("ffca69") if kind == "evidence" else Color("65eaff")
		draw_arc(position, 38.0, 0.0, TAU, 18, Color(tag_color.r, tag_color.g, tag_color.b, 0.52), 1.4)

func _draw_buildings() -> void:
	for building: Dictionary in buildings:
		var position: Vector2 = building.get("pos", Vector2.ZERO) as Vector2
		if str(building.get("team", "")) == SYNDICATE and not _revealed(position):
			continue
		var size: Vector2 = building.get("size", Vector2(70.0, 50.0)) as Vector2
		var kind: String = str(building.get("kind", ""))
		var texture: Texture2D = SkinBank.get_texture(kind)
		var rect: Rect2 = Rect2(position - size * 0.62, size * 1.24)
		draw_rect(Rect2(rect.position + Vector2(9.0, 12.0), rect.size), Color(0.01, 0.02, 0.05, 0.40), true)
		if texture != null:
			var build_alpha: float = 1.0 if bool(building.get("done", false)) else 0.58
			draw_texture_rect(texture, rect, false, Color(1.0, 1.0, 1.0, build_alpha))
		else:
			draw_rect(Rect2(position - size * 0.5, size), _building_color(building), true)
		if not bool(building.get("done", false)):
			_draw_construction_scaffold(position, size, _building_color(building), building)
		_draw_health_bar(position + Vector2(-size.x * 0.44, -size.y * 0.76), size.x * 0.88, float(building.get("hp", 0.0)) / maxf(1.0, float(building.get("max", 1.0))))
		if int(building.get("id", -1)) == selected_building:
			draw_rect(rect.grow(7.0), Color("ffffff"), false, 2.2)

func _draw_units() -> void:
	for unit: Dictionary in units:
		var position: Vector2 = unit.get("pos", Vector2.ZERO) as Vector2
		if str(unit.get("team", "")) == SYNDICATE and not _revealed(position):
			continue
		var accent: Color = _unit_color(unit)
		var radius: float = float(unit.get("radius", 16.0))
		if not bool(unit.get("ready", true)):
			var pct: float = float(unit.get("progress", 0.0)) / maxf(0.01, float(unit.get("train_time", 1.0)))
			draw_arc(position, radius + 13.0, -PI * 0.5, -PI * 0.5 + TAU * pct, 18, accent, 3.0)
			continue
		var kind: String = str(unit.get("kind", ""))
		var texture: Texture2D = SkinBank.get_texture(kind)
		var walking: float = sin(float(unit.get("walk_phase", 0.0)) * 1.2)
		var airborne: bool = bool(unit.get("airborne", false))
		var lift: float = -10.0 + sin(float(unit.get("altitude_phase", 0.0)) * 3.0) * 4.0 if airborne else walking * 2.0
		var scale_y: float = 1.0 + absf(walking) * 0.035 if not airborne else 1.0
		var sprite_size: Vector2 = Vector2(radius * 3.2, radius * 3.2 * scale_y)
		var sprite_position: Vector2 = position + Vector2(0.0, lift)
		if texture != null:
			draw_texture_rect(texture, Rect2(sprite_position - sprite_size * 0.5, sprite_size), false)
		else:
			draw_circle(sprite_position, radius, accent)
		if selected.has(int(unit.get("id", -1))):
			draw_arc(position, radius + 11.0, 0.0, TAU, 20, Color("ecf9ff"), 2.5)
		_draw_unit_action_fx(unit, sprite_position, accent, radius)
		_draw_health_bar(position + Vector2(-radius, -radius - 22.0), radius * 2.0, float(unit.get("hp", 0.0)) / maxf(1.0, float(unit.get("max", 1.0))))
		if int(unit.get("carrying", 0)) > 0:
			draw_circle(position + Vector2(0.0, -radius - 35.0), 5.0, Color("65eaff"))

func _draw_unit_action_fx(unit: Dictionary, position: Vector2, accent: Color, radius: float) -> void:
	var facing: Vector2 = unit.get("facing", Vector2.RIGHT) as Vector2
	var flash: float = float(unit.get("action_flash", 0.0))
	if flash > 0.0:
		var muzzle: Vector2 = position + facing * (radius + 12.0)
		draw_circle(muzzle, 7.0 + flash * 16.0, Color(accent.r, accent.g, accent.b, 0.45))
		draw_circle(muzzle, 3.0 + flash * 7.0, Color("fff8df"))
	var state: String = str(unit.get("action_state", "idle"))
	if state == "healing" or state == "repairing" or state == "constructing":
		var ring: float = radius + 12.0 + sin(mission_clock * 8.0 + float(unit.get("id", 0))) * 3.0
		draw_arc(position, ring, 0.0, TAU, 18, Color(accent.r, accent.g, accent.b, 0.78), 1.9)
	elif state == "harvesting":
		draw_arc(position, radius + 10.0, mission_clock * 3.0, mission_clock * 3.0 + PI * 1.4, 16, Color("65eaff"), 2.2)
	elif state == "deploying" or state == "unloading":
		draw_arc(position, radius + 18.0 + sin(mission_clock * 7.0) * 4.0, 0.0, TAU, 20, Color("eaffff"), 2.2)

func _draw_defense_overlays() -> void:
	pass

func _draw_vehicle_overlays() -> void:
	pass

func _draw_force_overlays() -> void:
	pass
