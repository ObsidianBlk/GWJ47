extends Node2D
tool

# -----------------------------------------------------------------------------
# Signal
# -----------------------------------------------------------------------------
signal max_height_reached()

# -----------------------------------------------------------------------------
# Export Variables
# -----------------------------------------------------------------------------
export var height : float = 540.0
export var max_positional_height : float = 1080.0

# -----------------------------------------------------------------------------
# Variables
# -----------------------------------------------------------------------------
var tween_node : Tween = null


# -----------------------------------------------------------------------------
# Setters
# -----------------------------------------------------------------------------
func set_height(h : float) -> void:
	if h > 0.0:
		height = h
		update()

# -----------------------------------------------------------------------------
# Override Methods
# -----------------------------------------------------------------------------
func _ready() -> void:
	if Engine.editor_hint:
		set_process(false)
	tween_node = Tween.new()
	add_child(tween_node)
	update()

func _draw() -> void:
	if Engine.editor_hint:
		draw_rect(Rect2(0, 0, 1920, height), Color.cyan, false, 1.0, true)

func _process(_delta : float) -> void:
	if position.y >= max_positional_height:
		emit_signal("max_height_reached")

# -----------------------------------------------------------------------------
# Private Methods
# -----------------------------------------------------------------------------
func _GetPlayerStartNode() -> Node2D:
	for child in get_children():
		if child.name == "Player_Start":
			return child
	return null

# -----------------------------------------------------------------------------
# Public Methods
# -----------------------------------------------------------------------------
func drop(amount : float, duration : float) -> void:
	if Engine.editor_hint or amount <= 0.0:
		return
	
	print("Dropping: ", amount)
	
	if duration > 0.0:
		if tween_node.is_active():
			tween_node.remove_all()
		tween_node.interpolate_property(
			self, "position",
			position, position + Vector2(0, amount),
			duration,
			Tween.TRANS_LINEAR, Tween.EASE_IN_OUT
		)
		tween_node.start()
	else:
		position += Vector2(0, amount)

func pause(enable : bool = true) -> void:
	if not Engine.editor_hint:
		if enable:
			tween_node.resume_all()
		else:
			tween_node.stop_all()

func has_player_start() -> bool:
	return _GetPlayerStartNode() != null

func get_player_start() -> Vector2:
	var ps : Node2D = _GetPlayerStartNode()
	if ps != null:
		return ps.position
	return Vector2.ZERO
