extends Node
## Fifteen PvP battlefield layouts for MoonGoons: Crime Wars.
## Coordinates fit the current RTS world rectangle: -1150..1350 x -760..740.

var active_map_id := "breakwater_split"

const MAPS := {
	"breakwater_split": {
		"name":"Breakwater Split","players":"1v1","terrain":"Lunar dockyard","pace":"Balanced","resources":"Medium","feature":"A central cargo trench separates two equal approach lanes.",
		"spawns":[Vector2(-780,180),Vector2(780,-180)],
		"nodes":[["ore",Vector2(-560,250),900],["ore",Vector2(540,-250),900],["ore",Vector2(-130,210),680],["ore",Vector2(130,-210),680],["evidence",Vector2(0,0),520]],
		"zones":[["dock",Rect2(-180,-120,360,240)],["crater",Rect2(-700,-520,260,200)],["crater",Rect2(440,320,260,200)]]
	},
	"glass_canyon": {
		"name":"Glass Canyon","players":"1v1","terrain":"Crystal ravine","pace":"Rush","resources":"Low","feature":"Two narrow crystal passes reward early pressure and scouting.",
		"spawns":[Vector2(-840,-180),Vector2(840,180)],
		"nodes":[["ore",Vector2(-610,-250),700],["ore",Vector2(610,250),700],["ore",Vector2(-70,-270),480],["ore",Vector2(70,270),480],["evidence",Vector2(0,0),420]],
		"zones":[["crystal",Rect2(-130,-720,260,1440)],["canyon",Rect2(-400,-110,800,220)]]
	},
	"red_dust_basin": {
		"name":"Red Dust Basin","players":"1v1","terrain":"Iron regolith basin","pace":"Macro","resources":"High","feature":"Open lanes and rich ore fields make flanking and expansion vital.",
		"spawns":[Vector2(-850,0),Vector2(850,0)],
		"nodes":[["ore",Vector2(-610,210),1200],["ore",Vector2(-610,-210),1200],["ore",Vector2(610,210),1200],["ore",Vector2(610,-210),1200],["ore",Vector2(0,0),1050],["evidence",Vector2(-180,0),460],["evidence",Vector2(180,0),460]],
		"zones":[["dust",Rect2(-1100,-700,2200,1400)],["basin",Rect2(-240,-220,480,440)]]
	},
	"void_rail": {
		"name":"Void Rail","players":"1v1","terrain":"Orbital freight line","pace":"Tactical","resources":"Medium","feature":"A broken mag-rail creates three bridges, with the middle bridge richest and most dangerous.",
		"spawns":[Vector2(-860,320),Vector2(860,-320)],
		"nodes":[["ore",Vector2(-680,230),850],["ore",Vector2(680,-230),850],["ore",Vector2(-150,320),600],["ore",Vector2(150,-320),600],["evidence",Vector2(0,0),700]],
		"zones":[["rail",Rect2(-1200,-70,2400,140)],["void",Rect2(-420,-620,840,1240)]]
	},
	"frozen_sirens": {
		"name":"Frozen Sirens","players":"1v1","terrain":"Cryo relay field","pace":"Defensive","resources":"Medium","feature":"Frozen relay towers form sight blockers around a central research cache.",
		"spawns":[Vector2(-760,-300),Vector2(760,300)],
		"nodes":[["ore",Vector2(-560,-360),820],["ore",Vector2(560,360),820],["ore",Vector2(-280,140),650],["ore",Vector2(280,-140),650],["evidence",Vector2(0,0),860]],
		"zones":[["ice",Rect2(-1100,-700,2200,1400)],["relay",Rect2(-180,-180,360,360)]]
	},
	"ember_furnace": {
		"name":"Ember Furnace","players":"1v1","terrain":"Volcanic mining scar","pace":"Brawl","resources":"High","feature":"Hot extraction vents cluster in the center, forcing close-range fights for fast income.",
		"spawns":[Vector2(-820,210),Vector2(820,-210)],
		"nodes":[["ore",Vector2(-620,260),900],["ore",Vector2(620,-260),900],["ore",Vector2(-120,170),900],["ore",Vector2(120,-170),900],["evidence",Vector2(0,0),600]],
		"zones":[["lava",Rect2(-230,-110,460,220)],["ash",Rect2(-1100,-700,2200,1400)]]
	},
	"mirrormoon": {
		"name":"Mirror Moon","players":"1v1","terrain":"Reflective salt flats","pace":"Recon","resources":"Medium","feature":"Symmetrical terrain gives clean early scouting but hidden evidence caches tempt detours.",
		"spawns":[Vector2(-850,-250),Vector2(850,250)],
		"nodes":[["ore",Vector2(-650,-240),780],["ore",Vector2(650,240),780],["ore",Vector2(-240,-80),620],["ore",Vector2(240,80),620],["evidence",Vector2(-20,300),500],["evidence",Vector2(20,-300),500]],
		"zones":[["salt",Rect2(-1100,-700,2200,1400)],["mirror",Rect2(-260,-150,520,300)]]
	},
	"prisoner_exchange": {
		"name":"Prisoner Exchange","players":"2v2","terrain":"Transfer yard","pace":"Objective","resources":"Medium","feature":"Four bases orbit a neutral holding-yard that contains the richest Intel cache.",
		"spawns":[Vector2(-850,360),Vector2(850,-360),Vector2(-850,-360),Vector2(850,360)],
		"nodes":[["ore",Vector2(-680,360),760],["ore",Vector2(-680,-360),760],["ore",Vector2(680,360),760],["ore",Vector2(680,-360),760],["ore",Vector2(0,250),700],["ore",Vector2(0,-250),700],["evidence",Vector2(0,0),1050]],
		"zones":[["yard",Rect2(-250,-180,500,360)],["cells",Rect2(-90,-100,180,200)]]
	},
	"black_archive": {
		"name":"Black Archive","players":"2v2","terrain":"Buried data vault","pace":"Tactical","resources":"Low","feature":"Few deposits, many corridors, and high-value archive terminals reward coordinated ambushes.",
		"spawns":[Vector2(-820,380),Vector2(820,-380),Vector2(-820,-380),Vector2(820,380)],
		"nodes":[["ore",Vector2(-620,360),620],["ore",Vector2(-620,-360),620],["ore",Vector2(620,360),620],["ore",Vector2(620,-360),620],["evidence",Vector2(-120,0),760],["evidence",Vector2(120,0),760]],
		"zones":[["archive",Rect2(-300,-300,600,600)],["corridor",Rect2(-1100,-75,2200,150)]]
	},
	"neon_collapse": {
		"name":"Neon Collapse","players":"2v2","terrain":"Cartel megablock","pace":"Rush","resources":"Medium","feature":"Dense alleys lead to rooftop shortcuts and a central smuggler vault.",
		"spawns":[Vector2(-880,300),Vector2(880,-300),Vector2(-880,-300),Vector2(880,300)],
		"nodes":[["ore",Vector2(-650,280),780],["ore",Vector2(-650,-280),780],["ore",Vector2(650,280),780],["ore",Vector2(650,-280),780],["evidence",Vector2(0,0),900]],
		"zones":[["neon",Rect2(-500,-420,1000,840)],["alley",Rect2(-1100,-130,2200,260)]]
	},
	"orbit_of_teeth": {
		"name":"Orbit of Teeth","players":"2v2","terrain":"Debris ring","pace":"Flank","resources":"High","feature":"Asteroid teeth create rotating combat pockets around two exposed expansion fields.",
		"spawns":[Vector2(-860,300),Vector2(860,-300),Vector2(-860,-300),Vector2(860,300)],
		"nodes":[["ore",Vector2(-650,270),900],["ore",Vector2(-650,-270),900],["ore",Vector2(650,270),900],["ore",Vector2(650,-270),900],["ore",Vector2(0,360),950],["ore",Vector2(0,-360),950],["evidence",Vector2(0,0),540]],
		"zones":[["debris",Rect2(-520,-520,1040,1040)],["void",Rect2(-160,-160,320,320)]]
	},
	"choir_of_static": {
		"name":"Choir of Static","players":"2v2","terrain":"Signal storm","pace":"Recon","resources":"Medium","feature":"Signal storms cloak routes around a central Null Choir spire.",
		"spawns":[Vector2(-900,200),Vector2(900,-200),Vector2(-650,-450),Vector2(650,450)],
		"nodes":[["ore",Vector2(-650,220),760],["ore",Vector2(650,-220),760],["ore",Vector2(-380,-390),680],["ore",Vector2(380,390),680],["evidence",Vector2(0,0),980]],
		"zones":[["signal",Rect2(-330,-330,660,660)],["storm",Rect2(-1100,-700,2200,1400)]]
	},
	"sunspear_pass": {
		"name":"Sunspear Pass","players":"3v3","terrain":"Solar ridge","pace":"Macro","resources":"High","feature":"Three lanes meet at a sunlit ridge where control creates the best expansion routes.",
		"spawns":[Vector2(-920,420),Vector2(-920,0),Vector2(-920,-420),Vector2(920,-420),Vector2(920,0),Vector2(920,420)],
		"nodes":[["ore",Vector2(-700,400),780],["ore",Vector2(-700,0),780],["ore",Vector2(-700,-400),780],["ore",Vector2(700,400),780],["ore",Vector2(700,0),780],["ore",Vector2(700,-400),780],["ore",Vector2(0,240),920],["ore",Vector2(0,-240),920],["evidence",Vector2(0,0),760]],
		"zones":[["ridge",Rect2(-150,-600,300,1200)],["solar",Rect2(-1100,-700,2200,1400)]]
	},
	"graveyard_of_kings": {
		"name":"Graveyard of Kings","players":"3v3","terrain":"Warship cemetery","pace":"Defensive","resources":"Medium","feature":"Wreck hulls form natural fort lines, while the center holds a salvaged royal engine.",
		"spawns":[Vector2(-930,400),Vector2(-930,0),Vector2(-930,-400),Vector2(930,-400),Vector2(930,0),Vector2(930,400)],
		"nodes":[["ore",Vector2(-720,380),720],["ore",Vector2(-720,0),720],["ore",Vector2(-720,-380),720],["ore",Vector2(720,380),720],["ore",Vector2(720,0),720],["ore",Vector2(720,-380),720],["evidence",Vector2(0,0),1180]],
		"zones":[["wreck",Rect2(-450,-480,900,960)],["engine",Rect2(-110,-110,220,220)]]
	},
	"second_siren": {
		"name":"Second Siren","players":"4v4","terrain":"Selene under-city","pace":"Epic","resources":"Very High","feature":"Eight approach roads, large resource pools, and a central fracture alarm for long-form team battles.",
		"spawns":[Vector2(-940,450),Vector2(-940,150),Vector2(-940,-150),Vector2(-940,-450),Vector2(940,-450),Vector2(940,-150),Vector2(940,150),Vector2(940,450)],
		"nodes":[["ore",Vector2(-730,430),860],["ore",Vector2(-730,140),860],["ore",Vector2(-730,-140),860],["ore",Vector2(-730,-430),860],["ore",Vector2(730,430),860],["ore",Vector2(730,140),860],["ore",Vector2(730,-140),860],["ore",Vector2(730,-430),860],["ore",Vector2(0,310),1050],["ore",Vector2(0,-310),1050],["evidence",Vector2(0,0),1400]],
		"zones":[["undercity",Rect2(-500,-600,1000,1200)],["fracture",Rect2(-160,-160,320,320)]]
	}
}

func get_active() -> Dictionary:
	return MAPS.get(active_map_id, MAPS["breakwater_split"])

func choose(map_id: String) -> void:
	if MAPS.has(map_id):
		active_map_id = map_id

func get_map(map_id: String) -> Dictionary:
	return MAPS.get(map_id, MAPS["breakwater_split"])

func get_node_data(map_id: String) -> Array:
	return get_map(map_id).get("nodes", [])

func get_spawns(map_id: String) -> Array:
	return get_map(map_id).get("spawns", [])
