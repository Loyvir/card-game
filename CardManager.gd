extends Node2D

const COLLISION_MASK_CARD = 1
const COLLISION_MASK_CARD_SLOT = 2

var screen_size
var card_being_dragged = null
var current_hovered_card = null
var original_z_index = 0

# A counter to track how many card areas the mouse is currently inside.
# This makes the logic for overlapping cards efficient.
var card_hover_count = 0


func _ready() -> void:
	screen_size = get_viewport_rect().size
	# Find all nodes in the "cards" group and connect to their signals
	var cards = get_tree().get_nodes_in_group("cards")
	for card in cards:
		card.hovered.connect(_on_card_hovered)
		card.hovered_off.connect(_on_card_hovered_off)


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


# --- NEW SIGNAL HANDLERS ---
# These functions just update the counter.
func _on_card_hovered(card):
	card_hover_count += 1

func _on_card_hovered_off(card):
	card_hover_count -= 1


# --- THE REST OF THE CODE IS THE SAME ---

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.is_pressed():
			# This now correctly uses the hovered card identified in _process
			if is_instance_valid(current_hovered_card):
				start_drag(current_hovered_card)
		else:
			finish_drag()


func start_drag(card):
	card_being_dragged = card
	original_z_index = card.z_index
	card.z_index = 100
	highlight_card(card, false) # Un-highlight when dragging starts


func finish_drag():
	# Only run ANY of this logic if a card is actually being dragged.
	if is_instance_valid(card_being_dragged):
		card_being_dragged.z_index = original_z_index
		var card_slot_found = raycast_check_for_card_slot()
		
		# Check if we dropped it on a valid, empty slot
		if card_slot_found and not card_slot_found.card_in_slot:
			# Snap the card to the slot's position
			card_being_dragged.position = card_slot_found.position
			# Disable the card's collision so it can't be picked up again (optional)
			card_being_dragged.get_node("Area2D/CollisionShape2D").disabled = true
			# Mark the slot as occupied
			card_slot_found.card_in_slot = true
		
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
		card.scale = Vector2(1.05, 1.05)
		card.z_index = 2 # Assumes default is 1
	else:
		card.scale = Vector2(1, 1)
		card.z_index = 1
