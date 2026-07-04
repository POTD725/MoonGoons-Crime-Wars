extends "res://force_collision_guard.gd"
## Texture-driven gameplay renderer. Core PNG art is preferred; legacy skins remain as a safe fallback.

func _ready() -> void:
	super._ready()
	if CoreArtBank != null:
		CoreArtBank.validate_assets()
	elif SkinBank != null:
		SkinBank.ensure_all_assets()

func _draw_resources() -> void:
	for resource: Dictionary in nodes:
		if int(resource.get("amount", 0)) <= 0:
			continue
		var position: Vector2 = resource.get("pos", Vector2.ZERO) as Vector2
		var kind: String = str(resource.get("type", "ore"))
		var texture: Texture2D = CoreArtBank.get_texture(kind) if CoreArtBank != null else SkinBank.get_texture(kind)
		var pulse: float = 1.0 + sin(mission_clock * 2.4 + float(resource.get("id", 0))) * 0.065
		var sprite_size: Vector2 = Vector2(112.0, 112.0) * pulse
		if texture != null:
			draw_texture_rect(texture, Rect2(position - sprite_size * 0.5, sprite_size), false)
		else:
			draw_circle(position, 34.0, Color("65eaff"))
		var tag_color: Color = Color("ffca69") if kind == "evidence" else Color("65eaff")
		draw_arc(position, 49.0, 0.0, TAU, 22, Color(tag_color.r, tag_color.g, tag_color.b, 0.58), 1.8)
		draw_circle(position, 55.0 + sin(mission_clock * 2.0) * 2.0, Color(tag_color.r, tag_color.g, tag_color.b, 0.07), false, 1.2)

func _draw_buildings() -> void:
	for building: Dictionary in buildings:
		var position: Vector2 = building.get("pos", Vector2.ZERO) as Vector2
		if str(building.get("team", "")) == SYNDICATE and not _revealed(position):
			continue
		var size: Vector2 = building.get("size", Vector2(70.0, 50.0)) as Vector2
		var kind: String = str(building.get("kind", ""))
		var texture: Texture2D = CoreArtBank.get_texture(kind) if CoreArtBank != null else SkinBank.get_texture(kind)
		var art_size: Vector2 = size * 1.48
		var rect: Rect2 = Rect2(position - art_size * 0.5, art_size)
		draw_rect(Rect2(rect.position + Vector2(12.0, 15.0), rect.size), Color(0.01, 0.02, 0.05, 0.44), true)
		if texture != null:
			var build_alpha: float = 1.0 if bool(building.get("done", false)) else 0.58
			draw_texture_rect(texture, rect, false, Color(1.0, 1.0, 1.0, build_alpha))
		else:
			draw_rect(Rect2(position - size * 0.5, size), _building_color(building), true)
		if not bool(building.get("done", false)):
			_draw_construction_scaffold(position, art_size, _building_color(building), building)
		_draw_health_bar(position + Vector2(-art_size.x * 0.44, -art_size.y * 0.63), art_size.x * 0.88, float(building.get("hp", 0.0)) / maxf(1.0, float(building.get("max", 1.0))))
		if int(building.get("id", -1)) == selected_building:
			draw_rect(rect.grow(9.0), Color("ffffff"), false, 2.5)

func _draw_units() -> void:
	for unit: Dictionary in units:
		var position: Vector2 = unit.get("pos", Vector2.ZERO) as Vector2
		if str(unit.get("team", "")) == SYNDICATE and not _revealed(position):
			continue
		var accent: Color = _unit_color(unit)
		var radius: float = float(unit.get("radius", 16.0))
		if not bool(unit.get("ready", true)):
			var pct: float = float(unit.get("progress", 0.0)) / maxf(0.01, float(unit.get("train_time", 1.0)))
			draw_arc(position, radius + 17.0, -PI * 0.5, -PI * 0.5 + TAU * pct, 20, accent, 3.4)
			continue
		var kind: String = str(unit.get("kind", ""))
		var texture: Texture2D = CoreArtBank.get_texture(kind) if CoreArtBank != null else SkinBank.get_texture(kind)
		var walking: float = sin(float(unit.get("walk_phase", 0.0)) * 1.2)
		var airborne: bool = bool(unit.get("airborne", false))
		var lift: float = -13.0 + sin(float(unit.get("altitude_phase", 0.0)) * 3.0) * 5.0 if airborne else walking * 2.6
		var scale_y: float = 1.0 + absf(walking) * 0.045 if not airborne else 1.0
		var scale_factor: float = 4.15 if airborne else 4.35
		var sprite_size: Vector2 = Vector2(radius * scale_factor, radius * scale_factor * scale_y)
		var sprite_position: Vector2 = position + Vector2(0.0, lift)
		if texture != null:
			draw_texture_rect(texture, Rect2(sprite_position - sprite_size * 0.5, sprite_size), false)
		else:
			draw_circle(sprite_position, radius, accent)
		if selected.has(int(unit.get("id", -1))):
			draw_arc(position, radius + 15.0, 0.0, TAU, 24, Color("ecf9ff"), 2.8)
		_draw_unit_action_fx(unit, sprite_position, accent, radius)
		_draw_health_bar(position + Vector2(-radius * 1.15, -radius - 27.0), radius * 2.3, float(unit.get("hp", 0.0)) / maxf(1.0, float(unit.get("max", 1.0))))
		if int(unit.get("carrying", 0)) > 0:
			draw_circle(position + Vector2(0.0, -radius - 40.0), 6.0, Color("65eaff"))

func _draw_unit_action_fx(unit: Dictionary, position: Vector2, accent: Color, radius: float) -> void:
	var facing: Vector2 = unit.get("facing", Vector2.RIGHT) as Vector2
	var flash: float = float(unit.get("action_flash", 0.0))
	if flash > 0.0:
		var muzzle: Vector2 = position + facing * (radius + 16.0)
		draw_circle(muzzle, 8.0 + flash * 18.0, Color(accent.r, accent.g, accent.b, 0.45))
		draw_circle(muzzle, 3.5 + flash * 7.0, Color("fff8df"))
	var state: String = str(unit.get("action_state", "idle"))
	if state == "healing" or state == "repairing" or state == "constructing":
		var ring: float = radius + 15.0 + sin(mission_clock * 8.0 + float(unit.get("id", 0))) * 3.0
		draw_arc(position, ring, 0.0, TAU, 20, Color(accent.r, accent.g, accent.b, 0.80), 2.1)
	elif state == "harvesting":
		draw_arc(position, radius + 14.0, mission_clock * 3.0, mission_clock * 3.0 + PI * 1.4, 18, Color("65eaff"), 2.5)
	elif state == "deploying" or state == "unloading":
		draw_arc(position, radius + 22.0 + sin(mission_clock * 7.0) * 4.0, 0.0, TAU, 22, Color("eaffff"), 2.5)

func _draw_defense_overlays() -> void:
	pass

func _draw_vehicle_overlays() -> void:
	pass

func _draw_force_overlays() -> void:
	pass
