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

const DROP_RATE : float = 8.0


# -----------------------------------------------------------------------------
# Export Variables
# -----------------------------------------------------------------------------
export var level_seed : float = 2345790.0
export var beat_stream_nodepath : NodePath = ""

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

# -----------------------------------------------------------------------------
# Setters
# -----------------------------------------------------------------------------
func set_level_seed(s : float) -> void:
	level_seed = s
	if _rng == null:
		_rng = RandomNumberGenerator.new()
	_rng.seed = level_seed

# -----------------------------------------------------------------------------
# Override Methods
# -----------------------------------------------------------------------------
func _ready() -> void:
	if _rng == null:
		_rng = RandomNumberGenerator.new()
	_rng.seed = level_seed
	
	var beat_stream = get_node_or_null(beat_stream_nodepath)
	if beat_stream == null or not beat_stream.has_method("play_beat_delayed"):
		printerr("Failed to find beat generating audio stream player.")
	else:
		beat_stream.connect("beat", self, "_on_heartbeat")

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
func fill_level() -> void:
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

func _on_heartbeat(beat : int = 0) -> void:
	var latest : Chunk = _GetLatestChunk()
	if latest:
		if latest.position.y + DROP_RATE > 0.0:
			_AddNewChunk()
	var lead : Chunk = _GetLeadChunk()
	if lead:
		if lead.position.y + DROP_RATE >= OS.window_size.y:
			lead = null
			_DropLeadChunk()
	var include_player : bool = not _player_node.is_in_air()
	for chunk in _chunk_stack:
		chunk.position.y += DROP_RATE
	#if not _player_node.is_in_air():
	if include_player:
		_player_node.drop_if_not_in_air(DROP_RATE)

func _on_game(restart : bool) -> void:
	var beat_stream = get_node_or_null(beat_stream_nodepath)
	if beat_stream == null or not beat_stream.has_method("play_beat_delayed"):
		printerr("Failed to find beat generating audio stream player.")
		return
	
	if restart:
		clear()
	if _chunk_stack.size() <= 0:
		fill_level()
	
	if beat_stream.playing:
		beat_stream.stream_paused = not beat_stream.stream_paused
	else:
		var music_count = Game.music_track_count()
		if music_count > 0:
			var music_info = Game.get_music_track_info(_rng.randi_range(0, music_count - 1))
			if music_info != null:
				print("Playing: ", music_info.name)
				beat_stream.stream = load(music_info.filepath)
				beat_stream.beats_per_minute = music_info.bpm
				beat_stream.play_beat_delayed(4)
			else:
				print("Failed to find music")
		else:
			print("No music info found")

