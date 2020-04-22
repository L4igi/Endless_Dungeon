extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	get_node("/root/MainCamera").connect("cameraSmoothTransition", self, "_on_camera_transition")

func _on_camera_transition(camera, targetPosition):
	pass
	#fix camera movement
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
