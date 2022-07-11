extends Control

# -----------------------------------------------------------------------------
# Signals
# -----------------------------------------------------------------------------
signal ui_requested(ui_name)
signal enter_game()

# -----------------------------------------------------------------------------
# Export Variables
# -----------------------------------------------------------------------------
export var start_visible : bool = false


# -----------------------------------------------------------------------------
# Override Methods
# -----------------------------------------------------------------------------
func _ready() -> void:
	visible = start_visible

# -----------------------------------------------------------------------------
# Private Methods
# -----------------------------------------------------------------------------
func _GrabFocus() -> void:
	$MC/VBC/Options/Buttons/EnterGame.grab_focus()

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

func _on_GWJ_pressed():
	emit_signal("ui_requested", "GWJ47")


func _on_Quit_pressed():
	get_tree().quit()


func _on_EnterGame_pressed():
	emit_signal("enter_game")
