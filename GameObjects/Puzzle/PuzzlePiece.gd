extends Node2D


var color 

signal puzzlePlayedAnimation 

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func playColor():
	set_process(false)
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
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
