extends Node2D


const COLLISION_MASK_CARD = 1
const COLLISION_MASK_CARD_SLOT = 2
const DEFAULT_CARD_MOVE_SPEED = 0.1
const DEFAULT_CARD_SCALE = 0.5
const CARD_HOVER_SCALE = 0.55
const CARD_SMALLER_SCALE = 0.4

var screen_size
var card_being_dragged = null
var current_hovered_card = null
var original_z_index = 0
var player_hand_reference
var played_card_this_turn = false

# A counter to track how many card areas the mouse is currently inside.
# This makes the logic for overlapping cards efficient.
var card_hover_count = 0


func _ready() -> void:
	screen_size = get_viewport_rect().size
	player_hand_reference = $"../PlayerHand"
	$"../InputManager".connect("left_mouse_button_released", on_left_click_released)

	var cards = get_tree().get_nodes_in_group("cards")
	for card in cards:
		register_card(card)


func _process(delta: float) -> void:
	# Drag logic remains the same
	if is_instance_valid(card_being_dragged):
		var mouse_position = get_global_mouse_position()
		card_being_dragged.position = Vector2(
			clamp(mouse_position.x, 0, screen_size.x),
			clamp(mouse_position.y, 0, screen_size.y)
		)
		return # Stop processing hover logic while dragging

	# --- HYBRID HOVER LOGIC ---
	# Only run the hover check if the mouse is inside at least one card's area.
	if card_hover_count > 0:
		var top_card = raycast_check_for_card()
		# Check if the top-most card has changed since the last frame
		if top_card != current_hovered_card:
			# Un-highlight the old card (if it exists)
			if is_instance_valid(current_hovered_card):
				highlight_card(current_hovered_card, false)
			
			# Set the new card and highlight it
			current_hovered_card = top_card
			if is_instance_valid(current_hovered_card):
				highlight_card(current_hovered_card, true)
	else:
		# If the mouse isn't over any card, make sure nothing is highlighted
		if is_instance_valid(current_hovered_card):
			highlight_card(current_hovered_card, false)
			current_hovered_card = null


func on_left_click_released(): 
	if card_being_dragged:
		finish_drag()

func _on_card_hovered(card):
	card_hover_count += 1

func _on_card_hovered_off(card):
	card_hover_count -= 1

func start_drag(card):
	card_being_dragged = card
	original_z_index = card.z_index
	card.z_index = 100
	highlight_card(card, false)


func finish_drag():
	# Only run ANY of this logic if a card is actually being dragged.
	if is_instance_valid(card_being_dragged):
		card_being_dragged.z_index = -1
		var card_slot_found = raycast_check_for_card_slot()
		
		# Check if we dropped it on a valid, empty slot
		if card_slot_found and not card_slot_found.card_in_slot:
			player_hand_reference.remove_card_from_hand(card_being_dragged)
			# Snap the card to the slot's position
			card_being_dragged.position = card_slot_found.position
			
			card_being_dragged.scale = Vector2(CARD_SMALLER_SCALE, CARD_SMALLER_SCALE)
			card_being_dragged.card_in_slot = card_slot_found 
			
			# Disable the card's collision so it can't be picked up again (optional)
			card_being_dragged.get_node("Area2D/CollisionShape2D").disabled = true
			# Mark the slot as occupied
			card_slot_found.card_in_slot = true
		else:
			player_hand_reference.add_card_to_hand(card_being_dragged, DEFAULT_CARD_MOVE_SPEED)
		
		# IMPORTANT: Set card_being_dragged to null AFTER all logic is done.
		card_being_dragged = null



func raycast_check_for_card_slot():
	var space_state = get_world_2d().direct_space_state
	var parameters = PhysicsPointQueryParameters2D.new()
	parameters.position = get_global_mouse_position()
	parameters.collide_with_areas = true
	parameters.collision_mask = COLLISION_MASK_CARD_SLOT
	var results = space_state.intersect_point(parameters)

	if results.size() > 0:
		return results[0].collider.get_parent()
	else:
		return null
		
		
func raycast_check_for_card():
	var space_state = get_world_2d().direct_space_state
	var parameters = PhysicsPointQueryParameters2D.new()
	parameters.position = get_global_mouse_position()
	parameters.collide_with_areas = true
	parameters.collision_mask = COLLISION_MASK_CARD
	var results = space_state.intersect_point(parameters)

	if results.size() > 0:
		return get_card_with_highest_z_index(results)
	else:
		return null

func register_card(card):
	card.hovered.connect(_on_card_hovered)
	card.hovered_off.connect(_on_card_hovered_off)
	
	
func get_card_with_highest_z_index(results):
	var highest_card = results[0].collider.get_parent()
	var highest_z = highest_card.z_index

	for i in range(1, results.size()):
		var current_card = results[i].collider.get_parent()
		if current_card.z_index > highest_z:
			highest_card = current_card
			highest_z = current_card.z_index
			
	return highest_card 


func highlight_card(card, hovered):
	if hovered:
		card.scale = Vector2(CARD_HOVER_SCALE, CARD_HOVER_SCALE)
		card.z_index = 2
	else:
		card.scale = Vector2(DEFAULT_CARD_SCALE, DEFAULT_CARD_SCALE)
		card.z_index = 1
