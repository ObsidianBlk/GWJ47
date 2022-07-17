extends Node2D


# -----------------------------------------------------------------------------
# Constants
# -----------------------------------------------------------------------------
const BEATS_PER_TRANSITION : int = 4
const POSITION_LIST : Array = [ # NOTE: In a perfect world, these wouldn't be hard coded.
	Vector2(320.0, 260.0),
	Vector2(1600.0, 260.0),
	Vector2(960.0, 540.0),
	Vector2(320.0, 820.0),
	Vector2(1600.0, 820.0),
]
const POINTS : int = 100

# -----------------------------------------------------------------------------
# Export Variables
# -----------------------------------------------------------------------------


# -----------------------------------------------------------------------------
# Variables
# -----------------------------------------------------------------------------
var _active : bool = false
var _active_draw : bool = false
var _body : Node2D = null

var _rng : RandomNumberGenerator = null

# -----------------------------------------------------------------------------
# Onready Variables
# -----------------------------------------------------------------------------
onready var col : CollisionShape2D = $Area2D/CollisionShape2D
onready var sfx : AudioStreamPlayer = $SFX

# -----------------------------------------------------------------------------
# Override Methods
# -----------------------------------------------------------------------------
func _ready() -> void:
	var _res : int = Game.connect("beat", self, "_on_heartbeat")

func _draw() -> void:
	if _active_draw:
		var size : Vector2 = col.shape.extents * 2
		draw_rect(Rect2(Vector2.ZERO, size), Color.red, false, 4.0, true)

func _physics_process(_delta : float) -> void:
	if _active and _body != null:
		sfx.play()
		_body = null
		_active_draw = false
		Game.add_to_score(POINTS)
		update()

# -----------------------------------------------------------------------------
# Private Methods
# -----------------------------------------------------------------------------


# -----------------------------------------------------------------------------
# Public Methods
# -----------------------------------------------------------------------------
func set_seed(rng_seed : float) -> void:
	if _rng == null:
		_rng = RandomNumberGenerator.new()
	_rng.seed = int(rng_seed)

func deactivate() -> void:
	if _active:
		_active = false
		_active_draw = false
		update()

# -----------------------------------------------------------------------------
# Handler Methods
# -----------------------------------------------------------------------------
func _on_body_entered(body : Node2D) -> void:
	if _body == null and body.has_method("is_in_air") and _active:
		_body = body

func _on_body_exited(body : Node2D) -> void:
	if body == _body:
		_body = null

func _on_heartbeat(beat : int) -> void:
	if not Game.is_game_active() or _rng == null:
		return
	
	if beat % BEATS_PER_TRANSITION == 0:
		_active = not _active
		_active_draw = _active
		if _active:
			position = POSITION_LIST[_rng.randi_range(0, POSITION_LIST.size() - 1)]
		update()


