extends Node2D

var player_deck = ["Soldier", "Archer", "Demon", "Soldier", "Soldier", "Archer", "Soldier", "Archer", "Soldier"]
var card_database_refrence

const CARD_SCENE_PATH = "res://Scenes/Card.tscn"
const CARD_DRAW_SPEED = 0.2 
const STARTING_HAND_SIZE = 5

var drawn_card_this_turn = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	player_deck.shuffle()
	$RichTextLabel.text = str(player_deck.size())
	card_database_refrence = preload("res://Scripts/CardDatabase.gd")
	for i in range(STARTING_HAND_SIZE):
		draw_card();
		drawn_card_this_turn = false
	drawn_card_this_turn = true
	 

 

func draw_card():
	if drawn_card_this_turn:
		return
	
	drawn_card_this_turn = true
	var card_drawn_name = player_deck[0]
	player_deck.erase(card_drawn_name)
	
	if player_deck.size() == 0:
		$Area2D/CollisionShape2D.disabled = true
		$Sprite2D.visible = false 
		$RichTextLabel.visible = false
		 
	$RichTextLabel.text = str(player_deck.size())
	var card_scene = preload(CARD_SCENE_PATH)
	var new_card = card_scene.instantiate()
	var card_image_path =str("res://assets/images/cards/" + card_drawn_name + "Card.png")
	new_card.get_node("CardImage").texture = load(card_image_path)
	new_card.get_node("Attack").text = str(card_database_refrence.CARDS[card_drawn_name][0])
	new_card.get_node("Health").text = str(card_database_refrence.CARDS[card_drawn_name][1])
	var card_manager = get_node("../CardManager")
 
	card_manager.add_child(new_card)
	card_manager.register_card(new_card)
 
	new_card.name = "Card"
	$"../PlayerHand".add_card_to_hand(new_card, CARD_DRAW_SPEED)
	new_card.get_node("AnimationPlayer").play("card_flip")
