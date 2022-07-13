extends Node2D


# -----------------------------------------------------------------------------
# Signals
# -----------------------------------------------------------------------------
signal drop(amount, duration)

# -----------------------------------------------------------------------------
# Constants
# -----------------------------------------------------------------------------

const CHUNK_LIST : Array = [
	preload("res://Chunks/Chunk_001.tscn"),
	preload("res://Chunks/Chunk_002.tscn")
]

const BASE_LIST : Array = [
	preload("res://Chunks/Bases/Base_001.tscn"),
	preload("res://Chunks/Bases/Base_002.tscn")
]

const DROP_RATE : float = 64.0


# -----------------------------------------------------------------------------
# Variables
# -----------------------------------------------------------------------------
var _rng : RandomNumberGenerator = null

var _chunk_stack : Array = []


# -----------------------------------------------------------------------------
# Onready Variables
# -----------------------------------------------------------------------------
onready var _player_node : KinematicBody2D = $Player
onready var _orchestra : Node = get_node("../Orchestra")

# -----------------------------------------------------------------------------
# Override Methods
# -----------------------------------------------------------------------------
func _ready() -> void:
	_rng = RandomNumberGenerator.new()
	_rng.randomize()

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

func _AddNewChunk(use_base : bool = false) -> void:
	var chunk_object : PackedScene = null
	if use_base:
		var idx : int = _rng.randi_range(0, BASE_LIST.size() - 1)
		chunk_object = BASE_LIST[idx]
	else:
		var idx : int = _rng.randi_range(0, CHUNK_LIST.size() - 1)
		chunk_object = CHUNK_LIST[idx]
	
	var chunk : Node2D = chunk_object.instance()
	if chunk and chunk is Chunk:
		if _chunk_stack.size() <= 0:
			chunk.position = Vector2(0.0, OS.window_size.y - chunk.height)
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

func _on_heartbeat() -> void:
	var latest : Chunk = _GetLatestChunk()
	if latest:
		if latest.position.y + DROP_RATE > 0.0:
			_AddNewChunk()
	var lead : Chunk = _GetLeadChunk()
	if lead:
		if lead.position.y + DROP_RATE >= OS.window_size.y:
			lead = null
			_DropLeadChunk()
	for chunk in _chunk_stack:
		chunk.position.y += DROP_RATE
	if not _player_node.is_in_air():
		_player_node.position.y += DROP_RATE

func _on_game(restart : bool) -> void:
	if restart:
		_orchestra.stop()
		clear()
	if _chunk_stack.size() <= 0:
		fill_level()
		_orchestra.generate()
	if not _orchestra.is_playing():
		_orchestra.play()
	else:
		_orchestra.pause(not _orchestra.is_paused())

