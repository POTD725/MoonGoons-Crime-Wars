extends "res://production_timing_layer.gd"
## Adds the core PNG terrain props over the playable lunar battlefield.

func _draw_lunar_dockyard() -> void:
	super._draw_lunar_dockyard()
	_draw_core_environment_art()

func _draw_core_environment_art() -> void:
	if CoreArtBank == null:
		return
	_draw_environment_sprite("cargo_wall", Vector2(-1210.0, 440.0), Vector2(260.0, 112.0))
	_draw_environment_sprite("cargo_wall", Vector2(720.0, -250.0), Vector2(240.0, 104.0))
	_draw_environment_sprite("crater", Vector2(470.0, -60.0), Vector2(220.0, 150.0))
	_draw_environment_sprite("crater", Vector2(1050.0, -640.0), Vector2(190.0, 132.0))
	_draw_environment_sprite("wrecked_shuttle", Vector2(152.0, 80.0), Vector2(156.0, 106.0))
	_draw_environment_sprite("wrecked_shuttle", Vector2(-430.0, 1010.0), Vector2(146.0, 98.0))
	_draw_environment_sprite("cargo_crate", Vector2(-470.0, 310.0), Vector2(68.0, 54.0))
	_draw_environment_sprite("cargo_crate", Vector2(-95.0, 215.0), Vector2(68.0, 54.0))
	_draw_environment_sprite("cargo_crate", Vector2(530.0, 250.0), Vector2(68.0, 54.0))
	_draw_environment_sprite("cargo_crate", Vector2(850.0, 470.0), Vector2(68.0, 54.0))

func _draw_environment_sprite(kind_name: String, position: Vector2, sprite_size: Vector2) -> void:
	var texture: Texture2D = CoreArtBank.get_texture(kind_name)
	if texture == null:
		return
	draw_texture_rect(texture, Rect2(position - sprite_size * 0.5, sprite_size), false)
