extends Node

const RACES := {
	"authority": {"name":"MOONGOONS AUTHORITY", "accent":"#8fe9ff", "hero":"Chief Nova", "rival":"lunar_cartel"},
	"lunar_cartel": {"name":"LUNAR CARTEL", "accent":"#ff79c6", "hero":"Vexa Null", "rival":"authority"},
	"null_choir": {"name":"NULL CHOIR", "accent":"#72f2bd", "hero":"Nyx Relay", "rival":"hollow_fang"},
	"hollow_fang": {"name":"HOLLOW FANG CLAN", "accent":"#ff9b62", "hero":"Nash Vanta", "rival":"null_choir"}
}

func get_rival(race_id: String) -> String:
	return str(RACES.get(race_id, RACES["authority"]).get("rival", "lunar_cartel"))
