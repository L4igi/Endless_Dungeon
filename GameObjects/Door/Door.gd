extends Node2D

onready var Grid = get_parent()

enum CELL_TYPES{PLAYER=0, WALL=1, ENEMY=2, PUZZLEPIECE=3, ITEM=4, DOOR=5, UNLOCKEDDOOR=6, MAGICPROJECTILE=7, BLOCK=8}
export(CELL_TYPES) var type = CELL_TYPES.DOOR

enum ROOM_TYPE{ENEMYROOM = 0, PUZZLEROOM = 1, EMPTYTREASUREROOM = 2}
export(ROOM_TYPE) var roomtype = ROOM_TYPE.EMPTYTREASUREROOM

var isUnlocked = false

var barrierKeyValue

var doorDirection

var doorRoomLeftMostCorner

var roomSize = Vector2.ZERO
var roomSizeMultiplier = Vector2.ZERO

var doorLocationDirection

var otherAdjacentRoom = {}

var isBarrier = false 

var enemiesInRoom = []

var isEnemyBarrier = false

var puzzlePiecesInRoom = []

var isPuzzleBarrier = false

var powerBlocksInRoom = []

var upgradeContainersInRoom = []

var roomType = ROOM_TYPE.EMPTYTREASUREROOM

var roomCleared = false

var createExit = false

func _ready():
	var player = Grid.get_node("Player")
	for child in player.get_children():
		if child is Camera2D:
			child.connect("toggleMapSignal", self, "on_toggle_map")
			
	get_node("Sprite").set_frame(6)
		
	
# warning-ignore:unused_argument
func _process(delta):
	pass
		

func rotateDoor():
	print(doorLocationDirection)
	match doorLocationDirection:
		"LEFT":
			get_node("Sprite").rotation_degrees = 270
			get_node("Gate").rotation_degrees = 270
		"RIGHT":
			get_node("Sprite").rotation_degrees = 90
			get_node("Gate").rotation_degrees = 90
		"UP":
			get_node("Sprite").rotation_degrees = 0
			get_node("Gate").rotation_degrees = 0
		"DOWN":
			get_node("Sprite").rotation_degrees = 180
			get_node("Gate").rotation_degrees = 180
	
func request_door_unlock(playerItemsInPosession):
	for item in playerItemsInPosession:
		print("Player items in posession " + str(item.keyValue))
	if(isBarrier):
		for item in playerItemsInPosession:
			if item.keyValue == barrierKeyValue:
				print("Door Barrier " + str(barrierKeyValue) + " was unlocked using item key " + str(item.keyValue))
				isBarrier = false
				get_node("Sprite").set_visible(false)
				return item
		print("need key: " + str(barrierKeyValue) + " to unlock door ")
		return null
	get_node("Sprite").set_visible(false)
	return true
	
# warning-ignore:unused_argument
func unlock_Door(enemyRoomChance, puzzleRoomChance, emptyTreasureRoomChance):
	isUnlocked=true

	Grid.create_doors(doorRoomLeftMostCorner, false, roomSize.x, roomSize.y, roomSizeMultiplier, doorLocationDirection)

	var randRoomType = randi()%85
#		randRoomType = 90
	if(randRoomType < enemyRoomChance):
		#print("create enemy room " + str(randRoomType))
		roomType = ROOM_TYPE.ENEMYROOM
		GlobalVariables.turnController.inRoomType = ROOM_TYPE.ENEMYROOM
		Grid.create_enemy_room(self)
	elif(randRoomType > enemyRoomChance && randRoomType < (enemyRoomChance+puzzleRoomChance)):
		#print("creating puzzle room " + str(randRoomType))
		roomType = ROOM_TYPE.PUZZLEROOM
		GlobalVariables.turnController.inRoomType = ROOM_TYPE.PUZZLEROOM
		Grid.create_puzzle_room(self)
	elif(randRoomType > (enemyRoomChance+puzzleRoomChance)):
		#print("creating empty/Treasure room " + str(randRoomType))
		GlobalVariables.turnController.inRoomType = ROOM_TYPE.EMPTYTREASUREROOM
		roomType = ROOM_TYPE.EMPTYTREASUREROOM
		Grid.create_empty_treasure_room(self)
		#set room to cleared because its empty room


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
	Grid.numberRoomsCleared+=1
	on_room_solved()
	return true
	
func updateContainerPrices():
	for container in upgradeContainersInRoom:
		container.updatePrice()
	
func makeDoorBarrier(currentGrid):
	var barrierChance = 1
	var checkBarrierPossible = currentGrid.manage_barrier_creation(GlobalVariables.BARRIERTYPE.DOOR)
	if(barrierChance == 1 && currentGrid.currentNumberRoomsgenerated!=0 && checkBarrierPossible):
		#print("generating door barrier")
		isBarrier = true
		get_node("Sprite").set_modulate(Color(randf(),randf(),randf(),1.0))
		barrierKeyValue = str(randi()%10) + str(randi()%10) + str(randi()%10) + str(randi()%10) + str(randi()%10)
		#check if generated value is unique and not already used 
		for count in range (0,currentGrid.barrierKeysNoSolution.size()):
			if barrierKeyValue == currentGrid.barrierKeysNoSolution[count].keyValue:
				barrierKeyValue = str(randi()%10) + str(randi()%10) + str(randi()%10) + str(randi()%10) + str(randi()%10)
				count = 0
		currentGrid.generate_keyValue_item(barrierKeyValue, get_node("Sprite").get_modulate(), GlobalVariables.ITEMTYPE.KEY, self)


#functions to add/change Map Boxes 
func setBoxMapBG():
	get_node("showBarrierItemsTextRekt").set_dimensions(roomSize, position, doorRoomLeftMostCorner)
	
func setBoxMapItems(item):
	get_node("showBarrierItemsTextRekt").addBoxElement(item)

func on_toggle_map():
	get_node("showBarrierItemsTextRekt").toggleBox()
	
func on_use_key_item(item):
	get_node("showBarrierItemsTextRekt").delete_Box_item(item)

func on_room_solved():
	get_node("showBarrierItemsTextRekt").setSolvedTexture()
