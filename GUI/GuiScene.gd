extends Node

var wandTexture = preload ("res://GUI/Wand.png")

var swordTexture = preload ("res://GUI/Sword.png")

var pickAxeTexture = preload ("res://GUI/PickAxe.png")

var powerHandCombat = preload ("res://GUI/PowerHandCombat.png")

var powerHandPuzzle = preload ("res://GUI/PowerHandPuzzle.png")

var roomMode = GlobalVariables.ROOM_TYPE.ENEMYROOM

var currentAttackMode = GlobalVariables.ATTACKTYPE.SWORD

onready var HealthBarFill = $PlayerStats/HealthBarFill
onready var HealthBarEmpty = $PlayerStats/HealthBarEmpty
onready var PotionBarEmpty = $PlayerStats/PotionBarEmpty
onready var PotionBarFill = $PlayerStats/PotionBarFill
onready var PlayerStats = $PlayerStats
onready var currentTurnActionsText = $TurnStats/CurrentTurnActions
onready var maxTurnActionsText = $TurnStats/MaxTurnsActions
onready var TurnStats = $TurnStats

var hearts = 10
var maxHearts = 10
var healthRectSize = 16
var currentTurnActionCount = 0

var potions = 0
var maxPotions = 3
var potionRectSize = 32

func _ready():
	PlayerStats.rect_size.x = maxHearts*4-6
	HealthBarEmpty.rect_size.x = (maxHearts)*healthRectSize
	HealthBarFill.rect_size.x = (hearts)*healthRectSize
	PotionBarEmpty.rect_size.x = maxPotions*potionRectSize
	PotionBarFill.rect_size.x = potions*potionRectSize
	currentTurnActionsText.set_text(str(0))

func _process(delta):
	pass
		
func set_maxturn_actions(maxTurnActions):
		maxTurnActionsText.set_text(str(maxTurnActions))
		
func update_current_turns(reset = false):
	if reset:
		currentTurnActionCount = 0
	else:
		currentTurnActionCount += 1
	currentTurnActionsText.set_text(str(currentTurnActionCount))
	
func change_health(attackDamage):
	#print("current Healthbar value " + str($TextureRect/HealthBar.value))
	HealthBarFill.rect_size.x -= attackDamage * healthRectSize
		
func set_health(lifepoints):
	if HealthBarFill != null:
		HealthBarFill.rect_size.x = lifepoints*healthRectSize

func fill_one_potion():
	#print("filling one potion")
	if PotionBarFill.rect_size.x != 3*potionRectSize:
		PotionBarFill.rect_size.x += 1*potionRectSize

func use_potion():
	if PotionBarFill.rect_size.x > 0:
		PotionBarFill.rect_size.x -= 1*potionRectSize
		return true
	return false

func change_hand_on_room(roomMode):
	self.roomMode = roomMode
	if roomMode == GlobalVariables.ROOM_TYPE.PUZZLEROOM && currentAttackMode == GlobalVariables.ATTACKTYPE.HAND:
		$AttackMode/Attacks.texture = powerHandPuzzle
	elif currentAttackMode == GlobalVariables.ATTACKTYPE.HAND:
		$AttackMode/Attacks.texture = powerHandCombat
		
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
			if roomMode == GlobalVariables.ROOM_TYPE.PUZZLEROOM:
				$AttackMode/Attacks.texture = powerHandPuzzle
			else:
				$AttackMode/Attacks.texture = powerHandCombat
			currentAttackMode = attackmode

