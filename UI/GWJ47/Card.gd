extends TextureRect

# -----------------------------------------------------------------------------
# Signals
# -----------------------------------------------------------------------------
signal transition_finished()

# -----------------------------------------------------------------------------
# Export Variables
# -----------------------------------------------------------------------------
export var reference : NodePath = ""
export var enabled : bool = true
export (float, 0.0, 180.0) var max_angle_degree : float = 5.0		setget set_max_angle_degree
export (float, 0.0, 1.0) var angle_variance : float = 0.1
export var angle_dps : float = 2.0									setget set_angle_dps
export var max_v_drift : float = 20.0								setget set_max_v_drift
export (float, 0.0, 1.0) var drift_variance : float = 0.1
export var drift_pps : float = 10.0									setget set_drift_pps

# -----------------------------------------------------------------------------
# Variables
# -----------------------------------------------------------------------------
var _is_visible : bool = false
var _viz_transition : bool = false
var _is_fullview : bool = false
var _origin : Vector2 = Vector2.ZERO
var _out_vector : Vector2 = Vector2.UP


var _target : Vector2 = Vector2.ZERO
var _target_rot : float = 0.0

var _drift_enabled : bool = false
var _angle_enabled : bool = false

var _tween_drift : Tween = null
var _tween_rot : Tween = null
var _tween_scale : Tween = null

# -----------------------------------------------------------------------------
# Onready Variables
# -----------------------------------------------------------------------------
onready var _rng : RandomNumberGenerator = RandomNumberGenerator.new()

# -----------------------------------------------------------------------------
# Setters
# -----------------------------------------------------------------------------
func set_max_angle_degree(d : float) -> void:
	if d >= 0.0 and d <= 180.0:
		max_angle_degree = d

func set_angle_dps(d : float) -> void:
	if d >= 0.0:
		angle_dps = d

func set_max_v_drift(d : float) -> void:
	if d >= 0.0:
		max_v_drift = d

func set_drift_pps(s : float) -> void:
	if s > 0.0:
		drift_pps = s

# -----------------------------------------------------------------------------
# Override Methods
# -----------------------------------------------------------------------------
func _ready() -> void:
	show_behind_parent = true
	_rng.randomize()
	_target = Vector2(_origin.x, sign(_rng.randf_range(-1.0, 1.0)) * _origin.y)
	_target_rot = _rng.randf_range(-1.0, 1.0)
	
	_tween_drift = Tween.new()
	add_child(_tween_drift)
	var _res : int = _tween_drift.connect("tween_all_completed", self, "_on_drift_tween_complete")
	
	_tween_rot = Tween.new()
	add_child(_tween_rot)
	_res = _tween_rot.connect("tween_all_completed", self, "_on_angle_tween_complete")
	
	_tween_scale = Tween.new()
	add_child(_tween_scale)
	
	_ResizeToRef(true)



# -----------------------------------------------------------------------------
# Private Methods
# -----------------------------------------------------------------------------
func _GetRef() -> Control:
	var ref = get_node_or_null(reference)
	if ref is Control:
		return ref
	return null

func _ResizeToRef(updateOutVector : bool = false) -> void:
	var ref : Control = _GetRef()
	if ref:
		if not ref.is_connected("resized", self, "_on_ref_resized"):
			ref.connect("resized", self, "_on_ref_resized")
			if ref is Button:
				ref.connect("focus_entered", self, "_on_focus_entered")
				ref.connect("mouse_entered", self, "_on_focus_entered")
				ref.connect("focus_exited", self, "_on_focus_exited")
				ref.connect("mouse_exited", self, "_on_focus_exited")
				ref.connect("pressed", self, "_on_pressed")
				ref.connect("gui_input", self, "_on_gui_input")
		rect_size = ref.rect_size
		rect_pivot_offset = rect_size * 0.5
		if updateOutVector:
			if name == "Theme":
				print("Pos: ", rect_global_position)
				print("Ref: ", ref.rect_global_position)
			_out_vector = ref.rect_global_position.direction_to(rect_global_position).normalized()
			if name == "Theme":
				print("Out Vec: ", _out_vector)
		var dist : float = max(OS.window_size.x, OS.window_size.y)
		_origin = ref.rect_global_position + (_out_vector * dist)
		if not _is_visible:
			rect_position = _origin
		else:
			_tween_drift.remove_all()
			rect_position = ref.rect_global_position
			if _drift_enabled:
				call_deferred("_UpdateDrift")

func _TweenPositionTo(from : Vector2, target : Vector2, duration : float) -> void:
	if not _tween_drift.is_inside_tree():
		return
	
	var _res : int = _tween_drift.remove_all()
	_res = _tween_drift.interpolate_property(
		self, "rect_position",
		from, target,
		duration,
		Tween.TRANS_LINEAR, Tween.EASE_IN_OUT
	)
	_res = _tween_drift.start()

func _TweenAngleTo(angle : float, duration : float) -> void:
	if not _tween_rot.is_inside_tree():
		return
	
	var _res : int = _tween_rot.remove_all()
	_res = _tween_rot.interpolate_property(
		self, "rect_rotation",
		rect_rotation, angle,
		duration,
		Tween.TRANS_LINEAR, Tween.EASE_IN_OUT
	)
	_res = _tween_rot.start()

func _UpdateDrift() -> void:
	var ref : Control = _GetRef()
	if not _is_visible or ref == null:
		return
	
	var ty : float = max_v_drift - _rng.randf_range(0, max_v_drift * drift_variance)
	ty *= 1 if ref.rect_global_position.y > _target.y else -1
	_target = Vector2(ref.rect_global_position.x, ref.rect_global_position.y + ty)
	var dur : float = abs(rect_position.y - _target.y) / drift_pps
	_TweenPositionTo(rect_position, _target, dur)

func _UpdateAngle() -> void:
	var new_target : float = max_angle_degree - _rng.randf_range(0, max_angle_degree * angle_variance)
	new_target *= 1 if _target_rot < 0.0 else -1
	_target_rot = new_target
	var dur : float = abs(rect_rotation - _target_rot) / angle_dps
	_TweenAngleTo(_target_rot, dur)

func _FullView(enable : bool = true) -> void:
	if not enabled or enable == _is_fullview:
		return
	
	_is_fullview = enable
	if _is_fullview:
		show_behind_parent = false
		_tween_drift.remove_all()
		_tween_rot.remove_all()
		_drift_enabled = false
		_angle_enabled = false
		var parent = get_parent()
		if parent != null:
			_tween_scale.remove_all()
			_tween_scale.interpolate_property(
				self, "rect_size",
				rect_size, parent.rect_size,
				0.25, 
				Tween.TRANS_LINEAR, Tween.EASE_IN_OUT
			)
			_tween_scale.start()
			_TweenPositionTo(rect_position, Vector2.ZERO, 0.25)
		_TweenAngleTo(0, 0.25)
	else:
		show_behind_parent = true
		var ref : Control = _GetRef()
		if not ref:
			return
		
		_tween_scale.remove_all()
		_tween_scale.interpolate_property(
			self, "rect_size",
			rect_size, ref.rect_size,
			0.25, 
			Tween.TRANS_LINEAR, Tween.EASE_IN_OUT
		)
		_tween_scale.start()
		_TweenPositionTo(rect_position, ref.rect_global_position, 0.25)

# -----------------------------------------------------------------------------
# Public Methods
# -----------------------------------------------------------------------------
func show(enable : bool = true, instant : bool = false) -> void:
	var ref : Control = _GetRef()
	if ref == null or _is_visible == enable:
		call_deferred("emit_signal", "transition_finished")
		return
	
	var total_dist : float = _origin.distance_to(ref.rect_global_position)
	if total_dist == 0.0:
		total_dist = 1.0
	if enable:
		if instant:
			rect_position = ref.rect_global_position
		else:
			_viz_transition = true
			var dist : float = rect_position.distance_to(ref.rect_global_position)
			_TweenPositionTo(rect_position, ref.rect_global_position, dist / total_dist)
		_is_visible = true
	else:
		_tween_scale.remove_all()
		if rect_size != ref.rect_size:
			rect_size = ref.rect_size
		if instant:
			_tween_drift.remove_all()
			_tween_rot.remove_all()
			rect_position = _origin
			rect_rotation = 0
		else:
			_viz_transition = true
			var dist : float = rect_position.distance_to(_origin)
			_TweenPositionTo(rect_position, _origin, dist / total_dist)
			_TweenAngleTo(0, abs(rect_rotation) / angle_dps)
		_is_visible = false
		_drift_enabled = false
		_angle_enabled = false
	
	if not _viz_transition:
		#print("Emitting Deferred Transition Finished")
		call_deferred("emit_signal", "transition_finished")


# -----------------------------------------------------------------------------
# Handler Methods
# -----------------------------------------------------------------------------
func _on_drift_tween_complete() -> void:
	if _viz_transition:
		emit_signal("transition_finished")
	if _drift_enabled:
		_UpdateDrift()
		if _angle_enabled and rect_rotation == 0.0:
			_UpdateAngle()


func _on_angle_tween_complete() -> void:
	if _angle_enabled:
		_UpdateAngle()

func _on_ref_resized() -> void:
	_ResizeToRef()

func _on_focus_entered() -> void:
	if _is_visible:
		_drift_enabled = true
		_angle_enabled = true
		_UpdateDrift()

func _on_focus_exited() -> void:
	if _is_visible:
		_FullView(false)
		_drift_enabled = false
		_angle_enabled = false
		var ref : Control = _GetRef()
		if ref:
			_TweenPositionTo(rect_position, ref.rect_global_position, 0.25)
			_TweenAngleTo(0, 0.25)

func _on_pressed() -> void:
	_FullView()

func _on_gui_input(event : InputEvent) -> void:
	if _is_fullview:
		if event.is_action_pressed("ui_cancel"):
			_FullView(false)


