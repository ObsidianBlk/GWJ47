extends StaticBody2D
tool

# -----------------------------------------------------------------------------
# Constants
# -----------------------------------------------------------------------------
const COLOR_PURE_DAMAGE : Color = Color.darkorange
const COLOR_PURE_CRIT : Color = Color.red

const BEAT_TIME : float = 0.5

# -----------------------------------------------------------------------------
# Export Variables
# -----------------------------------------------------------------------------
export var color : Color = Color.slategray				setget set_color
export var size : Vector2 = Vector2(64, 64)				setget set_size
export var immortal : bool = false

# -----------------------------------------------------------------------------
# Variables
# -----------------------------------------------------------------------------
var _max_hp : float = 0.0
var _hp : float = 0.0
var _damaged_hp : float = 0.0
var _critical_hp : float = 0.0

var _beat_timer : float = -1.0

# -----------------------------------------------------------------------------
# Onready Variables
# -----------------------------------------------------------------------------
onready var coll_node : CollisionShape2D = $CollisionShape2D

# -----------------------------------------------------------------------------
# Setters / Getters
# -----------------------------------------------------------------------------
func set_color(c : Color) -> void:
	color = c
	_CalculateColor()
	#update()

func set_size(s : Vector2) -> void:
	if s.x > 0.0 and s.y > 0.0:
		size = s
		update()
		_UpdateCollisionShape()

func set_immortal(i : bool) -> void:
	immortal = i
	#get_material().set_shader_param("immortal", immortal);

# -----------------------------------------------------------------------------
# Override Methods
# -----------------------------------------------------------------------------
func _ready() -> void:
	_UpdateHP(true)
	_UpdateCollisionShape()

func _enter_tree() -> void:
	var parent = get_parent()
	if parent != null:
		if parent.has_signal("pulsed"):
			parent.connect("pulsed", self, "beat_pulse")

func _physics_process(delta : float) -> void:
	_UpdateBeatTimer(delta)

func _draw() -> void:
	draw_rect(Rect2(-(size * 0.5), size), Color.white, true)
#	var c : Color = color
#	var color_damage : Color = lerp(color, COLOR_PURE_DAMAGE, 0.4)
#	var color_critical : Color = lerp(color, COLOR_PURE_CRIT, 0.6)
#	if not Engine.editor_hint:
#		if _hp >= _damaged_hp:
#			var max_dist = _max_hp - _damaged_hp
#			var dist = _hp - _damaged_hp
#			c = lerp(color, color_damage, 1.0 - (dist / max_dist))
#		elif _hp >= _critical_hp:
#			var max_dist = _max_hp - _critical_hp
#			var dist = _hp - _critical_hp
#			c = lerp(color_damage, color_critical, 1.0 - (dist / max_dist))
#		else:
#			c = color_critical
#	draw_rect(Rect2(-(size * 0.5), size), c, true)
#	if immortal:
#		draw_rect(Rect2(-(size * 0.5), size), Color.black, false, 4.0, true)

# -----------------------------------------------------------------------------
# Private Methods
# -----------------------------------------------------------------------------
func _DisconnectPulse() -> void:
	var parent = get_parent()
	if parent != null:
		if parent.has_signal("pulsed"):
			if parent.is_connected("pulsed", self, "beat_pulse"):
				parent.disconnect("pulsed", self, "beat_pulse")

func _CalculateColor(pulse_amount : float = 0.0):
	var c : Color = color
	var color_damage : Color = lerp(color, COLOR_PURE_DAMAGE, 0.4)
	var color_critical : Color = lerp(color, COLOR_PURE_CRIT, 0.6)
	if not Engine.editor_hint and _max_hp > 0.0:
		if _hp >= _damaged_hp:
			var max_dist = _max_hp - _damaged_hp
			if max_dist == 0.0:
				max_dist = 1.0
			var dist = _hp - _damaged_hp
			c = lerp(color, color_damage, 1.0 - (dist / max_dist))
		elif _hp >= _critical_hp:
			var max_dist = _max_hp - _critical_hp
			if max_dist == 0.0:
				max_dist = 1.0
			var dist = _hp - _critical_hp
			c = lerp(color_damage, color_critical, 1.0 - (dist / max_dist))
		else:
			c = color_critical
	modulate = Color(pulse_amount, pulse_amount, pulse_amount, 0.0) + c

func _UpdateCollisionShape() -> void:
	if coll_node:
		coll_node.shape.extents = size * 0.5

func _UpdateHP(match_up : bool = false) -> void:
	var prev_match : bool = _max_hp == _hp
	
	_max_hp = (size.x * size.y) * 0.1
	if _max_hp < _hp or prev_match or match_up:
		_hp = _max_hp
	
	_damaged_hp = _max_hp * 0.75
	_critical_hp = _max_hp * 0.2

func _UpdateBeatTimer(amount : float) -> void:
	if _beat_timer >= 0.0:
		if _beat_timer < 0.0:
			_CalculateColor(0.0)
		else:
			_beat_timer -= amount
			_CalculateColor(max(0.0, _beat_timer / BEAT_TIME));

# -----------------------------------------------------------------------------
# Public Methods
# -----------------------------------------------------------------------------
func beat_pulse() -> void:
	if not immortal:
		_beat_timer = BEAT_TIME


func get_rect() -> Rect2:
	return Rect2(position - (size * 0.5), size)

func get_global_rect() -> Rect2:
	return Rect2(global_position - (size * 0.5), size)

func hurt(amount : float) -> void:
	if not immortal:
		_hp -= amount
		if _hp < 0.0:
			var score = int(max(1.0, (size.x * size.y) / 2000.0))
			Game.add_to_score(score)
			_DisconnectPulse()
			queue_free()
		else:
			get_material().set_shader_param("intensity", (1.0 - (_hp / _max_hp)) * 0.5);


func intersects(r : Rect2, use_global : bool = false) -> bool:
	var srect : Rect2 = get_rect()
	if use_global:
		srect = get_global_rect()
	return srect.intersects(r)

func intersects_surface(s : Node2D, use_global : bool = false) -> bool:
	if s.has_method("intersects"):
		if use_global:
			return intersects(s.get_global_rect(), true)
		return intersects(s.get_rect())
	return false

