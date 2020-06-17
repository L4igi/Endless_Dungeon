extends Node2D

var baseCount = 5
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
			pass
			#drop nickel
		elif currentCount == 1 || currentCount == -1:
			pass
			#drop penny
		else:
			pass
			#drop nothing
	else:
		pass
		#drop nothing
