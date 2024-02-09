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
	

func _on_SlayBtn_pressed():
	emit_signal("next_screen", "room_combat")
	#loading_screen.load_scene(self, "res://screens/room_combat/room_combat.tscn")

func _on_BuilderBtn_pressed() -> void:
	emit_signal("next_screen", "builder")
	#loading_screen.load_scene(self, "res://screens/builder/builder_screen.tscn")

func _on_QuitBtn_pressed() -> void:
	get_tree().quit()
