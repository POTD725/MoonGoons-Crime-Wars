extends "res://lunar_presentation_layer.gd"
## Production pacing and resource visibility.
## Every queued unit launches at least ten seconds after the prior unit from the same producer.

const SPAWN_INTERVAL_SECONDS: float = 10.0
const MAX_QUEUE_PER_PRODUCER: int = 8

var production_queues: Dictionary = {}
var enemy_reinforcement_queue: Array[Dictionary] = []
var enemy_reinforcement_timer: float = 0.0

func _process(delta: float) -> void:
	super._process(delta)
	if finished:
		return
	_update_production_queues(delta)
	_update_enemy_reinforcement_queue(delta)

func _train(kind: String) -> void:
	if not unit_specs.has(kind):
		return
	var producer: Dictionary = _selected_producer(kind)
	if producer.is_empty():
		flash("Select the correct completed production building before queuing this unit.", 2.5)
		_sound("error")
		return
	var spec: Dictionary = unit_specs[kind] as Dictionary
	var cost: int = int(spec.get("cost", 0))
	if credits < cost:
		flash("Insufficient Credits.", 2.0)
		_sound("error")
		return
	var producer_id: int = int(producer.get("id", -1))
	var queue: Array = production_queues.get(producer_id, []) as Array
	if queue.size() >= MAX_QUEUE_PER_PRODUCER:
		flash(str(producer.get("name", "Producer")) + " queue is full // maximum %d units." % MAX_QUEUE_PER_PRODUCER, 2.2)
		_sound("error")
		return
	credits -= cost
	var production_time: float = maxf(SPAWN_INTERVAL_SECONDS, float(spec.get("time", 0.0)))
	queue.append({
		"kind":kind,
		"name":str(spec.get("name", kind)),
		"elapsed":0.0,
		"duration":production_time,
		"cost":cost
	})
	production_queues[producer_id] = queue
	var queue_count: int = queue.size()
	flash(str(spec.get("name", "Unit")) + " queued // %d item(s) waiting. Deployments launch 10 seconds apart." % queue_count, 2.6)
	_sound("build")

func _update_production_queues(delta: float) -> void:
	var invalid_producers: Array[int] = []
	for producer_key in production_queues.keys():
		var producer_id: int = int(producer_key)
		var producer: Dictionary = _entity(producer_id)
		var queue: Array = production_queues.get(producer_id, []) as Array
		if producer.is_empty() or not bool(producer.get("done", false)):
			invalid_producers.append(producer_id)
			continue
		if queue.is_empty():
			invalid_producers.append(producer_id)
			continue
		var active_entry: Dictionary = queue[0] as Dictionary
		active_entry["elapsed"] = float(active_entry.get("elapsed", 0.0)) + delta
		queue[0] = active_entry
		if float(active_entry.get("elapsed", 0.0)) < float(active_entry.get("duration", SPAWN_INTERVAL_SECONDS)):
			production_queues[producer_id] = queue
			continue
		_launch_queued_unit(producer, active_entry, queue.size() - 1)
		queue.remove_at(0)
		if queue.is_empty():
			invalid_producers.append(producer_id)
		else:
			production_queues[producer_id] = queue
	for producer_id in invalid_producers:
		production_queues.erase(producer_id)

func _launch_queued_unit(producer: Dictionary, entry: Dictionary, remaining_after_launch: int) -> void:
	var launch_index: int = int(mission_clock * 10.0) % 6
	var angle: float = -0.35 + float(launch_index) * 0.48
	var producer_position: Vector2 = producer.get("pos", Vector2.ZERO) as Vector2
	var spawn_position: Vector2 = producer_position + Vector2.from_angle(angle) * 112.0
	var unit: Dictionary = _spawn_unit(str(entry.get("kind", "deputy")), AUTHORITY, spawn_position)
	var fallback_rally: Vector2 = producer_position + Vector2(170.0, 68.0)
	unit["rally_target"] = producer.get("rally_point", fallback_rally) as Vector2
	unit["rally_pending"] = true
	unit["action_state"] = "deploying"
	unit["arrival_flash"] = 0.65
	_spawn_effect("construct", spawn_position, _unit_color(unit), 0.62)
	flash(str(entry.get("name", "Unit")) + " deployed // %d item(s) remain in this queue." % remaining_after_launch, 2.0)
	_sound("complete")

func _spawn_enemy_wave() -> void:
	var relay: Dictionary = _relay()
	if relay.is_empty() or finished:
		return
	var count: int = 3
	if GameDifficulty.active_id == "hard":
		count = 4
	elif GameDifficulty.active_id == "nightmare":
		count = 5
	var relay_position: Vector2 = relay.get("pos", Vector2.ZERO) as Vector2
	for index in range(count):
		var angle: float = float(index) * TAU / float(maxi(1, count))
		var offset: Vector2 = Vector2.from_angle(angle) * 135.0
		var kind: String = "hacker" if index % 3 == 2 else "raider"
		enemy_reinforcement_queue.append({"kind":kind, "pos":relay_position + offset})
	flash("Syndicate response queued // %d hostile contacts deploy 10 seconds apart." % enemy_reinforcement_queue.size(), 3.2)
	_sound("alert")

func _update_enemy_reinforcement_queue(delta: float) -> void:
	if enemy_reinforcement_queue.is_empty():
		return
	enemy_reinforcement_timer -= delta
	if enemy_reinforcement_timer > 0.0:
		return
	var entry: Dictionary = enemy_reinforcement_queue[0] as Dictionary
	enemy_reinforcement_queue.remove_at(0)
	var enemy_position: Vector2 = entry.get("pos", Vector2.ZERO) as Vector2
	_spawn_unit(str(entry.get("kind", "raider")), SYNDICATE, enemy_position)
	enemy_reinforcement_timer = SPAWN_INTERVAL_SECONDS
	flash("Syndicate contact deployed // %d hostile contact(s) still queued." % enemy_reinforcement_queue.size(), 1.8)

func _get_production_queue_status(producer_id: int) -> Dictionary:
	var queue: Array = production_queues.get(producer_id, []) as Array
	if queue.is_empty():
		return {"count":0, "name":"", "remaining":0.0, "duration":0.0}
	var active_entry: Dictionary = queue[0] as Dictionary
	var duration: float = float(active_entry.get("duration", SPAWN_INTERVAL_SECONDS))
	var remaining: float = maxf(0.0, duration - float(active_entry.get("elapsed", 0.0)))
	return {"count":queue.size(), "name":str(active_entry.get("name", "Unit")), "remaining":remaining, "duration":duration}

func _get_total_pending_spawns() -> int:
	var total: int = enemy_reinforcement_queue.size()
	for producer_key in production_queues.keys():
		var queue: Array = production_queues.get(producer_key, []) as Array
		total += queue.size()
	return total

func _get_total_resource_amount(kind: String) -> int:
	var total: int = 0
	for resource: Dictionary in nodes:
		if str(resource.get("type", "")) == kind:
			total += int(resource.get("amount", 0))
	return total

func _draw_resources() -> void:
	super._draw_resources()
	for resource: Dictionary in nodes:
		var amount: int = int(resource.get("amount", 0))
		if amount <= 0:
			continue
		var maximum: int = maxi(1, int(resource.get("max", amount)))
		var position: Vector2 = resource.get("pos", Vector2.ZERO) as Vector2
		var resource_type: String = str(resource.get("type", "ore"))
		var label: String = "ORE %d/%d" % [amount, maximum] if resource_type == "ore" else "INTEL %d/%d" % [amount, maximum]
		var label_color: Color = Color("65eaff") if resource_type == "ore" else Color("ffca69")
		draw_string(font, position + Vector2(-55.0, 76.0), label, HORIZONTAL_ALIGNMENT_CENTER, 110.0, 12, label_color)
