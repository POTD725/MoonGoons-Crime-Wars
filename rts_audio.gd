extends Node
## Original synthesized tactical audio for the playable demo.

var stream: AudioStreamGenerator
var player: AudioStreamPlayer
var playback: AudioStreamGeneratorPlayback
var current_frequency: float = 0.0
var current_duration: float = 0.0
var current_age: float = 0.0
var queued_cues: Array[String] = []
var phase: float = 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	stream = AudioStreamGenerator.new()
	stream.mix_rate = 22050.0
	stream.buffer_length = 0.35
	player = AudioStreamPlayer.new()
	player.stream = stream
	add_child(player)
	player.play()
	playback = player.get_stream_playback()

func play_cue(cue: String) -> void:
	if queued_cues.size() < 8:
		queued_cues.append(cue)

func _process(_delta: float) -> void:
	if player != null:
		player.volume_db = linear_to_db(maxf(0.01, GameProfile.effects_volume)) - 13.0
	if playback == null:
		return
	if current_age >= current_duration and not queued_cues.is_empty():
		_start_cue(queued_cues.pop_front())
	_fill_buffer()

func _start_cue(cue: String) -> void:
	current_age = 0.0
	phase = 0.0
	match cue:
		"select":
			current_frequency = 510.0
			current_duration = 0.07
		"order":
			current_frequency = 670.0
			current_duration = 0.09
		"build":
			current_frequency = 430.0
			current_duration = 0.13
		"complete":
			current_frequency = 880.0
			current_duration = 0.16
		"fire":
			current_frequency = 220.0
			current_duration = 0.045
		"impact":
			current_frequency = 130.0
			current_duration = 0.06
		"alert":
			current_frequency = 260.0
			current_duration = 0.22
		"victory":
			current_frequency = 980.0
			current_duration = 0.38
		"defeat":
			current_frequency = 120.0
			current_duration = 0.34
		"error":
			current_frequency = 150.0
			current_duration = 0.12
		_:
			current_frequency = 400.0
			current_duration = 0.08

func _fill_buffer() -> void:
	var available: int = playback.get_frames_available()
	for _frame: int in available:
		var sample: float = 0.0
		if current_age < current_duration and current_frequency > 0.0:
			var fade: float = clampf(1.0 - current_age / maxf(0.01, current_duration), 0.0, 1.0)
			phase += TAU * current_frequency / stream.mix_rate
			sample = (sin(phase) * 0.09 + sin(phase * 0.52) * 0.035) * fade
			current_age += 1.0 / stream.mix_rate
		playback.push_frame(Vector2(sample, sample))
