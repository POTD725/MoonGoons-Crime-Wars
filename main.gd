extends Node2D

const WORLD := Rect2(-1150, -760, 2500, 1500)
const AUTH := "authority"
const SYND := "syndicate"

var cam := Vector2(60, 50)
var zoom := 0.82
var credits := 420
var supplies := 180
var intel := 0
var units: Array = []
var buildings: Array = []
var nodes: Array = []
var selected: Array[int] = []
var selected_building := -1
var next_id := 1
var build_kind := ""
var drag_from := Vector2.ZERO
var dragging := false
var wave_clock := 0.0
var finished := false
var victory := false
var note := ""
var note_time := 0.0
var font: Font
var stats_label: Label
var select_label: Label
var objective_label: Label
var note_label: Label

var B := {
	"nexus": {"name":"Command Nexus","cost":0,"size":Vector2(116,86),"hp":1250,"time":0.0,"color":Color("5976e8")},
	"armory": {"name":"Tactical Armory","cost":160,"size":Vector2(94,72),"hp":850,"time":8.0,"color":Color("bd76ef")},
	"relay": {"name":"Power Relay","cost":60,"size":Vector2(52,52),"hp":420,"time":4.0,"color":Color("62dcea")},
	"medbay": {"name":"Field Medbay","cost":120,"size":Vector2(78,62),"hp":620,"time":6.0,"color":Color("64dfb2")},
	"bay": {"name":"Drone Bay","cost":110,"size":Vector2(82,62),"hp":600,"time":6.0,"color":Color("79a9ff")},
	"cells": {"name":"Containment Block","cost":170,"size":Vector2(100,76),"hp":920,"time":8.0,"color":Color("f4b96b")},
	"syndicate_relay": {"name":"Syndicate Relay","cost":0,"size":Vector2(138,100),"hp":1650,"time":0.0,"color":Color("ef5877")}
}

var U := {
	"drone": {"name":"Builder Drone","hp":90,"speed":145.0,"range":0.0,"damage":0,"cool":0.0,"r":15.0,"color":Color("91edff"),"cost":65,"time":4.0},
	"deputy": {"name":"Patrol Deputy","hp":155,"speed":122.0,"range":155.0,"damage":13,"cool":0.65,"r":18.0,"color":Color("a0baff"),"cost":85,"time":5.0},
	"shield": {"name":"Shield Deputy","hp":280,"speed":92.0,"range":105.0,"damage":20,"cool":0.85,"r":22.0,"color":Color("dda7ff"),"cost":145,"time":8.0},
	"raider": {"name":"Syndicate Raider","hp":130,"speed":110.0,"range":130.0,"damage":11,"cool":0.8,"r":18.0,"color":Color("ff8094"),"cost":0,"time":0.0},
	"hacker": {"name":"Syndicate Hacker","hp":90,"speed":104.0,"range":190.0,"damage":8,"cool":0.52,"r":15.0,"color":Color("ffc36e"),"cost":0,"time":0.0}
}

func _ready() -> void:
	font = ThemeDB.fallback_font
	_make_hud()
	_spawn_building("nexus", AUTH, Vector2(-260, 145), true)
	for p in [Vector2(-166,180),Vector2(-215,245),Vector2(-310,255)]:
		_spawn_unit("drone", AUTH, p)
	for p in [Vector2(-145,92),Vector2(-332,78)]:
		_spawn_unit("deputy", AUTH, p)
	_spawn_node("ore", Vector2(-550,210),980)
	_spawn_node("ore", Vector2(-420,-95),720)
	_spawn_node("evidence", Vector2(90,280),480)
	_spawn_node("ore", Vector2(210,-155),930)
	_spawn_node("evidence", Vector2(480,150),520)
	_spawn_building("syndicate_relay", SYND, Vector2(780,-250), true)
	for p in [Vector2(675,-180),Vector2(845,-145),Vector2(895,-330)]:
		_spawn_unit("raider", SYND, p)
	for p in [Vector2(740,-385),Vector2(990,-250)]:
		_spawn_unit("hacker", SYND, p)
	flash("Operation Breakwater: mine ore, build an Armory, then silence the Syndicate Relay.", 8.0)

func _process(delta: float) -> void:
	if finished:
		queue_redraw()
		return
	note_time = maxf(0.0, note_time - delta)
	_move_camera(delta)
	_update_buildings(delta)
	_update_units(delta)
	_heal_units(delta)
	wave_clock += delta
	if wave_clock > 35.0:
		wave_clock = 0.0
		var relay := _relay()
		if not relay.is_empty():
			for d in [Vector2(-130,110),Vector2(120,90),Vector2(25,-145)]:
				_spawn_unit("raider", SYND, relay["pos"] + d)
			flash("Syndicate reinforcements have deployed.", 4.0)
	_cleanup()
	_check_end()
	_update_hud()
	queue_redraw()

func _move_camera(delta: float) -> void:
	var v := Vector2.ZERO
	if Input.is_key_pressed(KEY_W): v.y -= 1.0
	if Input.is_key_pressed(KEY_S): v.y += 1.0
	if Input.is_key_pressed(KEY_A): v.x -= 1.0
	if Input.is_key_pressed(KEY_D): v.x += 1.0
	if v.length_squared() > 0:
		cam += v.normalized() * 720.0 * delta / zoom
		cam.x = clampf(cam.x, WORLD.position.x + 320, WORLD.end.x - 320)
		cam.y = clampf(cam.y, WORLD.position.y + 220, WORLD.end.y - 220)

func _update_buildings(delta: float) -> void:
	for b in buildings:
		if not b["done"]:
			b["progress"] = minf(b["progress"] + delta, b["time"])
			if b["progress"] >= b["time"]:
				b["done"] = true
				flash(str(b["name"]) + " is online.", 3.0)

func _update_units(delta: float) -> void:
	for u in units:
		if not u["ready"]:
			u["progress"] += delta
			if u["progress"] >= u["time"]:
				u["ready"] = true
				flash(str(u["name"]) + " deployed.", 2.0)
			continue
		if u["team"] == SYND:
			_enemy_ai(u, delta)
		else:
			_authority_ai(u, delta)

func _authority_ai(u: Dictionary, delta: float) -> void:
	if u["order"] == "move":
		_walk(u, u["target"], delta)
		if u["pos"].distance_to(u["target"]) < 4: u["order"] = "idle"
	elif u["order"] == "attack":
		var target := _entity(int(u["target_id"]))
		if target.is_empty():
			u["order"] = "idle"
		elif u["pos"].distance_to(target["pos"]) > u["range"]:
			_walk(u, target["pos"], delta)
		else:
			_hit(u, target, delta)
	elif u["order"] == "harvest":
		_harvest(u, delta)
	else:
		var enemy := _enemy_near(u, u["range"])
		if not enemy.is_empty(): _hit(u, enemy, delta)

func _enemy_ai(u: Dictionary, delta: float) -> void:
	var t := _closest_authority(u)
	if t.is_empty(): return
	if u["pos"].distance_to(t["pos"]) > u["range"]:
		_walk(u, t["pos"], delta)
	else:
		_hit(u, t, delta)

func _walk(u: Dictionary, target: Vector2, delta: float) -> void:
	u["pos"] = u["pos"].move_toward(target, u["speed"] * delta)

func _harvest(u: Dictionary, delta: float) -> void:
	var i := int(u["target_id"])
	if i < 0 or i >= nodes.size():
		u["order"] = "idle"
		return
	var n := nodes[i]
	if n["amount"] <= 0:
		u["order"] = "idle"
		flash("Resource deposit exhausted.", 2.5)
		return
	if u["pos"].distance_to(n["pos"]) > 48:
		_walk(u, n["pos"], delta)
		return
	u["harvest"] += delta
	if u["harvest"] >= 1.0:
		u["harvest"] = 0.0
		n["amount"] = maxi(0, n["amount"] - 20)
		if n["type"] == "ore":
			credits += 14
			supplies += 4
		else:
			credits += 8
			intel += 5

func _hit(a: Dictionary, t: Dictionary, delta: float) -> void:
	a["attack"] += delta
	if a["attack"] < a["cool"]: return
	a["attack"] = 0.0
	t["hp"] -= a["damage"]
	if t["hp"] <= 0 and t.get("team","") == SYND:
		credits += 18
		intel += 3

func _heal_units(delta: float) -> void:
	for b in buildings:
		if b["team"] != AUTH or b["kind"] != "medbay" or not b["done"]: continue
		for u in units:
			if u["team"] == AUTH and u["pos"].distance_to(b["pos"]) < 150:
				u["hp"] = minf(u["max"], u["hp"] + delta * 9.0)

func _cleanup() -> void:
	units = units.filter(func(x): return x["hp"] > 0)
	buildings = buildings.filter(func(x): return x["hp"] > 0)
	selected = selected.filter(func(id): return not _entity(id).is_empty())
	if selected_building != -1 and _entity(selected_building).is_empty(): selected_building = -1

func _check_end() -> void:
	if _relay().is_empty():
		finished = true
		victory = true
		flash("Operation Breakwater complete. The Relay is silent.", 999.0)
		return
	var nexus_ok := false
	for b in buildings:
		if b["team"] == AUTH and b["kind"] == "nexus": nexus_ok = true
	if not nexus_ok:
		finished = true
		victory = false
		flash("The Command Nexus has fallen.", 999.0)

func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventMouseButton:
		if e.button_index == MOUSE_BUTTON_WHEEL_UP and e.pressed: zoom = clampf(zoom * 1.12, 0.48, 1.42)
		elif e.button_index == MOUSE_BUTTON_WHEEL_DOWN and e.pressed: zoom = clampf(zoom / 1.12, 0.48, 1.42)
		elif e.button_index == MOUSE_BUTTON_LEFT:
			if e.pressed:
				drag_from = e.position
				dragging = true
				if not build_kind.is_empty():
					_place(_world(e.position))
					dragging = false
			else:
				if dragging: _select(_world(e.position))
				dragging = false
		elif e.button_index == MOUSE_BUTTON_RIGHT and e.pressed:
			_order(_world(e.position))
	elif e is InputEventKey and e.pressed and not e.echo:
		match e.keycode:
			KEY_ESCAPE: build_kind = ""; flash("Build order cancelled.", 2.0)
			KEY_1: _build("armory")
			KEY_2: _build("relay")
			KEY_3: _build("medbay")
			KEY_4: _build("bay")
			KEY_5: _build("cells")
			KEY_Q: _train("deputy")
			KEY_E: _train("drone")
			KEY_R: _train("shield")

func _select(p: Vector2) -> void:
	if finished: return
	selected.clear()
	selected_building = -1
	var a := _world(drag_from)
	var box := Rect2(a,p-a).abs()
	if box.size.length() < 20:
		var u := _our_unit(p)
		if not u.is_empty():
			selected.append(u["id"])
			return
		var b := _our_building(p)
		if not b.is_empty(): selected_building = b["id"]
		return
	for u in units:
		if u["team"] == AUTH and box.has_point(u["pos"]): selected.append(u["id"])

func _order(p: Vector2) -> void:
	if selected.is_empty() or finished: return
	var enemy := _enemy_at(p)
	var resource := _node_at(p)
	var f := 0
	for id in selected:
		var u := _entity(id)
		if u.is_empty(): continue
		if not enemy.is_empty():
			u["order"] = "attack"
			u["target_id"] = enemy["id"]
		elif u["kind"] == "drone" and resource >= 0:
			u["order"] = "harvest"
			u["target_id"] = resource
		else:
			u["order"] = "move"
			u["target"] = p + Vector2((f % 3 - 1) * 28,(f / 3 - 1) * 28)
			f += 1

func _build(kind: String) -> void:
	if not _has_drone():
		flash("Select a Builder Drone before placing a structure.", 3.5)
		return
	build_kind = kind
	flash("Place " + str(B[kind]["name"]) + " with left-click.", 4.0)

func _place(p: Vector2) -> void:
	var s := B[build_kind]
	if credits < s["cost"]:
		flash("Insufficient Credits.", 2.5)
		return
	if not _valid(p, s["size"]):
		flash("Construction zone blocked.", 2.5)
		return
	credits -= s["cost"]
	_spawn_building(build_kind, AUTH, p, false)
	build_kind = ""

func _train(kind: String) -> void:
	var producer := _producer(kind)
	if producer.is_empty():
		flash("Select a Command Nexus, or an Armory for Shield Deputies.", 3.5)
		return
	var spec := U[kind]
	if credits < spec["cost"]:
		flash("Insufficient Credits.", 2.5)
		return
	credits -= spec["cost"]
	var u := _spawn_unit(kind, AUTH, producer["pos"] + Vector2(88,58))
	u["ready"] = false
	u["progress"] = 0.0
	u["time"] = spec["time"]
	flash(str(spec["name"]) + " queued.", 2.5)

func _has_drone() -> bool:
	for id in selected:
		var u := _entity(id)
		if not u.is_empty() and u["kind"] == "drone": return true
	return false

func _producer(kind: String) -> Dictionary:
	var b := _entity(selected_building)
	if b.is_empty() or not b["done"]: return {}
	if kind == "shield" and b["kind"] == "armory": return b
	if kind != "shield" and b["kind"] == "nexus": return b
	return {}

func _spawn_unit(kind: String, team: String, p: Vector2) -> Dictionary:
	var s := U[kind]
	var u := {"id":next_id,"kind":kind,"name":s["name"],"team":team,"pos":p,"target":p,"target_id":-1,"order":"idle","hp":float(s["hp"]),"max":float(s["hp"]),"speed":s["speed"],"range":s["range"],"damage":s["damage"],"cool":s["cool"],"r":s["r"],"color":s["color"],"attack":0.0,"harvest":0.0,"ready":true,"progress":0.0,"time":0.0}
	next_id += 1
	units.append(u)
	return u

func _spawn_building(kind: String, team: String, p: Vector2, done: bool) -> Dictionary:
	var s := B[kind]
	var b := {"id":next_id,"kind":kind,"name":s["name"],"team":team,"pos":p,"hp":float(s["hp"]),"max":float(s["hp"]),"size":s["size"],"color":s["color"],"done":done,"time":s["time"],"progress":s["time"] if done else 0.0}
	next_id += 1
	buildings.append(b)
	return b

func _spawn_node(kind: String, p: Vector2, amount: int) -> void:
	nodes.append({"type":kind,"pos":p,"amount":amount,"max":amount})

func _entity(id: int) -> Dictionary:
	for u in units:
		if u["id"] == id: return u
	for b in buildings:
		if b["id"] == id: return b
	return {}

func _relay() -> Dictionary:
	for b in buildings:
		if b["kind"] == "syndicate_relay": return b
	return {}

func _enemy_near(u: Dictionary, d: float) -> Dictionary:
	var best := {}
	var dist := d
	for x in units + buildings:
		if x["team"] == SYND and u["pos"].distance_to(x["pos"]) < dist:
			best = x
			dist = u["pos"].distance_to(x["pos"])
	return best

func _closest_authority(u: Dictionary) -> Dictionary:
	var best := {}
	var dist := INF
	for x in units + buildings:
		if x["team"] == AUTH and u["pos"].distance_to(x["pos"]) < dist:
			best = x
			dist = u["pos"].distance_to(x["pos"])
	return best

func _our_unit(p: Vector2) -> Dictionary:
	var best := {}
	var d := 34.0
	for u in units:
		if u["team"] == AUTH and p.distance_to(u["pos"]) < d:
			best = u
			d = p.distance_to(u["pos"])
	return best

func _our_building(p: Vector2) -> Dictionary:
	for b in buildings:
		if b["team"] == AUTH and Rect2(b["pos"]-b["size"]*0.5,b["size"]).has_point(p): return b
	return {}

func _enemy_at(p: Vector2) -> Dictionary:
	var best := {}
	var d := 44.0
	for u in units:
		if u["team"] == SYND and _revealed(u["pos"]) and p.distance_to(u["pos"]) < d:
			best = u
			d = p.distance_to(u["pos"])
	for b in buildings:
		if b["team"] == SYND and _revealed(b["pos"]) and Rect2(b["pos"]-b["size"]*0.5,b["size"]).grow(20).has_point(p): return b
	return best

func _node_at(p: Vector2) -> int:
	var best := -1
	var d := 54.0
	for i in nodes.size():
		if nodes[i]["amount"] > 0 and p.distance_to(nodes[i]["pos"]) < d:
			best = i
			d = p.distance_to(nodes[i]["pos"])
	return best

func _valid(p: Vector2, size: Vector2) -> bool:
	var r := Rect2(p-size*0.5,size)
	if not WORLD.grow(-80).encloses(r): return false
	for b in buildings:
		if r.grow(30).intersects(Rect2(b["pos"]-b["size"]*0.5,b["size"])): return false
	for n in nodes:
		if r.grow(22).has_point(n["pos"]): return false
	return true

func _world(screen: Vector2) -> Vector2:
	return cam + (screen-get_viewport_rect().size*0.5)/zoom

func _revealed(p: Vector2) -> bool:
	for x in units + buildings:
		if x["team"] == AUTH and x["pos"].distance_to(p) < 340: return true
	return false

func _draw() -> void:
	var view := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO,view),Color("071021"))
	draw_set_transform(view*0.5-cam*zoom,0,Vector2.ONE*zoom)
	_terrain()
	_draw_nodes()
	_draw_buildings()
	_draw_units()
	_fog()
	_ghost()
	draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
	if dragging and build_kind.is_empty():
		draw_rect(Rect2(drag_from,get_viewport().get_mouse_position()-drag_from).abs(),Color(0.6,0.8,1,0.12),true)
	if finished: _banner(view)

func _terrain() -> void:
	draw_rect(WORLD,Color("131e33"),true)
	for x in range(int(WORLD.position.x),int(WORLD.end.x),80):
		draw_line(Vector2(x,WORLD.position.y),Vector2(x,WORLD.end.y),Color(0.24,0.32,0.47,0.36))
	for y in range(int(WORLD.position.y),int(WORLD.end.y),80):
		draw_line(Vector2(WORLD.position.x,y),Vector2(WORLD.end.x,y),Color(0.24,0.32,0.47,0.36))
	for c in [Vector2(-760,-420),Vector2(-40,-520),Vector2(360,420),Vector2(1050,320),Vector2(650,-650)]:
		draw_circle(c,92,Color(0.12,0.17,0.29,0.7))
	draw_rect(WORLD,Color("5d759e"),false,5)

func _draw_nodes() -> void:
	for n in nodes:
		if n["amount"] <= 0: continue
		var color := Color("65e6ff") if n["type"] == "ore" else Color("ffc15e")
		var p := n["pos"]
		draw_circle(p,29,Color(color,0.22))
		for i in 5:
			var a := i*TAU/5.0
			draw_colored_polygon(PackedVector2Array([p,p+Vector2.from_angle(a-.35)*26,p+Vector2.from_angle(a+.22)*30]),color)
		draw_string(font,p+Vector2(-28,46),"ORE" if n["type"]=="ore" else "EVID",HORIZONTAL_ALIGNMENT_LEFT,-1,12,color)

func _draw_buildings() -> void:
	for b in buildings:
		if b["team"] == SYND and not _revealed(b["pos"]): continue
		var r := Rect2(b["pos"]-b["size"]*0.5,b["size"])
		var c: Color = b["color"]
		draw_rect(r.grow(9),Color(c,0.10),true)
		draw_rect(r,Color(c,0.30 if b["done"] else 0.14),true)
		draw_rect(r,c.lightened(0.25),false,3 if b["id"]==selected_building else 2)
		draw_rect(r.grow(-12),Color("0b1325"),true)
		if b["kind"] == "syndicate_relay":
			draw_circle(b["pos"],31,Color("ef5877"))
			draw_circle(b["pos"],17,Color("3a0b28"))
		elif b["kind"] == "nexus":
			draw_circle(b["pos"],28,Color("8c9fff"))
			draw_arc(b["pos"],38,-.3,TAU-.3,24,Color("d2ddff"),3)
		elif b["kind"] == "medbay":
			draw_rect(Rect2(b["pos"]+Vector2(-8,-26),Vector2(16,52)),c,true)
			draw_rect(Rect2(b["pos"]+Vector2(-26,-8),Vector2(52,16)),c,true)
		else:
			draw_circle(b["pos"],minf(b["size"].x,b["size"].y)*0.25,c)
		_bar(b["pos"]+Vector2(-b["size"].x*.45,-b["size"].y*.63),b["size"].x*.9,b["hp"]/b["max"])
		draw_string(font,b["pos"]+Vector2(-b["size"].x*.42,b["size"].y*.5+19),b["name"],HORIZONTAL_ALIGNMENT_LEFT,b["size"].x*.84,13,Color("e9f4ff"))
		if not b["done"]:
			draw_rect(Rect2(b["pos"]+Vector2(-b["size"].x*.4,b["size"].y*.5+27),Vector2(b["size"].x*.8*b["progress"]/b["time"],6)),Color("6ee4d2"),true)

func _draw_units() -> void:
	for u in units:
		if u["team"] == SYND and not _revealed(u["pos"]): continue
		var p := u["pos"]
		var r: float = u["r"]
		var c: Color = u["color"]
		if not u["ready"]:
			draw_arc(p,r+10,-PI*.5,-PI*.5+TAU*u["progress"]/maxf(.01,u["time"]),18,c,3)
			continue
		if selected.has(u["id"]): draw_arc(p,r+9,0,TAU,20,Color("deecff"),2.5)
		if u["team"] == AUTH:
			draw_circle(p,r+6,Color(c,0.16))
			draw_circle(p,r,Color(c,0.82))
			draw_circle(p,r*.45,Color("101b31"))
			if u["kind"] == "drone":
				draw_line(p+Vector2(-r,0),p+Vector2(r,0),Color("d8f7ff"),3)
				draw_line(p+Vector2(0,-r),p+Vector2(0,r),Color("d8f7ff"),3)
		else:
			draw_colored_polygon(PackedVector2Array([p+Vector2(0,-r),p+Vector2(r,r),p+Vector2(-r,r)]),Color(c,0.9))
		_bar(p+Vector2(-r,-r-17),r*2,u["hp"]/u["max"])
		if u["order"] == "harvest": draw_arc(p,r+3,0,TAU*.65,16,Color("ffc15e"),2)

func _fog() -> void:
	for x in range(int(WORLD.position.x/80),int(WORLD.end.x/80)):
		for y in range(int(WORLD.position.y/80),int(WORLD.end.y/80)):
			var p := Vector2(x*80,y*80)
			if not _revealed(p+Vector2(40,40)):
				draw_rect(Rect2(p,Vector2(80,80)),Color(0.015,0.025,0.07,.78),true)

func _ghost() -> void:
	if build_kind.is_empty(): return
	var s := B[build_kind]
	var p := _world(get_viewport().get_mouse_position())
	var good := _valid(p,s["size"]) and credits >= s["cost"]
	var c := Color("70f2bf") if good else Color("ff4f71")
	var r := Rect2(p-s["size"]*.5,s["size"])
	draw_rect(r,Color(c,.16),true)
	draw_rect(r,c,false,2)
	draw_string(font,p+Vector2(-s["size"].x*.45,s["size"].y*.5+22),str(s["name"])+"  "+str(s["cost"])+"c",HORIZONTAL_ALIGNMENT_LEFT,s["size"].x*.9,13,c)

func _bar(p: Vector2, width: float, ratio: float) -> void:
	draw_rect(Rect2(p,Vector2(width,6)),Color("190d18"),true)
	draw_rect(Rect2(p,Vector2(width*clampf(ratio,0,1),6)),Color("7dffad") if ratio>.35 else Color("ff6f83"),true)

func _banner(view: Vector2) -> void:
	var r := Rect2(view*.5-Vector2(310,102),Vector2(620,204))
	var c := Color("7cebd1") if victory else Color("ff6d83")
	draw_rect(r,Color(0.02,0.04,0.1,.94),true)
	draw_rect(r,c,false,3)
	draw_string(font,r.position+Vector2(72,75),"MISSION COMPLETE" if victory else "MISSION FAILED",HORIZONTAL_ALIGNMENT_LEFT,480,34,c)
	draw_string(font,r.position+Vector2(72,120),"The Authority reclaimed Breakwater." if victory else "The Syndicate swallowed the outpost.",HORIZONTAL_ALIGNMENT_LEFT,480,19,Color("ebf4ff"))

func _make_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var p := Panel.new()
	p.position=Vector2(18,18)
	p.size=Vector2(500,265)
	layer.add_child(p)
	var style := StyleBoxFlat.new()
	style.bg_color=Color(0.035,0.07,0.15,.9)
	style.border_color=Color("4068a0")
	style.set_border_width_all(2)
	style.corner_radius_top_left=10
	style.corner_radius_top_right=10
	style.corner_radius_bottom_left=10
	style.corner_radius_bottom_right=10
	p.add_theme_stylebox_override("panel",style)
	var title := _label(p,Vector2(16,12),Vector2(465,24),15,Color("bbd7ff"))
	title.text="MOONGOONS: CRIME WARS  //  OPERATION BREAKWATER"
	stats_label=_label(p,Vector2(16,42),Vector2(465,24),16,Color("eef6ff"))
	select_label=_label(p,Vector2(16,68),Vector2(465,25),14,Color("bfd2ed"))
	objective_label=_label(p,Vector2(16,96),Vector2(465,37),14,Color("ffdc8f"))
	note_label=_label(p,Vector2(16,136),Vector2(465,35),13,Color("85f1cf"))
	var help:=_label(p,Vector2(16,178),Vector2(465,78),13,Color("b6cbe6"))
	help.text="Left-click or drag: select   •   Right-click: move / attack / harvest\n1 Armory  2 Relay  3 Medbay  4 Drone Bay  5 Containment\nQ Deputy at Nexus  •  E Drone at Nexus  •  R Shield at Armory\nWASD pan camera  •  Wheel zoom  •  Esc cancel build"

func _label(parent: Control, p: Vector2, size: Vector2, fs: int, c: Color) -> Label:
	var l:=Label.new()
	l.position=p
	l.size=size
	l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size",fs)
	l.add_theme_color_override("font_color",c)
	parent.add_child(l)
	return l

func _update_hud() -> void:
	if stats_label == null: return
	stats_label.text="CREDITS  %d     SUPPLIES  %d     INTEL  %d" % [credits,supplies,intel]
	var s:="No active selection."
	if not selected.is_empty():
		var names:=[]
		for id in selected:
			var u:=_entity(id)
			if not u.is_empty(): names.append(u["name"])
		s="Selected: "+", ".join(names)
	elif selected_building != -1:
		var b:=_entity(selected_building)
		if not b.is_empty(): s="Selected: "+str(b["name"])+(" [ONLINE]" if b["done"] else " [BUILDING]")
	if not build_kind.is_empty(): s="BUILD MODE: "+str(B[build_kind]["name"])+" · "+str(B[build_kind]["cost"])+" Credits"
	select_label.text=s
	var r:=_relay()
	objective_label.text="OBJECTIVE: Neutralize the Syndicate Relay." + ("  Relay: %d / %d HP" % [int(r["hp"]),int(r["max"])] if not r.is_empty() else "")
	note_label.text=note if note_time>0 or finished else ""

func flash(t: String, time: float=3.0) -> void:
	note=t
	note_time=time
