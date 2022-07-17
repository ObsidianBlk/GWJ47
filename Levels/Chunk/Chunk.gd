extends Node2D
tool
class_name Chunk

# -----------------------------------------------------------------------------
# Signal
# -----------------------------------------------------------------------------
signal max_height_reached()
signal pulsed()

# -----------------------------------------------------------------------------
# Constants
# -----------------------------------------------------------------------------
const SURFACE_OBJ : PackedScene = preload("res://Objects/Surface/Surface.tscn")


const SURFACE_COLORS : Array = [
	Color.blueviolet,
	Color.darkmagenta,
	Color.webpurple,
	Color.slateblue,
	Color.rebeccapurple
]

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


func _SurfaceIntersectsSurfaces(surf : Node2D) -> bool:
	for child in get_children():
		if child is Node2D and child.has_method("intersects_surface"):
			if child.intersects_surface(surf):
				return true
	return false

func _RectIntersectsSurfaces(rect : Rect2) -> bool:
	for child in get_children():
		if child is Node2D and child.has_method("intersects"):
			if child.intersects(rect):
				return true
	return false

func _GenerateSurfaceNode(pos : Vector2, size : Vector2, allow_immortal : bool = false, force_immortal : bool = false) -> Node2D:
	var surf : Node2D = SURFACE_OBJ.instance()
	if pos.y < 0.0 or pos.y + size.y > height:
		return null
	
	surf.size = size
	surf.position = pos + (size * 0.5)
	if not _SurfaceIntersectsSurfaces(surf):
		if allow_immortal:
			surf.immortal = false if not force_immortal and _rng.randf() > 0.15 else true
		surf.color = SURFACE_COLORS[_rng.randi_range(0, SURFACE_COLORS.size() - 1)]
		add_child(surf)
		return surf
	return null

# Didn't have time to do this in a better way.
func _GenerateSurface(pos : Vector2, size : Vector2, allow_immortal : bool = false, force_immortal : bool = false) -> bool:
	return _GenerateSurfaceNode(pos, size, allow_immortal, force_immortal) != null

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
		cpos += Vector2(dir_x * segment, 0.0)

func _GenerateSegmentedWall(pos : Vector2, width : float, segments : Array, dir_y : float = 1.0, allow_immortal : bool = true) -> void:
	var cpos : Vector2 = pos
	for segment in segments:
		if not _GenerateSurface(cpos, Vector2(width, segment), allow_immortal):
			break
		cpos += Vector2(0.0, dir_y * segment)

func _RandomSurfaceSize(player_size : float, width_dominant : bool = false) -> Vector2:
	var surface_unit_size : Array = [0.5, 1, 2, 4, 8]
	
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


func _RandomPosition(region : Rect2, size : Vector2, force_pure_random : bool = false) -> Vector2:
	var mode : int = 0
	if not force_pure_random:
		var mode_dist : RandomDistribution = RandomDistribution.new()
		mode_dist.set_items([
			0, 0.25,
			1, 0.5,
			2, 0.5,
			3, 0.5,
			4, 0.5
		])
		mode = mode_dist.randv(_rng)
	
	var pos = Vector2.ZERO
	match mode:
		0: # Pure Random
			if not (size.x >= region.size.x or size.y >= region.size.y):
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
	
	var region_dist : RandomDistribution = RandomDistribution.new()
	region_dist.set_items([
		Rect2(0, 0, width, hh), 0.25,
		Rect2(0, hh, width, hh), 0.25,
		Rect2(0, 0, qw, height), 0.33,
		Rect2(qw, 0, qw, height), 0.33,
		Rect2(2*qw, 0, qw, height), 0.33,
	])
	
	var base_standin_surface : Node2D = null
	if base:
		_GenerateSurface(Vector2(0, height - player_size), Vector2(width, player_size), true, true)
		var attempts : int = 10
		for _i in range(attempts):
			var region : Rect2 = region_dist.randv(_rng)
			var size : Vector2 = Vector2(player_size * 1.25, player_size * 1.25)
			var pos : Vector2 = _RandomPosition(region, size, true)
			base_standin_surface = _GenerateSurfaceNode(pos, size)
			if base_standin_surface != null:
				break
			if base_standin_surface == null:
				printerr("failed to generate a player start")
		
	
	var num_structures : int = _rng.randi_range(5, 20)
	var structure_dist : RandomDistribution = RandomDistribution.new()
	structure_dist.set_items([
		0, 0.1,
		1, 0.4,
		2, 0.6,
		3, 0.4,
		4, 0.4
	])
	
	for _i in range(num_structures):
		var region : Rect2 = region_dist.randv(_rng)
		match structure_dist.randv(_rng):
			0: # Basic Random Surface
				#print("Generating Basic Surface")
				var ssize = _RandomSurfaceSize(player_size)
				_GenerateSurface(_RandomPosition(region, ssize), ssize, true)
			1: # Basic Random Surface (Width Dominant)
				#print("Generating Basic Surface (Width Dominant)")
				var ssize = _RandomSurfaceSize(player_size, true)
				_GenerateSurface(_RandomPosition(region, ssize), ssize, true)
			2: # Segmented Platform
				#print("Generating Segmented PLatform")
				var segments : Array = []
				var segheight : float = 0.0
				for _n in range(_rng.randi_range(2, 8)):
					var size = _RandomSurfaceSize(player_size, true)
					if segheight == 0.0:
						segheight = size.y
					segments.append(size.x)
				_GenerateSegmentedPlatform(_RandomPosition(region, Vector2(segheight, segheight)), segments, segheight)
			3: # Segmented Wall
				#print("Generating Segmented Wall")
				var segments : Array = []
				var segwidth : float = 0.0
				for _n in range(_rng.randi_range(2, 8)):
					var size = _RandomSurfaceSize(player_size)
					if segwidth == 0.0:
						segwidth = size.x
					segments.append(size.y)
				_GenerateSegmentedWall(_RandomPosition(region, Vector2(segwidth, segwidth)), segwidth, segments)
			4: # Stairs
				#print("Generating Stairs")
				var steps : int = _rng.randi_range(2, 8)
				var dir : Vector2 = Vector2(
					1 if _rng.randf() < 0.5 else -1,
					1 if _rng.randf() < 0.5 else -1
				)
				var size = _RandomSurfaceSize(player_size)
				var pos = _RandomPosition(region, size)
				_GenerateStair(pos, size, steps, dir)
			5: # Cuboid
				pass
	
	if base_standin_surface != null:
		var pos2D : Position2D = Position2D.new()
		add_child(pos2D)
		pos2D.name = "Player_Start"
		pos2D.position = base_standin_surface.position
		remove_child(base_standin_surface)
		base_standin_surface.queue_free()

func pulse() -> void:
	emit_signal("pulsed")


func has_player_start() -> bool:
	return _GetPlayerStartNode() != null

func get_player_start() -> Vector2:
	var ps : Node2D = _GetPlayerStartNode()
	if ps != null:
		return ps.position
	return Vector2.ZERO
