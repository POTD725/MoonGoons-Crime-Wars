extends Node

const PLAYER_TEAM := "authority"
const ENEMY_TEAM := "syndicate"

var root: Node
var root_id := -1
var chosen_race := ""
var chosen_rival := ""
var picker: Control
var status_label: Label
var passive_clock := 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_picker()
