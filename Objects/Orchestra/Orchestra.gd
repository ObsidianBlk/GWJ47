extends Node

# Implementation idea source(s)...
# https://www.procjam.com/tutorials/en/music/

# -----------------------------------------------------------------------------
# Signals
# -----------------------------------------------------------------------------
signal beat()

# -----------------------------------------------------------------------------
# Constants and ENUMs
# -----------------------------------------------------------------------------
enum SCALE {
	Chromatic,				# (random, atonal: all twelve notes)
	Major,					# (classic, happy)
	HarmonicMinor,			# (haunting, creepy)
	MinorPentatonic,		# (blues, rock)
	NaturalMinor,			# (scary, epic)
	MelodicMinorUp,			# (wistful, mysterious)
	MelodicMinorDown, 		# (sombre, soulful)
	Dorian,					# (cool, jazzy)
	Mixolydian,				# (progressive, complex)
	AhavaRaba,				# (exotic, unfamiliar)
	MajorPentatonic,		# (country, gleeful)
	Diatonic,				# (bizarre, symmetrical)
}
const SCALEDATA : Array = [
	[1,1,1,1,1,1,1,1,1,1,1],
	[2,2,1,2,2,2,1],
	[2,1,2,2,1,3,1],
	[3,2,2,3,2],
	[2,1,2,2,1,2,2],
	[2,1,2,2,2,2,1],
	[2,2,1,2,2,1,2],
	[2,1,2,2,2,1,2],
	[2,2,1,2,2,1,2],
	[1,3,1,2,1,2,2],
	[2,2,3,2,3],
	[2,2,2,2,2,2],
]

# -----------------------------------------------------------------------------
# Export Variables
# -----------------------------------------------------------------------------
export var rng_seed : float = 1701.0
export (SCALE) var scale : int = SCALE.Major
export var beats_per_minute : int = 120					setget set_beats_per_minute
export var beats_per_bar : int = 4						setget set_beats_per_bar
export var bars_per_measure : int = 4					setget set_bars_per_measure


# -----------------------------------------------------------------------------
# Variables
# -----------------------------------------------------------------------------
var _rng : RandomNumberGenerator = null
var _beat_duration : float = 0.0

var _measures : Array = []
var _arrangement : Array = []

var _playing : bool = false
var _paused : bool = false

# -----------------------------------------------------------------------------
# Onready Variables
# -----------------------------------------------------------------------------
onready var _timer : Timer = $Timer

# -----------------------------------------------------------------------------
# Setters
# -----------------------------------------------------------------------------
func set_rng_seed(s : float) -> void:
	if _rng == null:
		_rng = RandomNumberGenerator.new()
	rng_seed = s
	_rng.seed = rng_seed

func set_scale(s : int) -> void:
	if SCALE.values().find(s) >= 0:
		scale = s

func set_beats_per_minute(bpm : int) -> void:
	if bpm > 0:
		beats_per_minute = bpm
		_beat_duration = 60.0 / float(bpm)

func set_beats_per_bar(bpb : int) -> void:
	if bpb > 0:
		beats_per_bar = bpb

func set_bars_per_measure(bpm : int) -> void:
	if bpm > 0:
		bars_per_measure = bpm

# -----------------------------------------------------------------------------
# Override Methods
# -----------------------------------------------------------------------------
func _ready() -> void:
	if _rng == null:
		_rng = RandomNumberGenerator.new()
		_rng.seed = rng_seed
	_timer.connect("timeout", self, "_on_heartbeat")


# -----------------------------------------------------------------------------
# Private Methods
# -----------------------------------------------------------------------------
func _GetScaleShift(amount : int, dir : int = 0) -> int:
	var nscale : Array = SCALEDATA[scale]
	var shift : int = 0
	var from : int = 0 if dir >= 0 else nscale.size() - 1
	var to : int = 0 if dir < 0 else nscale.size() - 1
	
	for idx in range(from, to, 1 if dir >= 0 else -1):
		if shift + nscale[idx] > amount:
			break
		shift += nscale[idx]
	return shift


func _GenerateBarPattern() -> Array:
	var pattern : Array = []
	for beat in range(beats_per_bar):
		pattern.append(1)
	
	var up_beat_1: int = 0 if _rng.randf() < 0.98 else _rng.randi_range(0, int(float(beats_per_bar) * 0.25))
	var up_beat_1_dir : int = -1 if _rng.randf() < 0.5 else 1
	var up_beat_2: int = min(up_beat_1 + int(beats_per_bar * 0.5), beats_per_bar - 1)
	var up_beat_2_dir : int = -1 if _rng.randf() < 0.5 else 1
	
	# TODO: Finish this method... obviously
	
	return pattern

# -----------------------------------------------------------------------------
# Public Methods
# -----------------------------------------------------------------------------
func generate() -> void:
	stop()

func play() -> void:
	if not _playing:
		_playing = true
		_timer.start(_beat_duration)

func stop() -> void:
	_playing = false
	_paused = false

func pause(enable : bool = true) -> void:
	if _playing:
		_paused = not _paused

func is_playing() -> bool:
	return _playing

func is_paused() -> bool:
	return _playing and _paused

# -----------------------------------------------------------------------------
# Handler Methods
# -----------------------------------------------------------------------------
func _on_heartbeat() -> void:
	if not _playing or _paused:
		return
	emit_signal("beat")
	# TODO: Actual heartbeat stuff
	_timer.start(_beat_duration)


