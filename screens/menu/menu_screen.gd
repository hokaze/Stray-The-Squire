extends AbstractScreen

onready var _display = $HomeDisplay
onready var _slay_btn = $ButtonsLayout/SlayBtn


func _ready():
	var db = CardEngine.db().get_database("main")
	var q = Query.new()
	var store = CardPile.new()

	var cards = q.from(["rarity:common"]).execute(db)

	store.populate(db, cards)
	store.shuffle()
	store.keep(3)

	_display.set_store(store)
	_slay_btn.grab_focus()
	

func _on_BoardGameBtn_pressed() -> void:
	emit_signal("next_screen", "board")

func _on_SlayBtn_pressed():
	emit_signal("next_screen", "spire_board1")

func _on_BuilderBtn_pressed() -> void:
	emit_signal("next_screen", "builder")


func _on_QuitBtn_pressed() -> void:
	get_tree().quit()
