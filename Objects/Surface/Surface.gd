extends StaticBody2D
tool

# -----------------------------------------------------------------------------
# Export Variables
# -----------------------------------------------------------------------------
export var color : Color = Color.slategray				setget set_color
export var damaged_color : Color = Color.webgray		setget set_damaged_color
export var critical_color : Color = Color.webmaroon		setget set_critical_color
export var size : Vector2 = Vector2(64, 64)				setget set_size
export var filled : bool = true							setget set_filled
export var line_width : float = 1.0						setget set_line_width
export var hit_points : float = 100.0					setget set_hit_points
export var immortal : bool = false

# -----------------------------------------------------------------------------
# Variables
# -----------------------------------------------------------------------------
var _hp : float = 0.0
var _damaged_hp : float = 0.0
var _critical_hp : float = 0.0

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

func set_damaged_color(c : Color) -> void:
	damaged_color = c
	update()

func set_critical_color(c : Color) -> void:
	critical_color = c
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

func set_hit_points(hp : float) -> void:
	if hp >= 0.0:
		hit_points = hp

# -----------------------------------------------------------------------------
# Override Methods
# -----------------------------------------------------------------------------
func _ready() -> void:
	_hp = hit_points
	_damaged_hp = hit_points * 0.75
	_critical_hp = hit_points * 0.2
	_UpdateCollisionShape()

func _draw() -> void:
	var c : Color = color
	if not Engine.editor_hint:
		if _hp >= _damaged_hp:
			var max_dist = hit_points - _damaged_hp
			var dist = _hp - _damaged_hp
			c = lerp(color, damaged_color, 1.0 - (dist / max_dist))
		elif _hp >= _critical_hp:
			var max_dist = hit_points - _critical_hp
			var dist = _hp - _critical_hp
			c = lerp(damaged_color, critical_color, 1.0 - (dist / max_dist))
		else:
			c = critical_color
	draw_rect(Rect2(-(size * 0.5), size), c, filled, line_width, not filled)

# -----------------------------------------------------------------------------
# Private Methods
# -----------------------------------------------------------------------------
func _UpdateCollisionShape() -> void:
	if coll_node:
		coll_node.shape.extents = size * 0.5

# -----------------------------------------------------------------------------
# Public Methods
# -----------------------------------------------------------------------------
func hurt(amount : float) -> void:
	if not immortal:
		_hp -= amount
		if _hp < 0.0:
			queue_free()
		else:
			update()


