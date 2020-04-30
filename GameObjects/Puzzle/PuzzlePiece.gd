extends Node2D


var color 

var baseModulation 

signal puzzlePlayedAnimation 

signal puzzlePieceActivated
# Called when the node enters the scene tree for the first time.
func _ready():
	baseModulation = get_node("Sprite").get_self_modulate()
	
func playColor():
	set_process(false)
	get_node("Sprite").set_self_modulate(baseModulation)
	match color:
		GlobalVariables.COLOR.RED:
			$AnimationPlayer.play("Red")
		GlobalVariables.COLOR.BLUE:
			$AnimationPlayer.play("Blue")
		GlobalVariables.COLOR.GREEN:
			$AnimationPlayer.play("Green")
		GlobalVariables.COLOR.YELLOW:
			$AnimationPlayer.play("Yellow")
	$Tween.interpolate_property(self, "position", position, position , $AnimationPlayer.current_animation_length, Tween.TRANS_LINEAR, Tween.EASE_IN)
	$Tween.start()
	yield($AnimationPlayer, "animation_finished")
	set_process(true)
	emit_signal("puzzlePlayedAnimation")

func activatePuzzlePiece():
	get_node("Sprite").set_self_modulate(Color(0,255,0,1.0))
	emit_signal("puzzlePieceActivated")
