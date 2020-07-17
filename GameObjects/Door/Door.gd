#The Door is the root of every Room 
# It holds the roomType, elements in the Room etc. 
#can be a barrier 
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

var roomCleared = false 

var enemiesInRoom = []

var puzzlePiecesInRoom = []

var powerBlocksInRoom = []

var upgradeContainersInRoom = []

var countingBlocksInRoom = []

var roomType = ROOM_TYPE.EMPTYTREASUREROOM

func _ready():
	var player = Grid.get_node("Player")
	for child in player.get_children():
		if child is Camera2D:
			child.connect("toggleMapSignal", self, "on_toggle_map")
	get_node("Sprite").set_frame(6)
	

func rotate_door_sprite():
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
	
#creates adjacent rooms 
#decides roomType for room just entered 
#adaptes roomtype spawn probability 
func unlock_Door():
	isUnlocked=true
	Grid.create_doors(doorRoomLeftMostCorner, false, roomSize.x, roomSize.y, roomSizeMultiplier, doorLocationDirection)
	var randRoomType = randi()%100
	if(randRoomType <= GlobalVariables.enemyRoomChance):
		roomType = ROOM_TYPE.ENEMYROOM
		GlobalVariables.turnController.inRoomType = ROOM_TYPE.ENEMYROOM
		Grid.create_enemy_room(self)
		if GlobalVariables.enemyRoomChance >= 2:
			GlobalVariables.enemyRoomChance -= 2
			GlobalVariables.puzzleRoomChance += 1
			GlobalVariables.emptyTreasureRoomChance += 1
	elif(randRoomType > GlobalVariables.enemyRoomChance && randRoomType < (GlobalVariables.enemyRoomChance+GlobalVariables.puzzleRoomChance)):
		roomType = ROOM_TYPE.PUZZLEROOM
		GlobalVariables.turnController.inRoomType = ROOM_TYPE.PUZZLEROOM
		Grid.create_puzzle_room(self)
		if GlobalVariables.puzzleRoomChance >= 4:
			GlobalVariables.puzzleRoomChance -= 4
			GlobalVariables.enemyRoomChance += 2
			GlobalVariables.emptyTreasureRoomChance += 1
	elif(randRoomType >= (GlobalVariables.enemyRoomChance+GlobalVariables.puzzleRoomChance)):
		GlobalVariables.turnController.inRoomType = ROOM_TYPE.EMPTYTREASUREROOM
		roomType = ROOM_TYPE.EMPTYTREASUREROOM
		Grid.create_empty_treasure_room(self)
		if GlobalVariables.emptyTreasureRoomChance > 4:
			GlobalVariables.emptyTreasureRoomChance -= 4
			GlobalVariables.puzzleRoomChance += 2
			GlobalVariables.enemyRoomChance += 2
			
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
	
func get_room_by_movement_direction(direction):
	if(otherAdjacentRoom.has(direction) == true):
		return otherAdjacentRoom.get(direction)
	return self

func drop_loot():
	Grid.numberRoomsCleared+=1
	on_room_solved()
	return true
	
func update_container_prices():
	for container in upgradeContainersInRoom:
		container.updatePrice()
	
func make_door_barrier(currentGrid):
	var barrierChance = randi()%3
	print("BarrierChance == " + str(barrierChance))
	var checkBarrierPossible = currentGrid.manage_barrier_creation(GlobalVariables.BARRIERTYPE.DOOR)
	if(barrierChance == 1 && currentGrid.currentNumberRoomsgenerated!=0 && checkBarrierPossible):
		isBarrier = true
		get_node("Sprite").set_modulate(Color(randf(),randf(),randf(),1.0))
		barrierKeyValue = str(randi()%10) + str(randi()%10) + str(randi()%10) + str(randi()%10) + str(randi()%10)
		#check if generated value is unique and not already used 
		for count in range (0,currentGrid.barrierKeysNoSolution.size()):
			if barrierKeyValue == currentGrid.barrierKeysNoSolution[count].keyValue:
				barrierKeyValue = str(randi()%10) + str(randi()%10) + str(randi()%10) + str(randi()%10) + str(randi()%10)
				count = 0
		currentGrid.generate_keyValue_item(barrierKeyValue, get_node("Sprite").get_modulate(), GlobalVariables.ITEMTYPE.KEY, self)


#functions to add/change Map TextureRects
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
