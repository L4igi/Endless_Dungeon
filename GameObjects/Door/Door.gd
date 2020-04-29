extends Node2D

onready var Grid = get_parent()

enum CELL_TYPES{PLAYER=0, WALL=1, ENEMY=2, PUZZLEPIECE=3, ITEM=4, DOOR=5, UNLOCKEDDOOR=6, MAGICPROJECTILE=7, BLOCK=8}
export(GlobalVariables.CELL_TYPES) var type = CELL_TYPES.DOOR

enum ROOM_TYPE{ENEMYROOM = 0, PUZZLEROOM = 1, EMPTYTREASUREROOM = 2}
export(ROOM_TYPE) var roomtype = ROOM_TYPE.EMPTYTREASUREROOM


var isUnlocked = false

var isBarrier = false 

var barrierKeyValue

var doorDirection

var doorRoomLeftMostCorner

var roomSize = Vector2.ZERO
var roomSizeMultiplier = Vector2.ZERO

var doorLocationDirection

var otherAdjacentRoom = {}

var enemiesInRoom = []

var roomType = ROOM_TYPE.EMPTYTREASUREROOM

var roomCleared = false

func _ready():
	randomize()
	#determins if door is barrier or not 
	var barrierChance = randi()% 4+1 
	if(barrierChance == 1 && Grid.currentNumberRoomsgenerated!=0):
		isBarrier = true
		get_node("Sprite").set_modulate(Color(0,0,0,1.0))
		barrierKeyValue = str(randi()%10) + str(randi()%10) + str(randi()%10) + str(randi()%10) + str(randi()%10)
		#check if generated value is unique and not already used 
		for count in range (0,Grid.barrierKeysNoSolution.size()):
			if barrierKeyValue == Grid.barrierKeysNoSolution[count]:
				barrierKeyValue = str(randi()%10) + str(randi()%10) + str(randi()%10) + str(randi()%10) + str(randi()%10)
				count = 0
		Grid.barrierKeysNoSolution.append(barrierKeyValue)
	
			
func _process(delta):
	pass
		
func request_door_unlock(playerItemsInPosession):
	for item in playerItemsInPosession:
		print("Player items in posession " + str(item.keyValue))
	if(isBarrier):
		for item in playerItemsInPosession:
			if item.keyValue == barrierKeyValue:
				print("Door Barrier " + str(barrierKeyValue) + " was unlocked using item key " + str(item.keyValue))
				return true
		print("need key: " + str(barrierKeyValue) + " to unlock door ")
		return false
	return true
	
func unlock_Door(enemyRoomChance, puzzleRoomChance, emptyTreasureRoomChance):
	isUnlocked=true
	Grid.create_doors(doorRoomLeftMostCorner, false, roomSize.x, roomSize.y, roomSizeMultiplier, doorLocationDirection)
#	Grid.create_enemy_room(self)
	#print("Door was unlocked")
	#choose type of room to be created 
	#var randRoomType = randi()%100
	var randRoomType = randi()%60
	if(randRoomType < enemyRoomChance):
		#print("create enemy room " + str(randRoomType))
		roomType = ROOM_TYPE.ENEMYROOM
		Grid.create_enemy_room(self)
	elif(randRoomType > enemyRoomChance && randRoomType < (enemyRoomChance+puzzleRoomChance)):
		#print("creating puzzle room " + str(randRoomType))
		roomType = ROOM_TYPE.PUZZLEROOM
		Grid.create_puzzle_room(self)
	elif(randRoomType > (enemyRoomChance+puzzleRoomChance)):
		#print("creating empty/Treasure room " + str(randRoomType))
		roomType = ROOM_TYPE.EMPTYTREASUREROOM
		#set room to cleared because its empty room
		roomCleared = true

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
	
	#print("set_other_adjacent_room " + str(otherRoom)+ " this room node " + str(self))
		
func get_room_by_movement_direction(direction):
	#print("Other room: " + str(otherAdjacentRoom) + " self room " + str(self))
	if(otherAdjacentRoom.has(direction) == true):
		return otherAdjacentRoom.get(direction)
	return self

func dropLoot():
	#calculate chance of loot dropping 
	return true
