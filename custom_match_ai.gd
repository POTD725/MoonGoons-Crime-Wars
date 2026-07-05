extends Node
## Lightweight CPU pressure for Custom Games.
## It creates paced enemy waves from the hostile relay and scales with selected difficulty and bot count.

var active_scene_id: int = -1
var wave_clock: float = 0.0
var wave_index: int = 0
var aggression: float = 1.0
var bot_count: int = 1

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(delta: float) -> void:
	var scene: Node = get_tree().current_scene
	if scene == null or not scene.has_method("_spawn_unit") or not bool(scene.get_meta("custom_match", false)):
		active_scene_id = -1
		return
	if scene.get_instance_id() != active_scene_id:
		_start_for_scene(scene)
	if bool(scene.get("finished")) or bool(scene.get_meta("protected_prep", false)):
		return
	wave_clock -= delta
	if wave_clock > 0.0:
		return
	_spawn_wave(scene)
	var interval: float = maxf(18.0, 42.0 / aggression - float(wave_index) * 1.5)
	wave_clock = interval

func _start_for_scene(scene: Node) -> void:
	active_scene_id = scene.get_instance_id()
	wave_clock = 20.0
	wave_index = 0
	bot_count = maxi(1, int(MatchState.bots))
	match str(MatchState.level_id):
		"easy": aggression = 0.65
		"hard": aggression = 1.3
		"nightmare": aggression = 1.7
		_: aggression = 1.0
	scene.call("flash", "CPU NETWORK ONLINE // %d hostile command node(s) detected." % bot_count, 3.0)

func _spawn_wave(scene: Node) -> void:
	var relay: Dictionary = scene.call("_relay") as Dictionary
	if relay.is_empty():
		return
	var relay_position: Vector2 = relay.get("pos", Vector2.ZERO) as Vector2
	var count: int = mini(12, 2 + bot_count + wave_index)
	for index in range(count):
		var angle: float = TAU * float(index) / float(maxi(1, count))
		var offset: Vector2 = Vector2.from_angle(angle) * (125.0 + float(index % 3) * 24.0)
		var kind: String = "hacker" if (index + wave_index) % 4 == 3 else "raider"
		var unit: Dictionary = scene.call("_spawn_unit", kind, "syndicate", relay_position + offset) as Dictionary
		if not unit.is_empty():
			unit["order"] = "attack_move"
			var nexus: Dictionary = scene.call("_home_nexus") as Dictionary
			if not nexus.is_empty():
				unit["target"] = nexus.get("pos", Vector2.ZERO) as Vector2
	wave_index = mini(wave_index + 1, 6)
	scene.call("flash", "SYNDICATE WAVE %d // %d hostile contacts deployed." % [wave_index, count], 2.0)
