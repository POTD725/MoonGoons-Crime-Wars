extends Node
## Procedural confirmation and alert tones. No external audio dependency.

var player: AudioStreamPlayer
var playback: AudioStreamGeneratorPlayback
var stream: AudioStreamGenerator
var last_note := ""
var tone_hz := 0.0
var tone_left := 0.0
var phase := 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	stream = AudioStreamGenerator.new()
	stream.mix_rate = 22050.0
	stream.buffer_length = 0.25
	player = AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = linear_to_db(maxf(0.01, GameProfile.effects_volume))
	add_child(player)
	player.play()
	playback = player.get_stream_playback()

func _process(delta: float) -> void:
	if player != null:
		player.volume_db = linear_to_db(maxf(0.01, GameProfile.effects_volume))
	var current: Node = get_tree().current_scene
	if current != null and current.has_method("flash"):
		var note := str(current.get("note", ""))
		if not note.is_empty() and note != last_note:
			last_note = note
			if "complete" in note.to_lower():
				queue_tone(880.0, 0.18)
			elif "insufficient" in note.to_lower() or "blocked" in note.to_lower() or "fallen" in note.to_lower():
				queue_tone(180.0, 0.16)
			else:
				queue_tone(520.0, 0.08)
	_fill(delta)

func queue_tone(frequency: float, duration: float) -> void:
	tone_hz = frequency
	tone_left = duration
	phase = 0.0

func _fill(delta: float) -> void:
	if playback == null:
		return
	var frames: int = playback.get_frames_available()
	for index in frames:
		var sample := 0.0
		if tone_left > 0.0:
			phase += TAU * tone_hz / stream.mix_rate
			sample = sin(phase) * 0.11
			tone_left = maxf(0.0, tone_left - 1.0 / stream.mix_rate)
		playback.push_frame(Vector2(sample, sample))
