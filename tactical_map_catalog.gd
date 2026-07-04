extends RefCounted
## Playable battlefield profiles for MoonGoons: Crime Wars.
## Each profile defines hard map bounds, collision geometry, terrain elevation, build rules,
## resource locations, and opposing command positions.

static func get_profile(map_label: String) -> Dictionary:
	match map_label:
		"Black Crater":
			return _black_crater()
		"Syndicate Docks":
			return _syndicate_docks()
		"Underhive Sector":
			return _underhive_sector()
		"Iron Ridge":
			return _iron_ridge()
		"Shatterpoint":
			return _shatterpoint()
		"Obsidian Pass":
			return _obsidian_pass()
		"Null Chapel":
			return _null_chapel()
		"Smuggler's Run":
			return _smugglers_run()
		"Shadow Terminal":
			return _shadow_terminal()
		"Frostline Outpost":
			return _frostline_outpost()
		"Wreckage Fields":
			return _wreckage_fields()
		_:
			return _nexus_prime()

static func _profile(label: String, theme: String, player_spawn: Vector2, relay_spawn: Vector2, obstacles: Array, terrain: Array, resources: Array, authority_zone: Rect2, syndicate_zone: Rect2) -> Dictionary:
	return {
		"label": label,
		"theme": theme,
		"bounds": Rect2(-2700.0, -1700.0, 5400.0, 3400.0),
		"player_spawn": player_spawn,
		"relay_spawn": relay_spawn,
		"obstacles": obstacles,
		"terrain": terrain,
		"resources": resources,
		"authority_zone": authority_zone,
		"syndicate_zone": syndicate_zone
	}

static func _wall(x: float, y: float, width: float, height: float, name: String, type: String = "wall") -> Dictionary:
	return {"rect": Rect2(x, y, width, height), "name": name, "type": type}

static func _field(x: float, y: float, width: float, height: float, terrain_type: String, elevation: int, move_mult: float, buildable: bool = true, blocked: bool = false, label: String = "") -> Dictionary:
	return {
		"rect": Rect2(x, y, width, height),
		"type": terrain_type,
		"elevation": elevation,
		"move_mult": move_mult,
		"buildable": buildable,
		"blocked": blocked,
		"label": label
	}

static func _node(kind: String, x: float, y: float, amount: int) -> Dictionary:
	return {"type": kind, "pos": Vector2(x, y), "amount": amount}

static func _nexus_prime() -> Dictionary:
	return _profile(
		"Nexus Prime", "city", Vector2(-1880.0, 780.0), Vector2(1930.0, -940.0),
		[
			_wall(-1250, -1290, 610, 150, "Collapsed Freight Wall"),
			_wall(-980, -1160, 120, 470, "Freight Spine"),
			_wall(-1180, 820, 470, 110, "Salvage Bay North"),
			_wall(-1180, 930, 110, 350, "Salvage Bay West"),
			_wall(-790, 930, 110, 350, "Salvage Bay East"),
			_wall(-450, 650, 490, 155, "Crater Rampart", "crater"),
			_wall(260, 760, 540, 135, "Broken Conveyor"),
			_wall(690, 900, 120, 410, "Dock East Wall"),
			_wall(1040, 900, 120, 410, "Dock West Wall"),
			_wall(690, 1200, 470, 110, "Dock Cap"),
			_wall(640, -1280, 590, 145, "Irradiated Wreck Line", "crater"),
			_wall(1260, -1490, 130, 470, "Relay Service Wall"),
			_wall(1500, -520, 560, 135, "Cartel Barricade"),
			_wall(2260, -1250, 160, 520, "Relay Dead-End Wall")
		],
		[
			_field(-2440, 250, 980, 900, "plaza", 0, 1.0, true, false, "AUTHORITY LANDING"),
			_field(-580, 500, 580, 380, "crater_floor", -1, 0.73, false, false, "CRATER LOWLAND"),
			_field(420, -280, 760, 340, "elevated_deck", 1, 0.88, true, false, "FREIGHT DECK"),
			_field(1450, -1500, 930, 920, "relay_platform", 1, 0.90, true, false, "SYNDICATE RELAY")
		],
		[_node("ore", -2070, 700, 1050), _node("ore", -1510, 410, 860), _node("evidence", -1120, 1010, 620), _node("ore", -760, 190, 1080), _node("evidence", -180, -300, 760), _node("ore", 470, 280, 1120), _node("evidence", 980, -370, 720), _node("ore", 1420, -710, 980), _node("evidence", 1820, -1320, 640)],
		Rect2(-2440, 250, 980, 900), Rect2(1450, -1500, 930, 920)
	)

static func _black_crater() -> Dictionary:
	return _profile(
		"Black Crater", "moon", Vector2(-2080, 770), Vector2(2020, -890),
		[
			_wall(-1350, -1340, 460, 150, "Northern Crater Rim", "crater"),
			_wall(-720, -540, 450, 330, "The Maw", "crater"),
			_wall(140, -1260, 660, 150, "Razor Ridge", "crater"),
			_wall(520, 380, 520, 400, "Southfall Crater", "crater"),
			_wall(1310, -420, 190, 610, "Impact Spine", "crater"),
			_wall(1710, -1250, 550, 150, "Relay Rim", "crater")
		],
		[
			_field(-2260, 280, 760, 900, "regolith", 0, 1.0, true, false, "LUNAR APPROACH"),
			_field(-1120, -950, 620, 460, "high_rim", 2, 0.70, false, false, "HIGH RIM"),
			_field(-850, -710, 760, 620, "crater_floor", -2, 0.58, false, false, "BLACK CRATER"),
			_field(100, 420, 950, 560, "crater_floor", -1, 0.70, false, false, "DUST BASIN"),
			_field(1460, -1390, 760, 840, "high_rim", 2, 0.72, false, false, "RELAY RIM")
		],
		[_node("ore", -2050, 650, 1200), _node("ore", -1480, 980, 830), _node("evidence", -1330, -360, 700), _node("ore", -260, 260, 1060), _node("evidence", 680, -220, 760), _node("ore", 1180, 760, 960), _node("evidence", 1770, -760, 740), _node("ore", 2160, -1210, 920)],
		Rect2(-2350, 230, 800, 980), Rect2(1500, -1440, 820, 930)
	)

static func _syndicate_docks() -> Dictionary:
	return _profile(
		"Syndicate Docks", "docks", Vector2(-2180, 940), Vector2(1950, -1120),
		[
			_wall(-1720, -1260, 170, 1830, "West Drydock"),
			_wall(-1260, -870, 1260, 140, "Container Causeway"),
			_wall(-1180, -160, 840, 120, "Customs Gate"),
			_wall(-770, 540, 1620, 130, "Floodwall"),
			_wall(90, -1500, 150, 960, "Pier One"),
			_wall(720, -1090, 120, 920, "Pier Two"),
			_wall(1320, -1450, 130, 1130, "Relay Quay"),
			_wall(1750, -610, 580, 120, "Syndicate Breakwater")
		],
		[
			_field(-2450, 420, 790, 970, "cargo_yard", 0, 0.94, true, false, "CUSTOMS YARD"),
			_field(-1540, -1650, 2640, 670, "void_water", -3, 0.0, false, true, "DARK SEA"),
			_field(-1130, -720, 780, 480, "dock_deck", 1, 0.89, true, false, "PIER PLATFORM"),
			_field(270, -1490, 360, 1170, "dock_deck", 1, 0.86, true, false, "PIER ONE"),
			_field(890, -1490, 360, 1170, "dock_deck", 1, 0.86, true, false, "PIER TWO"),
			_field(1490, -1450, 830, 870, "dock_deck", 1, 0.91, true, false, "RELAY QUAY")
		],
		[_node("ore", -2140, 760, 1120), _node("evidence", -1890, 1120, 710), _node("ore", -1240, 250, 980), _node("evidence", -680, -540, 830), _node("ore", 460, -420, 970), _node("evidence", 1040, -780, 760), _node("ore", 1660, -980, 1080), _node("evidence", 2120, -1320, 700)],
		Rect2(-2450, 420, 790, 970), Rect2(1490, -1450, 830, 870)
	)

static func _underhive_sector() -> Dictionary:
	return _profile(
		"Underhive Sector", "underhive", Vector2(-2140, 820), Vector2(2040, -820),
		[
			_wall(-1770, -1510, 150, 2100, "West Hab Stack"),
			_wall(-1290, -1200, 150, 1620, "Hab Stack A"),
			_wall(-800, -1510, 150, 1190, "Hab Stack B"),
			_wall(-800, 130, 150, 1010, "Hab Stack C"),
			_wall(-300, -950, 150, 1550, "Market Spine"),
			_wall(220, -1510, 150, 1140, "Reactor Spine"),
			_wall(220, 100, 150, 1040, "Reactor Spine South"),
			_wall(740, -1140, 150, 1650, "Relay Spine"),
			_wall(1250, -1510, 150, 1130, "Relay Ward"),
			_wall(1250, 30, 150, 1110, "Relay Ward South"),
			_wall(1750, -1510, 150, 2060, "East Hab Stack")
		],
		[
			_field(-2500, -1600, 4900, 3100, "underhive_floor", 0, 0.96, true, false, "UNDERHIVE"),
			_field(-1530, -1100, 260, 1460, "service_trench", -1, 0.80, false, false, "SERVICE TRENCH"),
			_field(-1040, -440, 160, 510, "elevated_walkway", 2, 0.76, false, false, "WALKWAY"),
			_field(430, -470, 170, 540, "elevated_walkway", 2, 0.76, false, false, "WALKWAY"),
			_field(1540, -1030, 180, 1280, "elevated_walkway", 2, 0.76, false, false, "WALKWAY")
		],
		[_node("ore", -2200, 660, 1020), _node("evidence", -1480, 780, 740), _node("ore", -1030, 720, 910), _node("evidence", -540, -580, 820), _node("ore", 10, 760, 1040), _node("evidence", 550, -570, 760), _node("ore", 1080, 780, 970), _node("evidence", 1580, -720, 860), _node("ore", 2050, -1130, 980)],
		Rect2(-2450, 420, 720, 920), Rect2(1570, -1390, 680, 890)
	)

static func _iron_ridge() -> Dictionary:
	return _profile(
		"Iron Ridge", "iron", Vector2(-2160, 930), Vector2(2010, -930),
		[
			_wall(-1420, -1510, 240, 1300, "West Iron Ridge", "crater"),
			_wall(-1010, 250, 210, 1130, "West Ridge South", "crater"),
			_wall(-520, -1390, 230, 1180, "Central Ridge", "crater"),
			_wall(-80, 310, 230, 1060, "Central Ridge South", "crater"),
			_wall(430, -1500, 230, 1260, "East Ridge", "crater"),
			_wall(900, 210, 220, 1160, "East Ridge South", "crater"),
			_wall(1440, -1360, 230, 1250, "Relay Iron Ridge", "crater")
		],
		[
			_field(-2460, 390, 910, 980, "iron_flats", 0, 0.97, true, false, "MINING APPROACH"),
			_field(-1600, -1470, 420, 1320, "high_rim", 2, 0.68, false, false, "IRON RIDGE"),
			_field(-670, -1420, 470, 1260, "high_rim", 2, 0.68, false, false, "IRON RIDGE"),
			_field(270, -1470, 480, 1260, "high_rim", 2, 0.68, false, false, "IRON RIDGE"),
			_field(1320, -1450, 580, 1250, "high_rim", 2, 0.68, false, false, "RELAY RIDGE"),
			_field(-1130, 430, 2480, 900, "slag_lowland", -1, 0.77, false, false, "SLAG LOWLAND")
		],
		[_node("ore", -2180, 780, 1260), _node("ore", -1760, 1110, 980), _node("evidence", -1300, -680, 730), _node("ore", -820, 60, 1100), _node("evidence", -380, 880, 780), _node("ore", 290, 30, 1160), _node("evidence", 760, 910, 740), _node("ore", 1320, -590, 1080), _node("evidence", 2010, -1120, 790)],
		Rect2(-2470, 400, 890, 960), Rect2(1510, -1400, 720, 880)
	)

static func _shatterpoint() -> Dictionary:
	return _profile(
		"Shatterpoint", "volcanic", Vector2(-2110, 850), Vector2(2010, -890),
		[
			_wall(-1280, -1290, 740, 140, "Northern Fault", "crater"),
			_wall(-900, -930, 160, 970, "West Fracture", "crater"),
			_wall(-430, 400, 680, 160, "South Fracture", "crater"),
			_wall(50, -820, 160, 1030, "Central Fracture", "crater"),
			_wall(520, -1310, 780, 145, "East Fault", "crater"),
			_wall(920, -860, 160, 900, "East Fracture", "crater"),
			_wall(1430, -480, 620, 150, "Relay Fault", "crater")
		],
		[
			_field(-2440, 330, 880, 970, "ash_plain", 0, 0.94, true, false, "ASH APPROACH"),
			_field(-1500, -1480, 880, 470, "high_rim", 2, 0.72, false, false, "NORTH ESCARPMENT"),
			_field(-690, -760, 430, 1030, "magma_crack", -3, 0.0, false, true, "ACTIVE RIFT"),
			_field(230, -1070, 540, 1300, "ash_lowland", -1, 0.72, false, false, "SHATTER BASIN"),
			_field(1190, -1450, 970, 980, "high_rim", 2, 0.72, false, false, "RELAY ESCARPMENT")
		],
		[_node("ore", -2140, 720, 1160), _node("ore", -1700, 1080, 860), _node("evidence", -1180, -720, 760), _node("ore", -520, 90, 1010), _node("evidence", -130, -350, 840), _node("ore", 480, 410, 1040), _node("evidence", 900, -460, 780), _node("ore", 1420, -850, 960), _node("evidence", 1900, -1190, 820)],
		Rect2(-2420, 300, 850, 980), Rect2(1390, -1430, 800, 910)
	)

static func _obsidian_pass() -> Dictionary:
	return _profile(
		"Obsidian Pass", "obsidian", Vector2(-2200, 900), Vector2(1980, -900),
		[
			_wall(-1440, -1510, 500, 1330, "West Blackwall", "crater"),
			_wall(-1440, 220, 500, 1180, "West Blackwall South", "crater"),
			_wall(-510, -1220, 210, 840, "Gate Pillar West", "crater"),
			_wall(-510, 130, 210, 1010, "Gate Pillar West South", "crater"),
			_wall(290, -1210, 210, 840, "Gate Pillar East", "crater"),
			_wall(290, 130, 210, 1010, "Gate Pillar East South", "crater"),
			_wall(940, -1510, 500, 1330, "East Blackwall", "crater"),
			_wall(940, 220, 500, 1180, "East Blackwall South", "crater")
		],
		[
			_field(-2450, 370, 850, 980, "obsidian_plain", 0, 0.96, true, false, "AUTHORITY OUTCROP"),
			_field(-1530, -1510, 670, 2900, "high_rim", 3, 0.62, false, false, "OBSIDIAN WALL"),
			_field(-800, -1320, 1450, 2600, "pass_floor", -1, 0.81, true, false, "THE PASS"),
			_field(850, -1510, 670, 2900, "high_rim", 3, 0.62, false, false, "OBSIDIAN WALL"),
			_field(1510, -1410, 760, 850, "relay_platform", 1, 0.90, true, false, "RELAY REDOUBT")
		],
		[_node("ore", -2180, 760, 1150), _node("evidence", -1850, 1120, 720), _node("ore", -900, 780, 1010), _node("evidence", -410, -610, 810), _node("ore", 20, 760, 1200), _node("evidence", 380, -520, 830), _node("ore", 780, 780, 1020), _node("evidence", 1380, -710, 850), _node("ore", 2010, -1110, 980)],
		Rect2(-2460, 360, 850, 990), Rect2(1510, -1410, 760, 850)
	)

static func _null_chapel() -> Dictionary:
	return _profile(
		"Null Chapel", "chapel", Vector2(-2180, 890), Vector2(2030, -930),
		[
			_wall(-1160, -1510, 280, 1160, "West Nave"),
			_wall(-1160, 120, 280, 1190, "West Nave South"),
			_wall(-440, -1020, 880, 240, "North Transept"),
			_wall(-440, 290, 880, 240, "South Transept"),
			_wall(860, -1510, 280, 1160, "East Nave"),
			_wall(860, 120, 280, 1190, "East Nave South"),
			_wall(1250, -540, 780, 210, "Relay Cloister"),
			_wall(1250, -1200, 210, 610, "Relay Cloister West"),
			_wall(1980, -1200, 210, 610, "Relay Cloister East")
		],
		[
			_field(-2480, 360, 970, 970, "chapel_courtyard", 0, 0.96, true, false, "OUTER COURTYARD"),
			_field(-760, -1470, 1900, 2650, "chapel_floor", 1, 0.88, true, false, "NULL CHAPEL"),
			_field(-310, -720, 620, 580, "sanctum", 2, 0.71, false, false, "SANCTUM HEIGHT"),
			_field(1240, -1370, 1010, 960, "relay_platform", 1, 0.89, true, false, "CLOISTER RELAY")
		],
		[_node("ore", -2180, 750, 1070), _node("evidence", -1740, 1110, 760), _node("ore", -1340, -280, 940), _node("evidence", -700, 720, 810), _node("ore", -90, 720, 1080), _node("evidence", 180, -460, 860), _node("ore", 720, 740, 970), _node("evidence", 1450, -730, 870), _node("ore", 2050, -1050, 960)],
		Rect2(-2480, 360, 970, 970), Rect2(1240, -1370, 1010, 960)
	)

static func _smugglers_run() -> Dictionary:
	return _profile(
		"Smuggler's Run", "smuggler", Vector2(-2250, 950), Vector2(2050, -1050),
		[
			_wall(-1710, -1510, 170, 2050, "West Canyon Wall", "crater"),
			_wall(-1260, -1060, 980, 150, "North Switchback"),
			_wall(-830, -730, 150, 870, "Switchback West"),
			_wall(-360, 250, 970, 150, "Mid Switchback"),
			_wall(120, -780, 150, 870, "Switchback East"),
			_wall(570, -1230, 980, 150, "East Switchback"),
			_wall(1040, -870, 150, 760, "Relay Route Wall"),
			_wall(1520, -1510, 180, 1140, "Relay Canyon Wall", "crater")
		],
		[
			_field(-2450, 420, 730, 910, "dust_road", 0, 1.0, true, false, "RUNNER GATE"),
			_field(-1510, -1430, 3000, 2650, "smuggler_track", 0, 0.91, true, false, "SMUGGLER ROUTE"),
			_field(-1020, -850, 350, 950, "low_canyon", -2, 0.65, false, false, "LOW CUT"),
			_field(-120, -710, 350, 780, "low_canyon", -2, 0.65, false, false, "LOW CUT"),
			_field(1480, -1440, 760, 900, "high_rim", 2, 0.70, false, false, "RELAY ESCARPMENT")
		],
		[_node("ore", -2250, 760, 1160), _node("evidence", -1850, 1110, 730), _node("ore", -1360, -440, 1020), _node("evidence", -710, -160, 820), _node("ore", -450, 700, 1040), _node("evidence", 20, -390, 860), _node("ore", 470, 700, 1080), _node("evidence", 920, -600, 870), _node("ore", 1800, -970, 1010)],
		Rect2(-2460, 410, 760, 930), Rect2(1500, -1430, 760, 910)
	)

static func _shadow_terminal() -> Dictionary:
	return _profile(
		"Shadow Terminal", "terminal", Vector2(-2100, 860), Vector2(1980, -920),
		[
			_wall(-1470, -1410, 630, 220, "Terminal Block A"),
			_wall(-1470, -810, 630, 220, "Terminal Block B"),
			_wall(-1470, -210, 630, 220, "Terminal Block C"),
			_wall(-1470, 390, 630, 220, "Terminal Block D"),
			_wall(-450, -1210, 730, 220, "Terminal Block E"),
			_wall(-450, -560, 730, 220, "Terminal Block F"),
			_wall(-450, 90, 730, 220, "Terminal Block G"),
			_wall(680, -1420, 650, 220, "Terminal Block H"),
			_wall(680, -810, 650, 220, "Terminal Block I"),
			_wall(680, -200, 650, 220, "Terminal Block J"),
			_wall(1510, -1380, 630, 980, "Relay Customs Block")
		],
		[
			_field(-2440, 300, 930, 1050, "terminal_apron", 0, 0.95, true, false, "ARRIVAL APRON"),
			_field(-1580, -1510, 2950, 2800, "terminal_floor", 0, 0.90, true, false, "SHADOW TERMINAL"),
			_field(-270, -1480, 320, 1560, "concourse", 1, 0.86, true, false, "ELEVATED CONCOURSE"),
			_field(1430, -1440, 850, 980, "relay_platform", 1, 0.90, true, false, "CUSTOMS RELAY")
		],
		[_node("ore", -2110, 720, 1100), _node("evidence", -1850, 1120, 760), _node("ore", -1120, -450, 970), _node("evidence", -820, 800, 810), _node("ore", -120, -260, 1060), _node("evidence", 220, 770, 840), _node("ore", 560, -430, 990), _node("evidence", 1120, 700, 810), _node("ore", 1850, -1060, 980)],
		Rect2(-2440, 300, 930, 1050), Rect2(1430, -1440, 850, 980)
	)

static func _frostline_outpost() -> Dictionary:
	return _profile(
		"Frostline Outpost", "frost", Vector2(-2140, 860), Vector2(2000, -920),
		[
			_wall(-1330, -1310, 500, 140, "Frozen Crevasse North", "crater"),
			_wall(-920, -960, 150, 780, "Frozen Crevasse West", "crater"),
			_wall(-520, 470, 650, 150, "Frozen Crevasse South", "crater"),
			_wall(60, -900, 150, 980, "Ice Shelf Wall", "crater"),
			_wall(640, -1320, 620, 145, "Blue Ice Ridge", "crater"),
			_wall(920, -790, 150, 780, "Blue Ice Spine", "crater"),
			_wall(1450, -440, 600, 150, "Relay Drift", "crater")
		],
		[
			_field(-2460, 330, 930, 1000, "snowfield", 0, 0.82, true, false, "OUTPOST APPROACH"),
			_field(-1500, -1450, 2800, 1700, "ice_sheet", 0, 1.12, false, false, "SLIPPERY ICE"),
			_field(-710, -790, 650, 700, "deep_crevasse", -3, 0.0, false, true, "CREVASSE"),
			_field(160, -1040, 540, 1250, "snow_drift", -1, 0.67, false, false, "DEEP DRIFT"),
			_field(1440, -1420, 790, 930, "ice_shelf", 2, 0.76, false, false, "RELAY SHELF")
		],
		[_node("ore", -2160, 720, 1140), _node("evidence", -1800, 1100, 740), _node("ore", -1260, -530, 960), _node("evidence", -900, 720, 820), _node("ore", -270, 280, 1050), _node("evidence", 420, -340, 850), _node("ore", 760, 670, 1020), _node("evidence", 1180, -620, 790), _node("ore", 1870, -1040, 1000)],
		Rect2(-2460, 330, 930, 1000), Rect2(1440, -1420, 790, 930)
	)

static func _wreckage_fields() -> Dictionary:
	return _profile(
		"Wreckage Fields", "wreckage", Vector2(-2170, 890), Vector2(1990, -940),
		[
			_wall(-1430, -1240, 420, 160, "Broken Hull North"),
			_wall(-1100, -800, 180, 520, "Broken Hull West"),
			_wall(-900, 300, 690, 160, "Wreck Line South"),
			_wall(-430, -870, 230, 560, "Split Freighter"),
			_wall(130, 90, 650, 160, "Fallen Carrier"),
			_wall(450, -1270, 500, 160, "Orbital Debris Ridge"),
			_wall(840, -840, 180, 620, "Torn Hangar"),
			_wall(1320, -500, 610, 160, "Relay Wreck Wall"),
			_wall(1770, -1300, 170, 640, "Relay Hull")
		],
		[
			_field(-2470, 340, 920, 990, "scrap_yard", 0, 0.86, true, false, "SALVAGE APPROACH"),
			_field(-1510, -1480, 2960, 2750, "wreckage_ground", 0, 0.80, true, false, "WRECKAGE FIELDS"),
			_field(-860, -910, 740, 640, "hull_ridge", 2, 0.70, false, false, "HULL RIDGE"),
			_field(90, -1180, 1050, 970, "debris_basin", -1, 0.67, false, false, "DEBRIS BASIN"),
			_field(1390, -1440, 820, 930, "relay_platform", 1, 0.86, true, false, "RELAY WRECK")
		],
		[_node("ore", -2180, 730, 1200), _node("evidence", -1820, 1120, 780), _node("ore", -1330, -560, 1020), _node("evidence", -760, 700, 820), _node("ore", -320, 340, 1120), _node("evidence", 250, -500, 850), _node("ore", 690, 680, 1060), _node("evidence", 1090, -660, 820), _node("ore", 1840, -1070, 1040)],
		Rect2(-2470, 340, 920, 990), Rect2(1390, -1440, 820, 930)
	)
