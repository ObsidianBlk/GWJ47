extends Node


# -----------------------------------------------------------------------------
# Signals
# -----------------------------------------------------------------------------
signal bus_volume_change(bus_id, volume)
signal score_changed(score)

# -----------------------------------------------------------------------------
# Constants
# -----------------------------------------------------------------------------
const DEFAULT_LEVEL : String = "res://Levels/TestLevel/TestLevel.tscn"
const MUSIC_DATA_PATH : String = "res://Music/music.json"

enum BUS {MASTER, MUSIC, SFX}

# -----------------------------------------------------------------------------
# Variables
# -----------------------------------------------------------------------------
var _world_node : Node2D = null
var _active_level : Node2D = null

var _music_tracks : Array = []

var _score : int = 0

# -----------------------------------------------------------------------------
# Onready Variables
# -----------------------------------------------------------------------------
onready var _BUS = {
	BUS.MASTER : AudioServer.get_bus_index("Master"),
	BUS.MUSIC : AudioServer.get_bus_index("Music"),
	BUS.SFX : AudioServer.get_bus_index("SFX")
}

# -----------------------------------------------------------------------------
# Override Methods
# -----------------------------------------------------------------------------
func _ready() -> void:
	call_deferred("_Initialize")

# -----------------------------------------------------------------------------
# Private Methods
# -----------------------------------------------------------------------------
func _Initialize() -> void:
	if _world_node != null:
		return
	
	_LoadMusicData()
	for child in get_tree().root.get_children():
		if child.name == "World":
			_world_node = child
			break
	
	if _world_node == null:
		printerr("Failed to find the World node.")

func _LoadMusicData() -> int:
	var file : File = File.new()
	var res : int = file.open(MUSIC_DATA_PATH, File.READ)
	if res == OK:
		var result : JSONParseResult = JSON.parse(file.get_as_text())
		file.close()
		
		if result.error != OK:
			printerr("[on line ", result.error_line, "]: ", result.error_string)
			return result.error
		if typeof(result.result) != TYPE_ARRAY:
			printerr("Failed to load music data json. Expected Array type.")
			return ERR_INVALID_DATA
		for item in result.result:
			if typeof(item) == TYPE_DICTIONARY:
				var dkeys : Array = item.keys()
				var valid : bool = true
				for param in ["name", "filepath", "http", "author", "copyright", "bpm"]:
					if dkeys.find(param) < 0:
						valid = false
						break
				if valid:
					_music_tracks.append(item)
	return res

# -----------------------------------------------------------------------------
# Public Methods
# -----------------------------------------------------------------------------
func get_audio_bus_names() -> PoolStringArray:
	return PoolStringArray(BUS.keys())

func get_bus_volume(bus_id : int) -> float:
	if bus_id in _BUS:
		return db2linear(AudioServer.get_bus_volume_db(_BUS[bus_id]))
	return 0.0

func set_bus_volume(bus_id : int, volume : float) -> void:
	if bus_id in _BUS:
		volume = max(0.0, min(1.0, volume))
		AudioServer.set_bus_volume_db(_BUS[bus_id], linear2db(volume))
		emit_signal("bus_volume_change", bus_id, volume)

func add_to_score(amount : int) -> void:
	if amount > 0:
		_score += amount
		emit_signal("score_changed", _score)

func get_score() -> int:
	return _score

func music_track_count() -> int:
	return _music_tracks.size()

func get_music_track_info(idx : int):
	if idx >= 0 and idx < _music_tracks.size():
		var res : Dictionary = {}
		for param in _music_tracks[idx].keys():
			res[param] = _music_tracks[idx][param]
		return res
	return null


