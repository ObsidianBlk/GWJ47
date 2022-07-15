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


# -----------------------------------------------------------------------------
# Variables
# -----------------------------------------------------------------------------
var _rng : RandomNumberGenerator = null
var _note_distribution : RandomDistribution = null
var _note_16th_duration : float = 0.0
var _beat_tracker : int = 0

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
		_UpdateNoteDistribution()

func set_beats_per_bar(bpb : int) -> void:
	if bpb > 0 and bpb%2 == 0:
		beats_per_bar = bpb


# -----------------------------------------------------------------------------
# Override Methods
# -----------------------------------------------------------------------------
func _ready() -> void:
	if _rng == null:
		_rng = RandomNumberGenerator.new()
		_rng.seed = rng_seed
	_UpdateNoteDistribution()
	_timer.connect("timeout", self, "_on_heartbeat")
	_sub_beat_timer.connect("timeout", self, "_on_subbeat")


# -----------------------------------------------------------------------------
# Private Methods
# -----------------------------------------------------------------------------
func _SetAudioServerVolume(vol : float) -> void:
	vol = max(0.0, min(1.0, vol))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Orchestra"), linear2db(vol))

func _UpdateNoteDistribution() -> void:
	_note_16th_duration = (60.0 / float(beats_per_minute)) * .25 # Length of a 16th note
	if _note_distribution == null:
		_note_distribution = RandomDistribution.new()
	var dist : Array = [0.05, 0.1, 0.8, 0.05, 0.02]
	if beats_per_minute >= 90 and beats_per_minute < 150:
		dist = [0.1, 0.2, 0.6, 0.02, 0.0]
	elif beats_per_minute >= 150:
		dist = [0.15, 0.35, 0.9, 0.0, 0.0]
	
	_note_distribution.set_items([
		1, dist[0],
		2, dist[1],
		4, dist[2],
		8, dist[3],
		16, dist[4]
	])
	_note_distribution.precalculate()
	
	

func _ScaledNotes() -> Dictionary:
	var nscale : Array = SCALEDATA[scale]
	var notes = {
		"scale":[],
		"origin":0
	}
	var total_notes : float = 14.0
	
	notes.scale.append(1.0)
	var cur_note : float = 0.0
	for i in range(nscale.size() - 1, 0, -1):
		cur_note += float(nscale[i])
		notes.scale.push_front(1.0 - (cur_note / total_notes))
	
	notes.origin = notes.scale.size() - 1 
	cur_note = 0.0
	for i in range(nscale.size()):
		cur_note += float(nscale[i])
		notes.scale.append(1.0 + (cur_note / total_notes))
	
	return notes

func _GetNoteLength(last_length : int, entries : int, on_beat : bool = true) -> int:
	if not on_beat:
		if _rng.randf() < 0.98:
			return last_length
	
	var length : int = _note_distribution.randv(_rng)
	if length > entries:
		return 0
	
	return length

func _GetNoteScaleOffset(NoteScaleList : Array, LastOffset : int) -> int:
	var note_offset_dist : RandomDistribution = RandomDistribution.new()
	for i in range(NoteScaleList.size()):
		var weight : float = 0.5
		if i < LastOffset:
			weight = float(LastOffset - i) / float(LastOffset)
		elif i > LastOffset:
			weight = float(i - LastOffset) / float(LastOffset + 1)
		note_offset_dist.add_item(i - LastOffset, weight)
	return LastOffset + note_offset_dist.randv(_rng)


func _GenerateMeasure() -> Dictionary:
	var measure : Dictionary = {
		"melody":[]
	}
	
	var note_scale : Array = _ScaledNotes().scale
	
	var num_entires : int = beats_per_bar * 4 # total number of 1/16th notes allowed.
	var beat_count : int = 1
	var length : int = 0
	var last_length : int = 0
	var note_scale_idx : int = -1#_rng.randi_range(0, note_scale.size() - 1)
	for e in range(num_entires):
		if length <= 0:
			length = _GetNoteLength(last_length, num_entires - e, beat_count == 1)
			last_length = length
			
			if note_scale_idx < 0:
				note_scale_idx = _rng.randi_range(0, note_scale.size() - 1)
			else:
				note_scale_idx = _GetNoteScaleOffset(note_scale, note_scale_idx)
			
			measure.melody.append({
				"scale":note_scale[note_scale_idx],
				"strong": beat_count == 1
			})
		else:
			measure.melody.append(null)
		length -= 1
		beat_count += 1 if beat_count < 4 else -3
	
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
	if note != null:
		_melody.stop()



func _on_heartbeat() -> void:
	if not _playing or _paused:
		return
	_beat_tracker += 1
	if _beat_tracker == 4: # There are 4 16th notes in a beat.
		emit_signal("beat")
	var measure : Dictionary = _measures[_arrangement[_aidx]]
	var note = measure.melody[_midx]
	if note != null:
		if "scale" in note:
			_melody.play()
			_melody.pitch_scale = note.scale
		if "strong" in note and note["strong"] == true:
			_SetAudioServerVolume(1.0)
		else:
			_SetAudioServerVolume(0.9)
	else:
		_SetAudioServerVolume(0.9)
			
	_midx += 1
	if _midx >= measure.melody.size():
		_midx = 0
		_aidx += 1
		if _aidx >= _arrangement.size():
			_aidx = 0
	
	_timer.start(_note_16th_duration)
	_sub_beat_timer.start(_note_16th_duration * 0.9)


