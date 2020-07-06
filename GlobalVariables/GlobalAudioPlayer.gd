#holds the main audio loop playing in the bakground
#keeps playing when entering new floor 
extends AudioStreamPlayer

var inMenu = false

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func _process(delta):
	pass
	#print(self.get_playback_position())


func _on_AudioStreamPlayer_finished():
	if inMenu:
		self.stream = load("res://GlobalVariables/GameLoop-Menu.ogg")
		self.play()
	else:
		self.stream = load("res://GlobalVariables/GameLoop-1.ogg")
		self.play()
