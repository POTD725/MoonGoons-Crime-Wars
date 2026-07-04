extends Node
## The three major forces of MoonGoons: Crime Wars.
## Internal ids preserve the existing game wiring while the player-facing factions follow the design canon.

const DATA: Dictionary = {
	"authority": {
		"name":"LUNAR PEACEKEEPERS", "label":"LUNAR PEACEKEEPERS", "accent":"#8fe9ff", "hero":"Chief Nova", "rival":"lunar_cartel",
		"subtitle":"Order under lunar pressure", "style":"SECURITY PRECINCT // disciplined squads, defense grids, investigations, and orbital response.",
		"construction":"Builder Drones assemble standardized precinct modules and establish security zones.", "passive":{"supplies":2, "command":2}
	},
	"lunar_cartel": {
		"name":"THE SYNDICATE", "label":"THE SYNDICATE", "accent":"#ff79c6", "hero":"Vexa Null", "rival":"authority",
		"subtitle":"The law is a decorative suggestion", "style":"HIDDEN NETWORK // raids, sabotage, black-market logistics, hacked defenses, and ambush routes.",
		"construction":"Contraband Riggers deploy hideouts through illicit supply channels and underground routes.", "passive":{"credits":8, "intel":1}
	},
	"null_choir": {
		"name":"THE NULLBORN", "label":"THE NULLBORN", "accent":"#72f2bd", "hero":"Nyx Relay", "rival":"authority",
		"subtitle":"The Moon remembers its experiments", "style":"CORRUPTED NETWORK // infected territory, unstable energy, mutations, and broken-machine evolution.",
		"construction":"Nullborn growths consume abandoned infrastructure and corrupted power systems.", "passive":{"intel":4, "alloy":1}
	}
}
const RACES: Dictionary = DATA

func get_rival(race_id: String) -> String:
	var entry: Dictionary = DATA.get(race_id, DATA["authority"])
	return str(entry.get("rival", "lunar_cartel"))

func label_for(race_id: String) -> String:
	var entry: Dictionary = DATA.get(race_id, DATA["authority"])
	return str(entry.get("label", "LUNAR PEACEKEEPERS"))

func get_construction(race_id: String) -> String:
	var entry: Dictionary = DATA.get(race_id, DATA["authority"])
	return str(entry.get("construction", "Builder Drones assemble standardized precinct modules."))

func get_passive(race_id: String) -> Dictionary:
	var entry: Dictionary = DATA.get(race_id, DATA["authority"])
	return entry.get("passive", {}) as Dictionary
