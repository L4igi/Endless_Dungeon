#Overlay of the Game
#shows all importent stats at all time
#updates depending on difficulty and game events 
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
onready var coinCount = $CoinCount/CoinCountLabel

var healthRectSize = 16
var currentTurnActionCount = 0
var potionRectSize = 32

#set up GUI elements with Player stats
func setUpGUI(maxTurnActions, maxLifePoints, lifePoints, coinCount, maxPotions, currentPotions):
	PlayerStats.rect_size.x = maxLifePoints*4-6
	HealthBarEmpty.rect_size.x = (maxLifePoints)*healthRectSize
	HealthBarFill.rect_size.x = (lifePoints)*healthRectSize
	PotionBarEmpty.rect_size.x = maxPotions*potionRectSize
	PotionBarFill.rect_size.x = currentPotions*potionRectSize
	self.coinCount.set_text(str(coinCount))
	currentTurnActionsText.set_text(str(0))
	set_maxturn_actions(maxTurnActions)
		
func set_maxturn_actions(maxTurnActions):
	maxTurnActionsText.set_text(str(maxTurnActions))
		
func update_current_turns(reset = false, addAmount = 1):
	if reset:
		currentTurnActionCount = 0
	else:
		currentTurnActionCount += addAmount
	currentTurnActionsText.set_text(str(currentTurnActionCount))
	
func change_health(attackDamage):
	#print("current Healthbar value " + str($TextureRect/HealthBar.value))
	HealthBarFill.rect_size.x -= attackDamage * healthRectSize
	
func change_max_health(amount):
	if PlayerStats.rect_size.x < amount*4-6:
		PlayerStats.rect_size.x = amount*4-6
	HealthBarEmpty.rect_size.x = (amount)*healthRectSize
	
func change_max_potions(amount):
	if PlayerStats.rect_size.x < amount*8:
		PlayerStats.rect_size.x = amount*8
	PotionBarEmpty.rect_size.x = amount*potionRectSize
	
func set_health(lifepoints):
	if HealthBarFill != null:
		HealthBarFill.rect_size.x = lifepoints*healthRectSize

func fill_potions(amount):
	#print("filling one potion")
	PotionBarFill.rect_size.x = amount*potionRectSize

func use_potion():
	if PotionBarFill.rect_size.x > 0:
		PotionBarFill.rect_size.x -= 1*potionRectSize
		return true
	return false
#update hand attack texture to reflect current room type
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

func add_coin(playerCoinCount):
	coinCount.set_text(str(playerCoinCount))
	
func spend_coins(playerCoinCount):
	coinCount.set_text(str(playerCoinCount))
