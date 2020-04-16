extends "res://GameObjects/gameObject.gd"

onready var Grid = get_parent()

var playerPreviousPosition = Vector2.ZERO

func _ready():
	pass

func _process(delta):
	var movement_direction = get_movement_direction()

	var target_position = Grid.request_move(self, movement_direction)
	if target_position:
		playerPreviousPosition = position
		position = target_position
		#print("Current FrameRate: " + str(Engine.get_frames_per_second())) 
		#Grid._spawn_enemy_after_move(self)
		#Grid.create_doors(self.position, Vector2(16,16), true)



func get_movement_direction():
	var UP = Input.is_action_just_pressed("player_up")
	var DOWN = Input.is_action_just_pressed("player_down")
	var LEFT = Input.is_action_just_pressed("player_left")
	var RIGHT = Input.is_action_just_pressed("player_right")
	
	var movedir = Vector2.ZERO
	movedir.x = -int(LEFT) + int(RIGHT) # if pressing both directions this will return 0
	movedir.y = -int(UP) + int(DOWN)
	
	return movedir
