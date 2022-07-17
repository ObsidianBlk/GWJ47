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
# Onready Variables
# -----------------------------------------------------------------------------
onready var title_node : Control = $MC/VBC/Options/Title
onready var start_btn : Button = $MC/VBC/Options/Panel/Buttons/EnterGame

# -----------------------------------------------------------------------------
# Override Methods
# -----------------------------------------------------------------------------
func _ready() -> void:
	visible = start_visible

# -----------------------------------------------------------------------------
# Private Methods
# -----------------------------------------------------------------------------
func _GrabFocus() -> void:
	$MC/VBC/Options/Panel/Buttons/EnterGame.grab_focus()

# -----------------------------------------------------------------------------
# Handler Methods
# -----------------------------------------------------------------------------
func _on_ui_requested(ui_name : String) -> void:
	if ui_name == name:
		visible = true
		_GrabFocus()
		if Game.is_game_active():
			start_btn.text = "Resume Game"
			title_node.visible = false
		else:
			start_btn.text = "Start Game"
			title_node.visible = true
	else:
		visible = false

func _on_ui_toggle_requested(ui_name : String) -> void:
	if ui_name == name:
		visible = not visible
		if visible:
			_GrabFocus()
			if Game.is_game_active():
				start_btn.text = "Resume Game"
				title_node.visible = false
			else:
				start_btn.text = "Start Game"
				title_node.visible = true
	else:
		visible = false

func _on_GWJ_pressed():
	emit_signal("ui_requested", "GWJ47")


func _on_Quit_pressed():
	get_tree().quit()


func _on_EnterGame_pressed():
	if Game.is_game_active():
		emit_signal("enter_game", 0.0)
	else:
		emit_signal("ui_requested", "StartGame")


func _on_Options_pressed():
	emit_signal("ui_requested", "Options")


func _on_Help_pressed():
	emit_signal("ui_requested", "Help")
