extends AbstractCard

onready var _name = $AnimContainer/Front/NameBackground/Name
onready var _desc = $AnimContainer/Front/DescBackground/Desc
onready var _cost = $AnimContainer/Front/CostBackground/Cost
onready var _picture_group = $AnimContainer/Front/PictureGroup
onready var _common = $AnimContainer/Front/PictureGroup/Common
onready var _uncommon = $AnimContainer/Front/PictureGroup/Uncommon
onready var _rare = $AnimContainer/Front/PictureGroup/Rare
onready var _mythic = $AnimContainer/Front/PictureGroup/Mythic
onready var _attack = $AnimContainer/Front/PictureGroup/Attack
onready var _skill = $AnimContainer/Front/PictureGroup/Skill
onready var _power = $AnimContainer/Front/PictureGroup/Power
onready var _card_id = $AnimContainer/Front/CardId

# if playing card from keyboard/controller, disable certain animations and movements that would
# normally apply with the mouse when losing focus, as in this mode we need to both demonstrate a
# card is active, but also let the keyboard/controller focus other elements to select target
var play_card_keyboard = false

func _update_data(data: CardData, default: CardData = null) -> void:
	_card_id.text = data.id

	if data.has_text("name"):
		_name.text = data.get_text("name")

	if data.has_text("desc"):
		var desc_text = data.get_text("desc")
		# by using [placeholder] in description instead of just the number, we can ensure that if an
		# effect boosts the damage of a card, that number actually gets reflected in the description
		if data.has_value("damage"):
			desc_text = desc_text.replace("[damage]", "%d" % data.get_value("damage"))
		if data.has_value("block"):
			desc_text = desc_text.replace("[block]", "%d" % data.get_value("block"))
		if data.has_value("vulnerable"):
			desc_text = desc_text.replace("[vulnerable]", "%d" % data.get_value("vulnerable"))
		if data.has_value("weak"):
			desc_text = desc_text.replace("[weak]", "%d" % data.get_value("weak"))
		if data.has_value("add_energy"):
			desc_text = desc_text.replace("[add_energy]", "%d" % data.get_value("add_energy"))
		_desc.text = desc_text

	if data.has_value("energy"):
		var val = data.get_value("energy")
		if val >= 0:
			_cost.text = "%d" % val
		else:
			_cost.text = "X"

	if default != null:
		var val = data.get_value("energy")
		var orig = default.get_value("energy")

		if val > orig:
			_cost.add_color_override("font_color", Color("ff0000"))
		elif val < orig:
			_cost.add_color_override("font_color", Color("00ff00"))
		else:
			_cost.add_color_override("font_color", Color("ffffff"))


	_update_picture(data)


func _update_picture(data: CardData) -> void:
	for child in _picture_group.get_children():
		child.visible = false

	if data.has_meta_category("rarity"):
		if data.get_category("rarity") == "common":
			_common.visible = true
		elif data.get_category("rarity") == "uncommon":
			_uncommon.visible = true
		elif data.get_category("rarity") == "rare":
			_rare.visible = true
		elif data.get_category("rarity") == "mythic":
			_mythic.visible = true
	if data.has_meta_category("class"):
		if data.get_category("class") == "attack":
			_attack.visible = true
		elif data.get_category("class") == "skill":
			_skill.visible = true
		elif data.get_category("class") == "power":
			_power.visible = true


func _on_NormalCard_instance_changed() -> void:
	# warning-ignore:return_value_discarded
	instance().connect("modified", self, "_on_instance_modified")
	_update_data(instance().data(), instance().unmodified())


func _on_instance_modified() -> void:
	_update_data(instance().data(), instance().unmodified())


# EXPERIMENTAL / WIP - keyboard/controller support for selecting cards
func _on_Button_focus_entered():
	print("DEBUG NormalCard button focus enter: " + _name.text)
	_on_MouseArea_mouse_entered()

func _on_Button_focus_exited():
	print("DEBUG NormalCard button focus exit: " + _name.text)
	_on_MouseArea_mouse_exited()

func _on_Button_pressed():
	print("DEBUG NormalCard button pressed: " + _name.text)
	play_card_keyboard = !play_card_keyboard
	_on_MouseArea_button_down()

# override mouse exit event if card is being played (clicked) with keyboard so it no longer does the
# unfocus and idle events, but still plays them if changing focus with keyboard or mouse WITHOUT playing
# the card
#func _on_MouseArea_mouse_exited() -> void:
#	if !play_card_keyboard:
#		._on_MouseArea_mouse_exited() # godot equivalent of "super"
#	else:
#		print("DEBUG NormalCard play card keyboard mouse exit")
