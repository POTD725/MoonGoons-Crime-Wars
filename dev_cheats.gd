extends Node
## MoonGoons: Crime Wars developer console.
## F9 opens the console. This is intentionally a local development tool.

const CONSOLE_TITLE := "DEV CONSOLE // CRIME WARS"

var console_layer: CanvasLayer
var panel: Panel
var command_line: LineEdit
var output: RichTextLabel
var god_mode := false
var infinite_resources := false

func _ready() -> void:
	set_process(true)
	call_deferred("_build_console")

func _process(_delta: float) -> void:
	var root := _game()
	if root == null:
		return
	if infinite_resources:
		root.set("credits", max(9999, int(root.get("credits"))))
		root.set("supplies", max(9999, int(root.get("supplies"))))
		root.set("intel", max(9999, int(root.get("intel"))))
	if god_mode:
		for unit in root.get("units"):
			if unit.get("team", "") == "authority":
				unit["hp"] = unit.get("max", unit.get("max_hp", 1.0))
		for building in root.get("buildings"):
			if building.get("team", "") == "authority":
				building["hp"] = building.get("max", building.get("max_hp", 1.0))

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F9:
		_toggle_console()
		get_viewport().set_input_as_handled()

func _build_console() -> void:
	console_layer = CanvasLayer.new()
	console_layer.layer = 20
	add_child(console_layer)

	panel = Panel.new()
	panel.position = Vector2(610, 18)
	panel.size = Vector2(570, 280)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.025, 0.045, 0.09, 0.96)
	style.border_color = Color("d8ff56")
	style.set_border_width_all(2)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	panel.add_theme_stylebox_override("panel", style)
	console_layer.add_child(panel)

	var heading := Label.new()
	heading.text = CONSOLE_TITLE + "  [F9]"
	heading.position = Vector2(14, 10)
	heading.size = Vector2(530, 24)
	heading.add_theme_font_size_override("font_size", 16)
	heading.add_theme_color_override("font_color", Color("d8ff56"))
	panel.add_child(heading)

	output = RichTextLabel.new()
	output.position = Vector2(14, 42)
	output.size = Vector2(542, 172)
	output.bbcode_enabled = true
	output.fit_content = false
	output.scroll_active = true
	output.add_theme_font_size_override("normal_font_size", 13)
	output.add_theme_color_override("default_color", Color("cbd6e8"))
	panel.add_child(output)

	command_line = LineEdit.new()
	command_line.position = Vector2(14, 228)
	command_line.size = Vector2(542, 36)
	command_line.placeholder_text = "Type help, then press Enter"
	command_line.add_theme_font_size_override("font_size", 14)
	command_line.text_submitted.connect(_run_command)
	panel.add_child(command_line)

	_write("[color=#d8ff56]Developer console armed.[/color] Type [b]help[/b] for commands.")
	panel.visible = false

func _toggle_console() -> void:
	if panel == null:
		return
	panel.visible = not panel.visible
	if panel.visible:
		command_line.grab_focus()
		_write("[color=#8fe9ff]Console opened.[/color] god=%s  infinite=%s" % [str(god_mode), str(infinite_resources)])
	else:
		command_line.release_focus()

func _run_command(raw_command: String) -> void:
	var command := raw_command.strip_edges()
	command_line.clear()
	if command.is_empty():
		return
	_write("[color=#d8ff56]> %s[/color]" % command)
	var parts := command.to_lower().split(" ", false)
	var action := parts[0]
	var root := _game()
	if root == null:
		_write("[color=#ff7187]No RTS mission scene is running.[/color]")
		return

	match action:
		"help", "?":
			_show_help()
		"give", "fund":
			_give(root, parts)
		"resources", "res":
			root.set("credits", 9999)
			root.set("supplies", 9999)
			root.set("intel", 9999)
			_write("[color=#7dffad]Credits, Supplies, and Intel set to 9,999.[/color]")
		"infinite", "inf":
			infinite_resources = not infinite_resources
			_write("Infinite resources: [b]%s[/b]" % str(infinite_resources))
		"god", "godmode":
			god_mode = not god_mode
			_write("Authority invulnerability: [b]%s[/b]" % str(god_mode))
		"heal":
			_heal_authority(root)
			_write("[color=#7dffad]Authority units and structures restored.[/color]")
		"spawn":
			_spawn(root, parts)
		"build":
			_build(root, parts)
		"wave":
			_spawn_wave(root)
		"clear", "killall":
			_clear(root, parts)
		"win":
			_force_result(root, true)
		"lose":
			_force_result(root, false)
		"reveal":
			_reveal_relay(root)
		"speed":
			_set_speed(parts)
		"reload", "reset":
			get_tree().reload_current_scene()
		"status":
			_status(root)
		_:
			_write("[color=#ff7187]Unknown command.[/color] Use [b]help[/b].")

func _show_help() -> void:
	_write("[b]COMMANDS[/b]\n" +
		"[color=#8fe9ff]give 500 100 25[/color]  Add Credits, Supplies, Intel\n" +
		"[color=#8fe9ff]resources[/color]  Set all resources to 9,999\n" +
		"[color=#8fe9ff]infinite[/color]  Toggle infinite resources\n" +
		"[color=#8fe9ff]god[/color]  Toggle Authority invulnerability\n" +
		"[color=#8fe9ff]heal[/color]  Restore Authority health\n" +
		"[color=#8fe9ff]spawn deputy 5[/color]  Spawn units at the mouse\n" +
		"[color=#8fe9ff]spawn raider 8 syndicate[/color]  Spawn enemy test units\n" +
		"[color=#8fe9ff]build armory[/color]  Finish a structure at the mouse\n" +
		"[color=#8fe9ff]wave[/color]  Spawn a Syndicate attack wave\n" +
		"[color=#8fe9ff]clear enemy[/color]  Remove enemy units and buildings\n" +
		"[color=#8fe9ff]win[/color] / [color=#8fe9ff]lose[/color]  Force mission result\n" +
		"[color=#8fe9ff]reveal[/color]  Move a scout near the enemy relay\n" +
		"[color=#8fe9ff]speed 0.5[/color] or [color=#8fe9ff]speed 2[/color]  Change time scale\n" +
		"[color=#8fe9ff]status[/color]  Print test-state summary\n" +
		"[color=#8fe9ff]reload[/color]  Restart the mission")

func _give(root: Node, parts: PackedStringArray) -> void:
	var credits_to_add := _number(parts, 1, 500)
	var supplies_to_add := _number(parts, 2, 0)
	var intel_to_add := _number(parts, 3, 0)
	root.set("credits", int(root.get("credits")) + credits_to_add)
	root.set("supplies", int(root.get("supplies")) + supplies_to_add)
	root.set("intel", int(root.get("intel")) + intel_to_add)
	_write("[color=#7dffad]+%d Credits, +%d Supplies, +%d Intel.[/color]" % [credits_to_add, supplies_to_add, intel_to_add])

func _spawn(root: Node, parts: PackedStringArray) -> void:
	if parts.size() < 2:
		_write("Usage: spawn drone|deputy|shield|raider|hacker [count] [authority|syndicate]")
		return
	var kind := parts[1]
	if not ["drone", "deputy", "shield", "raider", "hacker"].has(kind):
		_write("[color=#ff7187]Unknown unit. Use drone, deputy, shield, raider, or hacker.[/color]")
		return
	var count := clampi(_number(parts, 2, 1), 1, 40)
	var team := "syndicate" if kind == "raider" or kind == "hacker" else "authority"
	if parts.size() >= 4 and ["authority", "syndicate"].has(parts[3]):
		team = parts[3]
	var origin := _cursor_world(root)
	for index in count:
		var column := index % 5
		var row := index / 5
		root.call("_spawn_unit", kind, team, origin + Vector2((column - 2) * 34, (row - 2) * 34))
	_write("[color=#7dffad]Spawned %d %s unit(s) for %s.[/color]" % [count, kind, team])

func _build(root: Node, parts: PackedStringArray) -> void:
	if parts.size() < 2:
		_write("Usage: build nexus|armory|relay|medbay|bay|cells|syndicate_relay [authority|syndicate]")
		return
	var kind := parts[1]
	if not ["nexus", "armory", "relay", "medbay", "bay", "cells", "syndicate_relay"].has(kind):
		_write("[color=#ff7187]Unknown structure.[/color]")
		return
	var team := "syndicate" if kind == "syndicate_relay" else "authority"
	if parts.size() >= 3 and ["authority", "syndicate"].has(parts[2]):
		team = parts[2]
	root.call("_spawn_building", kind, team, _cursor_world(root), true)
	_write("[color=#7dffad]Completed %s for %s.[/color]" % [kind, team])

func _spawn_wave(root: Node) -> void:
	var relay: Dictionary = root.call("_relay")
	var origin := relay.get("pos", _cursor_world(root))
	for offset in [Vector2(-130, 110), Vector2(120, 90), Vector2(25, -145), Vector2(160, -110)]:
		root.call("_spawn_unit", "raider", "syndicate", origin + offset)
	root.call("_spawn_unit", "hacker", "syndicate", origin + Vector2(-30, -175))
	_write("[color=#ffbe72]Spawned a Syndicate test wave.[/color]")

func _clear(root: Node, parts: PackedStringArray) -> void:
	var target := "enemy" if parts.size() < 2 else parts[1]
	if target == "enemy" or target == "syndicate":
		for unit in root.get("units"):
			if unit.get("team", "") == "syndicate":
				unit["hp"] = 0.0
		for building in root.get("buildings"):
			if building.get("team", "") == "syndicate":
				building["hp"] = 0.0
	elif target == "authority":
		for unit in root.get("units"):
			if unit.get("team", "") == "authority":
				unit["hp"] = 0.0
		for building in root.get("buildings"):
			if building.get("team", "") == "authority":
				building["hp"] = 0.0
	else:
		_write("Usage: clear enemy|authority")
		return
	root.call("_cleanup")
	root.call("_check_end")
	_write("[color=#ffbe72]Cleared %s entities.[/color]" % target)

func _force_result(root: Node, should_win: bool) -> void:
	for building in root.get("buildings"):
		if should_win and building.get("kind", "") == "syndicate_relay":
			building["hp"] = 0.0
		elif not should_win and building.get("team", "") == "authority" and building.get("kind", "") == "nexus":
			building["hp"] = 0.0
	root.call("_cleanup")
	root.call("_check_end")
	_write("[color=#ffbe72]Forced mission %s.[/color]" % ("victory" if should_win else "failure"))

func _heal_authority(root: Node) -> void:
	for unit in root.get("units"):
		if unit.get("team", "") == "authority":
			unit["hp"] = unit.get("max", unit.get("max_hp", 1.0))
	for building in root.get("buildings"):
		if building.get("team", "") == "authority":
			building["hp"] = building.get("max", building.get("max_hp", 1.0))

func _reveal_relay(root: Node) -> void:
	var relay: Dictionary = root.call("_relay")
	if relay.is_empty():
		_write("[color=#ff7187]No Syndicate Relay remains.[/color]")
		return
	root.call("_spawn_unit", "drone", "authority", relay.get("pos", Vector2.ZERO) + Vector2(-255, 0))
	_write("[color=#7dffad]Scout beacon drone deployed near the relay. Fog lifted locally.[/color]")

func _set_speed(parts: PackedStringArray) -> void:
	var value := 1.0
	if parts.size() > 1 and parts[1].is_valid_float():
		value = clampf(parts[1].to_float(), 0.1, 4.0)
	Engine.time_scale = value
	_write("[color=#8fe9ff]Time scale set to %.2fx.[/color]" % value)

func _status(root: Node) -> void:
	_write("[b]TEST STATUS[/b]  Credits=%d  Supplies=%d  Intel=%d  Units=%d  Buildings=%d  God=%s  Infinite=%s  Time=%.2fx" % [int(root.get("credits")), int(root.get("supplies")), int(root.get("intel")), root.get("units").size(), root.get("buildings").size(), str(god_mode), str(infinite_resources), Engine.time_scale])

func _cursor_world(root: Node) -> Vector2:
	return root.call("_world", root.get_viewport().get_mouse_position())

func _number(parts: PackedStringArray, index: int, fallback: int) -> int:
	if index < parts.size() and parts[index].is_valid_int():
		return parts[index].to_int()
	return fallback

func _game() -> Node:
	var root := get_tree().current_scene
	if root != null and root.has_method("_spawn_unit") and root.has_method("_spawn_building"):
		return root
	return null

func _write(message: String) -> void:
	if output == null:
		return
	output.append_text(message + "\n")
	output.scroll_to_line(output.get_line_count())
