extends Control


onready var song_info_label : Label = $Info/MC/HBC/Song
onready var score_label : Label = $Info/MC/HBC/Score/ScoreLabel

func _ready() -> void:
	visible = false
	Game.connect("music_playing", self, "_on_music_playing")
	Game.connect("game_started", self, "_on_game_started")
	Game.connect("game_finished", self, "_on_game_finished")
	Game.connect("score_changed", self, "_on_score_changed")


func _on_music_playing(info : Dictionary) -> void:
	song_info_label.text = "\"%s\" by: %s"%[info.name, info.author]

func _on_game_started(game_seed : float) -> void:
	visible = true

func _on_game_finished(win : bool, score : int) -> void:
	visible = false

func _on_score_changed(score : int) -> void:
	score_label.text = String(score)

