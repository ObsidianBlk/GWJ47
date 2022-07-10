extends StaticBody2D
tool

# -----------------------------------------------------------------------------
# Export Variables
# -----------------------------------------------------------------------------
export var color : Color = Color.slategray				setget set_color
export var size : Vector2 = Vector2(64, 64)				setget set_size
export var filled : bool = true
export var line_width : float = 1.0


# -----------------------------------------------------------------------------
# Onready Variables
# -----------------------------------------------------------------------------
onready var coll_node : CollisionShape2D = $CollisionShape2D

# -----------------------------------------------------------------------------
# Setters / Getters
# -----------------------------------------------------------------------------
func set_color(c : Color) -> void:
	color = c
	update()

func set_size(s : Vector2) -> void:
	if s.x > 0.0 and s.y > 0.0:
		size = s
		update()
		_UpdateCollisionShape()

func set_filled(f : bool) -> void:
	filled = f
	update()

func set_line_width(w : float) -> void:
	if w >= 0.0:
		line_width = w
		update()

# -----------------------------------------------------------------------------
# Override Methods
# -----------------------------------------------------------------------------
func _ready() -> void:
	_UpdateCollisionShape()

func _draw() -> void:
	draw_rect(Rect2(-(size * 0.5), size), color, filled, line_width, not filled)

# -----------------------------------------------------------------------------
# Private Methods
# -----------------------------------------------------------------------------
func _UpdateCollisionShape() -> void:
	if coll_node:
		coll_node.shape.extents = size * 0.5