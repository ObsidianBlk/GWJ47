extends Node2D


func _ready() -> void:
	$Player.connect("dash_updated", self, "_on_dash_update")


func _on_dash_update(power : float, power_max : float, timer : float) -> void:
	pass#print("Power: ", power / power_max, " | Timer: ", timer)
