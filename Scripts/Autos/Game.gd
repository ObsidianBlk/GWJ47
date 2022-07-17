extends Node


# -----------------------------------------------------------------------------
# Signals
# -----------------------------------------------------------------------------
signal game_started()
signal game_finished(win, score)
signal bus_volume_change(bus_id, volume)
signal score_changed(score)
signal beat(beat)
signal subbeat()

signal beat_pulse_state_changed(enabled)
signal glow_state_changed(enabled, intensity)

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

var _beat_pulse_enabled : bool = true
var _glow_enabled : bool = true
var _glow_intensity : float = 0.8

var _score : int = 0
var _win_state : bool = false

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
	config.set_value("Effects", "Beat_Pulse", _beat_pulse_enabled)
	config.set_value("Effects", "Glow", _glow_enabled)
	config.set_value("Effects", "Glow_Intensity", _glow_intensity)
	EIM.save_to_config(config)
	var res : int = config.save(CONFIG_FILEPATH)
	if not res == OK:
		printerr("Failed to save config file.")
	return res

func load_config() -> int:
	var config : ConfigFile = ConfigFile.new()
	var res : int = config.load(CONFIG_FILEPATH)
	if res == OK:
		if config.has_section("Audio"):
			if config.has_section_key("Audio", "Master"):
				set_bus_volume(BUS.MASTER, config.get_value("Audio", "Master"))
			if config.has_section_key("Audio", "SFX"):
				set_bus_volume(BUS.SFX, config.get_value("Audio", "SFX"))
			if config.has_section_key("Audio", "Music"):
				set_bus_volume(BUS.MUSIC, config.get_value("Audio", "Music"))
		if config.has_section("Effects"):
			if config.has_section_key("Effects", "Beat_Pulse"):
				enable_beat_pulse(config.get_value("Effects", "Beat_Pulse"))
			if config.has_section_key("Effects", "Glow"):
				enable_glow_effect(config.get_value("Effects", "Glow"))
			if config.has_section_key("Effects", "Glow_Intensity"):
				set_glow_intensity(config.get_value("Effects", "Glow_Intensity"))
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
				_music_player.beats_per_minute = info.bpm
				if beat_delay == 0:
					_music_player.play()
				else:
					_music_player.play_beat_delayed(beat_delay)

func is_music_playing() -> bool:
	if _music_player != null:
		return _music_player.playing
	return false

func pause_music(pause : bool = true) -> void:
	if _music_player != null and _music_player.playing:
		_music_player.stream_paused = pause

func is_music_paused(paused_if_not_playing : bool = true) -> bool:
	if _music_player != null and _music_player.playing:
		return _music_player.stream_paused
	return paused_if_not_playing

func get_music_track_info(idx : int):
	if idx >= 0 and idx < _music_tracks.size():
		var res : Dictionary = {}
		for param in _music_tracks[idx].keys():
			res[param] = _music_tracks[idx][param]
		return res
	return null

func enable_beat_pulse(enable : bool = true) -> void:
	if _beat_pulse_enabled != enable:
		_beat_pulse_enabled = enable
		emit_signal("beat_pulse_state_changed", _beat_pulse_enabled)

func is_beat_pulse_enabled() -> bool:
	return _beat_pulse_enabled

func enable_glow_effect(enable : bool = true) -> void:
	if _glow_enabled != enable:
		_glow_enabled = enable
		emit_signal("glow_state_changed", _glow_enabled, _glow_intensity)

func is_glow_enabled() -> bool:
	return _glow_enabled

func set_glow_intensity(intensity : float) -> void:
	intensity = max(0.0, min(1.0, intensity))
	if _glow_intensity != intensity:
		_glow_intensity = intensity
		emit_signal("glow_state_changed", _glow_enabled, _glow_intensity)

func get_glow_intensity() -> float:
	return _glow_intensity

func is_game_active() -> bool:
	if _music_player != null:
		return _music_player.playing
	return false

func start_game(game_seed : float) -> void:
	if not is_game_active():
		_win_state = false
		emit_signal("game_started", game_seed)

func end_game(win : bool) -> void:
	if is_game_active():
		if _music_player != null and _music_player.playing:
			_win_state = win
			_music_player.stop()
			_music_player.stream = null
			#emit_signal("game_finished", win, _score)

# -----------------------------------------------------------------------------
# Handler Methods
# -----------------------------------------------------------------------------
func _on_beat(beat : int) -> void:
	emit_signal("beat", beat)

func _on_music_finished() -> void:
	_music_player.stop()
	_music_player.stream = null
	emit_signal("game_finished", _win_state, _score)
