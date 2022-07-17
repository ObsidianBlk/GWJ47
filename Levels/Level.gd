extends Node2D


# -----------------------------------------------------------------------------
# Signals
# -----------------------------------------------------------------------------
signal drop(amount, duration)

# -----------------------------------------------------------------------------
# Constants
# -----------------------------------------------------------------------------
const CHUNK_OBJ : PackedScene = preload("res://Levels/Chunk/Chunk.tscn")
#const CHUNK_LIST : Array = [
#	preload("res://Chunks/Chunk_001.tscn"),
#	preload("res://Chunks/Chunk_002.tscn")
#]
#
#const BASE_LIST : Array = [
#	preload("res://Chunks/Bases/Base_001.tscn"),
#	preload("res://Chunks/Bases/Base_002.tscn")
#]

const DROP_RATE : float = 30.0


# -----------------------------------------------------------------------------
# Export Variables
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Variables
# -----------------------------------------------------------------------------
var _rng : RandomNumberGenerator = null

var _chunk_seed_list : Array = []
var _chunk_stack : Array = []


# -----------------------------------------------------------------------------
# Onready Variables
# -----------------------------------------------------------------------------
onready var _player_node : KinematicBody2D = $Player

onready var _env : WorldEnvironment = $WorldEnvironment
onready var _beattarget : Node2D = $BeatTarget

# -----------------------------------------------------------------------------
# Setters
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Override Methods
# -----------------------------------------------------------------------------
func _ready() -> void:
	if _rng == null:
		_rng = RandomNumberGenerator.new()
	
	Game.connect("beat", self, "_on_heartbeat")
	Game.connect("subbeat", self, "_on_subbeat")
	Game.connect("game_started", self, "_on_game_started")
	Game.connect("glow_state_changed", self, "_on_glow_state_changed")

func _process(_delta : float) -> void:
	if not Game.is_music_paused():
		var viewport_size : Vector2 = get_viewport().size
		if (_player_node.position.y - _player_node.size.y) > viewport_size.y:
			clear()
			Game.end_game(false)

# -----------------------------------------------------------------------------
# Private Methods
# -----------------------------------------------------------------------------
func _GetLatestChunk() -> Node2D:
	if _chunk_stack.size() <= 0:
		return null
	return _chunk_stack[_chunk_stack.size() - 1]

func _GetLeadChunk() -> Node2D:
	if _chunk_stack.size() <= 0:
		return null
	return _chunk_stack[0]

func _AddNewChunk(base : bool = false) -> void:
	var chunk : Node2D = CHUNK_OBJ.instance()
	var chunk_seed : float = 0.0
	if base:
		chunk_seed = _rng.randf_range(0.0, 10000.0)
	else:
		var idx : int = _rng.randi_range(0, _chunk_seed_list.size() - 1)
		chunk_seed = _chunk_seed_list[idx]
	
	chunk.generate(chunk_seed, 1920.0, _player_node.size.x, base)
	if _chunk_stack.size() <= 0:
		chunk.position = Vector2(0.0, 1080.0 - chunk.height)
	else:
		chunk.position = _GetLatestChunk().position - Vector2(0.0, chunk.height)
	add_child(chunk)
	_chunk_stack.append(chunk)


func _DropChunk(chunk : Node2D) -> void:
	if chunk and chunk is Chunk:
		remove_child(chunk)
		for i in range(_chunk_stack.size()):
			if _chunk_stack[i] == chunk:
				_chunk_stack.remove(i)
				break
		chunk.queue_free()


func _DropLeadChunk() -> void:
	if _chunk_stack.size() > 0:
		var chunk : Node2D = _chunk_stack.pop_front()
		remove_child(chunk)
		chunk.queue_free()

# -----------------------------------------------------------------------------
# Public Methods
# -----------------------------------------------------------------------------
func fill_level(level_seed : float) -> void:
	_rng.seed = level_seed
	if _chunk_seed_list.size() > 0:
		_chunk_seed_list.clear()
	var num_chunk_seeds : int = _rng.randi_range(6, 12)
	for _i in range(num_chunk_seeds):
		_chunk_seed_list.append(_rng.randf_range(0.0, 10000.0))
	
	_AddNewChunk(true)
	if _chunk_stack.size() <= 0:
		printerr("Failed to instance a base chunk.")
		return
	var latest : Chunk = _GetLatestChunk()
	if not latest.has_player_start():
		printerr("Base Chunk missing player start.")
		clear()
		return
	
	_player_node.position = latest.get_player_start()
	while latest.position.y >= 0.0:
		_AddNewChunk()
		latest = _GetLatestChunk()
	_beattarget.set_seed(_rng.randf() * 10000.0)


func clear() -> void:
	for i in range(_chunk_stack.size()):
		remove_child(_chunk_stack[i])
		_chunk_stack[i].queue_free()
	_chunk_stack.clear()
	_player_node.position = Vector2(-500.0, 0.0) # Position is semi-arbutrary

# -----------------------------------------------------------------------------
# Handler Methods
# -----------------------------------------------------------------------------
func _on_max_height_reached(chunk : Node2D) -> void:
	_DropChunk(chunk)
	_AddNewChunk()

func _on_glow_state_changed(glow_enabled : bool, intensity : float) -> void:
	_env.environment.glow_enabled = glow_enabled
	_env.environment.glow_intensity = intensity


func _on_subbeat() -> void:
	pass
	#if Game.is_beat_pulse_enabled():
	#	for chunk in _chunk_stack:
	#		chunk.pulse()

func _on_heartbeat(beat : int = 0) -> void:
	var viewport_size : Vector2 = get_viewport().size
	var latest : Chunk = _GetLatestChunk()
	if latest:
		if latest.position.y + DROP_RATE > 0.0:
			_AddNewChunk()
	var lead : Chunk = _GetLeadChunk()
	if lead:
		if lead.position.y + DROP_RATE >= viewport_size.y:
			lead = null
			_DropLeadChunk()
	for chunk in _chunk_stack:
		chunk.position.y += DROP_RATE
		if Game.is_beat_pulse_enabled():
			chunk.pulse()
	#if not _player_node.is_in_air():
	if not _player_node.is_in_air():
		_player_node.drop_if_not_in_air(DROP_RATE)
	_player_node.pulse()


func _on_game_started(game_seed : float) -> void:
	clear()
	fill_level(game_seed)
	var music_count = Game.music_track_count()
	if music_count > 0:
		Game.play_track(0)
		#Game.play_track(_rng.randi_range(0, music_count - 1))

