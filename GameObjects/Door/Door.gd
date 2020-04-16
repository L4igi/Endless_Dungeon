extends Node2D

onready var Grid = get_parent()

enum CELL_TYPES{PLAYER=0, WALL=1, ENEMY=2, PUZZLEPIECE=3, ITEM=4, DOOR=5}
export(CELL_TYPES) var type = CELL_TYPES.DOOR

var isUnlocked = false
var doorDirection

var doorRoomLeftMostCorner

var roomSize = Vector2.ZERO
var roomSizeMultiplier = Vector2.ZERO

var doorLocationDirection

func _ready():
	pass
	

func _process(delta):
	pass
	
func unlock_Door():
	isUnlocked=true
	print("Door was unlocked")
	Grid.create_doors(doorRoomLeftMostCorner, false, roomSize.x, roomSize.y, roomSizeMultiplier, doorLocationDirection)
	
#func create_doors(roomLeftMostCorner, startingRoom=false, roomSizeHorizontal = 13, roomSizeVertical = 13, roomsizeMultiplyer = Vector2(1,1), doorLocationDirection = "LEFT"):
