extends Node

var wandTexture = preload ("res://GUI/Wand.png")

var swordTexture = preload ("res://GUI/Sword.png")

var pickAxeTexture = preload ("res://GUI/PickAxe.png")

var powerHandCombat = preload ("res://GUI/PowerHandCombat.png")

var powerHandPuzzle = preload ("res://GUI/PowerHandPuzzle.png")

var currentAttackMode = GlobalVariables.ATTACKTYPE.SWORD

onready var HealthBarFill = $PlayerStats/HealthBarFill
onready var HealthBarEmpty = $PlayerStats/HealthBarEmpty
onready var PotionBarEmpty = $PlayerStats/PotionBarEmpty
onready var PotionBarFill = $PlayerStats/PotionBarFill

var hearts = 10
var maxHearts = 10
var healthRectSize = 16

var potions = 0
var maxPotions = 3
var potionRectSize = 32

func _ready():
	HealthBarEmpty.rect_size.x = (maxHearts)*healthRectSize
	HealthBarFill.rect_size.x = (hearts)*healthRectSize
	PotionBarEmpty.rect_size.x = maxPotions*potionRectSize
	PotionBarFill.rect_size.x = potions*potionRectSize

func _process(delta):
	pass
		
func change_health(attackDamage):
	#print("current Healthbar value " + str($TextureRect/HealthBar.value))
	HealthBarFill.rect_size.x -= attackDamage * healthRectSize
		
func set_health(lifepoints):
	if HealthBarFill != null:
		HealthBarFill.rect_size.x = lifepoints*healthRectSize

func fill_one_potion():
	#print("filling one potion")
	PotionBarFill.rect_size.x += 1*potionRectSize

func use_potion():
	if HealthBarFill.rect_size.x > 0:
		HealthBarFill.rect_size.x -= 1*potionRectSize
		return true
	return false
	
func change_attack_mode(attackmode):
	if(attackmode == currentAttackMode):
		return 
	match attackmode:
		GlobalVariables.ATTACKTYPE.SWORD:
			$AttackMode/Attacks.texture = swordTexture
			currentAttackMode = attackmode
		GlobalVariables.ATTACKTYPE.MAGIC:
			$AttackMode/Attacks.texture = wandTexture
			currentAttackMode = attackmode
		GlobalVariables.ATTACKTYPE.BLOCK:
			$AttackMode/Attacks.texture = pickAxeTexture
			currentAttackMode = attackmode
		GlobalVariables.ATTACKTYPE.HAND:
			$AttackMode/Attacks.texture = powerHandCombat
			currentAttackMode = attackmode

