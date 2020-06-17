extends Node2D

var baseCount = 2
var currentCount = 0
var interActed = false

onready var countLabel = $Sprite/Count

func _ready():
	currentCount = baseCount
	countLabel.set_text(str(baseCount))


func decrease_count():
	interActed = true
	currentCount-=1
	countLabel.set_text(str(currentCount))
	
func reset_count():
	interActed = false
	currentCount = baseCount
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
			pass
		"nickel":
			pass
		"nothing":
			pass
	#yield animation done 
	GlobalVariables.turnController.on_counting_block_delete(self, true)
