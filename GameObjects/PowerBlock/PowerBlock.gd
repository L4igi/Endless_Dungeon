extends Node2D

onready var Grid = get_parent()

var counters = 0
var inPuzzleRoom = false
var availableDirections = []
var activeDirections = []

# Called when the node enters the scene tree for the first time.
func _ready():
	if Grid.activeRoom != null:
		if Grid.activeRoom.roomType == GlobalVariables.ROOM_TYPE.PUZZLEROOM:
			$AnimationPlayer.play("PuzzleCounter0")
	else:
		$AnimationPlayer.play("Counter0")

func addCounters(roomType):
	if counters == 5:
		return
	counters += 1
	
	if roomType != null && roomType == GlobalVariables.ROOM_TYPE.PUZZLEROOM:
		match counters:
			0:
				$AnimationPlayer.play("PuzzleCounter0")
			1:
				availableDirections.append(GlobalVariables.DIRECTION.UP)
				$AnimationPlayer.play("PuzzleCounter1")
			2:
				availableDirections.append(GlobalVariables.DIRECTION.DOWN)
				$AnimationPlayer.play("PuzzleCounter2")
			3:
				availableDirections.erase(GlobalVariables.DIRECTION.DOWN)
				availableDirections.append(GlobalVariables.DIRECTION.RIGHT)
				$AnimationPlayer.play("PuzzleCounter3")
			4:
				availableDirections.append(GlobalVariables.DIRECTION.DOWN)
				$AnimationPlayer.play("PuzzleCounter4")
			5:
				availableDirections.append(GlobalVariables.DIRECTION.LEFT)
				$AnimationPlayer.play("PuzzleCounter5")
	else:
		match counters:
			0:
				$AnimationPlayer.play("Counter0")
			1:
				availableDirections.append(GlobalVariables.DIRECTION.UP)
				$AnimationPlayer.play("Counter1")
			2:
				availableDirections.append(GlobalVariables.DIRECTION.DOWN)
				$AnimationPlayer.play("Counter2")
			3:
				availableDirections.erase(GlobalVariables.DIRECTION.DOWN)
				availableDirections.append(GlobalVariables.DIRECTION.RIGHT)
				$AnimationPlayer.play("Counter3")
			4:
				availableDirections.append(GlobalVariables.DIRECTION.DOWN)
				$AnimationPlayer.play("Counter4")
			5:
				availableDirections.append(GlobalVariables.DIRECTION.LEFT)
				$AnimationPlayer.play("Counter5")
	
	activeDirections = availableDirections.duplicate()

func explodeBlock():
	if counters < 1:
		return false 
		
	set_process(false)
	$AnimationPlayer.play("ExplodeBlock", -1, 1.0)
	$Tween.interpolate_property(self, "position", position, position , $AnimationPlayer.current_animation_length, Tween.TRANS_LINEAR, Tween.EASE_IN)
	#position = target_position
	$Tween.start()
	yield($AnimationPlayer, "animation_finished")
	set_process(true)
	Grid.on_Power_Block_explode(self)
	return true
	
func rotateBlock():
	activeDirections.clear()
	rotation_degrees += 90
	if rotation_degrees == 360:
		rotation_degrees = 0

	activeDirections = availableDirections.duplicate()
	
	var tempDirections = []
	var loopTimes = int(rotation_degrees/90)
	for count in range(loopTimes):
		for direction in activeDirections:
			match direction:
				GlobalVariables.DIRECTION.UP:
					tempDirections.append(GlobalVariables.DIRECTION.RIGHT)
				GlobalVariables.DIRECTION.DOWN:
					tempDirections.append(GlobalVariables.DIRECTION.LEFT)
				GlobalVariables.DIRECTION.LEFT:
					tempDirections.append(GlobalVariables.DIRECTION.UP)
				GlobalVariables.DIRECTION.RIGHT:
					tempDirections.append(GlobalVariables.DIRECTION.DOWN)
		activeDirections = tempDirections.duplicate()
		tempDirections.clear()

	#print("Available directions" + str(activeDirections))
	
func spawnMagicFromBlock():
	Grid.on_powerBlock_spawn_magic(self)
