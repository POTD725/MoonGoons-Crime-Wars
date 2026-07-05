extends "res://frontier_map_layer.gd"
## Composition-friendly campaign map routing.
## Custom Game keeps its chosen map. Campaign stages use authored battlefield identities.

const CAMPAIGN_MAPS: Dictionary = {
	"CW-001":"Nexus Prime",
	"CW-002":"Underhive Sector",
	"CW-003":"Black Crater"
}

func _selected_map_label() -> String:
	if MatchState != null and MatchState.is_ready():
		return super._selected_map_label()
	if GameProfile != null:
		for mission_id in ["CW-001", "CW-002", "CW-003"]:
			if not GameProfile.is_complete(mission_id):
				return str(CAMPAIGN_MAPS.get(mission_id, "Nexus Prime"))
	return "Black Crater"
