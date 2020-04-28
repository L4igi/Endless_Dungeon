extends Node

var wandTexture = preload ("res://GUI/Wand.png")

var swordTexture = preload ("res://GUI/Sword.png")

var pickAxeTexture = preload ("res://GUI/PickAxe.png")

var powerHandCombat = preload ("res://GUI/PowerHandCombat.png")

var powerHandPuzzle = preload ("res://GUI/PowerHandPuzzle.png")

var currentAttackMode = GlobalVariables.ATTACKTYPE.SWORD

func _ready():
	pass

func _process(delta):
	pass
		
	
func change_health(attackDamage):
	#print("current Healthbar value " + str($TextureRect/HealthBar.value))
	$TextureRect/HealthBar.value -= attackDamage
		
func set_health(lifepoints):
	$TextureRect/HealthBar.value = lifepoints

func fill_one_potion():
	#print("filling one potion")
	$TextureRect/HealthPotionBar.value += 1

func use_potion():
	if $TextureRect/HealthPotionBar.value > 0:
		$TextureRect/HealthPotionBar.value -= 1
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

