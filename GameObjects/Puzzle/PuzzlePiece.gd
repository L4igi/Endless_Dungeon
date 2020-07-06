extends Node2D

onready var Grid = get_parent()

var activateSound = preload("res://GameObjects/Puzzle/activate_puzzle.wav")

var color 

var baseModulation 

var isActivated = false

var isBarrier = false

var activationDelay = 0

var inRoom = null

var barrierKeyValue

signal puzzlePlayedAnimation(puzzlePiece)

signal puzzlePieceActivated


func _ready():
	baseModulation = get_node("Sprite").get_self_modulate()
	Grid.connect("puzzleBarrierDisableSignal", self, "_on_puzzlepiece_barrier_disable")
	
func play_color(puzzlePieceArray, count, onRoomEnter):
	set_process(false)
	var playDuration = 1.1
	if count == 0 && onRoomEnter:
		playDuration = 0.55
	if isBarrier:
		get_node("Sprite").set_self_modulate(baseModulation)
		$AnimationPlayer.play("isBarrier", -1, playDuration)
	else:
		get_node("Sprite").set_self_modulate(color)
		$AnimationPlayer.play("playColor", -1, playDuration)
	yield($AnimationPlayer, "animation_finished")
	if !isBarrier:
		$AnimationPlayer.play("Idle")
	set_process(true)
	get_node("Sprite").set_self_modulate(baseModulation)
	emit_signal("puzzlePlayedAnimation", self)
	count += 1
	if count < puzzlePieceArray.size():
		puzzlePieceArray[count].play_color(puzzlePieceArray, count, onRoomEnter)

func activate_puzzle_piece():
	if !isActivated && !Grid.activeRoom.roomCleared:
		isActivated = true
		if !isBarrier:
			print("recoloring")
			get_node("Sprite").set_self_modulate(color)
			get_node("AudioStreamPlayer2D").stream = activateSound
			get_node("AudioStreamPlayer2D").play()
		emit_signal("puzzlePieceActivated")
	
func play_wrong_right_animation(right = true):
	if right:
		get_node("Sprite").set_self_modulate(baseModulation)
		$AnimationPlayer.play("inactive")
	else:
		get_node("Sprite").set_self_modulate(baseModulation)
		if isBarrier:
			$AnimationPlayer.play("isBarrier")
		else:
			$AnimationPlayer.play("wrong")

func make_puzzle_barrier(currentGrid, unlockedDoor):
	randomize()
	var barrierChance = randi()%3
	var checkBarrierPossible = currentGrid.manage_barrier_creation(GlobalVariables.BARRIERTYPE.PUZZLE)
	if(barrierChance == 1 && currentGrid.currentNumberRoomsgenerated!=0 && checkBarrierPossible):
		isBarrier = true
		inRoom = unlockedDoor
		get_node("Sprite").set_self_modulate(Color(randf(),randf(),randf(),1.0))
		barrierKeyValue = str(randi()%10) + str(randi()%10) + str(randi()%10) + str(randi()%10) + str(randi()%10)
		#check if generated value is unique and not already used 
		for count in range (0,currentGrid.barrierKeysNoSolution.size()):
			if barrierKeyValue == currentGrid.barrierKeysNoSolution[count].keyValue:
				barrierKeyValue = str(randi()%10) + str(randi()%10) + str(randi()%10) + str(randi()%10) + str(randi()%10)
				count = 0
		currentGrid.generate_keyValue_item(barrierKeyValue, get_node("Sprite").get_self_modulate(), GlobalVariables.ITEMTYPE.PUZZLESWITCH, unlockedDoor)
	
	
func _on_puzzlepiece_barrier_disable(item, mainPlayer):
	if item.keyValue == barrierKeyValue:
		get_node("Sprite").set_deferred("self_modulate", "ffffff")
		baseModulation = "ffffff"
		print("Player activated PuzzlePiece Switch")
		isBarrier = false
		inRoom.on_use_key_item(item)
