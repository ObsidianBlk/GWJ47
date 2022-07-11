extends KinematicBody2D
tool

# -----------------------------------------------------------------------------
# Signals
# -----------------------------------------------------------------------------
signal dash_updated(power_accum, power_max, time)

# -----------------------------------------------------------------------------
# Constants and ENUMs
# -----------------------------------------------------------------------------
enum STATE {Idle=0, Moving=1, Air=2, Jump=3, Dash=4}

# -----------------------------------------------------------------------------
# Export Variables
# -----------------------------------------------------------------------------
export var color : Color = Color.lawngreen				setget set_color
export var size : Vector2 = Vector2(64, 64)				setget set_size
export var max_speed : float = 1000.0					setget set_max_speed
export var accel : float = 1000.0						setget set_accel
export var gravity : float = 800.0						setget set_gravity
export var jump_strength : float = 1000.0				setget set_jump_strength
export var dash_dist : float = 400.0					setget set_dash_dist


# -----------------------------------------------------------------------------
# Variables
# -----------------------------------------------------------------------------
var _velocity : Vector2 = Vector2.ZERO
var _direction : Vector2 = Vector2.ZERO

var _dash_timer : float = -1.0
var _dash_powering : bool = false
var _dash_dist_accum : float = 0.0

var _size_dirty : bool = true
var _state : int = STATE.Idle


# -----------------------------------------------------------------------------
# Onready Variables
# -----------------------------------------------------------------------------
onready var groundray_node : RayCast2D = $GroundRay
onready var dashray_node : RayCast2D = $DashRay

# -----------------------------------------------------------------------------
# Setter / Getter
# -----------------------------------------------------------------------------
func set_size(s : Vector2) -> void:
	if s.x > 0.0 and s.y > 0.0:
		size = s
		_size_dirty = true
		update()

func set_color(c : Color) -> void:
	color = c
	update()

func set_max_speed(s : float) -> void:
	if s > 0.0:
		max_speed = s

func set_accel(a : float) -> void:
	if a > 0.0:
		accel = a

func set_gravity(g : float) -> void:
	if g >= 0.0:
		gravity = g

func set_jump_strength(j : float) -> void:
	if j > 0.0:
		jump_strength = j

func set_dash_dist(d : float) -> void:
	if d > 0.0:
		dash_dist = d

# -----------------------------------------------------------------------------
# Override Methods
# -----------------------------------------------------------------------------

func _draw() -> void:
	draw_rect(Rect2(-(size * 0.5), size), color, true, 0.0, false)


func _unhandled_input(event : InputEvent) -> void:
	_HandleMoveEvents(event)
	match _state:
		STATE.Idle, STATE.Moving:
			_HandleJumpEvents(event)
			_HandleDashEvent(event)
		STATE.Air, STATE.Dash:
			_HandleDashEvent(event)


func _physics_process(delta : float) -> void:
	if Engine.editor_hint:
		return
	
	if _dash_timer >= 0.0:
		if _dash_timer > 2.0:
			_SetDashParams(false)
			_ProcessGroundRayStates()
		else:
			_dash_timer += delta
	
	if _size_dirty:
		_size_dirty = false
		groundray_node.position = Vector2(0, size.y * 0.5)
	
	if _state == STATE.Dash:
		if _dash_powering:
			_UpdateDashRay()
			_dash_dist_accum = min(_dash_dist_accum + (dash_dist * delta), dash_dist)
			emit_signal("dash_updated", _dash_dist_accum, dash_dist, 0.0 if _dash_timer < 0.0 else (_dash_timer/2.0))
		else:
			emit_signal("dash_updated", 0.0, dash_dist, 0.0)
			if _direction.length_squared() > 0.0:
				if dashray_node.is_colliding():
					var pos = dashray_node.get_collision_point()
					global_position = pos - (_direction.normalized() * (size * 0.5))
				else:
					global_position += _direction.normalized() * _dash_dist_accum
			else:
				pass # TODO: Maybe some powered explosion!
			_velocity = Vector2.ZERO
			dashray_node.cast_to = Vector2.ZERO
			_SetDashParams(false)
			_ProcessGroundRayStates()
	else:
		if _state == STATE.Jump:
			_velocity.y = -jump_strength
		else:
			_velocity.y += gravity * delta
		
		if _direction.length_squared() > 0.0:
			if sign(_direction.x) != sign(_velocity.x):
				_velocity.x *= 0
			_velocity.x += _direction.x * accel * delta
			if _velocity.length() > max_speed:
				_velocity = _velocity.normalized() * max_speed
		else:
			_velocity.x = lerp(_velocity.x, 0.0, 0.1)
		
		_velocity = move_and_slide_with_snap(_velocity, Vector2.DOWN, Vector2.UP, true)
		_ProcessGroundRayStates()

# -----------------------------------------------------------------------------
# Private Methods
# -----------------------------------------------------------------------------
func _ProcessGroundRayStates() -> void:
	if groundray_node.is_colliding():
		_state = STATE.Idle if abs(_velocity.x) < 0.1 else STATE.Moving
	else:
		_state = STATE.Air


func _HandleMoveEvents(event : InputEvent) -> void:
	if event.is_action("left") or event.is_action("right"):
		_direction.x = Input.get_action_strength("right") - Input.get_action_strength("left")
	elif event.is_action("up") or event.is_action("down"):
		_direction.y = Input.get_action_strength("down") - Input.get_action_strength("up")

func _HandleJumpEvents(event : InputEvent) -> void:
	if event.is_action_pressed("jump"):
		_state = STATE.Jump

func _HandleDashEvent(event : InputEvent) -> void:
	if event.is_action_pressed("dash"):
		print("Dash attempt")
		if _dash_timer < 0.0:
			print("Dash Powering")
			_state = STATE.Dash
			_SetDashParams(true)
	elif event.is_action_released("dash"):
		_dash_powering = false

func _UpdateDashRay() -> void:
	if _direction.length_squared() <= 0.0:
		dashray_node.cast_to = Vector2(0.01, 0.0)
	dashray_node.cast_to = _direction.normalized() * _dash_dist_accum

func _SetDashParams(enabled : bool = true) -> void:
	_dash_dist_accum = 0.0
	if enabled:
		_dash_timer = 0.0
		_dash_powering = true
	else:
		_dash_timer = -1.0
		_dash_powering = false

#func _UpdateDashRay_vec() -> void:
#	if _velocity.length_squared() <= 0.0:
#		dashray_node.cast_to = Vector2.ZERO
#	dashray_node.cast_to = _velocity.normalized() * dash_dist

# -----------------------------------------------------------------------------
# Public Methods
# -----------------------------------------------------------------------------


# -----------------------------------------------------------------------------
# Handler Methods
# -----------------------------------------------------------------------------


