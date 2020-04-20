extends "res://GameObjects/gameObject.gd"

onready var Grid = get_parent()

var madeMove = false 

var playerPreviousPosition = Vector2.ZERO

signal playerMadeMove 

var playerPassedDoor = Vector2.ZERO

func _ready():
	pass

func _process(delta):
	if(madeMove == false):
		var movement_direction = get_movement_direction()
	
		if(playerPassedDoor == Vector2.ZERO):
			var target_position = Grid.request_move(self, movement_direction)
		#	if (target_position && madeMove == false):
			if target_position:
				playerPreviousPosition = position
				position = target_position
				emit_signal("playerMadeMove")
				#print("Current FrameRate: " + str(Engine.get_frames_per_second())) 
				#Grid._spawn_enemy_after_move(self)
				#Grid.create_doors(self.position, Vector2(16,16), true)
		else:
			var target_position = Grid.request_move(self,playerPassedDoor)
			if (target_position):
				playerPreviousPosition = position
				position = target_position
			playerPassedDoor = Vector2.ZERO
			



func get_movement_direction():
	var UP = Input.is_action_just_pressed("player_up")
	var DOWN = Input.is_action_just_pressed("player_down")
	var LEFT = Input.is_action_just_pressed("player_left")
	var RIGHT = Input.is_action_just_pressed("player_right")
	
	var movedir = Vector2.ZERO
	movedir.x = -int(LEFT) + int(RIGHT) # if pressing both directions this will return 0
	movedir.y = -int(UP) + int(DOWN)
	
	return movedir
