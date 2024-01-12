class_name HandContainer
extends HandContainerPrivate
# Public class for HandContainer

# loop through cards and set appropriate neighbour buttons for keyboard/controller use
func _update_card_focus_neighbors() -> void:
	var cards = _cards.get_children()
	var index = 0
	var size = cards.size()

	for card in cards:
		var current_button = card.find_node("Button")
		var next = index + 1
		var prev = index - 1
		var next_path = NodePath("")
		var prev_path = NodePath("")

		if next < size && _cards.get_child(next) != null:
			var next_button = _cards.get_child(next).find_node("Button")
			next_path = next_button.get_path()
#		else:
#			print("DEBUG: no next card, current card is " + card.find_node("Name").text)
		current_button.set_focus_neighbour(MARGIN_RIGHT, next_path)

		if prev > -1 && _cards.get_child(prev) != null:
			var prev_button = _cards.get_child(prev).find_node("Button")
			prev_path = prev_button.get_path()
#		else:
#			print("DEBUG: no prev card, current card is " + card.find_node("Name").text)
		current_button.set_focus_neighbour(MARGIN_LEFT, prev_path)

		index = next
	
# override AbstractContainer._update_container to do some custom stuff
func _update_container() -> void:
	._update_container() # godot equivalent of "super"
	_update_card_focus_neighbors()
	
# also need to update neighbors when removing cards from hand
func _on_need_removal(card: AbstractCard) -> void:
	._on_need_removal(card)
	_update_card_focus_neighbors()
