extends Node2D

# Define the custom signals the card can emit
signal hovered(card)
signal hovered_off(card)

var card_hand_position
var card_in_slot
var card_type

func _ready() -> void:
	# Add this node to the "cards" group so the main scene can identify it
	add_to_group("cards")

# These are connected to the mouse_entered/exited signals of your Area2D node
# in the Godot editor's "Node" tab.

func _on_area_2d_mouse_entered() -> void:
	# When the mouse enters this card's area, emit the 'hovered' signal
	emit_signal("hovered", self)

func _on_area_2d_mouse_exited() -> void:
	# When the mouse leaves, emit the 'hovered_off' signal
	emit_signal("hovered_off", self)
