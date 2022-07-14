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
var _aidx : int = 0
var _midx : int = 0

var _playing : bool = false
var _paused : bool = false

# -----------------------------------------------------------------------------
# Onready Variables
# -----------------------------------------------------------------------------
onready var _timer : Timer = $Timer
onready var _sub_beat_timer : Timer = $SubBeat_Timer
onready var _melody : AudioStreamPlayer = $Melody_1

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
	if bpb > 0 and bpb%2 == 0:
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
	_sub_beat_timer.connect("timeout", self, "_on_subbeat")


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
		pattern.append(0)
	
	var up_beat_1: int = 0 if _rng.randf() < 0.98 else _rng.randi_range(0, int(float(beats_per_bar) * 0.25))
	var up_beat_1_dir : int = -1 if _rng.randf() < 0.5 else 1
	var up_beat_2: int = min(up_beat_1 + int(beats_per_bar * 0.5), beats_per_bar - 1)
	var up_beat_2_dir : int = -1 if _rng.randf() < 0.5 else 1
	
	pattern[up_beat_1] = _GetScaleShift(_rng.randi_range(0, 4), -up_beat_1_dir)
	pattern[up_beat_2] = _GetScaleShift(_rng.randi_range(0, 4), -up_beat_2_dir)
	
	for beat in range(beats_per_bar):
		if beat > up_beat_1 and beat < up_beat_2:
			var dir : int = up_beat_1_dir if _rng.randf() > 0.8 else -up_beat_1_dir
			pattern[beat] = 1.0 + (dir * (_GetScaleShift(_rng.randi_range(0, 4), dir) / 12.0))
		if beat > up_beat_2:
			var dir : int = up_beat_2_dir if _rng.randf() > 0.8 else -up_beat_2_dir
			pattern[beat] = 1.0 + (dir * (_GetScaleShift(_rng.randi_range(0, 4), up_beat_2_dir) / 12.0))
	
	print("Bar Pattern: ", pattern)
	return pattern

func _BuildDistNoteArray(size : int, notes : Array, dist : Array) -> Array:
	var res : Array = []
	for n in range(notes.size()):
		if n >= dist.size():
			break
		var count = size * dist[n]
		for _i in range(count):
			res.append(notes[n])
		if res.size() >= size:
			break
	return res

func _GetNoteLength(last_note_length : int) -> int:
	var notes : Array = []
	notes.append(beats_per_bar)
	for div in [2,4,8,16]:
		var note = beats_per_bar / div
		if note > 0:
			notes.append(note)
	
	var r : float = _rng.randf()
	if beats_per_minute < 90: # Threshold for "calm" music
		if last_note_length == 0 or r > 0.7:
			var notedist : Array = _BuildDistNoteArray(20, notes, [0.1, 0.3, 0.5, 0.05, 0.05])
			var idx = _rng.randi_range(0, notedist.size()-1)
			return notedist[idx]
	elif beats_per_minute >= 90 and beats_per_minute < 150: # Threshold for "rock" music
		if last_note_length == 0 or r > 0.6:
			var notedist : Array = _BuildDistNoteArray(20, notes, [0.05, 0.1, 0.6, 0.2, 0.05])
			var idx = _rng.randi_range(0, notedist.size()-1)
			return notedist[idx]
	else: # Everything else is really fast
		if last_note_length == 0 or r > 0.6:
			var notedist : Array = _BuildDistNoteArray(20, notes, [0.01, 0.14, 0.5, 0.2, 0.15])
			var idx = _rng.randi_range(0, notedist.size()-1)
			return notedist[idx]
	return last_note_length # We'll probably use the same note length often.

func _GenerateMeasure() -> Dictionary:
	var measure : Dictionary = {
		"melody": [],
	}
	
	var bars : Array = []
	for b in bars_per_measure:
		bars.append(_GenerateBarPattern())
	
	var note_length = 0
	var beats_past = 0
	for bar in bars:
		for scale in bar:
			if note_length == beats_past:
				note_length = _GetNoteLength(note_length)
				beats_past = 1
				measure.melody.append({
					"scale": scale,
				})
			else:
				beats_past += 1
				measure.melody.append({
					"dur": note_length - beats_past
				})
		note_length = 0
		beats_past = 0
	
	return measure

# -----------------------------------------------------------------------------
# Public Methods
# -----------------------------------------------------------------------------
func generate() -> void:
	stop()
	_measures.clear()
	_arrangement.clear()

	var num_measures : int = _rng.randi_range(4, 8)
	var num_commons : int = _rng.randi_range(1, max(1, num_measures / 2))
	print(num_measures, " ", num_commons)
	var commons : Array = []
	var uniques : Array = []
	
	for _i in range(num_measures):
		_measures.append(_GenerateMeasure())
		if num_commons > 0:
			commons.append(_measures.size() - 1)
			num_commons -= 1
		else:
			uniques.append(_measures.size() - 1)
	
	_arrangement.append(commons[0])
	var last : int = 0   # 0 == Common | 1 == Unique
	num_measures = _rng.randi_range(num_measures, num_measures * 4)
	for _i in range(num_measures):
		var next : int = 0
		match last:
			0: # Common
				next = 1 if uniques.size() > 0 and _rng.randf() < 0.4 else 0
			1: # Unique
				next = 1 if uniques.size() > 0 and _rng.randf() < 0.1 else 0
		match next:
			0:
				var idx = _rng.randi_range(0, commons.size() - 1)
				_arrangement.append(commons[idx])
			1: 
				var idx = _rng.randi_range(0, uniques.size() - 1)
				_arrangement.append(uniques[idx])
				if _rng.randf() > 0.3:
					uniques.remove(idx)
		last = next
	
	print("Arrangement: ", _arrangement)


func play() -> void:
	#if not _playing and _arrangement.size() > 0:
	if not _playing:
		_playing = true
		_aidx = 0
		_midx = 0
		_on_heartbeat()

func stop() -> void:
	_playing = false
	_paused = false
	_aidx = 0
	_midx = 0

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
func _on_subbeat() -> void:
	var measure : Dictionary = _measures[_arrangement[_aidx]]
	var note = measure.melody[_midx]
	if note != null and "dur" in note and note["dur"] == 0:
		_melody.stop()



func _on_heartbeat() -> void:
	if not _playing or _paused:
		return
	emit_signal("beat")
#	var measure : Dictionary = _measures[_arrangement[_aidx]]
#	var note = measure.melody[_midx]
#	if note != null and "scale" in note:
#		_melody.play()
#		_melody.pitch_scale = note.scale
#	_midx += 1
#	if _midx >= measure.melody.size():
#		_midx = 0
#		_aidx += 1
#		if _aidx >= _arrangement.size():
#			_aidx = 0
		
	_timer.start(_beat_duration)
#	_sub_beat_timer.start(_beat_duration * 0.9)


