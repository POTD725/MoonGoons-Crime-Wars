extends "res://force_hud.gd"
## HUD variant with a live tactical map in the lower-right command deck.

var minimap_panel: Control
var mini_help_line: Label

func _build_help_panel(deck: Panel) -> void:
	var side_panel: Panel = _panel(Rect2(1204.0, 14.0, 376.0, 218.0), Color("06101d"), Color("efc75e"), 2)
	deck.add_child(side_panel)
	var title: Label = _label("TACTICAL MINIMAP", Rect2(16.0, 10.0, 344.0, 18.0), 14, Color("efc75e"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	side_panel.add_child(title)
	minimap_panel = Control.new()
	minimap_panel.position = Vector2(18.0, 33.0)
	minimap_panel.size = Vector2(340.0, 116.0)
	var minimap_script: Script = load("res://minimap_panel.gd") as Script
	minimap_panel.set_script(minimap_script)
	side_panel.add_child(minimap_panel)
	mini_help_line = _label("ARROWS/WASD move camera  |  P patrol  |  Z support\nMap dots: cyan friendly, pink hostile, gold evidence, blue ore", Rect2(18.0, 156.0, 340.0, 46.0), 10, Color("d7eaff"))
	mini_help_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	side_panel.add_child(mini_help_line)

func _refresh() -> void:
	super._refresh()
	if minimap_panel != null and game != null and minimap_panel.has_method("set_game"):
		minimap_panel.call("set_game", game)
