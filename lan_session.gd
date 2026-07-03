extends Node
## Shared local-network session state for the Crime Wars LAN lobby and co-op recon map.

var display_name := "Commander"
var port := 24571
var is_host := false
var roster: Dictionary = {}

func reset() -> void:
	display_name = "Commander"
	port = 24571
	is_host = false
	roster.clear()
