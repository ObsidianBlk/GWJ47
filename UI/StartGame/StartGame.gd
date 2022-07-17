extends CenterContainer

signal enter_game(game_seed)

var _last_seed_text : String = ""

onready var _seed_line : LineEdit = $Panel/Controls/Seed/LineEdit

func _ready() -> void:
	visible = false
	randomize()
	_seed_line.text = String(randi())

func _GrabFocus() -> void:
	$Panel/Controls/Play.grab_focus()


func _on_ui_requested(ui_name : String) -> void:
	if ui_name == name:
		visible = true
		if _last_seed_text != "":
			_seed_line.text = _last_seed_text
		else:
			_seed_line.text = String(int(rand_range(0.0, 10000.0)))
		_GrabFocus()
	elif visible:
		visible = false

func _on_ui_toggle_requested(ui_name : String) -> void:
	if ui_name == name:
		visible = not visible
		if visible:
			_seed_line.text = String(int(rand_range(0.0, 10000.0)))
			_GrabFocus()
	elif visible:
		visible = false


func _on_Refresh_pressed():
	_seed_line.text = String(int(rand_range(0.0, 10000.0)))


func _on_Play_pressed():
	var game_seed : float = 0.0
	if _seed_line.text == "":
		game_seed = floor(rand_range(0.0, 10000.0))
	else:
		_last_seed_text = _seed_line.text
		if _seed_line.text.is_valid_integer():
			game_seed = float(_seed_line.text.to_int())
		else:
			game_seed = float(_seed_line.text.hash())
	emit_signal("enter_game", game_seed)

