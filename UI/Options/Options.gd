extends CenterContainer



# -----------------------------------------------------------------------------
# Override Methods
# -----------------------------------------------------------------------------
func _ready() -> void:
	pass

# -----------------------------------------------------------------------------
# Private Methods
# -----------------------------------------------------------------------------
func _GrabFocus() -> void:
	$Panel/Controls/TabContainer.grab_focus()

# -----------------------------------------------------------------------------
# Handler Methods
# -----------------------------------------------------------------------------
func _on_ui_requested(ui_name : String) -> void:
	if ui_name == name:
		visible = true
		_GrabFocus()
	else:
		visible = false

func _on_ui_toggle_requested(ui_name : String) -> void:
	if ui_name == name:
		visible = not visible
		if visible:
			_GrabFocus()
	else:
		visible = false

