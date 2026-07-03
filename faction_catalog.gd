extends Node

const DATA: Dictionary = {
	"authority": {"label":"MOONGOONS AUTHORITY", "accent":"#8fe9ff", "hero":"Chief Nova", "rival":"lunar_cartel", "construction":"Builder Drones assemble standardized precinct modules.", "passive":{"supplies":2}},
	"lunar_cartel": {"label":"LUNAR CARTEL", "accent":"#ff79c6", "hero":"Vexa Null", "rival":"authority", "construction":"Contraband Riggers deploy lightweight hideout modules in a hurry.", "passive":{"credits":8,"intel":1}},
	"null_choir": {"label":"NULL CHOIR", "accent":"#72f2bd", "hero":"Nyx Relay", "rival":"hollow_fang", "construction":"Signal Seeds grow structures from captured data.", "passive":{"intel":4}},
	"hollow_fang": {"label":"HOLLOW FANG CLAN", "accent":"#ff9b62", "hero":"Nash Vanta", "rival":"null_choir", "construction":"Scrapwrights weld durable war-camp structures quickly from salvage.", "passive":{"supplies":5,"credits":3}}
}

func get_rival(race_id: String) -> String:
	var entry: Dictionary = DATA.get(race_id, DATA["authority"])
	return str(entry.get("rival", "lunar_cartel"))

func label_for(race_id: String) -> String:
	var entry: Dictionary = DATA.get(race_id, DATA["authority"])
	return str(entry.get("label", "MOONGOONS AUTHORITY"))

func get_construction(race_id: String) -> String:
	var entry: Dictionary = DATA.get(race_id, DATA["authority"])
	return str(entry.get("construction", "Builder Drones assemble standardized precinct modules."))

func get_passive(race_id: String) -> Dictionary:
	var entry: Dictionary = DATA.get(race_id, DATA["authority"])
	return entry.get("passive", {}) as Dictionary
