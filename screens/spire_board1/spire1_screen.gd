extends AbstractScreen

const STARTING_HAND_SIZE: int = 5
const MAX_HAND_SIZE: int = 10
const MAX_ENERGY: int = 3

var _hand: CardHand = CardHand.new()
var _draw_pile: CardPile = CardPile.new()
var _discard_pile: CardPile = CardPile.new()
var _exhaust_pile: CardPile = CardPile.new()
var _library_pile: CardPile = CardPile.new()
var _play_pile: CardPile = CardPile.new()
var _energy: int = MAX_ENERGY

onready var _hand_cont = $Board/HandZone/HandContainer
onready var _end_turn = $Board/ActionBar/EndTurnBtn
onready var _draw_count = $Board/DeckZone/VBox/DrawCount
onready var _discard_count = $Board/DiscardZone/VBox/DiscardCount
onready var _exhaust_count = $Board/ExhaustZone/VBox/ExhaustCount
onready var _hand_delay = $StartingHandDelay
onready var _drop_area = $Board/DropArea
onready var _visible_pile = $Board/VisiblePile
onready var _cards_visual = $Board/HandZone/HandContainer/DropArea/Cards
onready var _energy_label = $Board/ActionBar/Amount

# view deck/discard/exhaust piles with a scrollable grid view
onready var _library = $LibNode2D
onready var _lib_scroll = $LibNode2D/LibraryBG/LibraryScroll
onready var _lib_cont = $LibNode2D/LibraryBG/LibraryScroll/LibraryContainer

onready var _dead = $DeadNode2D

var _player_stats = {"hp": 70, "block": 0}
var _e1_intents = [ {"damage": 6, "block": 0, "weak": 0, "vuln": 0},
					{"damage": 0, "block": 6, "weak": 0, "vuln": 0} ]
var _e2_intents = [ {"damage": 4, "block": 6, "weak": 0, "vuln": 0},
					{"damage": 0, "block": 0, "weak": 1, "vuln": 1} ]
var _e1_stats = {"hp": 22, "block": 0, "intents": _e1_intents}
var _e2_stats = {"hp": 10, "block": 6, "intents": _e2_intents }
var _play_card_keyboard = false

onready var _player = $Board/Player
onready var _player_focus = $Board/Player/FocusBtn
onready var _enemy1 = $Board/Enemy1
onready var _enemy1_drop = $Board/Enemy1/Drop
onready var _enemy1_focus = $Board/Enemy1/FocusBtn
onready var _enemy2 = $Board/Enemy2
onready var _enemy2_drop = $Board/Enemy2/Drop
onready var _enemy2_focus = $Board/Enemy2/FocusBtn


func _ready() -> void:
	# connect piles from containers to relevant functions
	# warning-ignore:return_value_discarded
	_draw_pile.connect("changed", self, "_on_DrawPile_changed")
	# warning-ignore:return_value_discarded
	_discard_pile.connect("changed", self, "_on_DiscardPile_changed")
	# warning-ignore:return_value_discarded
	_exhaust_pile.connect("changed", self, "_on_ExhaustPile_changed")
	# warning-ignore:return_value_discarded
	_hand.connect("changed", self, "_on_Hand_changed")
	
	# set params for player - TODO: move DropArea to player scene while keeping large size?
	_player.init(_player_stats)
	
	# set params for enemies and connect enemy drop area to handler for playing cards
	_enemy1.init(_e1_stats)
	_enemy1_drop.connect("dropped", self, "_on_EnemyDrop_dropped", [_enemy1])
	_enemy2.init(_e2_stats)
	_enemy2_drop.connect("dropped", self, "_on_EnemyDrop_dropped", [_enemy2])
	
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
	
	# main drop area is for cards that target player or all enemies
	# enemy drops target that specific enemy, but also allow targeting player/all, so no filter
	var q_player_drop = Query.new()
	q_player_drop.from(["target:player", "target:all_enemy"])
	_drop_area.set_filter(q_player_drop)
	
	# TODO: need some way of targeting drop areas with keyboard/controller
	# make sure FocusBtn of each Player/Enemy are focus neighbors for easy selection
	_player_focus.set_focus_neighbour(MARGIN_RIGHT, _enemy1_focus.get_path())
	_enemy1_focus.set_focus_neighbour(MARGIN_LEFT, _player_focus.get_path())
	_enemy1_focus.set_focus_neighbour(MARGIN_RIGHT, _enemy2_focus.get_path())
	_enemy2_focus.set_focus_neighbour(MARGIN_LEFT, _enemy1_focus.get_path())
	
	# EXPERIMENTAL - VisiblePile Container temporary holding zone for playing cards with keyboard
	_visible_pile.data_id = "play_pile"
	_visible_pile.get_drop_area().set_source_filter(["hand"])
	_visible_pile.set_store(_play_pile)
	
	# connect the player/enemy FocusBtn to a method to allowing playing card with keyboard
	_player_focus.connect("pressed", self, "_on_FocusBtn_pressed", ["player", null])
	_enemy1_focus.connect("pressed", self, "_on_FocusBtn_pressed", ["enemy", _enemy1])
	_enemy2_focus.connect("pressed", self, "_on_FocusBtn_pressed", ["enemy", _enemy2])
	#_enemy1_focus.connect("pressed", self, "_on_EnemyFocusBtn_pressed")
	#_enemy2_focus.connect("pressed", self, "_on_EnemyFocusBtn_pressed")

func _update_stats() -> void:
	_energy_label.text = str(_energy)
	_player.update_display()
	_enemy1.update_display()
	_enemy2.update_display()
	
	# show placeholder screen for player death, then load main menu
	if _player._hp < 1:
		_show_dead()


func _on_MenuBtn_pressed() -> void:
	emit_signal("next_screen", "menu")

func _on_DrawPile_changed() -> void:
	_draw_count.text = "%d" % _draw_pile.count()

func _on_DiscardPile_changed() -> void:
	_discard_count.text = "%d" % _discard_pile.count()

func _on_ExhaustPile_changed() -> void:
	_exhaust_count.text = "%d" % _exhaust_pile.count()

func _on_Hand_changed() -> void:
	# EXPERIMENTAL, button workaround to focus/play cards with keyboard/controller
	var _cards = _hand_cont.get_node("DropArea/Cards")
	for i in range(_cards.get_child_count()):
		var _card = _cards.get_child(i)
		var _button = _card.get_node("Button")
		#print("DEBUG: _on_Hand_changed _card: " + str(_card.get_name()))
		# only connect if not already connected
		if !(_button.is_connected('pressed', self, '_on_CardBtn_pressed')):
			_button.connect('pressed', self, '_on_CardBtn_pressed', [_card.instance()]) 
	
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

func _on_EndTurnBtn_pressed() -> void:
	# disable end button until logic is done, to avoid being able to spam it to skip enemy turns
	_end_turn.disabled = true
	
	# tick down player debuffs
	if _player._weak > 0: _player._weak -= 1
	if _player._vuln > 0: _player._vuln -= 1
	
	# discard
	_hand.move_cards(_discard_pile)
	
	# TODO: enemy turn, to split off into own method/class later
	# just doing an example with the 2 demo enemies with static intent
	# clear their block, attack, re-apply block, tick down buffs/debuffs
	if _enemy1._hp > 0:
		_enemy1.attack(_player)
		yield(get_tree().create_timer(1.5), "timeout")
		# tick down debuffs
		if _enemy1._weak > 0: _enemy1._weak -= 1
		if _enemy1._vuln > 0: _enemy1._vuln -= 1
		# swap intents and update display
		if _enemy1._intent_index == 0:
			_enemy1.set_intent(1)
		else:
			_enemy1.set_intent(0)
	
	if _enemy2._hp > 0:
		_enemy2.attack(_player)
		yield(get_tree().create_timer(1.5), "timeout")
		# tick down debuffs
		if _enemy2._weak > 0: _enemy2._weak -= 1
		if _enemy2._vuln > 0: _enemy2._vuln -= 1
		# swap intents and update display
		if _enemy2._intent_index == 0:
			_enemy2.set_intent(1)
		else:
			_enemy2.set_intent(0)
	
	# draw up to starting hand size, unless dead
	if _player._hp > 0:
		_hand_delay.start(0.1)
	
	# reset player block
	_player._block = 0
	
	# refresh energy/energy
	_energy = MAX_ENERGY
	_update_stats()
	
	# re-enable end turn button
	yield(get_tree().create_timer(2.5), "timeout")
	_end_turn.disabled = false


func _play_card(card: CardInstance, target: Enemy=null, source: String="hand") -> void:
	var card_energy = card.data().get_value("energy") if card.data().has_value("energy") else 0
	var card_exhaust = card.data().get_value("exhaust") if card.data().has_value("exhaust") else 0
	var card_target = card.data().get_category("target") if card.data().has_meta_category("target") else ""
	var card_damage = card.data().get_value("damage") if card.data().has_value("damage") else 0
	var card_block = card.data().get_value("block") if card.data().has_value("block") else 0
	var card_weak = card.data().get_value("weak") if card.data().has_value("weak") else 0
	var card_vuln = card.data().get_value("vulnerable") if card.data().has_value("vulnerable") else 0
	var card_add_energy = card.data().get_value("add_energy") if card.data().has_value("add_energy") else 0
	
	var card_pile
	if source == "hand": card_pile = _hand
	else: card_pile = _play_pile
	
	if _energy >= card_energy:
		# check if card has Exhaust, if not, Discard when playing, as normal
		if card_exhaust == 1:
			print("DEBUG: played card with exhaust")
			#_hand.play_card(card.ref(), _exhaust_pile)
			card_pile.move_card(card.ref(), _exhaust_pile)
		else:
			#_hand.play_card(card.ref(), _discard_pile)
			card_pile.move_card(card.ref(), _discard_pile)
		_visible_pile.visible = false
		_play_card_keyboard = false
		
		# failsafe for stacking energy reductions
		if card_energy < 0:
			_energy = 0
		else:
			_energy -= card_energy
		
		# reduce damage if player is weak
		if _player._weak > 0:
			card_damage = (card_damage * 0.75)
		
		# TODO: better handling of "all" enemies for dynamic scenes with non-fixed no of enemies
		if card_target == "all_enemy":
			_player._animation_player.play("Player_Attack")
			yield(get_tree().create_timer(0.6), "timeout")
			_enemy1.play_card(card_damage, card_weak, card_vuln)
			_enemy2.play_card(card_damage, card_weak, card_vuln)
		elif card_target == "enemy" && target != null:
			_player._animation_player.play("Player_Attack")
			yield(get_tree().create_timer(0.6), "timeout")
			target.play_card(card_damage, card_weak, card_vuln)
		
		if card_block:
			_player._block += card_block
		
		# other misc card abilities
		if card_add_energy > 0:
			print("DEBUG: played card with add_energy " + str(card_add_energy))
			_energy += card_add_energy
		
		_update_stats()

func _on_DropArea_dropped(card: CardInstance, _source: String, _on_card: CardInstance) -> void:
	#print("DEBUG: drop area player/all dropped!")
	_play_card(card)

func _on_EnemyDrop_dropped(card: CardInstance, _source: String, _on_card: CardInstance, target: Enemy=null) -> void:
	#print("DEBUG: card played on enemy drop area: " + str(target))
	_play_card(card, target)

#func _on_Enemy2Drop_dropped(card: CardInstance, _source: String, _on_card: CardInstance) -> void:
#	#print("DEBUG: card played on enemy_2 drop area")
#	_play_card(card, _enemy2)

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

func _on_ViewExhaustBtn_pressed():
	_exhaust_pile.copy_cards(_library_pile)
	_library.visible = true
	_lib_scroll.grab_focus()

# used to allow playing cards with keyboard/controller instead of mouse
func _on_CardBtn_pressed(card: CardInstance) -> void:
	print ("DEBUG: " + str(card))
	if card != null:
		var card_name = card.data().get_text("name") if card.data().has_text("name") else ''
		print("DEBUG press: card " + str(card) + " " + card_name)
		
		# actually play the card
		# TODO: will need further focus selections when we have multiple zones
		# (e.g. self + multiple enemies instead of a single universal zone)
		#_on_DropArea_dropped(card, "hand", null)
		
		# need a time delay and to switch focus to something else then back otherwise while
		# it looks like we don't have the new card 0 focused, even though we actually do!
		#var focused = _hand_cont.get_focus_owner()
		#end_turn.grab_focus()
		#focused.grab_focus()
		
		_on_VisiblePile_card_dropped(card, "hand", null)
		_player_focus.grab_focus()
		
	else:
		print("DEBUG press: card is null")

# EXPERIMENTAL, WIP
# keyboard workaround, place card into visible pile to indicate it's active and next valid target
# "clicked" is targeted, otherwise give option to cancel and return to hand
func _on_VisiblePile_card_dropped(card, _source, _on_card):
	# warning-ignore:return_value_discarded
	_hand.move_card(card.ref(), _play_pile)
	_play_card_keyboard = true
	_visible_pile.visible = true

func _on_FocusBtn_pressed(type: String, target: Enemy=null):
	print("DEBUG: _on_FocusBtn_pressed")
	var card = _play_pile.get_first()
	if _play_card_keyboard == true:
		if (type == "player"):
			print("DEBUG: playing card on player (if valid)")
			_play_card(card, null, "play_pile")
			#_on_DropArea_dropped(card, "hand", null)
		elif (type == "enemy"):
			print("DEBUG: playing card on enemy (if valid): " + str(target))
			_play_card(card, target, "play_pile")
			#_on_EnemyDrop_dropped(card, "hand", null)

#func _on_PlayerFocusBtn_pressed():
#	print("STUB ENTRY: _on_PlayerFocusBtn_pressed")
#	var card = _play_pile.get_first()
#	if _play_card_keyboard == true:
#		print("TODO: play card on player if valid")
#		_play_card(card)
#
#func _on_EnemyFocusBtn_pressed():
#	print("STUB ENTRY: _on_EnemyFocusBtn_pressed")
#	if _play_card_keyboard == true:
#		print("TODO: play card on enemy if valid")
#	pass

func _on_CancelCardBtn_pressed():
	var card = _play_pile.get_first()
	# warning-ignore:return_value_discarded
	_play_pile.move_card(card.ref(), _hand)
	_play_card_keyboard = false
	_visible_pile.visible = false

# workaround for bug with keyboard focusing then trying to focus a different card by mouse
# the bug meant you couldn't select a different card by mouse until you'd hover'd over the focus'd
# card and then wiggled the mouse out of it to de-focus, workaround re-focuses on entering any card
func _on_HandZone_mouse_entered():
	for i in range(_cards_visual.get_child_count()):
		var visual = _cards_visual.get_child(i)
		if visual._is_focused:
			#visual._on_MouseArea_mouse_exited()
			_end_turn.grab_focus()

# quick placeholder splash screen for player death + auto reset to main menu after a few moments
# TODO: better handling for player death, disable controls in background, let player select main menu
func _show_dead():
	_dead.visible = true
	yield(get_tree().create_timer(2), "timeout")
	emit_signal("next_screen", "menu")

