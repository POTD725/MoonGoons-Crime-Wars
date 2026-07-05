extends Node
## Objective manager for Custom Game scenarios.
## It activates only for scenes explicitly marked as custom matches.

const RELAY_HOLD_SECONDS: float = 180.0
const RESOURCE_RUSH_CREDITS: int = 2000

var active_scene_id: int = -1
var scenario: String = "Standard Skirmish"
var match_timer: float = 0.0
var relay_hold_timer: float = 0.0
var initial_unit_count: int = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(delta: float) -> void:
	var scene: Node = get_tree().current_scene
	if scene == null or not scene.has_method("_entity") or not bool(scene.get_meta("custom_match", false)):
		active_scene_id = -1
		return
	if scene.get_instance_id() != active_scene_id:
		_start_for_scene(scene)
	if bool(scene.get("finished")):
		return
	match_timer += delta
	match scenario:
		"Resource Rush":
			if int(scene.get("credits")) >= RESOURCE_RUSH_CREDITS:
				_finish(scene, true, "RESOURCE RUSH COMPLETE // 2000 Credits secured.")
		"King of the Relay":
			_update_relay_hold(scene, delta)
		"Sudden Death":
			if _count_player_units(scene) < initial_unit_count:
				_finish(scene, false, "SUDDEN DEATH // A Peacekeeper unit was lost.")
		_:
			var relay: Dictionary = scene.call("_relay") as Dictionary
			if relay.is_empty():
				_finish(scene, true, "STANDARD SKIRMISH COMPLETE // Hostile relay destroyed.")

func _start_for_scene(scene: Node) -> void:
	active_scene_id = scene.get_instance_id()
	scenario = str(MatchState.selected_mode)
	match_timer = 0.0
	relay_hold_timer = 0.0
	initial_unit_count = _count_player_units(scene)
	scene.call("flash", "CUSTOM SCENARIO // " + scenario, 3.5)

func _update_relay_hold(scene: Node, delta: float) -> void:
	var relay: Dictionary = scene.call("_relay") as Dictionary
	if relay.is_empty():
		_finish(scene, true, "KING OF THE RELAY COMPLETE // The hostile relay was dismantled.")
		return
	var relay_position: Vector2 = relay.get("pos", Vector2.ZERO) as Vector2
	var peacekeepers: int = 0
	var syndicate: int = 0
	for unit: Dictionary in scene.get("units") as Array:
		if not bool(unit.get("ready", true)):
			continue
		if (unit.get("pos", Vector2.ZERO) as Vector2).distance_to(relay_position) > 180.0:
			continue
		if str(unit.get("team", "")) == "authority":
			peacekeepers += 1
		elif str(unit.get("team", "")) == "syndicate":
			syndicate += 1
	if peacekeepers > 0 and syndicate == 0:
		relay_hold_timer += delta
	else:
		relay_hold_timer = maxf(0.0, relay_hold_timer - delta * 0.5)
	if relay_hold_timer >= RELAY_HOLD_SECONDS:
		_finish(scene, true, "KING OF THE RELAY COMPLETE // Relay district held for 3 minutes.")

func _finish(scene: Node, won: bool, message: String) -> void:
	if bool(scene.get("finished")):
		return
	scene.set("finished", true)
	scene.set("victory", won)
	scene.call("flash", message, 999.0)
	if RtsAudio != null:
		RtsAudio.call("play_cue", "victory" if won else "defeat")

func _count_player_units(scene: Node) -> int:
	var count: int = 0
	for unit: Dictionary in scene.get("units") as Array:
		if str(unit.get("team", "")) == "authority" and bool(unit.get("ready", true)):
			count += 1
	return count
