extends Node
## Fallback art service. Keeps the game playable on installations that have not imported SVG support yet.

var MOONGOONS_LOGO: Texture2D = null
var STATION_HOLOGRAM: Texture2D = null
var OPS_CENTER: Texture2D = null
var DETENTION_BLOCK: Texture2D = null
var CHIEF_OFFICE: Texture2D = null
var RESEARCH_LAB: Texture2D = null
var ARMORY: Texture2D = null
var DARKSIDE_MOON_SIGIL: Texture2D = null

func structure_texture(_entity: Dictionary) -> Texture2D:
	return null

func faction_badge(_race_id: String) -> Texture2D:
	return null

func has_structure_art(_entity: Dictionary) -> bool:
	return false
