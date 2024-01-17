class_name Player
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
onready var _weak_icon = $Status/WeakIcon
onready var _weak_label = $Status/Weak
onready var _vuln_icon = $Status/VulnerableIcon
onready var _vuln_label = $Status/Vulnerable

onready var _hp = 70
onready var _max_hp = 70
onready var _block = 0

onready var _weak = 0
onready var _vuln = 0

# set player stats - TODO: eventually pull from data store, add flag for image?
func init(data: Dictionary) -> void:
	_hp = data.hp
	_max_hp = data.hp
	_block = data.block
	
	# make sure hp bar reflects the hp instead of using default 50/100
	update_display()
	

func update_display() -> void:
	_hp_bar.max_value = _max_hp
	_hp_bar.value = _hp
	_max_hp_label.text = str(_max_hp)
	_hp_label.text = str(_hp)
		
	if (_block > 0):
		_block_icon.visible = true
		_block_label.visible = true
	else:
		_block_icon.visible = false
		_block_label.visible = false
	_block_label.text = str(_block)
	
	if (_weak > 0):
		_weak_icon.visible = true
		_weak_label.visible = true
	else:
		_weak_icon.visible = false
		_weak_label.visible = false
	_weak_label.text = str(_weak)
	
	if (_vuln > 0):
		_vuln_icon.visible = true
		_vuln_label.visible = true
	else:
		_vuln_icon.visible = false
		_vuln_label.visible = false
	_vuln_label.text = str(_vuln)


func damage(damage: int) -> void:
	#print("DEBUG: player.damage(), dealing " + str(damage) + " before statuses")
	
	# handle vulnerable condition, incoming damage x1.5, rounded
	if _vuln > 0:
		damage = int(damage * 1.5)
	
	# handle weak condition, outgoing damage x 0.75, rounded
	if _vuln > 1:
		damage = int(damage * 0.75)
	
	#print("DEBUG: player.damage(), dealing " + str(damage) + " after statuses")
	var post_block_damage = damage
	if (_block > 0):
		post_block_damage -= _block
		_block -= damage
		#print("DEBUG: player.damage(), BLOCK DAMAGED")
	if (_block < 0):
		#print("DEBUG: player.damage(), BLOCK BROKEN")
		_block = 0
		
	# if pierced block or no block, inflict damage + play animation
	if (post_block_damage > 0):
		#print("DEBUG: player.damage(), HP DAMAGED")
		_hp -= post_block_damage
		_animation_damage_label.text = str(post_block_damage)
		_animation_player.play("Damaged")
	else:
		_animation_player.play("Blocked")

	# if hp < 1, player is defeated - TODO: actual defeat state / game over screen?
	if  _hp < 1:
		_dead.visible = true
		_drop.visible = false
	
	#print("DEBUG: player.damage(), post-attack player has " + str(_hp) + " hp and " + str(_block) + " block")	
	update_display()

func apply_status(weak: int, vuln: int) -> void:
	_weak += weak
	_vuln += vuln
	update_display()

# Called when the node enters the scene tree for the first time.
#func _ready():
#	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
