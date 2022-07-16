extends Node


# -----------------------------------------------------------------------------
# Signals
# -----------------------------------------------------------------------------
signal game_started()
signal game_finished()
signal bus_volume_change(bus_id, volume)
signal score_changed(score)
signal beat(beat)

# -----------------------------------------------------------------------------
# Constants
# -----------------------------------------------------------------------------
const CONFIG_FILEPATH : String = "user://setting.conf"
const MUSIC_DATA_PATH : String = "res://Music/music.json"

enum BUS {MASTER, MUSIC, SFX}

# -----------------------------------------------------------------------------
# Variables
# -----------------------------------------------------------------------------
var _music_player : AudioStreamPlayer = null
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
	_LoadMusicData()
	set_bus_volume(BUS.MUSIC, 0.5)
	if load_config() != OK:
		save_config()

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
func save_config() -> int:
	var config : ConfigFile = ConfigFile.new()
	config.set_value("Audio", "Master", get_bus_volume(BUS.MASTER))
	config.set_value("Audio", "SFX", get_bus_volume(BUS.SFX))
	config.set_value("Audio", "Music", get_bus_volume(BUS.MUSIC))
	EIM.save_to_config(config)
	var res : int = config.save(CONFIG_FILEPATH)
	if not res == OK:
		printerr("Failed to save config file.")
	return res

func load_config() -> int:
	var config : ConfigFile = ConfigFile.new()
	var res : int = config.load(CONFIG_FILEPATH)
	if res == OK:
		if not config.has_section("Audio"):
			printerr("Config missing required section.")
			return ERR_DOES_NOT_EXIST
		if config.has_section_key("Audio", "Master"):
			set_bus_volume(BUS.MASTER, config.get_value("Audio", "Master"))
			set_bus_volume(BUS.SFX, config.get_value("Audio", "SFX"))
			set_bus_volume(BUS.MUSIC, config.get_value("Audio", "Music"))
		EIM.load_from_config(config)
	else:
		printerr("Failed to load config file.")
	return res


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

func reset_score() -> void:
	_score = 0
	emit_signal("score_changed", _score)

func set_music_audio_stream(mas : AudioStreamPlayer) -> void:
	if _music_player == null and mas != null:
		if mas.has_method("play_beat_delayed"):
			_music_player = mas
			_music_player.connect("beat", self, "_on_beat")
			_music_player.connect("finished", self, "_on_music_finished")

func music_track_count() -> int:
	return _music_tracks.size()

func play_track(idx : int, beat_delay : int = 0) -> void:
	if _music_player != null and not _music_player.playing:
		var info = get_music_track_info(idx)
		if info != null:
			var stream = load(info.filepath)
			if stream:
				_music_player.stream = stream
				if beat_delay == 0:
					_music_player.play()
				else:
					_music_player.play_beat_delayed(beat_delay)

func pause_music(pause : bool = true) -> void:
	if _music_player != null and _music_player.playing:
		_music_player.stream_paused = pause

func is_music_paused() -> bool:
	if _music_player != null and _music_player.playing:
		return _music_player.stream_paused
	return false

func get_music_track_info(idx : int):
	if idx >= 0 and idx < _music_tracks.size():
		var res : Dictionary = {}
		for param in _music_tracks[idx].keys():
			res[param] = _music_tracks[idx][param]
		return res
	return null

func is_game_active() -> bool:
	if _music_player != null:
		return _music_player.playing
	return false

func start_game(game_seed : float) -> void:
	if not is_game_active():
		emit_signal("game_started", game_seed)

# -----------------------------------------------------------------------------
# Handler Methods
# -----------------------------------------------------------------------------
func _on_beat(beat : int) -> void:
	emit_signal("beat", beat)

func _on_music_finished() -> void:
	emit_signal("game_finished")
