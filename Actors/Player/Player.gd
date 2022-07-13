extends KinematicBody2D
tool

# -----------------------------------------------------------------------------
# Signals
# -----------------------------------------------------------------------------
signal stamina_updated(stamina, max_stamina)
signal dash_updated(power_accum, power_max)

# -----------------------------------------------------------------------------
# Constants and ENUMs
# -----------------------------------------------------------------------------
enum STATE {Idle=0, Moving=1, Air=2, Jump=3, Dash=4}
enum DASH {Charge=0, Release=1}

# -----------------------------------------------------------------------------
# Export Variables
# -----------------------------------------------------------------------------
export var color : Color = Color.lawngreen				setget set_color
export var size : Vector2 = Vector2(64, 64)				setget set_size

export var accel : float = 1000.0						setget set_accel
export var max_speed : float = 1000.0					setget set_max_speed
export var max_jump_height : float = 300.0				setget set_max_jump_height
export var half_jump_dist : float = 500.0				setget set_half_jump_dist
export var fall_multiplier : float = 2.0				setget set_fall_multiplier

export var dash_strength : float = 400.0				setget set_dash_strength
export var max_stamina : float = 500.0					setget set_max_stamina
export var stamina_regen : float = 250.0				setget set_stamina_regen


# -----------------------------------------------------------------------------
# Variables
# -----------------------------------------------------------------------------
var _velocity : Vector2 = Vector2.ZERO
var _direction : Vector2 = Vector2.ZERO

var _stamina : float = 0.0

var _jump_strength : float = 0.0
var _gravity : float = 0.0

var _dash_state = DASH.Release
var _dash_accum : float = 0.0

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

func set_max_jump_height(h : float) -> void:
	if h > 0.0:
		max_jump_height = h
		_CalculateJumpVariables()

func set_half_jump_dist(d : float) -> void:
	if d > 0.0:
		half_jump_dist = d
		_CalculateJumpVariables()

func set_max_speed(s : float) -> void:
	if s > 0.0:
		max_speed = s
		_CalculateJumpVariables()

func set_accel(a : float) -> void:
	if a > 0.0:
		accel = a

func set_fall_multiplier(m : float) -> void:
	if m > 0.0:
		fall_multiplier = m

func set_dash_strength(d : float) -> void:
	if d > 0.0:
		dash_strength = d

func set_max_stamina(s : float) -> void:
	if s > 0.0:
		max_stamina = s

func set_stamina_regen(s : float) -> void:
	if s > 0.0:
		stamina_regen = s

# -----------------------------------------------------------------------------
# Override Methods
# -----------------------------------------------------------------------------
func _ready() -> void:
	_CalculateJumpVariables()
	_stamina = max_stamina
	emit_signal("stamina_updated", _stamina, max_stamina)


func _draw() -> void:
	draw_rect(Rect2(-(size * 0.5), size), color, true, 1.0, false)


func _unhandled_input(event : InputEvent) -> void:
	_HandleMoveEvents(event)
	match _state:
		STATE.Idle, STATE.Moving:
			_HandleJumpEvents(event)
			_HandleDashEvent(event)
		STATE.Air, STATE.Dash:
			_HandleDashEvent(event)
		STATE.Jump:
			_HandleJumpEvents(event)


func _physics_process(delta : float) -> void:
	if Engine.editor_hint:
		return
	
	if _size_dirty:
		_size_dirty = false
		groundray_node.position = Vector2(0, size.y * 0.5)
	
	_UpdateStamina(stamina_regen * delta)
	if _state == STATE.Dash:
		_ProcessDash(delta)
	else:
		_ProcessVelocity_v(delta)
		_ProcessVelocity_h(delta)
		_velocity = move_and_slide_with_snap(_velocity, Vector2.DOWN, Vector2.UP, true)
		_ProcessGroundRayStates()

# -----------------------------------------------------------------------------
# Private Methods
# -----------------------------------------------------------------------------
func _CalculateJumpVariables() -> void:
	# NOTE: The idea for this came from...
	# https://youtu.be/hG9SzQxaCm8
	_jump_strength = (2 * max_jump_height * max_speed) / half_jump_dist
	_gravity = (2 * max_jump_height * pow(max_speed, 2)) / pow(half_jump_dist, 2)


func _ProcessDash(delta : float) -> void:
	match _dash_state:
		DASH.Charge:
			if _UpdateStamina(-(dash_strength * 0.3) * delta):
				_UpdateDashRay()
				_dash_accum = min(_dash_accum + (dash_strength * delta), dash_strength)
				#print("Dash Accum: ", _dash_accum)
				emit_signal("dash_updated", _dash_accum, dash_strength)
			else:
				_ProcessGroundRayStates()
		DASH.Release:
			emit_signal("dash_updated", 0.0, dash_strength)
			if _direction.length_squared() > 0.0:
				if dashray_node.is_colliding():
					var obj = dashray_node.get_collider()
					if obj and obj.has_method("hurt"):
						obj.hurt(_dash_accum)
					var pos = dashray_node.get_collision_point()
					global_position = pos - (_direction.normalized() * (size * 0.5))
				else:
					#print("Dash Accum: ", _dash_accum)
					global_position += _direction.normalized() * _dash_accum
			else:
				pass # TODO: Maybe some powered explosion!
			_velocity = Vector2.ZERO
			dashray_node.cast_to = Vector2.ZERO
			_ProcessGroundRayStates()

func _ProcessVelocity_v(delta : float) -> void:
	if _state == STATE.Jump and _velocity.y >= 0.0:
		_velocity.y = -_jump_strength
	else:
		var multiplier = fall_multiplier if (_state == STATE.Air or _velocity.y >= 0.0) else 1.0
		_velocity.y += _gravity * multiplier * delta

func _ProcessVelocity_h(delta : float) -> void:
	if _direction.length_squared() > 0.0:
		if sign(_direction.x) != sign(_velocity.x):
			_velocity.x *= 0
		_velocity.x += max(-max_speed, min(_direction.x * accel * delta, max_speed))
	else:
		_velocity.x = lerp(_velocity.x, 0.0, 0.1)


func _ProcessGroundRayStates() -> void:
	if _state != STATE.Jump and groundray_node.is_colliding():
		_state = STATE.Idle if abs(_velocity.x) < 0.1 else STATE.Moving
	elif _state == STATE.Dash or _velocity.y >= 0.0:
		_state = STATE.Air
		if _velocity.y < 0.0:
			_velocity.y = 0.0


func _HandleMoveEvents(event : InputEvent) -> void:
	if event.is_action("left") or event.is_action("right"):
		_direction.x = Input.get_action_strength("right") - Input.get_action_strength("left")
	elif event.is_action("up") or event.is_action("down"):
		_direction.y = Input.get_action_strength("down") - Input.get_action_strength("up")

func _HandleJumpEvents(event : InputEvent) -> void:
	if event.is_action_pressed("jump") and _UpdateStamina(-(_jump_strength * 0.1)):
		_state = STATE.Jump
	elif event.is_action_released("jump") and _state == STATE.Jump:
		_state = STATE.Air

func _HandleDashEvent(event : InputEvent) -> void:
	if event.is_action_pressed("dash") and _state != STATE.Dash and _UpdateStamina(-(dash_strength * 0.5)):
		_state = STATE.Dash
		_dash_state = DASH.Charge
		_dash_accum = 0.0
	elif event.is_action_released("dash"):
		if _dash_state == DASH.Charge:
			_dash_state = DASH.Release

func _UpdateDashRay() -> void:
	if _direction.length_squared() <= 0.0:
		dashray_node.cast_to = Vector2(0.01, 0.0)
	dashray_node.cast_to = _direction.normalized() * _dash_accum

func _UpdateStamina(amount : float) -> bool:
	if amount < 0.0 and abs(amount) > _stamina:
		return false
	_stamina = max(0.0, min(_stamina + amount, max_stamina))
	emit_signal("stamina_updated", _stamina, max_stamina)
	return true


# -----------------------------------------------------------------------------
# Public Methods
# -----------------------------------------------------------------------------
func is_in_air() -> bool:
	return [STATE.Jump, STATE.Air, STATE.Dash].find(_state) >= 0

# -----------------------------------------------------------------------------
# Handler Methods
# -----------------------------------------------------------------------------


