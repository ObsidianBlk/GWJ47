extends CenterContainer

# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const WIN_MESSAGE : String = "You Outlasted the Level!!"
const LOOSE_MESSAGE : String = "You Have Fallen to Oblivion!"

# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
onready var title_label : Label = $Panel/VBC/Title
onready var score_label : Label = $Panel/VBC/Score/ScoreLabel

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	visible = false
	Game.connect("game_finished", self, "_on_game_finished")


# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_game_finished(win : bool, score : int) -> void:
	print("Win: ", win)
	title_label.text = WIN_MESSAGE if win else LOOSE_MESSAGE
	score_label.text = String(score)

func _on_ui_requested(ui_name : String) -> void:
	if ui_name == name:
		visible = true
	elif visible:
		visible = false

func _on_ui_toggle_requested(ui_name : String) -> void:
	if ui_name == name:
		visible = not visible
	elif visible:
		visible = false

