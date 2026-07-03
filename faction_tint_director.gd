extends Node
## Applies faction identity colors to the live RTS entities after deployment.

var applied_scene_id: int = -1
var applied_signature: String = ""

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(_delta: float) -> void:
	var scene: Node = get_tree().current_scene
	if scene == null or not scene.has_method("_entity"):
		return
	if RaceMode == null or RaceMode.root != scene:
		return
	var friendly_race: String = RaceMode.chosen_race
	var enemy_race: String = RaceMode.chosen_rival
	if friendly_race.is_empty() or enemy_race.is_empty():
		return
	var signature: String = str(scene.get_instance_id()) + ":" + friendly_race + ":" + enemy_race
	if scene.get_instance_id() == applied_scene_id and signature == applied_signature:
		return
	applied_scene_id = scene.get_instance_id()
	applied_signature = signature
	_apply(scene, friendly_race, enemy_race)

func _apply(scene: Node, friendly_race: String, enemy_race: String) -> void:
	var friendly_color: Color = Color(str(RaceCatalog.RACES[friendly_race].get("accent", "#8fe9ff")))
	var enemy_color: Color = Color(str(RaceCatalog.RACES[enemy_race].get("accent", "#ff7199")))
	for unit: Dictionary in scene.get("units"):
		var color: Color = friendly_color if str(unit.get("team", "")) == "authority" else enemy_color
		unit["accent"] = _unit_color(color, str(unit.get("kind", "")), str(unit.get("team", "")))
	for building: Dictionary in scene.get("buildings"):
		var color: Color = friendly_color if str(building.get("team", "")) == "authority" else enemy_color
		building["accent"] = color

func _unit_color(base_color: Color, kind: String, team: String) -> Color:
	if kind == "hero":
		return Color("ffd270") if team == "authority" else base_color.lightened(0.25)
	if kind == "shield":
		return base_color.lightened(0.16)
	if kind == "hacker":
		return base_color.lightened(0.25)
	return base_color
