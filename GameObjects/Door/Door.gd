extends Node2D

onready var Grid = get_parent()

enum CELL_TYPES{PLAYER=0, WALL=1, ENEMY=2, PUZZLEPIECE=3, ITEM=4, DOOR=5, UNLOCKEDDOOR=6}
export(CELL_TYPES) var type = CELL_TYPES.DOOR

var isUnlocked = false
var doorDirection

var doorRoomLeftMostCorner

var roomSize = Vector2.ZERO
var roomSizeMultiplier = Vector2.ZERO

var doorLocationDirection

var otherAdjacentRoom = {}

var enemiesInRoom = []

func _ready():
	pass
	

func _process(delta):
	pass
	
func unlock_Door(enemyRoomChance, puzzleRoomChance, emptyTreasureRoomChance):
	isUnlocked=true
	Grid.create_doors(doorRoomLeftMostCorner, false, roomSize.x, roomSize.y, roomSizeMultiplier, doorLocationDirection)
#	Grid.create_enemy_room(self)
	#print("Door was unlocked")
	#choose type of room to be created 
	var randRoomType = randi()%100
	if(randRoomType < enemyRoomChance):
		print("create enemy room " + str(randRoomType))
		Grid.create_enemy_room(self)
	elif(randRoomType > enemyRoomChance && randRoomType < (enemyRoomChance+puzzleRoomChance)):
		print("creating puzzle room " + str(randRoomType))
	elif(randRoomType > (enemyRoomChance+puzzleRoomChance)):
		print("creating empty/Treasure room " + str(randRoomType))

func set_other_adjacent_room(otherRoom, direction):
	var reversedDirection 
	match direction:
		"UP":
			reversedDirection="DOWN"
		"DOWN":
			reversedDirection="UP"
		"LEFT":
			reversedDirection="RIGHT"
		"RIGHT":
			reversedDirection="LEFT"
		
	otherAdjacentRoom [reversedDirection] = otherRoom
	
	print("set_other_adjacent_room " + str(otherRoom)+ " this room node " + str(self))
		
func get_room_by_movement_direction(direction):
	#print("Other room: " + str(otherAdjacentRoom) + " self room " + str(self))
	if(otherAdjacentRoom.has(direction) == true):
		return otherAdjacentRoom.get(direction)
	return self
