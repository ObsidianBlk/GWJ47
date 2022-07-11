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


# -----------------------------------------------------------------------------
# Variables
# -----------------------------------------------------------------------------
var _rng : RandomNumberGenerator = null
var _timer : Timer = null

var _last_chunk : Node2D = null


# -----------------------------------------------------------------------------
# Onready Variables
# -----------------------------------------------------------------------------
onready var _player_node : KinematicBody2D = $Player

# -----------------------------------------------------------------------------
# Override Methods
# -----------------------------------------------------------------------------
func _ready() -> void:
	_rng = RandomNumberGenerator.new()
	_rng.randomize()
	
	_timer = Timer.new()
	add_child(_timer)
	_timer.one_shot = false
	_timer.connect("timeout", self, "_on_heartbeat")

# -----------------------------------------------------------------------------
# Private Methods
# -----------------------------------------------------------------------------
func _AddNewChunk(use_base : bool = false) -> void:
	var chunk_object : PackedScene = null
	if use_base:
		var idx : int = _rng.randi_range(0, BASE_LIST.size() - 1)
		chunk_object = BASE_LIST[idx]
	else:
		var idx : int = _rng.randi_range(0, CHUNK_LIST.size() - 1)
		chunk_object = CHUNK_LIST[idx]
	
	var chunk : Node2D = chunk_object.instance()
	if chunk and chunk.has_method("drop"):
		if _last_chunk == null:
			chunk.position = Vector2(0.0, OS.window_size.y - chunk.height)
		else:
			chunk.position = _last_chunk.position - Vector2(0.0, chunk.height)
		add_child(chunk)
		connect("drop", chunk, "drop")
		chunk.connect("max_height_reached", self, "_on_max_height_reached", [chunk])
		_last_chunk = chunk


func _DropChunk(chunk : Node2D) -> void:
	if chunk is Node2D and chunk.has_method("drop"):
		if is_connected("drop", chunk, "drop"):
			disconnect("drop", chunk, "drop")
		remove_child(chunk)
		chunk.queue_free()

# -----------------------------------------------------------------------------
# Public Methods
# -----------------------------------------------------------------------------
func fill_level() -> void:
	_AddNewChunk(true)
	if _last_chunk == null:
		printerr("Failed to instance a base chunk.")
		return
	if not _last_chunk.has_player_start():
		printerr("Base Chunk missing player start.")
		clear()
		return
	
	_player_node.position = _last_chunk.get_player_start()
	while _last_chunk.position.y > 0.0:
		_AddNewChunk()
	_timer.start(1.0)

func clear() -> void:
	_timer.stop()
	_last_chunk = null
	for child in get_children():
		_DropChunk(child)
	_player_node.position = Vector2(-500.0, 0.0) # Position is semi-arbutrary

# -----------------------------------------------------------------------------
# Handler Methods
# -----------------------------------------------------------------------------
func _on_max_height_reached(chunk : Node2D) -> void:
	_DropChunk(chunk)
	_AddNewChunk()

func _on_heartbeat() -> void:
	emit_signal("drop", 40, 0.0)

func _on_game(restart : bool) -> void:
	if restart:
		clear()
	if _last_chunk == null:
		fill_level()

