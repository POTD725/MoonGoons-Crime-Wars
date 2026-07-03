extends Node
## Shared, imported MoonGoons and Dark Side art for Crime Wars UI.

const MOONGOONS_LOGO: Texture2D = preload("res://assets/graphics/moongoons_logo.svg")
const STATION_HOLOGRAM: Texture2D = preload("res://assets/graphics/station_hologram.svg")
const OPS_CENTER: Texture2D = preload("res://assets/graphics/ops_center.svg")
const DETENTION_BLOCK: Texture2D = preload("res://assets/graphics/detention_block.svg")
const CHIEF_OFFICE: Texture2D = preload("res://assets/graphics/chief_office.svg")
const RESEARCH_LAB: Texture2D = preload("res://assets/graphics/research_lab.svg")
const ARMORY: Texture2D = preload("res://assets/graphics/armory.svg")
const DARKSIDE_MOON_SIGIL: Texture2D = preload("res://assets/graphics/darkside_moon_sigil.svg")

func structure_texture(entity: Dictionary) -> Texture2D:
	if entity.is_empty():
		return STATION_HOLOGRAM
	match str(entity.get("kind", "")):
		"nexus": return OPS_CENTER
		"syndicate_relay": return DARKSIDE_MOON_SIGIL
		"armory": return ARMORY
		"cells": return DETENTION_BLOCK
		"relay", "research_lab": return RESEARCH_LAB
		"medbay", "chief_office": return CHIEF_OFFICE
		_: return STATION_HOLOGRAM

func faction_badge(race_id: String) -> Texture2D:
	if race_id == "lunar_cartel":
		return DARKSIDE_MOON_SIGIL
	return MOONGOONS_LOGO

func has_structure_art(entity: Dictionary) -> bool:
	return not entity.is_empty() and entity.has("size")
