extends "res://custom_game.gd"
## Replaces legacy CPU labels with the universal Easy / Standard / Hard / Nightmare scale.

func _ready() -> void:
	super._ready()
	difficulty_menu.clear()
	for level_id in GameDifficulty.all_ids():
		difficulty_menu.add_item(GameDifficulty.LEVELS[level_id]["name"])
	var selected_index := GameDifficulty.all_ids().find(GameDifficulty.active_id)
	difficulty_menu.select(maxi(0, selected_index))
	difficulty_menu.item_selected.connect(func(_index: int): _refresh_summary())

func _launch() -> void:
	var slots: Array[Dictionary] = []
	var human_count := 0
	for slot in slot_controls:
		var controller: OptionButton = slot["controller"]
		var race: OptionButton = slot["race"]
		var controller_id := ["human", "cpu", "closed"][controller.get_selected()]
		if controller_id == "human":
			human_count += 1
		slots.append({
			"team":slot["team"],
			"controller":controller_id,
			"race":["authority", "lunar_cartel", "null_choir", "hollow_fang"][race.get_selected()],
			"name":"%s-%02d" % [slot["team"], int(slot["index"]) + 1]
		})
	if human_count == 0:
		slots[0]["controller"] = "human"
	var difficulty_id := GameDifficulty.all_ids()[difficulty_menu.get_selected()]
	CustomMatchConfig.configure(
		int(team_size_menu.get_selected_id()),
		map_ids[map_menu.get_selected()],
		scenario_ids[scenario_menu.get_selected()],
		slots,
		difficulty_id
	)
	PvpMaps.choose(CustomMatchConfig.map_id)
	get_tree().change_scene_to_file("res://main.tscn")

func _refresh_summary() -> void:
	super._refresh_summary()
	if summary_label != null and difficulty_menu != null:
		var level_id := GameDifficulty.all_ids()[difficulty_menu.get_selected()]
		summary_label.text += "\nDifficulty: " + str(GameDifficulty.LEVELS[level_id]["name"])
