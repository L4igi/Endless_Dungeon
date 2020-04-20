extends Node2D

onready var Grid = get_parent()

enum CELL_TYPES{PLAYER=0, WALL=1, ENEMY=2, PUZZLEPIECE=3, ITEM=4, DOOR=5, UNLOCKEDDOOR = 6}
export(CELL_TYPES) var type = CELL_TYPES.ENEMY

var madeMove = false

var isDisabled = true

signal enemyMadeMove

func _ready():
	pass
	

func _process(delta): 
	randomize()

	if(isDisabled == false && madeMove == false):
		var upDownLeftRight = randi()%4+1
		var movement_direction = Vector2.ZERO
		match upDownLeftRight:
			1:
				movement_direction = Vector2(1,0)
			2:
				movement_direction = Vector2(-1,0)
			3: 
				movement_direction = Vector2(0,1)
			4:
				movement_direction = Vector2(0,-1)
				
		var target_position = Grid.request_move(self, movement_direction)
		if(target_position):
			position=target_position
			madeMove = true
			emit_signal("enemyMadeMove")

func generateEnemy(): 
	pass 
	
	#set enemy difficulty and type set enemy stats based on difficulty set amount of enemies to spawn based on room size and difficulty 

