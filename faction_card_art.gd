extends Control
class_name CrimeWarsFactionCardArt
## Original vector-style faction illustrations for the deployment selector.

var faction_id: String = "authority"
var accent: Color = Color("8fe9ff")

func configure(new_faction_id: String, new_accent: Color) -> void:
	faction_id = new_faction_id
	accent = new_accent
	queue_redraw()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()

func _draw() -> void:
	var bounds: Rect2 = Rect2(Vector2.ZERO, size)
	var dark: Color = Color(0.018, 0.042, 0.09, 0.98)
	draw_rect(bounds, dark, true)
	draw_rect(bounds, Color(accent.r, accent.g, accent.b, 0.58), false, 2.0)
	_draw_stars()
	match faction_id:
		"authority":
			_draw_authority()
		"lunar_cartel":
			_draw_cartel()
		"null_choir":
			_draw_choir()
		"hollow_fang":
			_draw_fang()
		_:
			_draw_authority()

func _draw_stars() -> void:
	for index: int in 22:
		var x: float = fposmod(float(index * 47 + 19), maxf(1.0, size.x - 8.0)) + 4.0
		var y: float = fposmod(float(index * 29 + 31), maxf(1.0, size.y - 8.0)) + 4.0
		var alpha: float = 0.16 + float(index % 4) * 0.10
		draw_circle(Vector2(x, y), 1.0 + float(index % 3) * 0.45, Color(0.78, 0.9, 1.0, alpha))

func _draw_authority() -> void:
	var moon: Vector2 = Vector2(size.x * 0.73, size.y * 0.30)
	draw_circle(moon, 43.0, Color(0.36, 0.66, 0.86, 0.24))
	draw_circle(moon + Vector2(16.0, -7.0), 43.0, Color(0.018, 0.042, 0.09, 0.98))
	var base: Rect2 = Rect2(Vector2(46.0, size.y * 0.61), Vector2(size.x - 92.0, 35.0))
	draw_rect(base, Color(accent.r, accent.g, accent.b, 0.22), true)
	draw_rect(base, accent, false, 2.0)
	for index: int in 5:
		var x: float = base.position.x + 20.0 + float(index) * 54.0
		draw_rect(Rect2(Vector2(x, base.position.y + 10.0), Vector2(25.0, 12.0)), Color("d9f3ff"), true)
	var shield: PackedVector2Array = PackedVector2Array([
		Vector2(size.x * 0.50, 35.0), Vector2(size.x * 0.66, 65.0), Vector2(size.x * 0.61, 129.0),
		Vector2(size.x * 0.50, 156.0), Vector2(size.x * 0.39, 129.0), Vector2(size.x * 0.34, 65.0)
	])
	draw_colored_polygon(shield, Color(accent.r, accent.g, accent.b, 0.27))
	draw_polyline(shield, Color("e8f8ff"), 3.0, true)
	draw_line(Vector2(size.x * 0.43, 94.0), Vector2(size.x * 0.57, 94.0), Color("e8f8ff"), 3.0)
	draw_line(Vector2(size.x * 0.50, 69.0), Vector2(size.x * 0.50, 120.0), Color("e8f8ff"), 3.0)
	draw_string(ThemeDB.fallback_font, Vector2(0.0, size.y - 9.0), "PRECINCT // SHIELD LINE", HORIZONTAL_ALIGNMENT_CENTER, int(size.x), 12, accent)

func _draw_cartel() -> void:
	var neon: Color = Color("ff79c6")
	draw_circle(Vector2(size.x * 0.24, size.y * 0.30), 39.0, Color(neon.r, neon.g, neon.b, 0.18))
	draw_arc(Vector2(size.x * 0.24, size.y * 0.30), 43.0, 0.4, 5.8, 22, neon, 2.0)
	for index: int in 4:
		var y: float = 36.0 + float(index) * 27.0
		draw_line(Vector2(20.0, y), Vector2(size.x - 20.0, y - 24.0), Color(neon.r, neon.g, neon.b, 0.26), 1.4)
	var ship: PackedVector2Array = PackedVector2Array([
		Vector2(58.0, 130.0), Vector2(size.x * 0.51, 67.0), Vector2(size.x - 42.0, 116.0),
		Vector2(size.x * 0.69, 147.0), Vector2(size.x * 0.43, 148.0), Vector2(86.0, 153.0)
	])
	draw_colored_polygon(ship, Color(neon.r, neon.g, neon.b, 0.34))
	draw_polyline(ship, neon.lightened(0.32), 3.0, true)
	draw_circle(Vector2(size.x * 0.51, 108.0), 15.0, Color("5dfff1"))
	draw_circle(Vector2(size.x * 0.51, 108.0), 6.0, Color("15243a"))
	for index: int in 3:
		var crate: Rect2 = Rect2(Vector2(50.0 + float(index) * 83.0, 159.0), Vector2(56.0, 20.0))
		draw_rect(crate, Color(neon.r, neon.g, neon.b, 0.20), true)
		draw_rect(crate, neon, false, 1.5)
	draw_string(ThemeDB.fallback_font, Vector2(0.0, size.y - 9.0), "CONTRABAND // FAST LOGISTICS", HORIZONTAL_ALIGNMENT_CENTER, int(size.x), 12, neon)

func _draw_choir() -> void:
	var signal: Color = Color("72f2bd")
	var center: Vector2 = Vector2(size.x * 0.50, size.y * 0.50)
	for index: int in 4:
		var radius: float = 24.0 + float(index) * 24.0
		draw_arc(center, radius, -2.55, 0.75, 28, Color(signal.r, signal.g, signal.b, 0.20 + float(index) * 0.09), 2.0)
		draw_arc(center, radius, 0.59, 3.72, 28, Color(signal.r, signal.g, signal.b, 0.20 + float(index) * 0.09), 2.0)
	var tower: PackedVector2Array = PackedVector2Array([
		Vector2(size.x * 0.50, 35.0), Vector2(size.x * 0.64, 154.0), Vector2(size.x * 0.36, 154.0)
	])
	draw_colored_polygon(tower, Color(signal.r, signal.g, signal.b, 0.24))
	draw_polyline(tower, signal.lightened(0.22), 3.0, true)
	draw_circle(Vector2(size.x * 0.50, 76.0), 14.0, Color("eafff6"))
	draw_circle(Vector2(size.x * 0.50, 76.0), 6.0, signal)
	for index: int in 5:
		var angle: float = float(index) * TAU / 5.0 - PI * 0.5
		var glyph: Vector2 = center + Vector2.from_angle(angle) * 85.0
		draw_circle(glyph, 5.0, signal)
	draw_string(ThemeDB.fallback_font, Vector2(0.0, size.y - 9.0), "SIGNAL // RECURSIVE NETWORK", HORIZONTAL_ALIGNMENT_CENTER, int(size.x), 12, signal)

func _draw_fang() -> void:
	var ember: Color = Color("ff9b62")
	var moon: Vector2 = Vector2(size.x * 0.72, size.y * 0.32)
	draw_circle(moon, 45.0, Color(ember.r, ember.g, ember.b, 0.18))
	draw_arc(moon, 49.0, -2.0, 2.2, 22, ember, 2.0)
	var rig: PackedVector2Array = PackedVector2Array([
		Vector2(46.0, 143.0), Vector2(76.0, 105.0), Vector2(124.0, 112.0), Vector2(155.0, 75.0),
		Vector2(230.0, 94.0), Vector2(288.0, 140.0), Vector2(269.0, 164.0), Vector2(67.0, 164.0)
	])
	draw_colored_polygon(rig, Color(ember.r, ember.g, ember.b, 0.30))
	draw_polyline(rig, ember.lightened(0.24), 3.0, true)
	for x: float in [92.0, 238.0]:
		draw_circle(Vector2(x, 171.0), 17.0, Color("182033"))
		draw_arc(Vector2(x, 171.0), 17.0, 0.0, TAU, 16, ember, 2.4)
	var claw: PackedVector2Array = PackedVector2Array([
		Vector2(135.0, 80.0), Vector2(156.0, 37.0), Vector2(164.0, 82.0), Vector2(190.0, 40.0),
		Vector2(184.0, 91.0), Vector2(219.0, 62.0), Vector2(196.0, 112.0)
	])
	draw_colored_polygon(claw, ember)
	draw_string(ThemeDB.fallback_font, Vector2(0.0, size.y - 9.0), "WAR-RIG // BOARDING PRESSURE", HORIZONTAL_ALIGNMENT_CENTER, int(size.x), 12, ember)
