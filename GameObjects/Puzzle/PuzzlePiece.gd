extends Node2D

onready var Grid = get_parent()

var color 

var baseModulation 

var isActivated = false

var isBarrier = false

var activationDelay = 0

var barrierKeyValue

signal puzzlePlayedAnimation 

signal puzzlePieceActivated

# Called when the node enters the scene tree for the first time.
func _ready():
	baseModulation = get_node("Sprite").get_self_modulate()
	Grid.connect("puzzleBarrierDisableSignal", self, "_on_puzzlepiece_barrier_disable")
	
func playColor():
	set_process(false)
	if isBarrier:
		get_node("Sprite").set_self_modulate(baseModulation)
		$AnimationPlayer.play("isBarrier", -1, 0.8)
	else:
		get_node("Sprite").set_self_modulate(color)
		$AnimationPlayer.play("playColor", -1, 0.8)
	$Tween.interpolate_property(self, "position", position, position , $AnimationPlayer.current_animation_length*0.8, Tween.TRANS_LINEAR, Tween.EASE_IN)
	$Tween.start()
	yield($AnimationPlayer, "animation_finished")
	set_process(true)
	get_node("Sprite").set_self_modulate(baseModulation)
	emit_signal("puzzlePlayedAnimation")

func activatePuzzlePiece():
	if !isActivated:
		isActivated = true
		get_node("Sprite").set_self_modulate(Color(0,255,0,1.0))
		emit_signal("puzzlePieceActivated")
	
func playWrongWriteAnimation(right = true):
	if right:
		get_node("Sprite").set_self_modulate(baseModulation)
		$AnimationPlayer.play("inactive")
	else:
		get_node("Sprite").set_self_modulate(baseModulation)
		$AnimationPlayer.play("Idle")

func makePuzzleBarrier(currentGrid):
	randomize()
	if(currentGrid.currentNumberRoomsgenerated!=0):
		isBarrier = true
		get_node("Sprite").set_self_modulate(Color(randf(),randf(),randf(),1.0))
		barrierKeyValue = str(randi()%10) + str(randi()%10) + str(randi()%10) + str(randi()%10) + str(randi()%10)
		#check if generated value is unique and not already used 
		for count in range (0,currentGrid.barrierKeysNoSolution.size()):
			if barrierKeyValue == currentGrid.barrierKeysNoSolution[count].keyValue:
				barrierKeyValue = str(randi()%10) + str(randi()%10) + str(randi()%10) + str(randi()%10) + str(randi()%10)
				count = 0
		currentGrid.generate_keyValue_item(barrierKeyValue, get_node("Sprite").get_self_modulate(), GlobalVariables.ITEMTYPE.PUZZLESWITCH)
	
	
func _on_puzzlepiece_barrier_disable(item, mainPlayer):
	if item.keyValue == barrierKeyValue:
		get_node("Sprite").set_deferred("self_modulate", "ffffff")
		baseModulation = "ffffff"
		print("Player activated PuzzlePiece Switch")
		isBarrier = false
