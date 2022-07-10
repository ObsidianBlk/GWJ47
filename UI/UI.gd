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
	if event.is_action_pressed("ui_cancel") and _menu_stack.size() > 1:
		if _menu_stack.size() > 1:
			close_ui()
		elif _menu_stack.size() <= 0 and initial_menu != "" and not Game.is_game_active():
			request_ui(initial_menu)
	elif event.is_action_pressed("game_escape") and Game.is_game_active():
		if get_tree().paused:
			get_tree().paused = false
			request_ui("")
		elif initial_menu != "":
			get_tree().paused = true
			request_ui(initial_menu)

# -----------------------------------------------------------------------------
# Private Methods
# -----------------------------------------------------------------------------
func _ConnectToUI() -> void:
	for child in get_children():
		if child.has_signal("ui_requested"):
			child.connect("ui_requested", self, "request_ui")
		if child.has_signal("enter_game"):
			child.connect("enter_game", self, "_on_enter_game")
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
func _on_enter_game() -> void:
	get_tree().paused = false
	request_ui("")
	if not Game.is_game_active():
		Game.load_level(Game.DEFAULT_LEVEL)
