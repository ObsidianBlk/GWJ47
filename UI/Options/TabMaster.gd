extends TabContainer
# This exists to try to give better control of TabContainers when a Joypad or
# even Keyboard have control.

# NOTE: for the Joypad, a Joypad Button should be defined for the
# ui_focus_next and ui_focus_prev events.

# -----------------------------------------------------------------------------
# Override Methods
# -----------------------------------------------------------------------------
func _ready() -> void:
	var _res : int = connect("tab_changed", self, "_on_tab_changed")
	_res = connect("gui_input", self, "_on_gui_input")

func _input(event : InputEvent) -> void:
	# This is a horrible hack which I think runs the risk of breaking more
	# complex project. Might break this one too, but don't have the time for
	# a proper testing
	_on_gui_input(event)


# -----------------------------------------------------------------------------
# Private Methods
# -----------------------------------------------------------------------------
func _AutoGrabFocus(container : Control) -> int:
	for child in container.get_children():
		if child is Container:
			if _AutoGrabFocus(child) == OK:
				return OK
		elif child.focus_mode != FOCUS_NONE:
			child.grab_focus()
			return OK
	return ERR_DOES_NOT_EXIST

# -----------------------------------------------------------------------------
# Public Methods
# -----------------------------------------------------------------------------
func next_tab() -> void:
	print("Next Tab")
	var count : int = get_tab_count()
	var next_id : int = current_tab + 1
	if next_id < count:
		current_tab = next_id
		_AutoGrabFocus(get_tab_control(next_id))

func prev_tab() -> void:
	print("Prev Tab")
	var prev_id : int = current_tab - 1
	if prev_id >= 0:
		current_tab = prev_id
		_AutoGrabFocus(get_tab_control(prev_id))

func grab_focus() -> void:
	var _res : int = _AutoGrabFocus(get_current_tab_control())

# -----------------------------------------------------------------------------
# Handler Methods
# -----------------------------------------------------------------------------
func _on_tab_changed(id : int) -> void:
	var _res : int = _AutoGrabFocus(get_tab_control(id))

func _on_gui_input(event : InputEvent) -> void:
	if event.is_action_pressed("ui_focus_next"):
		next_tab()
	if event.is_action_pressed("ui_focus_prev"):
		prev_tab()
