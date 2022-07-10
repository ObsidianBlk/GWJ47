extends Node

# -----------------------------------------------------------------------------
# Constants
# -----------------------------------------------------------------------------
const DEFAULT_LEVEL : String = "res://Levels/TestLevel/TestLevel.tscn"

# -----------------------------------------------------------------------------
# Variables
# -----------------------------------------------------------------------------
var _world_node : Node2D = null
var _active_level : Node2D = null

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
	
	for child in get_tree().root.get_children():
		if child.name == "World":
			_world_node = child
			break
	
	if _world_node == null:
		printerr("Failed to find the World node.")

# -----------------------------------------------------------------------------
# Public Methods
# -----------------------------------------------------------------------------
func load_level(src : String) -> void:
	var Level = load(src)
	if not Level:
		printerr("Failed to load level ", src)
		return
	
	if _active_level != null:
		_world_node.remove_child(_active_level)
		_active_level.queue_free()
		_active_level = null
	
	_active_level = Level.instance()
	if _active_level:
		_world_node.add_child(_active_level)

func is_game_active() -> bool:
	return _active_level != null


