extends Object
class_name RandomDistribution


# -----------------------------------------------------------------------------
# Variables
# -----------------------------------------------------------------------------
var _seed : float = 0.0
var _items : Array = []
var _total_weight : float = 0.0
var _dirty : bool = true

var _rng : RandomNumberGenerator = null

# -----------------------------------------------------------------------------
# Override Methods
# -----------------------------------------------------------------------------
func _init(rng_seed : float = 0.0, items : Array = []) -> void:
	_seed = rng_seed
	_rng = RandomNumberGenerator.new()
	_rng.seed = _seed
	add_items(items)

# -----------------------------------------------------------------------------
# Public Methods
# -----------------------------------------------------------------------------
func item_count() -> int:
	return _items.size()

func item_chance(idx : int) -> float:
	if _dirty:
		precalculate()
	
	if idx >= 0 and idx < _items.size():
		return _items[idx].chance
	return 0.0

func item_value(idx : int):
	if idx >= 0 and idx < _items.size():
		return _items[idx].value
	return null

func item_weight(idx : int) -> float:
	if idx >= 0 and idx < _items.size():
		return _items[idx].weight
	return 0.0

func add_item(value, weight : float) -> int:
	# Appends the given item to the distribution list.
	if weight < 0.0:
		printerr("Weight expected to be a value greater than 0.0")
		return ERR_PARAMETER_RANGE_ERROR

	_items.append({
		"value":value,
		"weight":weight,
		"chance": 0.0
	})
	
	_total_weight += weight
	_dirty = true
	
	return OK

func add_items(items : Array) -> int:
	# Appends items to the distribution list
	# <items> expected to be in the form [<item_value_1>, <item_weight_1>, ...]
	var value = null
	for item in items:
		if value == null:
			value = item
		else:
			var res : int = add_item(value, item)
			if res != OK:
				return res
			value = null
	
	return OK


func set_items(items : Array) -> void:
	# Clears previous distribution and starts a new distribution with the given items
	# <items> expected to be in the form [<item_val_1>, <item_weight_1>, ...]
	clear()
	add_items(items)

func set_item_weight(idx : int, weight : float) -> void:
	if weight <= 0.0:
		printerr("Weight value expected to be greater than zero.")
		return
	
	if idx >= 0 and idx < _items.size():
		_total_weight -= _items[idx].weight
		_total_weight += weight
		_items[idx].weight = weight
		_dirty = true

func set_seed(rng_seed : float) -> void:
	_seed = rng_seed
	_rng.seed = _seed

func clear() -> void:
	_items.clear()
	_total_weight = 0.0
	_dirty = true

func reset() -> void:
	_rng.seed = _seed

func precalculate() -> void:
	var accum : float = 0.0
	for item in _items:
		accum += item.weight
		item.chance = accum / _total_weight
	_dirty = false

func randv(rng_override : RandomNumberGenerator = null):
	var rng = _rng if rng_override == null else rng_override
	if _dirty:
		precalculate()
	var r = rng.randf()
	for item in _items:
		if item.chance > r:
			return item.value
	return null

