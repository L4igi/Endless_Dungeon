extends Node

var wandTexture = preload ("res://GUI/Wand.png")

var swordTexture = preload ("res://GUI/Sword.png")

var currentAttackMode = 1

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
		1:
			$AttackMode/Attacks.texture = swordTexture
			currentAttackMode = attackmode
		2:
			$AttackMode/Attacks.texture = wandTexture
			currentAttackMode = attackmode

