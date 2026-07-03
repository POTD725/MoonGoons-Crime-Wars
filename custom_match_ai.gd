extends Node
## Lightweight computer-player director for custom local skirmishes.
## CPU bases reinforce periodically and CPU units receive attack orders.

var root: Node
var active := false
var production_clock := 0.0
var command_clock := 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func begin_match(new_root: Node) -> void:
	root = new_root
	active = true
	production_clock = 0.0
	command_clock = 0.0

func _process(delta: float) -> void:
	if not active or root == null or not is_instance_valid(root):
		return
	if not bool(root.get_meta("custom_match", false)) or bool(root.get("finished")):
		return
	production_clock += delta
	command_clock += delta
	if command_clock >= 1.1:
		command_clock = 0.0
		_assign_cpu_orders()
	if production_clock >= _production_interval():
		production_clock = 0.0
		_reinforce_cpu_bases()

func _production_interval() -> float:
	# Easy has breathing room; Nightmare builds armies at a brisk lunar gallop.
	return 10.0 * GameDifficulty.multiplier("ai_interval", 1.0)

func _assign_cpu_orders() -> void:
	for unit in root.get("units"):
		if not bool(unit.get("cpu", false)) or not bool(unit.get("ready", true)):
			continue
		var target := _nearest_enemy(unit)
		if target.is_empty():
			continue
		unit["order"] = "attack"
		unit["target_id"] = int(target["id"])

func _reinforce_cpu_bases() -> void:
	var slots: Array = root.get_meta("custom_slots", [])
	for base in root.get("buildings"):
		if not bool(base.get("cpu", false)) or float(base.get("hp", 0.0)) <= 0.0:
			continue
		var slot_id := int(base.get("slot_id", -1))
		if slot_id < 0 or slot_id >= slots.size():
			continue
		var slot: Dictionary = slots[slot_id]
		if str(slot.get("controller", "closed")) != "cpu":
			continue
		var kind := "shield" if randf() < _shield_chance() else "deputy"
		var offset := Vector2(randf_range(-110.0, 110.0), randf_range(-100.0, 100.0))
		var unit := CustomMatchRuntime.spawn_reinforcement(root, slot, base["pos"] + offset, kind)
		_apply_cpu_scaling(unit)

func _shield_chance() -> float:
	match GameDifficulty.active_id:
		"easy": return 0.18
		"hard": return 0.45
		"nightmare": return 0.62
		_: return 0.30

func _apply_cpu_scaling(unit: Dictionary) -> void:
	var health_multiplier := GameDifficulty.multiplier("ai_health")
	var damage_multiplier := GameDifficulty.multiplier("ai_damage")
	unit["hp"] = float(unit["hp"]) * health_multiplier
	unit["max"] = float(unit["max"]) * health_multiplier
	unit["damage"] = max(1, int(round(float(unit["damage"]) * damage_multiplier)))

func _nearest_enemy(unit: Dictionary) -> Dictionary:
	var nearest := {}
	var best_distance := INF
	for candidate in root.get("units"):
		if candidate.get("team", "") == unit.get("team", ""):
			continue
		var distance := unit["pos"].distance_to(candidate["pos"])
		if distance < best_distance:
			nearest = candidate
			best_distance = distance
	for candidate in root.get("buildings"):
		if candidate.get("team", "") == unit.get("team", ""):
			continue
		var distance := unit["pos"].distance_to(candidate["pos"])
		if distance < best_distance:
			nearest = candidate
			best_distance = distance
	return nearest
