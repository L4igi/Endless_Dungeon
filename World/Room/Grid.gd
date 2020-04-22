extends TileMap

enum objectTyped { EMPTY, PLAYER, WALL, ENEMY, PUZZLEPIECE, ITEM, DOOR, UNLOCKEDDOOR}

var Enemy = preload("res://GameObjects/Enemy/Enemy.tscn")

var Wall = preload("res://GameObjects/Wall/Wall.tscn")

var Door = preload("res://GameObjects/Door/Door.tscn")

var Item = preload("res://GameObjects/Item/Item.tscn")

var roomDimensions = 9

var evenOddModifier = 0 

var maxNumberRooms = 12

var currentNumberRoomsgenerated = 0

var activeRoom = null

var movedThroughDoor = false

var enemyRoomChance = 33
var puzzleRoomChance = 33
var emptyTreasureRoomChance = 34

var enemiesInActiveRoom = []

var enemiesMadeMoveCounter = 0

var barrierKeysNoSolution = []

var barrierKeysSolutionSpawned = []

func match_Enum(var index):
	match index:
		0:
			return "PLAYER"
		1:
			return "WALL"
		2:
			return "ENEMY"
		3:
			return "PUZZLEPIECE"
		4:
			return "ITEM"
		5:
			return "DOOR"
		6:
			return "UNLOCKEDDOOR"
		-1:
			return "EMPTY"
		_:
			return "NULL"
			

func set_enum_index(var enumName, var setTo):
	match enumName:
		"PLAYER":
			objectTyped.PLAYER=setTo
		"WALL":
			objectTyped.WALL=setTo
		"ENEMY":
			objectTyped.ENEMY=setTo
		"PUZZLEPIECE":
			objectTyped.PUZZLEPIECE=setTo
		"ITEM":
			objectTyped.ITEM=setTo
		"DOOR":
			objectTyped.DOOR=setTo
		"UNLOCKEDDOOR":
			objectTyped.UNLOCKEDDOOR=setTo
		"EMPTY":
			objectTyped.EMPTY=-1
		_:
			pass
			

func _ready():
	for child in get_children():
		set_cellv(world_to_map(child.position), get_tileset().find_tile_by_name(match_Enum(child.type)))
	for element in objectTyped:
		set_enum_index(element, get_tileset().find_tile_by_name(element))
		#print(get_tileset().find_tile_by_name(element))
	if(roomDimensions%2 == 0):
		evenOddModifier = 1
	create_starting_room(true)
	get_node("Player").connect("playerMadeMove", self, "_on_Player_Made_Move")
	get_node("Player").connect("playerAttacked", self, "_on_Player_Attacked")
		

func get_cell_pawn(coordinates):
	for node in get_children():
		if world_to_map(node.position) == coordinates:
			return(node)
			
			
func request_move(pawn, direction):
	var cell_start = world_to_map(pawn.position)
	
	var cell_target = cell_start + direction
	var cell_target_type = get_cellv(cell_target)
	
#	cell_target_type = get_tileset().find_tile_by_name(matchEnum(cell_target_type))
#	#print(get_tileset().find_tile_by_name(matchEnum(cell_target_type)))
		#print("Got Cell V: " + str(cell_target_type))
	if(pawn.name == "Player"):
		match cell_target_type:
			objectTyped.EMPTY:
				#print("EMPTY")
				#print("Player Position " + str(cell_target))
				return update_pawn_position(pawn, cell_start, cell_target)
			objectTyped.ENEMY:
#				var object_pawn = get_cell_pawn(cell_target)
#				activeRoom.enemiesInRoom.erase(object_pawn)
#				object_pawn.queue_free()
#				#print("ENEMY")
#				return update_pawn_position(pawn, cell_start, cell_target)
				pass
			objectTyped.WALL:
				#print("WALL")
				pass
			objectTyped.ITEM:
				var object_pawn = get_cell_pawn(cell_target)
				print("Item spawned key value " + object_pawn.keyValue)
				pawn.itemsInPosession.append(object_pawn)
				object_pawn.get_node("Sprite").queue_free()
				#print("Player has Items in posession " + str(pawn.itemsInPosession))
				return update_pawn_position(pawn, cell_start, cell_target)
			objectTyped.DOOR:
				var object_pawn = get_cell_pawn(cell_target)
				if(object_pawn.request_door_unlock(pawn.itemsInPosession)):
					object_pawn.unlock_Door(enemyRoomChance, puzzleRoomChance, emptyTreasureRoomChance)
					return update_pawn_position(pawn, cell_start, cell_target)
			objectTyped.UNLOCKEDDOOR:
				return update_pawn_position(pawn, cell_start, cell_target)
				
#	if(pawn.type == objectTyped.ENEMY):
	else:
		#print("MOVED enemy in room")
		match cell_target_type:
			objectTyped.EMPTY:
				return update_pawn_position(pawn, cell_start, cell_target)
			objectTyped.ENEMY:
				return pawn.position
			objectTyped.PLAYER:
				return pawn.position
			objectTyped.WALL:
				return pawn.position
			objectTyped.DOOR:
				return pawn.position
			objectTyped.UNLOCKEDDOOR:
				return pawn.position


#movedThroughDoor
func update_pawn_position(pawn, cell_start, cell_target):
	var oldCellTargetType = get_cellv(cell_target)
	var oldCellTargetNode = get_cell_pawn(cell_target)
	set_cellv(cell_target, get_tileset().find_tile_by_name(match_Enum(pawn.type)))
	set_cellv(cell_start, objectTyped.EMPTY)
	if(pawn.name == "Player"):
		if(movedThroughDoor == true):
			set_cellv(cell_start, objectTyped.UNLOCKEDDOOR)
			movedThroughDoor = false
		if(oldCellTargetType == get_tileset().find_tile_by_name("DOOR") || oldCellTargetType == get_tileset().find_tile_by_name("UNLOCKEDDOOR")):
			movedThroughDoor = true
			enemiesMadeMoveCounter = 0
			var direction 
			if(cell_target.x-cell_start.x < 0):
				direction = "LEFT"
				pawn.playerPassedDoor = Vector2(-1,0)
			if(cell_target.x-cell_start.x > 0):
				direction = "RIGHT"
				pawn.playerPassedDoor = Vector2(1,0)
			if(cell_target.y-cell_start.y < 0):
				direction = "UP"
				pawn.playerPassedDoor = Vector2(0,-1)
			if(cell_target.y-cell_start.y > 0):
				direction = "DOWN"
				pawn.playerPassedDoor = Vector2(0,1)
			if(oldCellTargetType == get_tileset().find_tile_by_name("DOOR")):
				oldCellTargetNode.set_other_adjacent_room(activeRoom, direction)
				activeRoom = oldCellTargetNode
			if(oldCellTargetType == get_tileset().find_tile_by_name("UNLOCKEDDOOR")):
				activeRoom=oldCellTargetNode.get_room_by_movement_direction(direction)
			
			if(activeRoom != null && enemiesInActiveRoom.size() != 0):
				#disable elements in room just left
				for element in activeRoom.enemiesInRoom:
					element.isDisabled = true
				activeRoom.enemiesInRoom = enemiesInActiveRoom.duplicate()
				enemiesInActiveRoom.clear()
				#set new elements if in room to be active 
				for element in activeRoom.enemiesInRoom:
					element.isDisabled = false
#			if(activeRoom != null):
#				print("current active room " + str(activeRoom) + " enemies in active room " + str(activeRoom.enemiesInRoom))
#			else:
#				print("current active room " + str(activeRoom))
			pawn.alreadyMovedThisTurn = true
			
			#update camera position 
			var mainCamera = get_node("/root/MainCamera")
			if(activeRoom != null):
				mainCamera.move_and_zoom_camera_to_room(activeRoom.doorRoomLeftMostCorner, map_to_world(activeRoom.roomSize/2), activeRoom.roomSizeMultiplier)
			else:
				mainCamera.position = map_to_world(Vector2(roomDimensions/2, roomDimensions/2))
			#mainCamera.zoom = mainCamera.zoom + Vector2(1,1)
			mainCamera.make_current()
			
			
	return map_to_world(cell_target) + cell_size / 2
	
func enablePlayerAttack(player):
	if(activeRoom == null || activeRoom.enemiesInRoom.empty()):
		player.playerCanAttack=false
		return
	for element in activeRoom.enemiesInRoom:
#		print("Enemy Position " + str(element.position) + " player left position " + str(player.position+ map_to_world(Vector2(1,0))))
#		print("Enemy Position " + str(element.position) + " player right position " + str(player.position+ map_to_world(Vector2(-1,0))))
#		print("Enemy Position " + str(element.position) + " player down position " + str(player.position+ map_to_world(Vector2(0,1))))
#		print("Enemy Position " + str(element.position) + " player up position " + str(player.position+ map_to_world(Vector2(0,-1))))
		if(element.position == player.position + map_to_world(Vector2(1,0)) || element.position == player.position + map_to_world(Vector2(-1,0)) || element.position == player.position + map_to_world(Vector2(0,1)) || element.position == player.position + map_to_world(Vector2(0,-1))):
			#print("player can attack in enable function ")
			player.playerCanAttack=true
			return 
	player.playerCanAttack=false

func enableEnemyAttack(enemy):
	if(get_cellv(world_to_map(enemy.position)+Vector2(1,0)) == objectTyped.PLAYER):
		return world_to_map(enemy.position)+Vector2(1,0)
	elif(get_cellv(world_to_map(enemy.position)+Vector2(-1,0)) == objectTyped.PLAYER):
		return world_to_map(enemy.position)+Vector2(-1,0)
	elif(get_cellv(world_to_map(enemy.position)+Vector2(0,1)) == objectTyped.PLAYER):
		return world_to_map(enemy.position)+Vector2(0,1)
	elif(get_cellv(world_to_map(enemy.position)+Vector2(0,-1)) == objectTyped.PLAYER):
		return world_to_map(enemy.position)+Vector2(0,-1)
		#print("player can attack in enable function ")
	return Vector2.ZERO

func create_enemy_room(unlockedDoor):
	randomize()
	#add adjustment for enemy amount 
	#-2 because of walls on both sides
	var enemiesToSpawn = randi()%4+1
	var sizecounter = 0
	var spawnCellArray = []
	for enemie in enemiesToSpawn: 
		var alreadyinArray = true
		while(alreadyinArray == true):
			var spawnCellX = randi()%(int(unlockedDoor.roomSize.x-2))+1
			var spawnCellY = randi()%(int(unlockedDoor.roomSize.y-2))+1
			var spawnCell = spawnCellX*spawnCellY
			if(!spawnCellArray.has(spawnCell)):
				alreadyinArray = false
				spawnCellArray.append(spawnCell)
				var newEnemy = Enemy.instance()
				#create enemy typ here (enemy. createEnemyType
				newEnemy.position = unlockedDoor.doorRoomLeftMostCorner + map_to_world(Vector2(spawnCellX, spawnCellY))
				newEnemy.get_node("Sprite").set_modulate(Color(randf(),randf(),randf(),1.0))
				newEnemy.connect("enemyMadeMove", self, "_on_enemy_made_move_ready")
				newEnemy.connect("enemyAttacked", self, "_on_enemy_attacked")
				newEnemy.connect("enemyDefeated", self, "_on_enemy_defeated")
				add_child(newEnemy)
				set_cellv(world_to_map(newEnemy.position), get_tileset().find_tile_by_name(match_Enum(newEnemy.type)))
				enemiesInActiveRoom.append(get_cell_pawn(world_to_map(newEnemy.position)))
	#print(spawnCellArray)

func _on_enemy_made_move_ready():
	enemiesMadeMoveCounter += 1
	print("Enemies made move " + str(enemiesMadeMoveCounter) + " enemies in active room " + str(activeRoom.enemiesInRoom.size()))
	#print("Currently Enemies made move " + str(enemiesMadeMoveCounter) + " of all enemies active " + str(activeRoom.enemiesInRoom.size()))
	if(enemiesMadeMoveCounter >= activeRoom.enemiesInRoom.size()):
		#print("All Enemies made move " + str(enemiesMadeMoveCounter))
		enemiesMadeMoveCounter = 0
		get_node("Player").alreadyAttackedThisMove = false
		get_node("Player").alreadyMovedThisTurn = false
		
func _on_Player_Made_Move():
	#print("Player position " + str(world_to_map(get_node("Player").position)))
	if(activeRoom!=null):
		for element in activeRoom.enemiesInRoom:
				element.alreadyMovedThisTurn = false
				element.alreadyAttackedThisTurn = false
		if(activeRoom.enemiesInRoom.empty()):
			get_node("Player").alreadyMovedThisTurn = false
	if(activeRoom == null):
		get_node("Player").alreadyMovedThisTurn = false
		
func _on_Player_Attacked(player, attack_direction, attackDamage):
	randomize()
	if(get_cellv(world_to_map(player.position) + attack_direction) == objectTyped.ENEMY):
		print("Woosh Player Attack hit")
		var attackedEnemy = get_cell_pawn(world_to_map(player.position) + attack_direction)
		attackedEnemy.inflictDamage(attackDamage)
	elif(get_cellv(world_to_map(player.position) + attack_direction) == objectTyped.EMPTY):
		print("ZZZ Attack missed")

func _on_enemy_attacked(enemy, attackCell, attackDamage):
	if(get_cellv(attackCell) == objectTyped.PLAYER):
		print("Woosh ENEMY Attack hit")
		var attackedPlayer = get_cell_pawn(attackCell)
		if attackedPlayer.playerDefeated(attackDamage):
			set_cellv(attackCell,get_tileset().find_tile_by_name("EMPTY")) 
			attackedPlayer.position = Vector2(48,48)
			attackedPlayer.lifePoints = 5
			print("Batsuuum Player was defeated reset to start")

func _on_enemy_defeated(enemy):
	activeRoom.enemiesInRoom.erase(enemy)
	set_cellv(world_to_map(enemy.position),get_tileset().find_tile_by_name("EMPTY")) 
	enemy.queue_free()
	print("Batsuuum Enemy was defeated")
	#set room to cleared if all enemies were defeated
	if(activeRoom.enemiesInRoom.size() == 0):
		activeRoom.roomCleared=true
		if activeRoom.dropLoot():
			#create loot currently matching with closed doord 
			print(barrierKeysNoSolution)
			if !barrierKeysNoSolution.empty():
				#create key and spawn it on floor spawn one left of player if player is in the middle of the room
				var itemToGenerate = barrierKeysNoSolution[randi()%barrierKeysNoSolution.size()]
				barrierKeysSolutionSpawned.append(itemToGenerate)
				barrierKeysNoSolution.erase(itemToGenerate)
				var newItem = Item.instance()
				var newItemPosition = activeRoom.doorRoomLeftMostCorner + map_to_world(activeRoom.roomSize/2)
				if(get_cellv(world_to_map(newItemPosition)) == objectTyped.PLAYER):
					newItemPosition += map_to_world(Vector2(0,1))
				newItem.position = newItemPosition
				newItem.keyValue = itemToGenerate
				add_child(newItem)
				set_cellv(world_to_map(newItem.position), get_tileset().find_tile_by_name(match_Enum(newItem.type)))
					#set type of item 
					

func create_starting_room(startingRoom=false):
	create_walls(null, startingRoom, true)



func create_walls (door = null, startingRoom = false, createDoors = false):
	#todo:calculate actual position of leftmost corner wall tile of the room
	randomize()
	var leftmostCorner = Vector2.ZERO
	var roomSizeHorizontal = roomDimensions
	var roomSizeVertical = roomDimensions
	var disableDown = false
	var disableUp = false
	var disableLeft = false
	var disableRight = false
	var disableLong = false
	var disableBig = false
	if(startingRoom):
		leftmostCorner = Vector2(16,16)
	else:
		var minRoomSize = roomSizeHorizontal

		match door.doorDirection:
			"LEFT":
				#see if there are any cross section and diasble this option to keep tiles from intersecting
				leftmostCorner=world_to_map(door.position-map_to_world(Vector2(minRoomSize, minRoomSize/2-evenOddModifier)))
				#print("LEFT LEftMost Corner " + str(leftmostCorner) + " door position " + str(world_to_map(door.position)))
				#check for wall up for room to be created 
				#print("LEFT Up Modifier : " + str(leftmostCorner-Vector2(0,1)) + " " + str(get_cellv(leftmostCorner-Vector2(0,1))))
				if(get_cellv(leftmostCorner-Vector2(0,1)) == objectTyped.WALL):
					disableUp = true
				#check for wall down for room to be created 
				#print("LEFT Down modifier : " + str(leftmostCorner+Vector2(0,minRoomSize)) + " " + str(get_cellv(leftmostCorner+Vector2(0,minRoomSize))))
				if(get_cellv(leftmostCorner+Vector2(0,minRoomSize)) == objectTyped.WALL):
					disableDown = true
				#check for wall long for room to be created 
				if(get_cellv(leftmostCorner-Vector2(1,0)) == objectTyped.WALL):
					disableLong = true
				#print("LEFT LONG modifier : " + str(leftmostCorner-Vector2(1,0))+ " " + str(get_cellv(leftmostCorner-Vector2(1,0))))
				#randomize and create different room sizes and layout types
				if(get_cellv(leftmostCorner+Vector2(minRoomSize, minRoomSize)) == objectTyped.WALL || get_cellv(leftmostCorner+Vector2(minRoomSize-1, minRoomSize)) == objectTyped.WALL || get_cellv(leftmostCorner+Vector2(minRoomSize, minRoomSize-1)) == objectTyped.WALL || get_cellv(leftmostCorner+Vector2(minRoomSize-1, minRoomSize-1)) == objectTyped.WALL):
					disableBig = true
				#print("Corner Location: " + str(leftmostCorner+Vector2(minRoomSize, minRoomSize)) + " LEFT disableBig " + str(disableBig))
				
				var horizontalRandom = randi()%2+1
				var verticalRandom = randi()%2+1
				var randUpDown = randi()%2+1
				
				if(disableBig == true && horizontalRandom == 2 && horizontalRandom == 2):
					if(randi()%2+1 == 1):
						verticalRandom = 1 
						horizontalRandom = 2
					else:
						verticalRandom = 2
						horizontalRandom = 1
						
				if(disableUp == true && disableDown == true && disableLong == true):
					horizontalRandom = 1 
					verticalRandom = 1
				if(disableUp == true && disableDown == true):
					verticalRandom = 1
				if(disableUp == true):
					randUpDown = 2
				if(disableDown == true):
					randUpDown = 1
				if (disableLong == true):
					horizontalRandom = 1
					
				roomSizeHorizontal = roomSizeHorizontal * horizontalRandom
				roomSizeVertical = roomSizeVertical* verticalRandom
					
				#print(str(disableUp) +  " disableup " + str(disableDown) + " disableDown " + str(disableLong) + " disablelong ")
				if(horizontalRandom == 2 && verticalRandom == 2):
					if(randUpDown==1):
						leftmostCorner=door.position-map_to_world(Vector2(roomSizeHorizontal, roomSizeVertical - roomSizeVertical/4 - 1))
						#print(str(ceil(roomSizeVertical/4)))
					else:
						leftmostCorner=door.position-map_to_world(Vector2(roomSizeHorizontal, roomSizeVertical/4 - evenOddModifier))
				elif(horizontalRandom == 1 &&  verticalRandom == 2):
					if(randUpDown==1):
						leftmostCorner=door.position-map_to_world(Vector2(roomSizeHorizontal, roomSizeVertical - roomSizeVertical/4 - 1))
					else:
						leftmostCorner=door.position-map_to_world(Vector2(roomSizeHorizontal, roomSizeVertical/4 - evenOddModifier))
						
				elif(horizontalRandom == 2 &&  verticalRandom == 1):
					leftmostCorner=door.position-map_to_world(Vector2(roomSizeHorizontal, roomSizeVertical/2 - evenOddModifier))
						
				else:
					leftmostCorner=door.position-map_to_world(Vector2(minRoomSize, minRoomSize/2-evenOddModifier))
				#print("LEFT LEftMost Corner "+ str(world_to_map(leftmostCorner)))
				
				#set room size and door leftmost corner in door connecting to room to be used for further room creation
				door.doorRoomLeftMostCorner = leftmostCorner
				door.doorLocationDirection = "LEFT"
				door.roomSizeMultiplier = Vector2(horizontalRandom, verticalRandom)
				door.roomSize = Vector2(roomSizeHorizontal, roomSizeVertical)
			"RIGHT":
				#see if there are any cross section and diasble this option to keep tiles from intersecting
				leftmostCorner=world_to_map(door.position+map_to_world(Vector2(1,0)-Vector2(0, minRoomSize/2 - evenOddModifier)))
				#print("RIGHT LEftMost Corner " + str(leftmostCorner))
				#check for wall up for room to be created 
				if(get_cellv(leftmostCorner-Vector2(0,1)) == objectTyped.WALL):
					disableUp = true
				#print("RIGHT Up Modifier : " + str(leftmostCorner-Vector2(0,1)) + " " + str(get_cellv(leftmostCorner-Vector2(0,1))))
				#check for wall down for room to be created 
				if(get_cellv(leftmostCorner+Vector2(0,minRoomSize)) == objectTyped.WALL):
					disableDown = true
				#print("RIGHT Down modifier : " + str(leftmostCorner+Vector2(0,minRoomSize)) + " " + str(get_cellv(leftmostCorner+Vector2(0,minRoomSize))))
				#check for wall long for room to be created 
				if(get_cellv(leftmostCorner+Vector2(minRoomSize,0)) == objectTyped.WALL):
					disableLong = true
				#print("RIGHT LONG modifier : " + str(leftmostCorner+Vector2(minRoomSize,0))+ " " + str(get_cellv(leftmostCorner+Vector2(minRoomSize,0))))
				if(get_cellv(leftmostCorner+Vector2(minRoomSize, minRoomSize)) == objectTyped.WALL || get_cellv(leftmostCorner+Vector2(minRoomSize-1, minRoomSize)) == objectTyped.WALL || get_cellv(leftmostCorner+Vector2(minRoomSize, minRoomSize-1)) == objectTyped.WALL || get_cellv(leftmostCorner+Vector2(minRoomSize-1, minRoomSize-1)) == objectTyped.WALL):
					disableBig = true
				#print("Corner Location: " + str(leftmostCorner+Vector2(minRoomSize, minRoomSize)) + " RIGHT disableBig " + str(disableBig))
				
				var horizontalRandom = randi()%2+1
				var verticalRandom = randi()%2+1
				var randUpDown = randi()%2+1
				
				if(disableBig == true && horizontalRandom == 2 && horizontalRandom == 2):
					if(randi()%2+1 == 1):
						verticalRandom = 1 
						horizontalRandom = 2
					else:
						verticalRandom = 2
						horizontalRandom = 1
						
				if(disableUp == true && disableDown == true && disableLong == true):
					horizontalRandom = 1 
					verticalRandom = 1
				if(disableUp == true && disableDown == true):
					verticalRandom = 1
				if(disableUp == true):
					randUpDown = 2
				if(disableDown == true):
					randUpDown = 1
				if (disableLong == true):
					horizontalRandom = 1

				roomSizeHorizontal = roomSizeHorizontal * horizontalRandom
				roomSizeVertical = roomSizeVertical* verticalRandom
				
				#print(str(disableUp) +  " disableup " + str(disableDown) + " disableDown " + str(disableLong) + " disablelong ")
				
				if(horizontalRandom == 2 && verticalRandom == 2):
					#move block up 
					if(randUpDown==1):
						leftmostCorner=door.position+map_to_world(Vector2(1,0)-Vector2(0, roomSizeVertical-roomSizeVertical/4 - 1))
					else:
						leftmostCorner=door.position+map_to_world(Vector2(1,0)-Vector2(0, roomSizeVertical/4 - evenOddModifier))
				elif(horizontalRandom == 1 &&  verticalRandom == 2):
					if(randUpDown==1):
						leftmostCorner=door.position+map_to_world(Vector2(1,0)-Vector2(0, roomSizeVertical-roomSizeVertical/4 - 1))
					else:
						leftmostCorner=door.position+map_to_world(Vector2(1,0)-Vector2(0, roomSizeVertical/4 - evenOddModifier))
						
				elif(horizontalRandom == 2 &&  verticalRandom == 1):
					leftmostCorner=door.position+map_to_world(Vector2(1,0)-Vector2(0, roomSizeVertical/2 - evenOddModifier))
						
				else:
					leftmostCorner=door.position+map_to_world(Vector2(1,0)-Vector2(0, minRoomSize/2 - evenOddModifier))
				#set room size and door leftmost corner in door connecting to room to be used for further room creation
				door.doorRoomLeftMostCorner = leftmostCorner
				door.doorLocationDirection = "RIGHT"
				door.roomSizeMultiplier = Vector2(horizontalRandom, verticalRandom)
				door.roomSize = Vector2(roomSizeHorizontal, roomSizeVertical)
			"UP":
				#see if there are any cross section and diasble this option to keep tiles from intersecting
				leftmostCorner=world_to_map(door.position-map_to_world(Vector2(minRoomSize/2  - evenOddModifier, minRoomSize)))
				#print("UP LEftMost Corner " + str(leftmostCorner))	
				#check left top corner of minimum size minus 1 y tile 
				if(get_cellv(leftmostCorner-Vector2(1,0)) == objectTyped.WALL):
					disableLeft = true
				#print("UP Left Modifier : " + str(leftmostCorner-Vector2(1,0)) + " " + str(get_cellv(leftmostCorner-Vector2(1,0))))
				#check left bottom corner of minimum size plus 1 y tile 
				if(get_cellv(leftmostCorner+Vector2(minRoomSize,0)) == objectTyped.WALL):
					disableRight = true
				#print("UP Right modifier : " + str(leftmostCorner+Vector2(minRoomSize,0)) + " " + str(get_cellv(leftmostCorner+Vector2(minRoomSize,0))))
				#randomize and create different room sizes and layout types 
				if(get_cellv(leftmostCorner-Vector2(0,1)) == objectTyped.WALL):
					disableLong = true
				#print("UP LONG modifier : " + str(leftmostCorner-Vector2(0,1))+ " " + str(get_cellv(leftmostCorner-Vector2(0,1))))
				if(get_cellv(leftmostCorner+Vector2(minRoomSize, minRoomSize)) == objectTyped.WALL || get_cellv(leftmostCorner+Vector2(minRoomSize-1, minRoomSize)) == objectTyped.WALL || get_cellv(leftmostCorner+Vector2(minRoomSize, minRoomSize-1)) == objectTyped.WALL || get_cellv(leftmostCorner+Vector2(minRoomSize-1, minRoomSize-1)) == objectTyped.WALL):
					disableBig = true
				#print("Corner Location: " + str(leftmostCorner+Vector2(minRoomSize, minRoomSize)) + " UP disableBig " + str(disableBig))
				
				var horizontalRandom = randi()%2+1
				var verticalRandom = randi()%2+1
				var randLeftRight = randi()%2+1
				
				if(disableBig == true && horizontalRandom == 2 && horizontalRandom == 2):
					if(randi()%2+1 == 1):
						verticalRandom = 1 
						horizontalRandom = 2
					else:
						verticalRandom = 2
						horizontalRandom = 1
						
				if(disableLeft == true && disableRight == true && disableLong == true):
					horizontalRandom = 1 
					verticalRandom = 1
				if(disableLeft == true && disableRight == true):
					horizontalRandom = 1
				if(disableLeft == true):
					randLeftRight = 2
				if(disableRight == true):
					randLeftRight = 1
				if (disableLong == true):
					verticalRandom = 1

				roomSizeHorizontal = roomSizeHorizontal * horizontalRandom
				roomSizeVertical = roomSizeVertical* verticalRandom

				#print(str(disableRight) +  " disableRight " + str(disableLeft) + " disableLeft " + str(disableLong) + " disablelong ")
				
				if(horizontalRandom == 2 && verticalRandom == 2):
					#move block up 
					if(randLeftRight==1):
						leftmostCorner=door.position-map_to_world(Vector2(roomSizeHorizontal-roomSizeHorizontal/4 - 1, roomSizeVertical))
					else:
						leftmostCorner=door.position-map_to_world(Vector2(roomSizeHorizontal/4 - evenOddModifier, roomSizeVertical))
						
				elif(horizontalRandom == 1 &&  verticalRandom == 2):
						leftmostCorner=door.position-map_to_world(Vector2(roomSizeHorizontal/2 - evenOddModifier, roomSizeVertical))		
				elif(horizontalRandom == 2 &&  verticalRandom == 1):
					if(randLeftRight==1):
						leftmostCorner=door.position-map_to_world(Vector2(roomSizeHorizontal-roomSizeHorizontal/4 - 1, roomSizeVertical))
					else:
						leftmostCorner=door.position-map_to_world(Vector2(roomSizeHorizontal/4 - evenOddModifier, roomSizeVertical))
				else:
					leftmostCorner=door.position-map_to_world(Vector2(minRoomSize/2  - evenOddModifier, minRoomSize))
				#print("LEFT LEftMost Corner "+ str(world_to_map(leftmostCorner)))
				#set room size and door leftmost corner in door connecting to room to be used for further room creation
				door.doorRoomLeftMostCorner = leftmostCorner
				door.doorLocationDirection = "UP"
				door.roomSizeMultiplier = Vector2(horizontalRandom, verticalRandom)
				door.roomSize = Vector2(roomSizeHorizontal, roomSizeVertical)
			"DOWN":
				#see if there are any cross section and diasble this option to keep tiles from intersecting
				leftmostCorner=world_to_map(door.position-map_to_world(Vector2(minRoomSize/2 - evenOddModifier, -1)))

				#check left top corner of minimum size minus 1 y tile 
				if(get_cellv(leftmostCorner-Vector2(1,0)) == objectTyped.WALL):
					disableLeft = true
				#print("DOWN Left Modifier : " + str(leftmostCorner-Vector2(1,0)) + " " + str(get_cellv(leftmostCorner-Vector2(1,0))))
				#check left bottom corner of minimum size plus 1 y tile 
				if(get_cellv(leftmostCorner+Vector2(minRoomSize,0)) == objectTyped.WALL):
					disableRight = true
				#print("DOWN Right modifier : " + str(leftmostCorner+Vector2(minRoomSize,0)) + " " + str(get_cellv(leftmostCorner+Vector2(minRoomSize,0))))
				#randomize and create different room sizes and layout types 
				if(get_cellv(leftmostCorner+Vector2(minRoomSize, minRoomSize)) == objectTyped.WALL || get_cellv(leftmostCorner+Vector2(minRoomSize-1, minRoomSize)) == objectTyped.WALL || get_cellv(leftmostCorner+Vector2(minRoomSize, minRoomSize-1)) == objectTyped.WALL || get_cellv(leftmostCorner+Vector2(minRoomSize-1, minRoomSize-1)) == objectTyped.WALL):
					disableLong = true
				#print("DOWN LONG modifier : "  + str(leftmostCorner+Vector2(0,minRoomSize))+ " " + str(get_cellv(leftmostCorner+Vector2(0,minRoomSize))))
				if(get_cellv(leftmostCorner+Vector2(minRoomSize, minRoomSize)) == objectTyped.WALL):
					disableBig = true
				#print("Corner Location: " + str(leftmostCorner+Vector2(minRoomSize, minRoomSize)) + " DOWN disableBig " + str(disableBig))
				
				var horizontalRandom = randi()%2+1
				var verticalRandom = randi()%2+1
				var randLeftRight = randi()%2+1
				
				if(disableBig == true && horizontalRandom == 2 && horizontalRandom == 2):
					if(randi()%2+1 == 1):
						verticalRandom = 1 
						horizontalRandom = 2
					else:
						verticalRandom = 2
						horizontalRandom = 1
				
				if(disableLeft == true && disableRight == true && disableDown == true):
					horizontalRandom = 1 
					verticalRandom = 1
				if(disableLeft == true && disableRight == true):
					horizontalRandom = 1
				if(disableLeft == true):
					randLeftRight = 2
				if(disableRight == true):
					randLeftRight = 1
				if (disableLong == true):
					verticalRandom = 1
					
				
					
					 
				roomSizeHorizontal = roomSizeHorizontal * horizontalRandom
				roomSizeVertical = roomSizeVertical* verticalRandom

				#print(str(disableRight) +  " disableRight " + str(disableLeft) + " disableLeft " + str(disableLong) + " disablelong ")
				#print("hor "+str(horizontalRandom) + " vert " + str(verticalRandom) + " randleftright " + str(randLeftRight))
				if(horizontalRandom == 2 && verticalRandom == 2):
					#move block up 
					if(randLeftRight==1):
						leftmostCorner=door.position-map_to_world(Vector2(roomSizeHorizontal-roomSizeHorizontal/4 -1, -1))
					else:
						leftmostCorner=door.position-map_to_world(Vector2(roomSizeHorizontal/4 - evenOddModifier, -1))
				elif(horizontalRandom == 1 &&  verticalRandom == 2):
					leftmostCorner=door.position-map_to_world(Vector2(roomSizeHorizontal/2 - evenOddModifier, -1))
				elif(horizontalRandom == 2 &&  verticalRandom == 1):
					if(randLeftRight==1):
						leftmostCorner=door.position-map_to_world(Vector2(roomSizeHorizontal-roomSizeHorizontal/4 - 1, -1))
					else:
						leftmostCorner=door.position-map_to_world(Vector2(roomSizeHorizontal/4  - evenOddModifier, -1))
				else:
					leftmostCorner=(door.position-map_to_world(Vector2(int(minRoomSize/2)-evenOddModifier, -1)))
					#print("in last else wehe nicht...")
				#print("DOWN LEftMost Corner " + str(world_to_map(leftmostCorner)))	
				#print(str(world_to_map((door.position-map_to_world(Vector2(int(minRoomSize/2)-evenOddModifier, -1))))))
				#print("Door location " + str(world_to_map(door.position)) + " modificator " + str(Vector2(int(minRoomSize/2)-evenOddModifier, -1)))
				#set room size and door leftmost corner in door connecting to room to be used for further room creation
				door.doorRoomLeftMostCorner = leftmostCorner
				door.doorLocationDirection = "DOWN"
				door.roomSizeMultiplier = Vector2(horizontalRandom, verticalRandom)
				door.roomSize = Vector2(roomSizeHorizontal, roomSizeVertical)
						

	var verticalAddcount = 0
	while verticalAddcount < roomSizeVertical:
		var horizontalAddcount = 0
		while horizontalAddcount < roomSizeHorizontal:
			var spawn_pos = leftmostCorner + Vector2(horizontalAddcount*32,verticalAddcount*32)
			var newWallPiece = Wall.instance()
			add_child(newWallPiece)
			newWallPiece.position = spawn_pos
			set_cellv(world_to_map(newWallPiece.position), get_tileset().find_tile_by_name(match_Enum(newWallPiece.type)))
			#print("VerticalAddAcc " + str(verticalAddcount) + " horaddacc " + str(horizontalAddcount))
			if(verticalAddcount==0 || verticalAddcount==roomSizeVertical-1 || horizontalAddcount==roomSizeHorizontal-1):
				horizontalAddcount+=1
			else:
				horizontalAddcount=roomSizeHorizontal-1
		verticalAddcount+=1
		
	if(startingRoom == false):
		var object_pawn = null
		match door.doorDirection:
			"LEFT":
				set_cellv(world_to_map(door.position) - Vector2(1,0), get_tileset().find_tile_by_name(match_Enum(objectTyped.EMPTY)))
				object_pawn = get_cell_pawn(world_to_map(door.position) - Vector2(1,0))
			"RIGHT":
				set_cellv(world_to_map(door.position) + Vector2(1,0), get_tileset().find_tile_by_name(match_Enum(objectTyped.EMPTY)))
				object_pawn = get_cell_pawn(world_to_map(door.position) + Vector2(1,0))
			"UP":
				set_cellv(world_to_map(door.position) - Vector2(0,1), get_tileset().find_tile_by_name(match_Enum(objectTyped.EMPTY)))
				object_pawn = get_cell_pawn(world_to_map(door.position) - Vector2(0,1))
			"DOWN":
				set_cellv(world_to_map(door.position) + Vector2(0,1), get_tileset().find_tile_by_name(match_Enum(objectTyped.EMPTY)))
				object_pawn = get_cell_pawn(world_to_map(door.position) + Vector2(0,1))
		if(object_pawn != null):
			object_pawn.queue_free()
		
	if(createDoors == true):

		create_doors(leftmostCorner, startingRoom, roomSizeHorizontal, roomSizeVertical)


func create_doors(roomLeftMostCorner, startingRoom=false, roomSizeHorizontal = 13, roomSizeVertical = 13, roomsizeMultiplyer = Vector2(1,1), doorLocationDirection = "LEFT"):
	randomize()
	roomSizeHorizontal = roomSizeHorizontal-1
	roomSizeVertical = roomSizeVertical-1
	var doorLocationDirectionsArray = ["LEFT", "RIGHT", "UP", "DOWN"]
	var doorLocationArray = []
	var doorArray = []
	var doorCount = randi()%4+1
	var canCreateDoor = true
	var doorEvenOddModifier = 0
			
	if(evenOddModifier == 0):
		doorEvenOddModifier = 1
	#todo: include remaning doors numbers
	if(!startingRoom):
		remove_opposite_doorlocation(doorLocationDirectionsArray, doorLocationDirection)
		doorCount = 3

	while doorCount > 0: 
		var doorLocation = randi()%doorLocationDirectionsArray.size()-1
		#var doorLocation = 3
		doorLocationArray.append(doorLocationDirectionsArray[doorLocation])
		doorLocationDirectionsArray.erase(doorLocationDirectionsArray[doorLocation])
		doorCount-=1
	for element in doorLocationArray:
		var locationToSpawnModifier = Vector2.ZERO
		var newDoor = Door.instance()
		var alternateSpawnLocation = false
		if(randi()%2+1 == 1):
			alternateSpawnLocation = true
		match element:
			"LEFT":
				match roomsizeMultiplyer:
					Vector2(1,1):
						locationToSpawnModifier = Vector2(0, int(roomSizeVertical/(2*roomsizeMultiplyer.y)))
					Vector2(2,1):
						locationToSpawnModifier = Vector2(0, int(roomSizeVertical/(2*roomsizeMultiplyer.y)))
					Vector2(1,2):
						locationToSpawnModifier = Vector2(0, int(roomSizeVertical/(2*roomsizeMultiplyer.y)))
						if(alternateSpawnLocation):
							locationToSpawnModifier = Vector2(0, int(3*roomSizeVertical/(2*roomsizeMultiplyer.y)+doorEvenOddModifier))
					Vector2(2,2):
						locationToSpawnModifier = Vector2(0, int(roomSizeVertical/(2*roomsizeMultiplyer.y)))
						if(alternateSpawnLocation):
							locationToSpawnModifier = Vector2(0, int(3*roomSizeVertical/(2*roomsizeMultiplyer.y)+doorEvenOddModifier))
				newDoor.doorDirection = "LEFT"
			"RIGHT":
				match roomsizeMultiplyer:
					Vector2(1,1):
						locationToSpawnModifier = Vector2(roomSizeHorizontal, int(roomSizeVertical/(2*roomsizeMultiplyer.y)))
					Vector2(2,1):
						locationToSpawnModifier = Vector2(roomSizeHorizontal, int(roomSizeVertical/(2*roomsizeMultiplyer.y)))
					Vector2(1,2):
						locationToSpawnModifier = Vector2(roomSizeHorizontal, int(roomSizeVertical/(2*roomsizeMultiplyer.y)))
						if(alternateSpawnLocation):
							locationToSpawnModifier = Vector2(roomSizeHorizontal, int(3*roomSizeVertical/(2*roomsizeMultiplyer.y)+doorEvenOddModifier))
					Vector2(2,2):
						locationToSpawnModifier = Vector2(roomSizeHorizontal, int(roomSizeVertical/(2*roomsizeMultiplyer.y)))
						if(alternateSpawnLocation):
							locationToSpawnModifier = Vector2(roomSizeHorizontal, int(3*roomSizeVertical/(2*roomsizeMultiplyer.y)+doorEvenOddModifier))
				newDoor.doorDirection = "RIGHT"
			"UP":
				match roomsizeMultiplyer:
					Vector2(1,1):
						locationToSpawnModifier = Vector2(int(roomSizeHorizontal/(2*roomsizeMultiplyer.x)), 0)
					Vector2(2,1):
						locationToSpawnModifier = Vector2(int(roomSizeHorizontal/(2*roomsizeMultiplyer.x)), 0)
						if(alternateSpawnLocation):
							locationToSpawnModifier = Vector2(int(3*roomSizeHorizontal/(2*roomsizeMultiplyer.x))+doorEvenOddModifier, 0)
					Vector2(1,2):
						locationToSpawnModifier = Vector2(int(roomSizeHorizontal/(2*roomsizeMultiplyer.x)), 0)
					Vector2(2,2):
						if(alternateSpawnLocation):
							locationToSpawnModifier = Vector2(int(3*roomSizeHorizontal/(2*roomsizeMultiplyer.x))+doorEvenOddModifier, 0)
						locationToSpawnModifier = Vector2(int(roomSizeHorizontal/(2*roomsizeMultiplyer.x)), 0)
				newDoor.doorDirection = "UP"
			"DOWN":
				match roomsizeMultiplyer:
					Vector2(1,1):
						locationToSpawnModifier = Vector2(int(roomSizeHorizontal/(2*roomsizeMultiplyer.x)), roomSizeVertical)
					Vector2(2,1):
						locationToSpawnModifier = Vector2(int(roomSizeHorizontal/(2*roomsizeMultiplyer.x)), roomSizeVertical)
						if(alternateSpawnLocation):
							locationToSpawnModifier = Vector2(int(3*roomSizeHorizontal/(2*roomsizeMultiplyer.x)+doorEvenOddModifier), roomSizeVertical)
					Vector2(1,2):
						locationToSpawnModifier = Vector2(int(roomSizeHorizontal/(2*roomsizeMultiplyer.x)), roomSizeVertical)
					Vector2(2,2):
						locationToSpawnModifier = Vector2(int(roomSizeHorizontal/(2*roomsizeMultiplyer.x)), roomSizeVertical)
						if(alternateSpawnLocation):
							locationToSpawnModifier = Vector2(int(3*roomSizeHorizontal/(2*roomsizeMultiplyer.x)+doorEvenOddModifier), roomSizeVertical)
				newDoor.doorDirection = "DOWN"
		
				
		#print("LocationDir " + str(element) + " LocationSpawnModifier " + str(locationToSpawnModifier))
		newDoor.position = roomLeftMostCorner + map_to_world(locationToSpawnModifier)
		#print("NewDoor leftmost Position " + str(world_to_map(roomLeftMostCorner)))
		#print("Newdoor position" + str(world_to_map(newDoor.position))+ " roomsizemult " + str(roomsizeMultiplyer))
		
		match element:
			"LEFT":
				if (get_cellv(world_to_map(newDoor.position)-Vector2(1,0)) == objectTyped.WALL):
					canCreateDoor = false
			"RIGHT":
				if (get_cellv(world_to_map(newDoor.position)+Vector2(1,0)) == objectTyped.WALL):
					canCreateDoor = false
			"UP":
				if (get_cellv(world_to_map(newDoor.position)-Vector2(0,1)) == objectTyped.WALL):
					canCreateDoor = false
			"DOWN":
				if (get_cellv(world_to_map(newDoor.position)+Vector2(0,1)) == objectTyped.WALL):
					canCreateDoor = false

		if(currentNumberRoomsgenerated >= maxNumberRooms):
			canCreateDoor=false
		if(canCreateDoor == true):
			add_child(newDoor)
			#delete the wall piece before creating the door
			var object_pawn = get_cell_pawn(world_to_map(newDoor.position))
			object_pawn.queue_free()
			set_cellv(world_to_map(newDoor.position), get_tileset().find_tile_by_name(match_Enum(newDoor.type)))
			doorArray.append(newDoor)
			
		canCreateDoor = true
		
	for door in doorArray:
		currentNumberRoomsgenerated+=1
		#print(currentNumberRoomsgenerated)
		create_walls(door, false, false)
		#print(str(newDoor.position) + " element "+ str(element))

func remove_opposite_doorlocation(doorLocationDirectionsArray, direction):
	match direction:
		"LEFT":
			doorLocationDirectionsArray.erase("RIGHT")
		"RIGHT":
			doorLocationDirectionsArray.erase("LEFT")
		"UP":
			doorLocationDirectionsArray.erase("DOWN")
		"DOWN":
			doorLocationDirectionsArray.erase("UP")
		_:
			pass
	return doorLocationDirectionsArray
