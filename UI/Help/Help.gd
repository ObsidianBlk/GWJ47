extends CenterContainer

# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
onready var song_attribs : RichTextLabel = $PanelContainer/TabContainer/Attributions

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	visible = false
	Game.connect("music_info_loaded", self, "_SongAttribs")
	_SongAttribs()

func _SongAttribs() -> void:
	var bbtext : String = "[color=aqua][u][b]Music, Author, Attributions[/b][/u][/color]\n\n"
	var count = Game.music_track_count()
	for i in range(count):
		var info = Game.get_music_track_info(i)
		bbtext += "[b][color=silver]\"%s\"[/color][/b] by: [color=silver]%s[/color]\n(%s)\n\n"%[info.name, info.author, info.http]
	song_attribs.bbcode_text = bbtext

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
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
