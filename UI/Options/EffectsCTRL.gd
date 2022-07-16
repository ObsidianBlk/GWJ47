extends Control

# -----------------------------------------------------------------------------
# Onready Variables
# -----------------------------------------------------------------------------
onready var btn_pulse : CheckButton = $PulseCtrls/BTN_Pulse

onready var btn_glow : CheckButton = $GlowCtrls/BTN_Glow
onready var hs_glow_intensity : HSlider = $GlowCtrls/HSlider

# -----------------------------------------------------------------------------
# Override Methods
# -----------------------------------------------------------------------------
func _ready() -> void:
	Game.connect("beat_pulse_state_changed", self, "_on_pulse_state_changed")
	btn_pulse.pressed = Game.is_beat_pulse_enabled()
	btn_pulse.connect("toggled", self, "_on_pulse_toggled")
	
	Game.connect("glow_state_changed", self, "_on_glow_state_changed")
	btn_glow.pressed = Game.is_glow_enabled()
	btn_glow.connect("toggled", self, "_on_glow_toggled")
	
	hs_glow_intensity.value = Game.get_glow_intensity() * 100.0
	hs_glow_intensity.connect("value_changed", self, "_on_glow_intensity_changed")


# -----------------------------------------------------------------------------
# Handler Methods
# -----------------------------------------------------------------------------
func _on_pulse_state_changed(enabled : bool) -> void:
	btn_pulse.pressed = enabled

func _on_pulse_toggled(pressed : bool) -> void:
	Game.enable_beat_pulse(pressed)

func _on_glow_state_changed(glow_enabled : bool, glow_intensity : float) -> void:
	btn_glow.pressed = glow_enabled
	hs_glow_intensity.value = glow_intensity * 100.0

func _on_glow_toggled(pressed : bool) -> void:
	Game.enable_glow_effect(pressed)

func _on_glow_intensity_changed(value : float) -> void:
	Game.set_glow_intensity(value * 0.1)

