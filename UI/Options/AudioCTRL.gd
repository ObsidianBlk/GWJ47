extends GridContainer

# -----------------------------------------------------------------------------
# Variables
# -----------------------------------------------------------------------------
var _ignore_change : bool = false

# -----------------------------------------------------------------------------
# Onready Variables
# -----------------------------------------------------------------------------
onready var master_slider : HSlider = $HS_Master
onready var sfx_slider : HSlider = $HS_SFX
onready var music_slider : HSlider = $HS_Music

# -----------------------------------------------------------------------------
# Override Methods
# -----------------------------------------------------------------------------
func _ready() -> void:
	master_slider.value = Game.get_bus_volume(Game.BUS.MASTER) * 1000.0
	master_slider.connect("value_changed", self, "_on_master_changed")
	
	sfx_slider.value = Game.get_bus_volume(Game.BUS.SFX) * 1000.0
	sfx_slider.connect("value_changed", self, "_on_sfx_changed")
	
	music_slider.value = Game.get_bus_volume(Game.BUS.MUSIC) * 1000.0
	music_slider.connect("value_changed", self, "_on_music_changed")
	
	Game.connect("bus_volume_change", self, "_on_bus_volume_change")

# -----------------------------------------------------------------------------
# Handler Methods
# -----------------------------------------------------------------------------
func _on_master_changed(value : float) -> void:
	_ignore_change = true
	Game.set_bus_volume(Game.BUS.MASTER, value / 1000.0)

func _on_sfx_changed(value : float) -> void:
	_ignore_change = true
	Game.set_bus_volume(Game.BUS.SFX, value / 1000.0)

func _on_music_changed(value : float) -> void:
	_ignore_change = true
	Game.set_bus_volume(Game.BUS.MUSIC, value / 1000.0)

func _on_bus_volume_change(id : int, vol : float) -> void:
	if _ignore_change:
		_ignore_change = false
	else:
		match id:
			Game.BUS.MASTER:
				master_slider.value = vol * 1000.0
			Game.BUS.SFX:
				sfx_slider.value = vol * 1000.0
			Game.BUS.MUSIC:
				music_slider.value = vol * 1000.0

