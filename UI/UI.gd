extends CanvasLayer

# -----------------------------------------------------------------------------
# Signals
# -----------------------------------------------------------------------------
signal ui_requested(ui_name)
signal ui_toggle_requested(ui_name)

# -----------------------------------------------------------------------------
# Export Variables
# -----------------------------------------------------------------------------
export var initial_menu : String = ""

# -----------------------------------------------------------------------------
# Variables
# -----------------------------------------------------------------------------
var _menu_stack : Array = []

# -----------------------------------------------------------------------------
# Override Methods
# -----------------------------------------------------------------------------
func _ready() -> void:
	_ConnectToUI()
	if initial_menu != "":
		request_ui(initial_menu)


func _unhandled_input(event : InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if _menu_stack.size() > 1:
			close_ui()

# -----------------------------------------------------------------------------
# Private Methods
# -----------------------------------------------------------------------------
func _ConnectToUI() -> void:
	for child in get_children():
		if child.has_signal("ui_requested"):
			child.connect("ui_requested", self, "request_ui")
		if child.has_method("_on_ui_requested"):
			connect("ui_requested", child, "_on_ui_requested")
		if child.has_method("_on_ui_toggle_requested"):
			connect("ui_toggle_requested", child, "_on_ui_toggle_requested")

# -----------------------------------------------------------------------------
# Public Methods
# -----------------------------------------------------------------------------
func request_ui(ui_name : String) -> void:
	var idx : int = _menu_stack.find(ui_name)
	if idx >= 0:
		_menu_stack = _menu_stack.slice(0, idx)
	else:
		if ui_name != "":
			_menu_stack.append(ui_name)
		else:
			_menu_stack.clear()
	emit_signal("ui_requested", ui_name)

func close_ui() -> void:
	if _menu_stack.size() >= 1:
		_menu_stack.pop_back()
		emit_signal("ui_requested", _menu_stack[_menu_stack.size() - 1])
	else:
		_menu_stack.clear()
		emit_signal("ui_toggle_requested", "")

# -----------------------------------------------------------------------------
# Handler Methods
# -----------------------------------------------------------------------------

