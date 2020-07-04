extends Node2D

var baseCount = 2
var currentCount = 0
var interActed = false
var activationDelay = 0
var reverseFill = false
var countSound = preload("res://GameObjects/CountingBlock/countingSound.wav")
onready var countLabel = $Sprite/Count

onready var Grid = get_parent()

func _ready():
	adjust_base_count()
	currentCount = baseCount
	countLabel.set_text(str(baseCount))
	get_node("Sprite/TextureProgress").set_value(0)

func adjust_base_count():
	var adjustCount = int(GlobalVariables.puzzleBonusLootDropped/3)
	if adjustCount >= 8: 
		adjustCount = 8
	baseCount = int((randi()%(adjustCount+1)+2)* GlobalVariables.globalDifficultyMultiplier)
	get_node("Sprite/TextureProgress").set_max(baseCount)
	
func decrease_count():
	if !Grid.cancelMagicPuzzleRoom:
		get_node("AudioStreamPlayer2D").stream = countSound
		get_node("AudioStreamPlayer2D").play()
		interActed = true
		currentCount-=1
		if !reverseFill:
			get_node("Sprite/TextureProgress").set_value(get_node("Sprite/TextureProgress").get_value()+1)
			countLabel.set_text(str(currentCount))
		else:
			get_node("Sprite/TextureProgress").set_value(get_node("Sprite/TextureProgress").get_value()-1)
			countLabel.set_text(str(currentCount*-1))
		if currentCount == 0:
			reverseFill = true
		
	
func reset_count():
	interActed = false
	currentCount = baseCount
	reverseFill = false
	get_node("Sprite/TextureProgress").set_value(0)
	countLabel.set_text(str(currentCount))
	
func checkLootDrop():
	if interActed:
		if currentCount == 0: 
			return str("nickel")
			#drop nickel
		elif currentCount == 1 || currentCount == -1:
			return str("penny")
			#drop penny
		else:
			return null
			#drop nothing
	else:
		return null
		#drop nothing

func playAnimation(animationType):
	match animationType:
		"penny":
			$AnimationPlayer.play("penny")
		"nickel":
			$AnimationPlayer.play("nickel")
		"nothing":
			$AnimationPlayer.play("nothing")
	yield($AnimationPlayer, "animation_finished")
	GlobalVariables.turnController.on_counting_block_delete(self, true)
