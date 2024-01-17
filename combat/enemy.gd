class_name Enemy
extends Node2D

#onready var _sprite = $Sprite # unused in script
onready var _animation_player = $AnimationPlayer
#onready var _animation_block_label = $Blocked # unused in script
onready var _animation_damage_label = $Damage

onready var _hp_bar = $HPBar
onready var _hp_label = $HPBar/HBox/HP
onready var _max_hp_label = $HPBar/HBox/MaxHP
onready var _block_icon = $BlockIcon
onready var _block_label = $BlockIcon/Block
onready var _drop = $Drop
onready var _dead = $Dead

onready var _intent_damage_label = $Intent/Damage
onready var _intent_damage_icon = $Intent/DamageIcon
onready var _intent_block_label = $Intent/Block
onready var _intent_block_icon = $Intent/BlockIcon
onready var _intent_debuff_icon = $Intent/DebuffIcon
#onready var _intent_buff_icon = $Intent/BuffIcon # unused in script

onready var _weak_icon = $Status/WeakIcon
onready var _weak_label = $Status/Weak
onready var _vuln_icon = $Status/VulnerableIcon
onready var _vuln_label = $Status/Vulnerable

onready var _hp = 50
onready var _max_hp = 100
onready var _block = 0
onready var _intents = []
onready var _intent = {}
onready var _intent_index = 0

onready var _weak = 0
onready var _vuln = 0

# set enemy stats - TODO: eventually pull from data store, add flag for image?
func init(data: Dictionary) -> void:
	_hp = data.hp
	_max_hp = data.hp
	_block = data.block
	_intents = data.intents
	
	# use 0th intent by default + update display
	set_intent(0)
	

func set_intent(index: int) -> void:
	# duplicate dictionary to make copy instead of a reference, means we can alter current intent
	# via status effects like weak without affecting the enemy intent once the debuff wears off
	_intent = _intents[index].duplicate()
	_intent_index = index
	update_display()

func update_display() -> void:
	_hp_bar.max_value = _max_hp
	_hp_bar.value = _hp
	_max_hp_label.text = str(_max_hp)
	_hp_label.text = str(_hp)
	_intent_damage_label.text = str(_intent.damage)
	_intent_block_label.text = str(_intent.block)
		
	if (_block > 0):
		_block_icon.visible = true
		_block_label.visible = true
	else:
		_block_icon.visible = false
		_block_label.visible = false
	_block_label.text = str(_block)
	
	# only show attack/block icons/labels if relevant to intent
	if (_intent.block > 0):
		_intent_block_icon.visible = true
		_intent_block_label.visible = true
	else:
		_intent_block_icon.visible = false
		_intent_block_label.visible = false
	if (_intent.damage > 0):
		_intent_damage_icon.visible = true
		_intent_damage_label.visible = true
	else:
		_intent_damage_icon.visible = false
		_intent_damage_label.visible = false
	
	# if intending debuff/buff, show generic icons, NOT the specific buff/debuff to apply
	if (_intent.weak > 0 || _intent.vuln > 0):
		_intent_debuff_icon.visible = true
	else:
		_intent_debuff_icon.visible = false
	# TODO: buff icon, don't actually have any buffs implemented yet!
#	if (_intent.TODO_BUFF_1_HERE > 0 || _intent.TODO_BUFF_2_HERE > 0):
#		_intent_buff_icon.visible = true
#	else:
#		_intent_buff_icon.visible = false
	
	# update intent to reflect applied debuffs
	if (_weak > 0):
		_weak_icon.visible = true
		_weak_label.visible = true
		_intent_damage_label.add_color_override("font_color", Color("ff9999"))
		_intent.damage = int(_intent.damage * 0.75)
	else:
		_weak_icon.visible = false
		_weak_label.visible = false
		_intent_damage_label.remove_color_override("font_color")
		_intent.damage = _intent.damage
	_weak_label.text = str(_weak)
	
	if (_vuln > 0):
		_vuln_icon.visible = true
		_vuln_label.visible = true
	else:
		_vuln_icon.visible = false
		_vuln_label.visible = false
	_vuln_label.text = str(_vuln)


func damage(damage: int) -> void:
	#print("DEBUG: enemy.damage(), dealing " + str(damage) + " before statuses")
	
	# handle vulnerable condition, incoming damage x1.5, rounded
	if _vuln > 0:
		damage = int(damage * 1.5)
	
	#print("DEBUG: enemy.damage(), dealing " + str(damage) + " after statuses")
	var post_block_damage = damage
	if (_block > 0):
		post_block_damage -= _block
		_block -= damage
		#print("DEBUG: enemy.damage(), BLOCK DAMAGED")
	if (_block < 0):
		#print("DEBUG: enemy.damage(), BLOCK BROKEN")
		_block = 0
	
	# if pierced block or no block, inflict damage + play animation
	if (post_block_damage > 0):
		#print("DEBUG: enemy.damage(), HP DAMAGED")
		_hp -= post_block_damage
		_animation_damage_label.text = str(post_block_damage)
		_animation_player.play("Damaged")
	else:
		_animation_player.play("Blocked")

	# if hp < 1, enemy is defeated, cross them out and don't let them act, disable their drop area
	if  _hp < 1:
		_dead.visible = true
		_drop.visible = false
	
	#print("DEBUG: enemy.damage(), post-attack enemy has " + str(_hp) + " hp and " + str(_block) + " block")	
	update_display()


func play_card(damage: int, weak: int, vuln: int) -> void:
	# always apply damage BEFORE condition, to avoid vulnerable attack self-proc
	damage(damage)
	_weak += weak
	_vuln += vuln
	update_display()


func attack(player: Player) -> void:
	_block = 0
	_animation_player.play("Enemy_Attack")
	
	# improvised wait, should probably use an actual timer
	# ensures damage isn't inflicted until the "impact" part of the attack animation
	yield(get_tree().create_timer(0.6), "timeout")
	player.damage(_intent.damage)
	player.apply_status(_intent.weak, _intent.vuln)
	_block = _intent.block
	
	# cycle to the next intent

# Called when the node enters the scene tree for the first time.
#func _ready():
#	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
