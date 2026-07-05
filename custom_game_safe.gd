extends Control
## Stable local skirmish setup screen. Uses the three canonical major forces.

var race_menu: OptionButton
var opponent_menu: OptionButton
var map_menu: OptionButton
var scenario_menu: OptionButton
var difficulty_menu: OptionButton
var cpu_menu: OptionButton
var summary: Label

func _ready() -> void:
	_build()

func _build() -> void:
	var background: ColorRect = ColorRect.new()
	background.color = Color("071021")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var title: Label = Label.new()
	title.text = "CUSTOM GAME WAR ROOM"
	title.position = Vector2(250, 50)
	title.size = Vector2(1100, 44)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color("8fe9ff"))
	add_child(title)
	var subtitle: Label = Label.new()
	subtitle.text = "Choose a live battlefield. Every map has hard borders, impassable terrain, elevation bands, and its own resource routes."
	subtitle.position = Vector2(230, 105)
	subtitle.size = Vector2(1140, 26)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 15)
	add_child(subtitle)
	race_menu = _menu("YOUR FORCE", 235, ["Lunar Peacekeepers", "The Syndicate", "The Nullborn"])
	opponent_menu = _menu("CPU FORCE", 315, ["The Syndicate", "Lunar Peacekeepers", "The Nullborn"])
	map_menu = _menu("BATTLEFIELD", 395, ["Nexus Prime", "Black Crater", "Syndicate Docks", "Underhive Sector", "Iron Ridge", "Shatterpoint", "Obsidian Pass", "Null Chapel", "Smuggler's Run", "Shadow Terminal", "Frostline Outpost", "Wreckage Fields"])
	scenario_menu = _menu("SCENARIO", 475, ["Standard Skirmish", "Resource Rush", "King of the Relay", "Sudden Death"])
	difficulty_menu = _menu("DIFFICULTY", 555, ["Easy", "Standard", "Hard", "Nightmare"])
	difficulty_menu.select(1)
	cpu_menu = _menu("COMPUTER OPPONENTS", 635, ["1 CPU", "2 CPU", "3 CPU", "4 CPU", "5 CPU", "6 CPU", "7 CPU"])
	summary = Label.new()
	summary.position = Vector2(780, 230)
	summary.size = Vector2(480, 300)
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	summary.add_theme_font_size_override("font_size", 17)
	summary.add_theme_color_override("font_color", Color("e8f5ff"))
	add_child(summary)
	var launch: Button = Button.new()
	launch.text = "LAUNCH CUSTOM BATTLE"
	launch.position = Vector2(760, 570)
	launch.size = Vector2(440, 62)
	launch.add_theme_font_size_override("font_size", 20)
	launch.pressed.connect(_launch)
	add_child(launch)
	var back: Button = Button.new()
	back.text = "RETURN TO MAIN MISSION"
	back.position = Vector2(760, 650)
	back.size = Vector2(440, 46)
	back.pressed.connect(func(): get_tree().change_scene_to_file("res://main.tscn"))
	add_child(back)
	for menu: OptionButton in [race_menu, opponent_menu, map_menu, scenario_menu, difficulty_menu, cpu_menu]:
		menu.item_selected.connect(_refresh)
	_refresh(0)

func _menu(label_text: String, y: float, choices: Array[String]) -> OptionButton:
	var label: Label = Label.new()
	label.text = label_text
	label.position = Vector2(300, y)
	label.size = Vector2(360, 24)
	label.add_theme_font_size_override("font_size", 15)
	label.add_theme_color_override("font_color", Color("a8c8e5"))
	add_child(label)
	var menu: OptionButton = OptionButton.new()
	menu.position = Vector2(300, y + 28)
	menu.size = Vector2(360, 38)
	for choice: String in choices:
		menu.add_item(choice)
	add_child(menu)
	return menu

func _refresh(_index: int) -> void:
	if summary == null:
		return
	summary.text = "MATCH BRIEF\n\n%s versus %s\n\nMap: %s\nScenario: %s\nDifficulty: %s\nOpposition: %s\n\nTerrain rules: units cannot leave the battlefield; deep terrain blocks ground movement; climbs are slower; low ground and difficult surfaces change routing; only buildable terrain accepts structures." % [race_menu.get_item_text(race_menu.selected), opponent_menu.get_item_text(opponent_menu.selected), map_menu.get_item_text(map_menu.selected), scenario_menu.get_item_text(scenario_menu.selected), difficulty_menu.get_item_text(difficulty_menu.selected), cpu_menu.get_item_text(cpu_menu.selected)]

func _launch() -> void:
	var races: Array[String] = ["authority", "lunar_cartel", "null_choir"]
	var player_race: String = races[race_menu.selected]
	var opponent_race: String = races[opponent_menu.selected]
	var levels: Array[String] = ["easy", "standard", "hard", "nightmare"]
	MatchState.set_match(player_race, opponent_race, map_menu.get_item_text(map_menu.selected), scenario_menu.get_item_text(scenario_menu.selected), levels[difficulty_menu.selected], cpu_menu.selected + 1)
	get_tree().change_scene_to_file("res://main.tscn")
