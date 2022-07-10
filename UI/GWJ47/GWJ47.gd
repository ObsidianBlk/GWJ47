extends Control

# -----------------------------------------------------------------------------
# Export Variables
# -----------------------------------------------------------------------------
export var start_visible : bool = false

# -----------------------------------------------------------------------------
# Variables
# -----------------------------------------------------------------------------
var _timer : Timer = null
var _is_visible : bool = false
var _transitioning_cards : Dictionary = {}

# -----------------------------------------------------------------------------
# Onready Variables
# -----------------------------------------------------------------------------
onready var anim_node : AnimationPlayer = $AnimationPlayer

# -----------------------------------------------------------------------------
# Override Methods
# -----------------------------------------------------------------------------
func _ready() -> void:
	if (start_visible and not _is_visible) or (not start_visible and _is_visible):
		_ShowUI(true)
	else:
		anim_node.play("idle_shown" if _is_visible else "idle_hidden")

# -----------------------------------------------------------------------------
# Private Methods
# -----------------------------------------------------------------------------
func _ShowUI(instant : bool = false) -> void:
	# TODO: There's a bug here... fix me
	if _transitioning_cards.empty():
		#print("Transition Cards Empty")
		_is_visible = not _is_visible
		if _is_visible:
			#print("Making Visible")
			visible = true
			anim_node.play("show" if not instant else "idle_shown")
		else:
			var anim : String = "hide" if not instant else "idle_hidden"
			#print("Hiding GWJ: ", anim, " | ", instant)
			anim_node.play(anim)


func _ShowCards(enable : bool = true, instant : bool = false) -> void:
	var nlist = get_tree().get_nodes_in_group("GWJ_Card")
	for n in nlist:
		if n.has_method("show"):
			n.connect("transition_finished", self, "_on_card_transition_finished", [n])
			_transitioning_cards[n.name] = n
			n.show(enable, instant)

# -----------------------------------------------------------------------------
# Handler Methods
# -----------------------------------------------------------------------------
func _on_card_transition_finished(card) -> void:
	if card.name in _transitioning_cards:
		_transitioning_cards.erase(card.name)
		if _transitioning_cards.empty():
			if not _is_visible:
				visible = false
	else:
		printerr("Card transitioned but not stored.")
	card.disconnect("transition_finished", self, "_on_card_transition_finished")

func _on_ui_requested(ui_name : String) -> void:
	if ui_name == name:
		if not _is_visible:
			_ShowUI()
	elif _is_visible:
		_ShowUI()

func _on_ui_toggle_requested(ui_name : String) -> void:
	if ui_name == name:
		_ShowUI()
	elif _is_visible:
		_ShowUI()
