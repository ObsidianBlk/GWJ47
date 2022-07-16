extends AudioStreamPlayer

# Strongly based on code from...
# https://github.com/LegionGames/Conductor-Example/blob/master/Scripts/Conductor.gd

# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal beat(position)
signal measure(position)

# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
export var beats_per_minute : float = 100.0				setget set_beats_per_minute

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _beat_seconds : float = 0.0
var _song_position : float = 0.0
var _song_beat : int = 0
var _last_song_beat : int = 0
var _beats_before_start : int = 0

var _timer : Timer = null


# ------------------------------------------------------------------------------
# Setters
# ------------------------------------------------------------------------------
func set_beats_per_minute(bpm : float) -> void:
	if bpm > 0.0:
		beats_per_minute = bpm
		_beat_seconds = 60.0 / beats_per_minute
		print("beats_per_minute: ", beats_per_minute)

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	set_beats_per_minute(beats_per_minute)
	_timer = Timer.new()
	add_child(_timer)
	_timer.one_shot = true
	_timer.connect("timeout", self, "_on_timeout")
	Game.set_music_audio_stream(self)

func _physics_process(_delta : float) -> void:
	if playing:
		_song_position = get_playback_position() + AudioServer.get_time_since_last_mix()
		_song_position -= AudioServer.get_output_latency()
		_song_beat = int(_song_position / _beat_seconds) + _beats_before_start
		_report_beat()


# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _report_beat() -> void:
	if _song_beat != _last_song_beat:
		call_deferred("emit_signal", "beat", _song_beat)
		#emit_signal("beat", _song_beat)
		_last_song_beat = _song_beat

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func play_beat_delayed(beats : int = 0) -> void:
	_beats_before_start = beats
	if beats > 0:
		_song_beat = 0
		_last_song_beat = -1
		_timer.start(_beat_seconds)
	else: play()


# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_timeout() -> void:
	_song_beat += 1
	if _song_beat < _beats_before_start - 1:
		_timer.start(_beat_seconds)
	elif _song_beat == _beats_before_start - 1:
		var dur : float = _beat_seconds - (AudioServer.get_time_to_next_mix() + AudioServer.get_output_latency())
		_timer.start(dur)
	else:
		play()
	_report_beat()
