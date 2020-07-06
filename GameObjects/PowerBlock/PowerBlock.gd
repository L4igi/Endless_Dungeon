extends Node2D

onready var Grid = get_parent()

var counters = 0
var activeDirections = []
var backupActiveDirections = []
var shootDelay = 0

func _ready():
	if Grid.activeRoom != null:
		if Grid.activeRoom.roomType == GlobalVariables.ROOM_TYPE.PUZZLEROOM:
			$AnimationPlayer.play("ArrowNull")
	else:
		$AnimationPlayer.play("Counter0")

func interact_power_block(direction, roomType):
	if roomType != null && roomType == GlobalVariables.ROOM_TYPE.PUZZLEROOM:
		match direction:
			Vector2(-1,0):
				if activeDirections.has(GlobalVariables.DIRECTION.LEFT):
					activeDirections.erase(GlobalVariables.DIRECTION.LEFT)
				else:
					activeDirections.append(GlobalVariables.DIRECTION.LEFT)
			Vector2(1,0):
				if activeDirections.has(GlobalVariables.DIRECTION.RIGHT):
					activeDirections.erase(GlobalVariables.DIRECTION.RIGHT)
				else:
					activeDirections.append(GlobalVariables.DIRECTION.RIGHT)
			Vector2(0,-1):
				if activeDirections.has(GlobalVariables.DIRECTION.UP):
					activeDirections.erase(GlobalVariables.DIRECTION.UP)
				else:
					activeDirections.append(GlobalVariables.DIRECTION.UP)
			Vector2(0,1):
				if activeDirections.has(GlobalVariables.DIRECTION.DOWN):
					activeDirections.erase(GlobalVariables.DIRECTION.DOWN)
				else:
					activeDirections.append(GlobalVariables.DIRECTION.DOWN)#
	if activeDirections.size() == 0:
		$AnimationPlayer.play("ArrowNull")
	if activeDirections.size() == 1:
		if activeDirections.has(GlobalVariables.DIRECTION.LEFT):
			$AnimationPlayer.play("ArrowLeft")
		if activeDirections.has(GlobalVariables.DIRECTION.RIGHT):
			$AnimationPlayer.play("ArrowRight")
		if activeDirections.has(GlobalVariables.DIRECTION.DOWN):
			$AnimationPlayer.play("ArrowDown")
		if activeDirections.has(GlobalVariables.DIRECTION.UP):
			$AnimationPlayer.play("ArrowUp")
			
	if activeDirections.size() == 2:
		if activeDirections.has(GlobalVariables.DIRECTION.LEFT) && activeDirections.has(GlobalVariables.DIRECTION.RIGHT):
			$AnimationPlayer.play("ArrowLeftRight")
		if activeDirections.has(GlobalVariables.DIRECTION.UP) && activeDirections.has(GlobalVariables.DIRECTION.DOWN):
			$AnimationPlayer.play("ArrowUpDown")
		if activeDirections.has(GlobalVariables.DIRECTION.UP) && activeDirections.has(GlobalVariables.DIRECTION.RIGHT):
			$AnimationPlayer.play("ArrowUpRight")
		if activeDirections.has(GlobalVariables.DIRECTION.RIGHT) && activeDirections.has(GlobalVariables.DIRECTION.DOWN):
			$AnimationPlayer.play("ArrowRightDown")
		if activeDirections.has(GlobalVariables.DIRECTION.DOWN) && activeDirections.has(GlobalVariables.DIRECTION.LEFT):
			$AnimationPlayer.play("ArrowDownLeft")
		if activeDirections.has(GlobalVariables.DIRECTION.LEFT) && activeDirections.has(GlobalVariables.DIRECTION.UP):
			$AnimationPlayer.play("ArrowLeftUp")

	if activeDirections.size() == 3:
		if activeDirections.has(GlobalVariables.DIRECTION.UP) && activeDirections.has(GlobalVariables.DIRECTION.RIGHT) && activeDirections.has(GlobalVariables.DIRECTION.DOWN):
			$AnimationPlayer.play("ArrowUpRightDown")
		if activeDirections.has(GlobalVariables.DIRECTION.RIGHT) && activeDirections.has(GlobalVariables.DIRECTION.DOWN) && activeDirections.has(GlobalVariables.DIRECTION.LEFT):
			$AnimationPlayer.play("ArrowRightDownLeft")
		if activeDirections.has(GlobalVariables.DIRECTION.DOWN) && activeDirections.has(GlobalVariables.DIRECTION.LEFT) && activeDirections.has(GlobalVariables.DIRECTION.UP):
			$AnimationPlayer.play("ArrowDownLeftUp")
			print("Arrow down left up")
		if activeDirections.has(GlobalVariables.DIRECTION.LEFT) && activeDirections.has(GlobalVariables.DIRECTION.UP) && activeDirections.has(GlobalVariables.DIRECTION.RIGHT):
			$AnimationPlayer.play("ArrowLeftUpRight")
			
	if activeDirections.size() == 4:
		if activeDirections.has(GlobalVariables.DIRECTION.UP) && activeDirections.has(GlobalVariables.DIRECTION.RIGHT) && activeDirections.has(GlobalVariables.DIRECTION.DOWN) && activeDirections.has(GlobalVariables.DIRECTION.LEFT):
			$AnimationPlayer.play("ArrowUpRightDownLeft")
			
	backupActiveDirections = activeDirections.duplicate()

func add_count():
	if counters == 5:
		return
	counters += 1
	match counters:
		0:
			$AnimationPlayer.play("Counter0")
		1:
			$AnimationPlayer.play("Counter1")
		2:
			$AnimationPlayer.play("Counter2")
		3:
			$AnimationPlayer.play("Counter3")
		4:
			$AnimationPlayer.play("Counter4")
		5:
			$AnimationPlayer.play("Counter5")


func explode_block():
	if counters < 1:
		return false 
	GlobalVariables.turnController.blocksExploding.append(self)
	set_process(false)
	$AnimationPlayer.play("ExplodeBlock", -1, 1.5)
	$Tween.interpolate_property(self, "position", position, position , $AnimationPlayer.current_animation_length/1.5, Tween.TRANS_LINEAR, Tween.EASE_IN)
	#position = target_position
	$Tween.start()
	yield($AnimationPlayer, "animation_finished")
	set_process(true)
	Grid.on_Power_Block_explode(self)
	return true
	
func spawn_magic_from_block(signalSpawnMagic):
	Grid.on_powerBlock_spawn_magic(self, signalSpawnMagic)
