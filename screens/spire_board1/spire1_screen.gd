extends AbstractScreen

const STARTING_HAND_SIZE: int = 5
const MAX_HAND_SIZE: int = 10
const MAX_MANA: int = 3

var _hand: CardHand = CardHand.new()
var _draw_pile: CardPile = CardPile.new()
var _discard_pile: CardPile = CardPile.new()
var _library_pile: CardPile = CardPile.new()
var _mana: int = MAX_MANA

onready var _hand_cont = $HandZone/HandContainer
onready var _end_turn = $ManaBar/EndTurnBtn
onready var _draw_count = $DeckZone/VBox/DrawCount
onready var _discard_count = $DiscardZone/VBox/DiscardCount
onready var _hand_delay = $StartingHandDelay
onready var _drop_area = $DropArea
onready var _cards_visual = $HandZone/HandContainer/DropArea/Cards

onready var _mana_label = $ManaBar/Amount
onready var _player_hp_label = $PlayerStats/HP/Amount
onready var _player_block_label = $PlayerStats/Block/Amount

# view deck/discard/exhaust piles with a scrollable grid view
onready var _library = $LibNode2D
onready var _lib_scroll = $LibNode2D/LibraryBG/LibraryScroll
onready var _lib_cont = $LibNode2D/LibraryBG/LibraryScroll/LibraryContainer

var _player = {"hp": 70, "block": 0}
var _e1_stats = {"hp": 22, "block": 0, "intent": {"damage": 6, "block": 0} }
var _e2_stats = {"hp": 10, "block": 6, "intent": {"damage": 4, "block": 6} }

onready var _enemy1 = $Enemy1
onready var _enemy1_drop = $Enemy1/Drop
onready var _enemy2 = $Enemy2
onready var _enemy2_drop = $Enemy2/Drop


func _ready() -> void:
	# connect piles from containers to relevant functions
	# warning-ignore:return_value_discarded
	_draw_pile.connect("changed", self, "_on_DrawPile_changed")
	# warning-ignore:return_value_discarded
	_discard_pile.connect("changed", self, "_on_DiscardPile_changed")
	# warning-ignore:return_value_discarded
	_hand.connect("changed", self, "_on_Hand_changed")
	
	# set params for enemies and connect enemy drop area to handler for playing cards
	_enemy1.init(_e1_stats)
	_enemy1_drop.connect("dropped", self, "_on_Enemy1Drop_dropped")
	_enemy2.init(_e2_stats)
	_enemy2_drop.connect("dropped", self, "_on_Enemy2Drop_dropped")
	
	_drop_area.set_source_filter(["hand"])
	_enemy1_drop.set_source_filter(["hand"])
	_enemy2_drop.set_source_filter(["hand"])
	
	# TODO: instead of using all cards by default, should use an actual test deck for demo?
	if Gameplay.current_deck == null:
		var db = CardEngine.db().get_database("main")
		_draw_pile.populate_all(db)
	else:
		Gameplay.current_deck.copy_cards(_draw_pile)

	_draw_pile.shuffle()
	_hand_cont.set_store(_hand)
	_update_stats()
	
	# used for library view of deck/discard/exhaust piles
	_lib_cont.set_store(_library_pile)
	
	# EXPERIMENTAL, button workaround to focus/play cards with keyboard/controller
#	for i in range(_card_hbox.get_child_count()):
#		_card_hbox.get_child(i).connect('pressed', self, '_on_CardBtn_pressed', [_card_hbox.get_child(i)]) 
#		_card_hbox.get_child(i).connect('focus_entered', self, '_on_CardBtn_focus_entered', [_card_hbox.get_child(i)]) 
#		_card_hbox.get_child(i).connect('focus_exited', self, '_on_CardBtn_focus_exited', [_card_hbox.get_child(i)]) 
	
	# main drop area is for cards that target player or all enemies
	# enemy drops target that specific enemy, but also allow targeting player/all, so no filter
	var q_player_drop = Query.new()
	q_player_drop.from(["target:player", "target:all_enemy"])
	_drop_area.set_filter(q_player_drop)
	
	# TODO: need some way of targeting drop areas with keyboard/controller
		

func _update_stats() -> void:
	_mana_label.text = str(_mana)
	_player_hp_label.text = str(_player.hp)
	_player_block_label.text = str(_player.block)
	
	_enemy1.update_display()
	_enemy2.update_display()


func _on_MenuBtn_pressed() -> void:
	emit_signal("next_screen", "menu")

func _on_DrawPile_changed() -> void:
	_draw_count.text = "%d" % _draw_pile.count()

func _on_DiscardPile_changed() -> void:
	_discard_count.text = "%d" % _discard_pile.count()

func _on_Hand_changed() -> void:
	# originally was code to disable draw button here if max hand size, but have removed draw button
	pass
	

func _on_StartingHandDelay_timeout() -> void:
	var card = _draw_pile.draw()

	# if deck is empty, shuffle discard into deck and draw again
	if card == null:
		_discard_pile.move_cards(_draw_pile)
		_draw_pile.shuffle()
		card = _draw_pile.draw()
	
	# we've somehow exhausted the entire deck!
	if card == null:
		return
	
	_hand.add_card(card)

	if _hand.count() >= STARTING_HAND_SIZE:
		_hand_delay.stop()
		
		# grab focus end turn button - later maybe try to start focus on first card, but only if
		# a key has been pressed? idk, needs polish, keyboard/controller mode is unfinished
		_end_turn.grab_focus()
	else:
		_hand_delay.start(0.5)


#func _on_DrawBtn_pressed() -> void:
#	var card = _draw_pile.draw()
#	if card == null:
#		return
#	_hand.add_card(card)

#func _on_ReshuffleBtn_pressed() -> void:
#	_discard_pile.move_cards(_draw_pile)
#	_draw_pile.shuffle()


func _damage_player(damage: int) -> void:
	var post_block_damage = damage
	#print("DEBUG: incoming damage = " + str(damage) + ", block = " + str(target.block))
	if (_player.block > 0):
		post_block_damage -= _player.block
		_player.block -= damage
	if (_player.block < 0):
		_player.block = 0
	if (post_block_damage > 0):
		_player.hp -= post_block_damage
	#print("DEBUG: post block damage = " + str(post_block_damage) + ", block = " + str(target.block))


func _on_EndTurnBtn_pressed() -> void:
	# discard
	_hand.move_cards(_discard_pile)
	
	# TODO: enemy turn, to split off into own method/class later
	# just doing an example with the 2 demo enemies with static intent
	# clear their block, attack, re-apply block
	if _enemy1._hp > 0:
		_enemy1._block = 0
		_damage_player(_enemy1._intent_damage)
		_enemy1._block = _enemy1._intent_block
	if _enemy2._hp > 0:
		_enemy2._block = 0
		_damage_player(_enemy2._intent_damage)
		_enemy2._block = _enemy2._intent_block
		
	# end of enemy turn, tick down their debuff statuses
	if _enemy1._weak > 0: _enemy1._weak -= 1
	if _enemy1._vuln > 0: _enemy1._vuln -= 1
	if _enemy2._weak > 0: _enemy2._weak -= 1
	if _enemy2._vuln > 0: _enemy2._vuln -= 1
	_enemy1.update_display()
	_enemy2.update_display()
	
	# draw up to starting hand size
	_hand_delay.start(0.1)
	
	# reset player block
	_player.block = 0
	
	# refresh mana/energy
	_mana = MAX_MANA
	_update_stats()


func _play_card(card: CardInstance, target: Enemy=null) -> void:
	var card_mana = card.data().get_value("mana") if card.data().has_value("mana") else 0
	var card_target = card.data().get_category("target") if card.data().has_meta_category("target") else ""
	var card_damage = card.data().get_value("damage") if card.data().has_value("damage") else 0
	var card_block = card.data().get_value("block") if card.data().has_value("block") else 0
	var card_weak = card.data().get_value("weak") if card.data().has_value("weak") else 0
	var card_vuln = card.data().get_value("vulnerable") if card.data().has_value("vulnerable") else 0
	
	if _mana >= card_mana:
		_hand.play_card(card.ref(), _discard_pile)

		if card_mana < 0:
			_mana = 0
		else:
			_mana -= card_mana
		
		# TODO: better handling of "all" enemies for dynamic scenes with non-fixed no of enemies
		if card_target == "all_enemy":
			_enemy1.play_card(card_damage, card_weak, card_vuln)
			_enemy2.play_card(card_damage, card_weak, card_vuln)
		elif card_target == "enemy" && target != null:
			target.play_card(card_damage, card_weak, card_vuln)
		
		if card_block:
			_player.block += card_block
		
		_update_stats()

func _on_DropArea_dropped(card: CardInstance, _source: String, _on_card: CardInstance) -> void:
	print("DEBUG: drop area player/all dropped!")
	_play_card(card)

func _on_Enemy1Drop_dropped(card: CardInstance, _source: String, _on_card: CardInstance) -> void:
	print("DEBUG: card played on enemy_1 drop area")
	_play_card(card, _enemy1)

func _on_Enemy2Drop_dropped(card: CardInstance, _source: String, _on_card: CardInstance) -> void:
	print("DEBUG: card played on enemy_2 drop area")
	_play_card(card, _enemy2)

# view deck/discard/exhaust piles with a scrollable grid view
func _on_LibraryScroll_resized() -> void:
	if _lib_scroll != null:
		_lib_cont.rect_min_size = _lib_scroll.rect_size

func _on_Close_pressed():
	_library.visible = false
	# reset the library view for deck/discard/exhaust to empty
	_library_pile.clear()
	_end_turn.grab_focus()

# this doesn't actually work yet, it's possible to swap focus back to the card buttons despite the popup!
func _on_ViewDeckBtn_pressed():
	_draw_pile.copy_cards(_library_pile)
	_library.visible = true
	_lib_scroll.grab_focus()

func _on_ViewDiscardBtn_pressed():
	_discard_pile.copy_cards(_library_pile)
	_library.visible = true
	_lib_scroll.grab_focus()

func _on_CardBtn_pressed(button):
	var index = int(button.text)
	var card = _hand.get_card(index)
	if card != null:
		var card_name = card.data().get_text("name") if card.data().has_text("name") else ''
		print("DEBUG press: card " + str(index) + ": " + card_name)
		
		# actually play the card
		# TODO: will need further focus selections when we have multiple zones
		# (e.g. self + multiple enemies instead of a single universal zone)
		_on_DropArea_dropped(card, "hand", null)
		
		# need a time delay and to switch focus to something else then back otherwise while
		# it looks like we don't have the new card 0 focused, even though we actually do!
		var focused = _hand_cont.get_focus_owner()
		_end_turn.grab_focus()
		focused.grab_focus()
		
	else:
		print("DEBUG press: card " + str(index) + " doesn't exist")


# workaround for bug with keyboard focusing then trying to focus a different card by mouse
# the bug meant you couldn't select a different card by mouse until you'd hover'd over the focus'd
# card and then wiggled the mouse out of it to de-focus, workaround re-focuses on entering any card
func _on_HandZone_mouse_entered():
	for i in range(_cards_visual.get_child_count()):
		var visual = _cards_visual.get_child(i)
		if visual._is_focused:
			#visual._on_MouseArea_mouse_exited()
			_end_turn.grab_focus()
