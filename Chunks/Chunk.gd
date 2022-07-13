extends Node2D
tool
class_name Chunk

# -----------------------------------------------------------------------------
# Signal
# -----------------------------------------------------------------------------
signal max_height_reached()

# -----------------------------------------------------------------------------
# Constants
# -----------------------------------------------------------------------------
const SURFACE_OBJ : PackedScene = preload("res://Objects/Surface/Surface.tscn")

# -----------------------------------------------------------------------------
# Export Variables
# -----------------------------------------------------------------------------
export var height : float = 540.0
export var max_positional_height : float = 1080.0

# -----------------------------------------------------------------------------
# Variables
# -----------------------------------------------------------------------------
var _rng : RandomNumberGenerator

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
	update()

func _draw() -> void:
	if Engine.editor_hint:
		draw_rect(Rect2(0, 0, 1920, height), Color.cyan, false, 1.0, true)

# -----------------------------------------------------------------------------
# Private Methods
# -----------------------------------------------------------------------------
func _GetPlayerStartNode() -> Node2D:
	for child in get_children():
		if child.name == "Player_Start":
			return child
	return null

func _CreateWeightedDistArray(src : Array, dist : Array, size : int) -> Array:
	var res : Array = []
	for i in range(src.size()):
		if i >= dist.size():
			break
		var count : int = int(float(size) * dist[i])
		for _i in range(count):
			res.append(src[i])
	return res

func _SurfaceIntersectsSurfaces(surf : Node2D) -> bool:
	for child in get_children():
		if child is Node2D and child.has_method("intersects_surface"):
			if child.intersects_surface(surf):
				return true
	return false

func _GenerateSurface(pos : Vector2, size : Vector2, allow_immortal : bool = false, force_immortal : bool = false) -> bool:
	var surf : Node2D = SURFACE_OBJ.instance()
	surf.size = size
	surf.position = pos + (size * 0.5)
	if not _SurfaceIntersectsSurfaces(surf):
		if allow_immortal:
			surf.immortal = false if not force_immortal and _rng.randf() > 0.15 else true
		add_child(surf)
		return true
	return false

func _GenerateStair(pos : Vector2, size : Vector2, steps : int, dir : Vector2 = Vector2(1.0, 1.0)) -> void:
	var cpos : Vector2 = pos
	for _i in range(steps):
		if not _GenerateSurface(cpos, size, true):
			break
		cpos += dir

func _GenerateSegmentedPlatform(pos : Vector2, segments : Array, height : float, dir_x : float = 1.0, allow_immortal : bool = true) -> void:
	var cpos : Vector2 = pos
	for segment in segments:
		if not _GenerateSurface(cpos, Vector2(segment, height), allow_immortal):
			break
		cpos += Vector2(dir_x, 0.0)

func _GenerateSegmentedWall(pos : Vector2, width : float, segments : Array, dir_y : float = 1.0, allow_immortal : bool = true) -> void:
	var cpos : Vector2 = pos
	for segment in segments:
		if not _GenerateSurface(cpos, Vector2(width, segment), allow_immortal):
			break
		cpos += Vector2(0.0, dir_y)

func _RandomSurfaceSize(player_size : float, width_dominant : bool = false) -> Vector2:
	var surface_unit_size : Array = [0.5, 1, 2, 4, 8, 16]
	
	var wsus_idx : int = _rng.randi_range(0, surface_unit_size.size() - 1)
	var hsus_idx : int = -1
	if wsus_idx > 0:
		var w_dom_target = 0.9 if width_dominant else 0.5
		if _rng.randf() < w_dom_target:
			hsus_idx = _rng.randi_range(0, wsus_idx)
	if hsus_idx < 0:
		hsus_idx = _rng.randi_range(0, surface_unit_size.size() - 1)
	
	var unit : Vector2 = Vector2(surface_unit_size[wsus_idx] , surface_unit_size[hsus_idx])
	return unit * player_size


func _RandomPosition(region : Rect2, size : Vector2) -> Vector2:
	var modearr : Array = _CreateWeightedDistArray([0,1,2,3,4], [0.1, 0.25, 0.25, 0.25, 0.25], 100)
	var mode : int = modearr[_rng.randi_range(0, modearr.size() - 1)]
	
	var pos = Vector2.ZERO
	match mode:
		0: # Pure Random
			if size.x >= region.size.x or size.y >= region.size.y:
				pos = region.position + Vector2(
					_rng.randf_range(0.0, region.size.x - size.x),
					_rng.randf_range(0.0, region.size.y - size.y)
				)
		1: # Left Edge
			pos = Vector2(
				region.position.x,
				region.position.y + _rng.randf_range(0.0, region.size.y - size.y)
			)
		2: # Right Edge
			pos = Vector2(
				region.position.x + (region.size.x - size.x),
				region.position.y + _rng.randf_range(0.0, region.size.y - size.y)
			)
		3: # Top Edge
			pos = Vector2(
				region.position.x + _rng.randf_range(0.0, region.size.x - size.x),
				region.position.y
			)
		4: # Bottom Edge
			pos = Vector2(
				region.position.x + _rng.randf_range(0.0, region.size.x - size.x),
				region.position.y + (region.size.y - size.y)
			)
	
	return pos

# -----------------------------------------------------------------------------
# Public Methods
# -----------------------------------------------------------------------------
func generate(gen_seed : float, width : float, player_size : float, base : bool = false) -> void:
	if _rng == null:
		_rng = RandomNumberGenerator.new()
	_rng.seed = gen_seed
	
	var hw : float = width * 0.5
	var hh : float = height * 0.5
	var qw : float = width * 0.33
	
	var _regions : Array = [
		Rect2(0, 0, width, hh),
		Rect2(0, hh, width, hh),
		Rect2(0, 0, hw, height),
		Rect2(hw, 0, hw, height),
		Rect2(0, 0, hw, hh),
		Rect2(0, hh, hw, hh),
		Rect2(hw, 0, hw, hh),
		Rect2(hw, hh, hw, hh),
		Rect2(0, 0, qw, height),
		Rect2(qw, 0, qw, height),
		Rect2(2*qw, 0, qw, height),
		Rect2(0, 0, qw, hh),
		Rect2(0, hh, qw, hh),
		Rect2(qw, 0, qw, hh),
		Rect2(qw, hh, qw, hh),
		Rect2(2*qw, 0, qw, hh),
		Rect2(2*qw, hh, qw, hh),
	]
	
	if base:
		_GenerateSurface(Vector2(0, height - player_size), Vector2(width, player_size), true, true)
	
	var num_structures : int = _rng.randi_range(5, 20)
	var darr : Array = _CreateWeightedDistArray([0,1,2,3,4,5], [0.16, 0.16, 0.17, 0.16, 0.16], 100)
	
	for _i in range(num_structures):
		var ridx = _rng.randi_range(0, _regions.size() - 1)
		var region : Rect2 = _regions[ridx]
		var idx = _rng.randi_range(0, darr.size() - 1)
		match darr[idx]:
			0: # Basic Random Surface
				var ssize = _RandomSurfaceSize(player_size)
				_GenerateSurface(_RandomPosition(region, ssize), ssize, true)
			1: # Basic Random Surface (Width Dominant)
				var ssize = _RandomSurfaceSize(player_size, true)
				_GenerateSurface(_RandomPosition(region, ssize), ssize, true)
			2: # Segmented Platform
				var segments : Array = []
				var segheight : float = 0.0
				var total_size : float = 0.0
				for _n in range(_rng.randi_range(2, 8)):
					var size = _RandomSurfaceSize(player_size, true)
					if segheight == 0.0:
						segheight = size.y
					segments.append(size.x)
					total_size += size.x
				_GenerateSegmentedPlatform(_RandomPosition(region, Vector2(total_size, segheight)), segments, segheight)
			3: # Segmented Wall
				var segments : Array = []
				var segwidth : float = 0.0
				var total_size : float = 0.0
				for _n in range(_rng.randi_range(2, 8)):
					var size = _RandomSurfaceSize(player_size)
					if segwidth == 0.0:
						segwidth = size.x
					segments.append(size.y)
					total_size += size.y
				_GenerateSegmentedWall(_RandomPosition(region, Vector2(segwidth, total_size)), segwidth, segments)
			4: # Stairs
				pass
			5: # Cuboid
				pass
	
	# TODO: Finish the above and calculate a player start position if this chunk is intended as a base.




func has_player_start() -> bool:
	return _GetPlayerStartNode() != null

func get_player_start() -> Vector2:
	var ps : Node2D = _GetPlayerStartNode()
	if ps != null:
		return ps.position
	return Vector2.ZERO
