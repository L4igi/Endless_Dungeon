extends TileMap

enum TILETYPES { EMPTY, PLAYER, WALL, ENEMY, PUZZLEPIECE, ITEM, DOOR, UNLOCKEDDOOR, MAGICPROJECTILE, BLOCK}


var Enemy = preload("res://GameObjects/Enemy/Enemy.tscn")

var Wall = preload("res://GameObjects/Wall/Wall.tscn")

var Door = preload("res://GameObjects/Door/Door.tscn")

var Item = preload("res://GameObjects/Item/Item.tscn")

var MagicProjectile = preload("res://GameObjects/Projectile/MagicProjectile.tscn")

var PowerBlock = preload("res://GameObjects/PowerBlock/PowerBlock.tscn")

var Player = preload("res://GameObjects/Player/Player.tscn")

var PuzzlePiece = preload("res://GameObjects/Puzzle/PuzzlePiece.tscn")

var roomDimensions = GlobalVariables.roomDimensions

var evenOddModifier = 0 

var maxNumberRooms = 12

var currentNumberRoomsgenerated = 0

var activeRoom = null

var movedThroughDoor = false

var enemyRoomChance = 33
var puzzleRoomChance = 33
var emptyTreasureRoomChance = 34

var projectilesInActiveRoom = []

var enemiesMadeMoveCounter = 0

var projectilesMadeMoveCounter = 0

var barrierKeysNoSolution = []

var barrierKeysSolutionSpawned = []

var mainPlayer 

signal enemyTurnDoneSignal

signal playerTurnDoneSignal

signal puzzleBarrierDisableSignal (item, mainPlayer)

var cancelMagicPuzzelRoom = false

var projectilesToDeleteTurnEnd = []

var spawnBlockProjectileNextTurn = []

var activatePuzzlePieceNextTurn = []

var activatedPuzzleBlock 

var magicProjectileLoopLevel = 0

var puzzlePiecesAnimationDoneCounter = 0

var roomJustEntered = false

var puzzleAnimationPlaying = false

var activatedPuzzlePieces = []

var onEndlessLoopStop = 0

var powerBlockSpawnDone = true

var exitMagicBlockLoopOnWallHitNumber = 0

var onEndlessLoopStopGlobal = 0


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
		7:
			return "MAGICPROJECTILE"
		8:
			return "BLOCK"
		-1:
			return "EMPTY"
		_:
			return "NULL"
			

func set_enum_index(var enumName, var setTo):
	match enumName:
		"PLAYER":
			TILETYPES.PLAYER=setTo
		"WALL":
			TILETYPES.WALL=setTo
		"ENEMY":
			TILETYPES.ENEMY=setTo
		"PUZZLEPIECE":
			TILETYPES.PUZZLEPIECE=setTo
		"ITEM":
			TILETYPES.ITEM=setTo
		"DOOR":
			TILETYPES.DOOR=setTo
		"UNLOCKEDDOOR":
			TILETYPES.UNLOCKEDDOOR=setTo
		"MAGICPROJECTILE":
			TILETYPES.MAGICPROJECTILE=setTo
		"BLOCK":
			TILETYPES.BLOCK = setTo
		"EMPTY":
			TILETYPES.EMPTY=-1
		_:
			pass
			

func _ready():
	var newPlayer = Player.instance()
	newPlayer.position = Vector2(80,80)
	newPlayer.set_name("Player")
	add_child(newPlayer)
	get_node("Player").connect("playerMadeMove", self, "_on_Player_Made_Move")
	get_node("Player").connect("playerAttacked", self, "_on_Player_Attacked")
	get_node("Player").connect("onPlayerDefeated", self, "_on_Player_Defeated")
	get_node("Player").connect("puzzleBlockInteractionSignal", self, "on_puzzle_Block_interaction")
	mainPlayer = get_node("Player")
	for child in get_children():
		set_cellv(world_to_map(child.position), get_tileset().find_tile_by_name(match_Enum(child.type)))
	for element in TILETYPES:
		set_enum_index(element, get_tileset().find_tile_by_name(element))
		#print(get_tileset().find_tile_by_name(element))
	if(roomDimensions%2 == 0):
		evenOddModifier = 1
	create_starting_room(true)
	

func _process(delta):
	pass
			
			
			
			
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
	#print("requesting move " + str(pawn.type) + "Player Type " + str(TILETYPES.PLAYER))
	if(match_Enum(pawn.type) == "PLAYER"):
		match cell_target_type:
			TILETYPES.EMPTY:
				return update_pawn_position(pawn, cell_start, cell_target)
			TILETYPES.ENEMY:
				pass
			TILETYPES.WALL:
				pass
			TILETYPES.ITEM:
				var object_pawn = get_cell_pawn(cell_target)
				#print("Item spawned key value " + str(object_pawn.keyValue))
				#add additional items with || 
				if(object_pawn.itemType == GlobalVariables.ITEMTYPE.POTION):
					pawn.add_nonkey_items(object_pawn.itemType)
				elif object_pawn.itemType == GlobalVariables.ITEMTYPE.PUZZLESWITCH:
					emit_signal("puzzleBarrierDisableSignal", object_pawn, mainPlayer)
				else:
					pawn.itemsInPosession.append(object_pawn)
					pawn.add_key_item_to_inventory(object_pawn)
				set_cellv(object_pawn.position, get_tileset().find_tile_by_name("EMPTY"))
				object_pawn.get_node("Sprite").queue_free()
				#pawn.queue_free()
				#print("Player has Items in posession " + str(pawn.itemsInPosession))
				return update_pawn_position(pawn, cell_start, cell_target)
			TILETYPES.DOOR:
				var object_pawn = get_cell_pawn(cell_target)
				var requestDoorUnlockResult = object_pawn.request_door_unlock(pawn.itemsInPosession)
				if(requestDoorUnlockResult):
					if requestDoorUnlockResult is preload("res://GameObjects/Item/Item.gd"):
						mainPlayer.remove_key_item_from_inventory(requestDoorUnlockResult)
					object_pawn.unlock_Door(enemyRoomChance, puzzleRoomChance, emptyTreasureRoomChance)
					roomJustEntered = true
					return update_pawn_position(pawn, cell_start, cell_target)
			TILETYPES.UNLOCKEDDOOR:
				roomJustEntered = true
				return update_pawn_position(pawn, cell_start, cell_target)
			TILETYPES.MAGICPROJECTILE:
				var object_pawn = get_cell_pawn(cell_target)
				if object_pawn.projectileType == GlobalVariables.PROJECTILETYPE.PLAYER:
					projectilesInActiveRoom.erase(object_pawn)
					object_pawn.queue_free()
					return update_pawn_position(pawn, cell_start, cell_target)
				elif object_pawn.projectileType == GlobalVariables.PROJECTILETYPE.ENEMY:
					projectilesInActiveRoom.erase(object_pawn)
					set_cellv(world_to_map(object_pawn.position), get_tileset().find_tile_by_name("EMPTY"))
					object_pawn.queue_free()
					if pawn.inflict_damage_playerDefeated(object_pawn.attackDamage, GlobalVariables.ATTACKTYPE.MAGIC):
						pawn.movementCount=2
						pawn.attackCount = 0
						return
					return update_pawn_position(pawn, cell_start, cell_target)
			TILETYPES.BLOCK:
				return pawn.position
					
				
#	if(pawn.type == TILETYPES.ENEMY):
	elif match_Enum(pawn.type) == "ENEMY":
		# add other enemies moving freely in the room 
		if get_cellv(cell_target+direction) == TILETYPES.DOOR || get_cellv(cell_target+direction) == TILETYPES.UNLOCKEDDOOR:
			return pawn.position 

		if pawn.enemyType == GlobalVariables.ENEMYTYPE.MAGEENEMY:
			#set mageenmy goal directly 
			cell_target = direction
			cell_target_type = get_cellv(cell_target)
		#print("MOVED enemy in room")
		match cell_target_type:
			TILETYPES.EMPTY:
				return update_pawn_position(pawn, cell_start, cell_target)
			TILETYPES.ENEMY:
				if pawn.enemyType == GlobalVariables.ENEMYTYPE.NINJAENEMY:
					match pawn.movementdirection:
						GlobalVariables.DIRECTION.LEFT:
							pawn.movementdirection = GlobalVariables.DIRECTION.UP
						GlobalVariables.DIRECTION.RIGHT:
							pawn.movementdirection = GlobalVariables.DIRECTION.DOWN
						GlobalVariables.DIRECTION.UP:
							pawn.movementdirection = GlobalVariables.DIRECTION.RIGHT
						GlobalVariables.DIRECTION.DOWN:
							pawn.movementdirection = GlobalVariables.DIRECTION.LEFT
				return pawn.position
			TILETYPES.PLAYER:
				return pawn.position
			TILETYPES.WALL:
				return pawn.position
			TILETYPES.DOOR:
				return pawn.position
			TILETYPES.UNLOCKEDDOOR:
				return pawn.position
			TILETYPES.MAGICPROJECTILE:
				var tempMagicProjectile = get_cell_pawn(cell_target)
				if tempMagicProjectile.projectileType == GlobalVariables.PROJECTILETYPE.PLAYER :
					projectilesInActiveRoom.erase(tempMagicProjectile)
					set_cellv(world_to_map(tempMagicProjectile.position),get_tileset().find_tile_by_name("EMPTY"))
					tempMagicProjectile.queue_free()
					if pawn.inflictDamage(tempMagicProjectile.attackDamage, GlobalVariables.ATTACKTYPE.MAGIC, cell_target):
						return pawn.position 
					else:
						return 
				else:
					projectilesInActiveRoom.erase(tempMagicProjectile)
					set_cellv(world_to_map(tempMagicProjectile.position),get_tileset().find_tile_by_name("EMPTY"))
					tempMagicProjectile.queue_free()
					return update_pawn_position(pawn, cell_start, cell_target)
			TILETYPES.BLOCK:
				return pawn.position
			_:
				return pawn.position

	elif match_Enum(pawn.type) == "MAGICPROJECTILE":
		#print("MOVED enemy in room")
		match cell_target_type:
			TILETYPES.EMPTY:
				return update_pawn_position(pawn, cell_start, cell_target)
			TILETYPES.ENEMY:
				var tempEnemy = get_cell_pawn(cell_target)
				if pawn.projectileType == GlobalVariables.PROJECTILETYPE.PLAYER :
					print("Projectile inflicted damage on enemy")
					tempEnemy.inflictDamage(pawn.attackDamage, GlobalVariables.ATTACKTYPE.MAGIC, cell_target)
					projectilesInActiveRoom.erase(pawn)
					set_cellv(world_to_map(pawn.position),get_tileset().find_tile_by_name("EMPTY")) 
					pawn.queue_free()
				if pawn.projectileType == GlobalVariables.PROJECTILETYPE.ENEMY:
					projectilesInActiveRoom.erase(pawn)
					set_cellv(world_to_map(pawn.position),get_tileset().find_tile_by_name("EMPTY")) 
					pawn.queue_free()
				else:
					return pawn.position
			TILETYPES.PLAYER:
				var tempPlayer = get_cell_pawn(cell_target)
				if pawn.projectileType == GlobalVariables.PROJECTILETYPE.ENEMY :
					tempPlayer.inflict_damage_playerDefeated(pawn.attackDamage, GlobalVariables.ATTACKTYPE.MAGIC)
					projectilesInActiveRoom.erase(pawn)
					set_cellv(world_to_map(pawn.position),get_tileset().find_tile_by_name("EMPTY")) 
					pawn.queue_free()
				elif activeRoom != null && activeRoom.roomType == GlobalVariables.ROOM_TYPE.PUZZLEROOM:
					#set_cellv(world_to_map(pawn.position),get_tileset().find_tile_by_name("EMPTY")) 
					set_cellv(cell_target, get_tileset().find_tile_by_name("MAGICPROJECTILE"))
					return map_to_world(cell_target)
				else:
					return pawn.position
			TILETYPES.WALL:
				projectilesInActiveRoom.erase(pawn)
				set_cellv(world_to_map(pawn.position),get_tileset().find_tile_by_name("EMPTY")) 
				pawn.queue_free()
				#print("Deleting magic projectile " + str(projectilesInActiveRoom.size()))
			TILETYPES.DOOR:
				projectilesInActiveRoom.erase(pawn)
				set_cellv(world_to_map(pawn.position),get_tileset().find_tile_by_name("EMPTY")) 
				pawn.queue_free()
			TILETYPES.UNLOCKEDDOOR:
				projectilesInActiveRoom.erase(pawn)
				set_cellv(world_to_map(pawn.position),get_tileset().find_tile_by_name("EMPTY")) 
				pawn.queue_free()
			TILETYPES.MAGICPROJECTILE:
				#if two enemy projectiles hit each other they bounce back 
				var targetProjectile = get_cell_pawn(cell_target)
				if targetProjectile:
					magicProjectileMagicProjectileInteraction(pawn, targetProjectile)
				return pawn.position
			TILETYPES.BLOCK:
				projectilesInActiveRoom.erase(pawn)
				set_cellv(world_to_map(pawn.position),get_tileset().find_tile_by_name("EMPTY")) 
				if activeRoom!= null && activeRoom.roomType == GlobalVariables.ROOM_TYPE.PUZZLEROOM && pawn.projectileType == GlobalVariables.PROJECTILETYPE.POWERBLOCK:
#					get_cell_pawn(cell_target).spawnMagicFromBlock()
					if !spawnBlockProjectileNextTurn.has(get_cell_pawn(cell_target)):
						get_cell_pawn(cell_target).shootDelay = 2
						spawnBlockProjectileNextTurn.append(get_cell_pawn(cell_target))
				pawn.queue_free()
			TILETYPES.PUZZLEPIECE:
				projectilesInActiveRoom.erase(pawn)
				set_cellv(world_to_map(pawn.position),get_tileset().find_tile_by_name("EMPTY")) 
				if pawn.projectileType == GlobalVariables.PROJECTILETYPE.POWERBLOCK:
					var activatedPuzzlePiece = get_cell_pawn(cell_target)
					if !activatedPuzzlePiece.isActivated:
						if !activatePuzzlePieceNextTurn.has(get_cell_pawn(cell_target)):
							get_cell_pawn(cell_target).activationDelay = 2
							activatePuzzlePieceNextTurn.append(get_cell_pawn(cell_target))
				pawn.queue_free()
			_:
				projectilesInActiveRoom.erase(pawn)
				set_cellv(world_to_map(pawn.position),get_tileset().find_tile_by_name("EMPTY")) 
				pawn.queue_free()
				

func magicProjectileMagicProjectileInteraction(magicProjectile1, magicProjectile2):
	#enemy enemy projectile interaction
	if magicProjectile1.projectileType == GlobalVariables.PROJECTILETYPE.ENEMY && magicProjectile2.projectileType == GlobalVariables.PROJECTILETYPE.ENEMY:
		projectilesInActiveRoom.erase(magicProjectile1)
		set_cellv(world_to_map(magicProjectile1.position),get_tileset().find_tile_by_name("EMPTY")) 
		magicProjectile1.queue_free()
		#magicProjectile1.movementDirection *=-1
	#player enemy projectile interaction
	elif magicProjectile1.projectileType == GlobalVariables.PROJECTILETYPE.PLAYER && magicProjectile2.projectileType == GlobalVariables.PROJECTILETYPE.ENEMY || magicProjectile1.projectileType == GlobalVariables.PROJECTILETYPE.ENEMY && magicProjectile2.projectileType == GlobalVariables.PROJECTILETYPE.PLAYER:
			projectilesToDeleteTurnEnd.append(magicProjectile1)
			projectilesToDeleteTurnEnd.append(magicProjectile2)
			var magicprojectil1temppos = magicProjectile1.position
			magicProjectile1.position = magicProjectile2.position
			magicProjectile2.position = magicprojectil1temppos

	#player player projectile interaction
	elif magicProjectile1.projectileType == GlobalVariables.PROJECTILETYPE.PLAYER && magicProjectile2.projectileType == GlobalVariables.PROJECTILETYPE.PLAYER:
		#print("Player projectiles hit each other " + str(magicProjectile1.movementDirection))
		#if magicProjectile1.movementDirection == magicProjectile2.movementDirection:
		match magicProjectile1.movementDirection:
			Vector2(0,1):
				magicProjectile1.movementDirection = Vector2(1,0)
				magicProjectile2.movementDirection = Vector2(-1,0)
			Vector2(0,-1):
				magicProjectile1.movementDirection = Vector2(1,0)
				magicProjectile2.movementDirection = Vector2(-1,0)
			Vector2(-1,0):
				magicProjectile1.movementDirection = Vector2(0,1)
				magicProjectile2.movementDirection = Vector2(0,-1)
			Vector2(1,0):
				magicProjectile1.movementDirection = Vector2(0,1)
				magicProjectile2.movementDirection = Vector2(0,-1)
		magicProjectile1.isMiniProjectile = true
		magicProjectile2.isMiniProjectile = true
		magicProjectile1.create_mini_projectile(1)
		magicProjectile2.create_mini_projectile(2)
		
	# PuzzleProjectile puzzleprojectile interaction:
	elif magicProjectile1.projectileType == GlobalVariables.PROJECTILETYPE.POWERBLOCK && magicProjectile2.projectileType == GlobalVariables.PROJECTILETYPE.POWERBLOCK:
		print("Magic Projectile Magic Projectile Puzzle Room interaction")
		#projectilesInActiveRoom.erase(magicProjectile1)
		#set_cellv(world_to_map(magicProjectile1.position),get_tileset().find_tile_by_name("EMPTY")) 
		var magicProjectile1BackupPos = magicProjectile1.position 
		magicProjectile1.position = magicProjectile2.position 
		magicProjectile2.position = magicProjectile1BackupPos
		#magicProjectile1.queue_free()


func update_pawn_position(pawn, cell_start, cell_target):
	var oldCellTargetType = get_cellv(cell_target)
	var oldCellTargetNode = get_cell_pawn(cell_target)
	set_cellv(cell_target, get_tileset().find_tile_by_name(match_Enum(pawn.type)))
	set_cellv(cell_start, TILETYPES.EMPTY)

	if(match_Enum(pawn.type) == "PLAYER"):
		if(movedThroughDoor == true):
			set_cellv(cell_start, TILETYPES.UNLOCKEDDOOR)
			movedThroughDoor = false
		if(oldCellTargetType == get_tileset().find_tile_by_name("DOOR") || oldCellTargetType == get_tileset().find_tile_by_name("UNLOCKEDDOOR")):
			movedThroughDoor = true
			var direction 
			if(cell_target.x-cell_start.x < 0):
				direction = "LEFT"
				pawn.movedThroughDoorDirection = Vector2(-1,0)
			if(cell_target.x-cell_start.x > 0):
				direction = "RIGHT"
				pawn.movedThroughDoorDirection = Vector2(1,0)
			if(cell_target.y-cell_start.y < 0):
				direction = "UP"
				pawn.movedThroughDoorDirection = Vector2(0,-1)
			if(cell_target.y-cell_start.y > 0):
				direction = "DOWN"
				pawn.movedThroughDoorDirection = Vector2(0,1)
			if(oldCellTargetType == get_tileset().find_tile_by_name("DOOR")):
				oldCellTargetNode.set_other_adjacent_room(activeRoom, direction)
				if !projectilesInActiveRoom.empty():
					#print("projectiles in active room not empty")
					var tempProjectiles = projectilesInActiveRoom.duplicate()
					for projectile in tempProjectiles:
						set_cellv(world_to_map(projectile.position),get_tileset().find_tile_by_name("EMPTY")) 
						projectile.queue_free()
					projectilesInActiveRoom.clear()
					tempProjectiles.clear()
				if(activeRoom != null):
					#disable elements in room just left
					if !activeRoom.enemiesInRoom.empty():
						for element in activeRoom.enemiesInRoom:
							element.isDisabled = true
					#remove rojectiles in old room
				activeRoom = oldCellTargetNode
				if activeRoom != null:
					pawn.inRoomType = activeRoom.roomType
					print (activeRoom.enemiesInRoom)
					for element in activeRoom.enemiesInRoom:
						element.isDisabled = false
						element.enemyTurnDone=true
						
				else:
					pawn.inRoomType = null
					#print ("Player in Room " + str(pawn.inRoomType))
			if(oldCellTargetType == get_tileset().find_tile_by_name("UNLOCKEDDOOR")):
				var tempProjectiles = projectilesInActiveRoom.duplicate()
				for projectile in tempProjectiles:
					set_cellv(world_to_map(projectile.position),get_tileset().find_tile_by_name("EMPTY")) 
					projectile.queue_free()
				projectilesInActiveRoom.clear()
				tempProjectiles.clear()
				if(activeRoom != null):
					#disable elements in room just left
					if !activeRoom.enemiesInRoom.empty():
						for element in activeRoom.enemiesInRoom:
							element.isDisabled = true
					#remove rojectiles in old room
				activeRoom=oldCellTargetNode.get_room_by_movement_direction(direction)
				if activeRoom != null:
					pawn.inRoomType = activeRoom.roomType
					#print ("Player in Room " + str(pawn.inRoomType))
					for element in activeRoom.enemiesInRoom:
						element.isDisabled = false
				else:
					pawn.inRoomType = null
					#print ("Player in Room " + str(pawn.inRoomType))
						
			#update camera position 
			var mainCamera = get_node("/root/MainCamera")
			if(activeRoom != null):
				#print(activeRoom.doorRoomLeftMostCorner) 
				mainCamera.move_and_zoom_camera_to_room(activeRoom.doorRoomLeftMostCorner, Vector2(float(activeRoom.roomSize.x)/2, float(activeRoom.roomSize.y)/2) * GlobalVariables.tileSize - GlobalVariables.tileOffset, activeRoom.roomSizeMultiplier) 
			else:
				mainCamera.set_camera_starting_room()
			#mainCamera.zoom = mainCamera.zoom + Vector2(1,1)
			mainCamera.make_current()

			#let player move freely if room is cleared
			if(activeRoom == null || activeRoom.roomType == GlobalVariables.ROOM_TYPE.EMPTYTREASUREROOM):
				pawn.inClearedRoom = true
				if activeRoom!= null && activeRoom.roomType == GlobalVariables.ROOM_TYPE.EMPTYTREASUREROOM && !activeRoom.roomCleared:
					dropLootInActiveRoom()
					activeRoom.roomCleared = true
			else:
				pawn.inClearedRoom = false

	#print("Map to world " + str(cell_target))
	return map_to_world(cell_target) + cell_size / GlobalVariables.isometricFactor
	
func enablePlayerAttack(player):
	if(activeRoom == null || activeRoom.enemiesInRoom.empty()):
		player.playerCanAttack=false
		return
	player.playerCanAttack = true
		#player can always attack if in enemy room
#	for element in activeRoom.enemiesInRoom:
#		if(element.position == player.position + map_to_world(Vector2(1,0)) || element.position == player.position + map_to_world(Vector2(-1,0)) || element.position == player.position + map_to_world(Vector2(0,1)) || element.position == player.position + map_to_world(Vector2(0,-1))):
#			#print("player can attack in enable function ")
#			player.playerCanAttack=true
#			return 
#	player.playerCanAttack=false

func enableEnemyAttack(enemy,attackType, horizontalVerticalAttack, diagonalAttack):
	if attackType == GlobalVariables.ATTACKTYPE.SWORD || attackType == GlobalVariables.ATTACKTYPE.NINJA:
		if horizontalVerticalAttack && !diagonalAttack:
			if(get_cellv(world_to_map(enemy.position)+Vector2(1,0)) == TILETYPES.PLAYER):
				return Vector2(1,0)
			elif(get_cellv(world_to_map(enemy.position)+Vector2(-1,0)) == TILETYPES.PLAYER):
				return Vector2(-1,0)
			elif(get_cellv(world_to_map(enemy.position)+Vector2(0,1)) == TILETYPES.PLAYER):
				return Vector2(0,1)
			elif(get_cellv(world_to_map(enemy.position)+Vector2(0,-1)) == TILETYPES.PLAYER):
				return Vector2(0,-1)
		elif !horizontalVerticalAttack && diagonalAttack:
			if(get_cellv(world_to_map(enemy.position)+Vector2(1,1)) == TILETYPES.PLAYER):
				return Vector2(1,1)
			elif(get_cellv(world_to_map(enemy.position)+Vector2(-1,-1)) == TILETYPES.PLAYER):
				return Vector2(-1,-1)
			elif(get_cellv(world_to_map(enemy.position)+Vector2(1,-1)) == TILETYPES.PLAYER):
				return Vector2(1,-1)
			elif(get_cellv(world_to_map(enemy.position)+Vector2(-1,1)) == TILETYPES.PLAYER):
				return Vector2(-1,1)
		else:
			if(get_cellv(world_to_map(enemy.position)+Vector2(1,0)) == TILETYPES.PLAYER):
				return Vector2(1,0)
			elif(get_cellv(world_to_map(enemy.position)+Vector2(-1,0)) == TILETYPES.PLAYER):
				return Vector2(-1,0)
			elif(get_cellv(world_to_map(enemy.position)+Vector2(0,1)) == TILETYPES.PLAYER):
				return Vector2(0,1)
			elif(get_cellv(world_to_map(enemy.position)+Vector2(0,-1)) == TILETYPES.PLAYER):
				return Vector2(0,-1)
			if(get_cellv(world_to_map(enemy.position)+Vector2(1,1)) == TILETYPES.PLAYER):
				return Vector2(1,1)
			elif(get_cellv(world_to_map(enemy.position)+Vector2(-1,-1)) == TILETYPES.PLAYER):
				return Vector2(-1,-1)
			elif(get_cellv(world_to_map(enemy.position)+Vector2(1,-1)) == TILETYPES.PLAYER):
				return Vector2(1,-1)
			elif(get_cellv(world_to_map(enemy.position)+Vector2(-1,1)) == TILETYPES.PLAYER):
				return Vector2(-1,1)
	if attackType == GlobalVariables.ATTACKTYPE.MAGIC:
		var possibleDirectionArray = []

		if get_cellv(world_to_map(enemy.position)+Vector2(-1,0)) != TILETYPES.WALL && get_cellv(world_to_map(enemy.position)+Vector2(-1,0)) != TILETYPES.BLOCK && get_cellv(world_to_map(enemy.position)+Vector2(-1,0)) != TILETYPES.ENEMY:
			possibleDirectionArray.append(GlobalVariables.DIRECTION.LEFT)
		if get_cellv(world_to_map(enemy.position)+Vector2(1,0)) != TILETYPES.WALL && get_cellv(world_to_map(enemy.position)+Vector2(1,0)) != TILETYPES.BLOCK && get_cellv(world_to_map(enemy.position)+Vector2(1,0)) != TILETYPES.ENEMY:
			possibleDirectionArray.append(GlobalVariables.DIRECTION.RIGHT)
		if get_cellv(world_to_map(enemy.position)+Vector2(0,1)) != TILETYPES.WALL && get_cellv(world_to_map(enemy.position)+Vector2(0,1)) != TILETYPES.BLOCK && get_cellv(world_to_map(enemy.position)+Vector2(0,1)) != TILETYPES.ENEMY:
			possibleDirectionArray.append(GlobalVariables.DIRECTION.DOWN)
		if get_cellv(world_to_map(enemy.position)+Vector2(0,-1)) != TILETYPES.WALL && get_cellv(world_to_map(enemy.position)+Vector2(0,-1)) != TILETYPES.BLOCK && get_cellv(world_to_map(enemy.position)+Vector2(0,-1)) != TILETYPES.ENEMY:
			possibleDirectionArray.append(GlobalVariables.DIRECTION.UP)
		
		#print (possibleDirectionArray)
		if !possibleDirectionArray.empty():
			var shootDirection = randi()%possibleDirectionArray.size()
			match possibleDirectionArray[shootDirection]:
				GlobalVariables.DIRECTION.LEFT:
					return Vector2(-1,0)
				GlobalVariables.DIRECTION.RIGHT:
					return Vector2(1,0)
				GlobalVariables.DIRECTION.UP:
					return Vector2(0,-1)
				GlobalVariables.DIRECTION.DOWN:
					return Vector2(0,1)
		else:
			return Vector2.ZERO
	#enable ninja range attack 
	if attackType == GlobalVariables.ATTACKTYPE.NINJA:
		var attackdirectionArray = []
		match enemy.movementdirection:
			GlobalVariables.DIRECTION.LEFT:
				attackdirectionArray.append(Vector2(0,1))
				attackdirectionArray.append(Vector2(0,-1))
			GlobalVariables.DIRECTION.RIGHT:
				attackdirectionArray.append(Vector2(0,1))
				attackdirectionArray.append(Vector2(0,-1))
			GlobalVariables.DIRECTION.UP:
				attackdirectionArray.append(Vector2(1,0))
				attackdirectionArray.append(Vector2(-1,0))
			GlobalVariables.DIRECTION.DOWN:
				attackdirectionArray.append(Vector2(1,0))
				attackdirectionArray.append(Vector2(-1,0))
				
		for direction in attackdirectionArray:
			for count in range (enemy.ninjaAttackRange):
				if direction == Vector2(1,0):
					if get_cellv(world_to_map(enemy.position)+Vector2(count,0)) == TILETYPES.PLAYER:
						#print("Player RIGHT " + str(Vector2(count,0)))
						return Vector2(count,0)
				elif direction == Vector2(-1,0):
					if get_cellv(world_to_map(enemy.position)-Vector2(count,0)) == TILETYPES.PLAYER:
						#print("Player LEFT " + str(Vector2(count,0)))
						return Vector2(-count,0)
				if direction == Vector2(0,1):
					if get_cellv(world_to_map(enemy.position)+Vector2(0,count)) == TILETYPES.PLAYER:
						#print("Player DOWN " + str(Vector2(count,0)))
						return Vector2(0,count)
				elif direction == Vector2(0,-1):
					if get_cellv(world_to_map(enemy.position)-Vector2(0,count)) == TILETYPES.PLAYER:
						#print("Player UP " + str(Vector2(count,0)))
						return Vector2(0,-count)
				
	return Vector2.ZERO

func create_puzzle_room(unlockedDoor):
	randomize()
	var puzzlePiecesToSpwan = 4
	var calculateSpawnAgain = true
	var alreadyUsedColors = []
	var spawnCellArray = []
	var spawnCellX
	var spawnCellY
	var spawnCell 
	var barrierPuzzlePieceAlreadySpawned = false
	for puzzlePieces in puzzlePiecesToSpwan:
		#print("generatig puzzle pieces")
		calculateSpawnAgain = true
		while(calculateSpawnAgain == true):
			spawnCellX = randi()%(int(unlockedDoor.roomSize.x-2))+1
			spawnCellY = randi()%(int(unlockedDoor.roomSize.y-2))+1
			spawnCell = spawnCellX*spawnCellY
			var spawnCords = world_to_map(unlockedDoor.doorRoomLeftMostCorner) + Vector2(spawnCellX, spawnCellY)
			#print("Spawn Coords" + str(spawnCords))
			if get_cellv(spawnCords - Vector2(1,0)) == TILETYPES.DOOR || get_cellv(spawnCords - Vector2(-1,0)) == TILETYPES.DOOR || get_cellv(spawnCords - Vector2(0,1)) == TILETYPES.DOOR || get_cellv(spawnCords - Vector2(0,-1)) == TILETYPES.DOOR || get_cellv(spawnCords - Vector2(1,0)) == TILETYPES.UNLOCKEDDOOR || get_cellv(spawnCords - Vector2(-1,0)) == TILETYPES.UNLOCKEDDOOR || get_cellv(spawnCords - Vector2(0,1)) == TILETYPES.UNLOCKEDDOOR || get_cellv(spawnCords - Vector2(0,-1)) == TILETYPES.UNLOCKEDDOOR:
				pass
			elif get_cellv(spawnCords + Vector2(1,0)) == TILETYPES.WALL && get_cellv(spawnCords + Vector2(-1,0)) == TILETYPES.WALL || get_cellv(spawnCords + Vector2(0,1)) == TILETYPES.WALL && get_cellv(spawnCords + Vector2(0,-1)) == TILETYPES.WALL:
				pass
			elif get_cellv(spawnCords - Vector2(2,0)) == TILETYPES.DOOR || get_cellv(spawnCords - Vector2(-2,0)) == TILETYPES.DOOR || get_cellv(spawnCords - Vector2(0,2)) == TILETYPES.DOOR || get_cellv(spawnCords - Vector2(0,-2)) == TILETYPES.DOOR || get_cellv(spawnCords - Vector2(1,0)) == TILETYPES.UNLOCKEDDOOR || get_cellv(spawnCords - Vector2(-1,0)) == TILETYPES.UNLOCKEDDOOR || get_cellv(spawnCords - Vector2(0,1)) == TILETYPES.UNLOCKEDDOOR || get_cellv(spawnCords - Vector2(0,-1)) == TILETYPES.UNLOCKEDDOOR:
				pass
			elif spawnCellArray.has(spawnCell):
				pass
			else:
				calculateSpawnAgain = false
				spawnCellArray.append(spawnCell)
		
		var colorToUse = GlobalVariables.COLOR.RED
		while alreadyUsedColors.has(colorToUse):
			var randColor = randi()%4
			match randColor:
				0:
					colorToUse = GlobalVariables.COLOR.RED
				1:
					colorToUse = GlobalVariables.COLOR.BLUE
				2:
					colorToUse = GlobalVariables.COLOR.GREEN
				3:
					colorToUse = GlobalVariables.COLOR.YELLOW
		alreadyUsedColors.append(colorToUse)
		var newPuzzlePiece = PuzzlePiece.instance()
		if !barrierPuzzlePieceAlreadySpawned:
			if randi()%4 == 0: 
				barrierPuzzlePieceAlreadySpawned=true
				newPuzzlePiece.makePuzzleBarrier(self)
		newPuzzlePiece.color = colorToUse
		newPuzzlePiece.position = unlockedDoor.doorRoomLeftMostCorner + map_to_world(Vector2(spawnCellX, spawnCellY))
		add_child(newPuzzlePiece)
		newPuzzlePiece.connect("puzzlePieceActivated", self, "_on_puzzle_piece_activated")
		newPuzzlePiece.connect("puzzlePlayedAnimation", self, "_on_puzzlepiece_played_animation")
		set_cellv(world_to_map(newPuzzlePiece.position), get_tileset().find_tile_by_name("PUZZLEPIECE"))
		unlockedDoor.puzzlePiecesInRoom.append(newPuzzlePiece)
	

func create_enemy_room(unlockedDoor):
	randomize()
	#add adjustment for enemy amount 
	#-2 because of walls on both sides
	var enemiesToSpawn = 4
	if unlockedDoor.roomSizeMultiplier == Vector2(1,1):
		enemiesToSpawn = randi()%3+1
	elif unlockedDoor.roomSizeMultiplier == Vector2(2,2):
		enemiesToSpawn = randi()%5+1
	var sizecounter = 0
	var mageEnemyCount = 0
	var spawnCellArray = []
	for enemie in enemiesToSpawn: 
		var tooCloseToDoor = true
		var alreadyinArray = true
		while(alreadyinArray == true):
			var spawnCellX = randi()%(int(unlockedDoor.roomSize.x-2))+1
			var spawnCellY = randi()%(int(unlockedDoor.roomSize.y-2))+1
			while tooCloseToDoor:
				var spawnCords = world_to_map(unlockedDoor.doorRoomLeftMostCorner) + Vector2(spawnCellX, spawnCellY)
				#print("Spawn Coords" + str(spawnCords))
				if get_cellv(spawnCords - Vector2(1,0)) == TILETYPES.DOOR || get_cellv(spawnCords - Vector2(-1,0)) == TILETYPES.DOOR || get_cellv(spawnCords - Vector2(0,1)) == TILETYPES.DOOR || get_cellv(spawnCords - Vector2(0,-1)) == TILETYPES.DOOR || get_cellv(spawnCords - Vector2(1,0)) == TILETYPES.UNLOCKEDDOOR || get_cellv(spawnCords - Vector2(-1,0)) == TILETYPES.UNLOCKEDDOOR || get_cellv(spawnCords - Vector2(0,1)) == TILETYPES.UNLOCKEDDOOR || get_cellv(spawnCords - Vector2(0,-1)) == TILETYPES.UNLOCKEDDOOR:
					spawnCellX = randi()%(int(unlockedDoor.roomSize.x-2))+1
					spawnCellY = randi()%(int(unlockedDoor.roomSize.y-2))+1
				elif get_cellv(spawnCords + Vector2(1,0)) == TILETYPES.WALL && get_cellv(spawnCords + Vector2(-1,0)) == TILETYPES.WALL || get_cellv(spawnCords + Vector2(0,1)) == TILETYPES.WALL && get_cellv(spawnCords + Vector2(0,-1)) == TILETYPES.WALL:
					spawnCellX = randi()%(int(unlockedDoor.roomSize.x-2))+1
					spawnCellY = randi()%(int(unlockedDoor.roomSize.y-2))+1
				else:
					tooCloseToDoor = false

			var spawnCell = spawnCellX*spawnCellY
			if(!spawnCellArray.has(spawnCell)):
				alreadyinArray = false
				spawnCellArray.append(spawnCell)
				var newEnemy = Enemy.instance()
				#create enemy typ here (enemy. createEnemyType
				newEnemy.position = unlockedDoor.doorRoomLeftMostCorner + map_to_world(Vector2(spawnCellX, spawnCellY))
				var generatedEnemyType = newEnemy.generateEnemy(mageEnemyCount, self)
				if(generatedEnemyType == GlobalVariables.ENEMYTYPE.MAGEENEMY):
					mageEnemyCount += 1
				newEnemy.connect("enemyMadeMove", self, "_on_enemy_made_move_ready")
				newEnemy.connect("enemyAttacked", self, "_on_enemy_attacked")
				newEnemy.connect("enemyDefeated", self, "_on_enemy_defeated")
				add_child(newEnemy)
				set_cellv(world_to_map(newEnemy.position), get_tileset().find_tile_by_name(match_Enum(newEnemy.type)))
				unlockedDoor.enemiesInRoom.append(newEnemy)
	#print(spawnCellArray)

func get_enemy_move_towards_player(enemy):
	var distance = world_to_map(mainPlayer.position) - world_to_map(enemy.position)
	if abs(distance.x) >= abs(distance.y):
		return Vector2(distance.x/abs(distance.x),0)
	else:
		return Vector2(0,distance.y/abs(distance.y))

func get_enemy_move_ninja_pattern(enemy, movementdirection, moveCellCount):
	match movementdirection:
		GlobalVariables.DIRECTION.LEFT:
			if get_cellv(world_to_map(enemy.position) - Vector2(moveCellCount,0)) == TILETYPES.WALL || get_cellv(world_to_map(enemy.position) - Vector2(1,0)) == TILETYPES.WALL:
				enemy.movementdirection = GlobalVariables.DIRECTION.RIGHT
				return Vector2(moveCellCount,0)
			return Vector2(-moveCellCount,0)
		GlobalVariables.DIRECTION.RIGHT:
			if get_cellv(world_to_map(enemy.position) + Vector2(moveCellCount,0)) == TILETYPES.WALL || get_cellv(world_to_map(enemy.position) + Vector2(1,0)) == TILETYPES.WALL:
				enemy.movementdirection = GlobalVariables.DIRECTION.LEFT
				return Vector2(-moveCellCount,0)
			return Vector2(moveCellCount,0)
		GlobalVariables.DIRECTION.UP:
			if get_cellv(world_to_map(enemy.position) - Vector2(0,moveCellCount)) == TILETYPES.WALL || get_cellv(world_to_map(enemy.position) - Vector2(0,1)) == TILETYPES.WALL:
				enemy.movementdirection = GlobalVariables.DIRECTION.DOWN
				return Vector2(0,moveCellCount)
			return Vector2(0,-moveCellCount)
		GlobalVariables.DIRECTION.DOWN:
			if get_cellv(world_to_map(enemy.position) + Vector2(0,moveCellCount)) == TILETYPES.WALL || get_cellv(world_to_map(enemy.position) + Vector2(0,1)) == TILETYPES.WALL:
				enemy.movementdirection = GlobalVariables.DIRECTION.UP
				return Vector2(0,-moveCellCount)
			return Vector2(0,moveCellCount)
	
func get_enemy_move_mage_pattern(enemy, movementdirection):
	#return corner of the room according to movementdirection
	match movementdirection:
		GlobalVariables.DIRECTION.MIDDLE:
			return world_to_map(activeRoom.doorRoomLeftMostCorner)+ Vector2(int(activeRoom.roomSize.x/2), int(activeRoom.roomSize.y/2))
		GlobalVariables.DIRECTION.RIGHT:
			return world_to_map(activeRoom.doorRoomLeftMostCorner)+ Vector2(activeRoom.roomSize.x-2,1)
		GlobalVariables.DIRECTION.DOWN:
			return world_to_map(activeRoom.doorRoomLeftMostCorner)+ Vector2(activeRoom.roomSize.x-2,activeRoom.roomSize.y-2)
		GlobalVariables.DIRECTION.LEFT:
			return world_to_map(activeRoom.doorRoomLeftMostCorner)+ Vector2(1,activeRoom.roomSize.y-2)
		GlobalVariables.DIRECTION.UP:
			return world_to_map(activeRoom.doorRoomLeftMostCorner)+ Vector2(1,1)
	return Vector2.ZERO
			
func _on_enemy_made_move_ready():
	if(activeRoom != null):
		enemiesMadeMoveCounter += 1
		#print("Enemies made move " + str(enemiesMadeMoveCounter) + " enemies in active room " + str(activeRoom.enemiesInRoom.size()))
		#print("Currently Enemies made move " + str(enemiesMadeMoveCounter) + " of all enemies active " + str(activeRoom.enemiesInRoom.size()))
		if(enemiesMadeMoveCounter >= activeRoom.enemiesInRoom.size()):
			if mainPlayer.playerDefeated:
				mainPlayer.playerDefeated = false
				_on_Player_Defeated(mainPlayer)
				return
			#print("All Enemies made move " + str(enemiesMadeMoveCounter))
			enemiesMadeMoveCounter = 0
			var tempProjectiles = projectilesInActiveRoom.duplicate()
			for projectile in tempProjectiles:
				projectile.move_projectile("movePlayerProjectiles")
			tempProjectiles.clear()
			if projectilesInActiveRoom.empty():
				emit_signal("enemyTurnDoneSignal")
			#if all enemies made their move move all player projectiles 
			
		
func _on_Player_Made_Move():
	if movedThroughDoor:
		return
	mainPlayer.playerBackupPosition = mainPlayer.position
	if activeRoom != null && !activeRoom.roomCleared && roomJustEntered && activeRoom.roomType == GlobalVariables.ROOM_TYPE.PUZZLEROOM && !activeRoom.puzzlePiecesInRoom.empty(): 
		#print("Playing _on_Player_Made_Move PuzzlePieceCounter " + str(puzzlePiecesAnimationDoneCounter))
		if !puzzleAnimationPlaying:
			puzzleAnimationPlaying=true
			activeRoom.puzzlePiecesInRoom[0].playColor()
	else:
		roomJustEntered = false
		if activeRoom != null && activeRoom.roomType == GlobalVariables.ROOM_TYPE.PUZZLEROOM:
			var tempProjectiles = projectilesInActiveRoom.duplicate()
			#print("Projectiles in active Room in Player made move" + str(projectilesInActiveRoom))
			
			if tempProjectiles.empty() && !spawnBlockProjectileNextTurn.empty():
				for projectile in spawnBlockProjectileNextTurn:
					#print("Projectiles waiting for turn " + str(spawnBlockProjectileNextTurn))
					_on_projectiles_made_move()
			else:
				for projectile in tempProjectiles:
					if projectile.projectileType != GlobalVariables.PROJECTILETYPE.POWERBLOCK:
						projectile.move_projectile("movePowerProjectile")
			tempProjectiles.clear()
		
		else:
			var tempProjectiles = projectilesInActiveRoom.duplicate()
			if tempProjectiles.empty():
				emit_signal("playerTurnDoneSignal")
			for projectile in tempProjectiles:
				if activeRoom == null || activeRoom.roomCleared:
					pass
				projectile.move_projectile("moveEnemyProjectiles")
			tempProjectiles.clear()
			
		if activeRoom == null:
			emit_signal("enemyTurnDoneSignal")
		elif activeRoom.roomType == GlobalVariables.ROOM_TYPE.PUZZLEROOM && !projectilesInActiveRoom.empty() :
			return
		elif activeRoom.enemiesInRoom.empty():
				emit_signal("enemyTurnDoneSignal")
		elif projectilesInActiveRoom.empty() && !GlobalVariables.ROOM_TYPE.PUZZLEROOM && !projectilesInActiveRoom.empty():
			emit_signal("playerTurnDoneSignal")
		elif projectilesInActiveRoom.empty() && GlobalVariables.ROOM_TYPE.PUZZLEROOM && !projectilesInActiveRoom.empty():
			_on_projectiles_made_move()
			
func _on_puzzlepiece_played_animation():
	puzzlePiecesAnimationDoneCounter += 1
	if puzzlePiecesAnimationDoneCounter < activeRoom.puzzlePiecesInRoom.size():
		#print("Playing Animation PuzzlePieceCounter " + str(puzzlePiecesAnimationDoneCounter))
		activeRoom.puzzlePiecesInRoom[puzzlePiecesAnimationDoneCounter].playColor()
	elif puzzlePiecesAnimationDoneCounter >= activeRoom.puzzlePiecesInRoom.size():
		puzzlePiecesAnimationDoneCounter = 0
		roomJustEntered = false
		puzzleAnimationPlaying = false
		_on_Player_Made_Move()

func _on_puzzle_piece_activated():
	print ("activated puzzle pieces size " + str(activatedPuzzlePieces.size()) + " active puzzle pieces in room " + str(activeRoom.puzzlePiecesInRoom.size()))
	if activatedPuzzlePieces.size() == activeRoom.puzzlePiecesInRoom.size():
		var puzzlePieceIsBarrier = false
		for puzzlePiece in activatedPuzzlePieces:
			if puzzlePiece.isBarrier:
				puzzlePieceIsBarrier = true
		if activatedPuzzlePieces == activeRoom.puzzlePiecesInRoom && !activeRoom.roomCleared && !puzzlePieceIsBarrier:
			print("Activated in right order")
			emit_signal("enemyTurnDoneSignal")
			activeRoom.roomCleared=true
			mainPlayer.inClearedRoom = true
			#delete all projectiles 
			if activeRoom.dropLoot():
				for puzzlePiece in activatedPuzzlePieces:
					puzzlePiece.playWrongWriteAnimation(true)
				dropLootInActiveRoom()
			cancelMagicPuzzelRoom = true
		else:
			if !activeRoom.roomCleared:
				if puzzlePieceIsBarrier:
					print("try again after activating puzzle piece barrier")
				else:
					print("try again activated in wrong order")
				for puzzlePiece in activatedPuzzlePieces:
						puzzlePiece.playWrongWriteAnimation(false)
						
func _on_projectiles_made_move(type=null):
	projectilesMadeMoveCounter +=1
	#print("Projectiles made move " + str(projectilesMadeMoveCounter) + " projectiles in active room " + str(projectilesInActiveRoom.size()) + " type " +str(type)) 
	if projectilesMadeMoveCounter >= projectilesInActiveRoom.size():
		projectilesMadeMoveCounter = 0
		
		if cancelMagicPuzzelRoom:
			var tempProjectiles = projectilesInActiveRoom.duplicate()
			for projectile in tempProjectiles:
				#interfere on next move projectile 
				if projectile.projectileType == GlobalVariables.PROJECTILETYPE.TICKERPROJECTILE:
					set_cellv(world_to_map(projectile.position),get_tileset().find_tile_by_name("WALL")) 
				else:
					set_cellv(world_to_map(projectile.position),get_tileset().find_tile_by_name("EMPTY")) 
				projectile.queue_free()
			projectilesInActiveRoom.clear()
			tempProjectiles.clear()
			cancelMagicPuzzelRoom = false
			for puzzlePiece in activatedPuzzlePieces:
				puzzlePiece.isActivated=false
			mainPlayer.position = mainPlayer.playerBackupPosition
			mainPlayer.get_node("Sprite").set_visible(true)
			set_cellv(world_to_map(mainPlayer.position), get_tileset().find_tile_by_name("PLAYER"))
			emit_signal("enemyTurnDoneSignal")
		elif activeRoom != null && activeRoom.roomType == GlobalVariables.ROOM_TYPE.PUZZLEROOM:
			var tempProjectiles = projectilesInActiveRoom.duplicate()
			#print("Projectiles in active Room " + str(projectilesInActiveRoom))
			for projectile in tempProjectiles:
				if projectile.projectileType == GlobalVariables.PROJECTILETYPE.TICKERPROJECTILE:
					#print("TICKTOCK")
					projectile.move_projectile("tickingProjectile")
#				elif projectile.projectileType == GlobalVariables.PROJECTILETYPE.TICKERPROJECTILE && projectile.tickAlreadyMoved:
#					print("ELIF TICKTOCK")
#					projectile.tickAlreadyMoved = false
				else:
					projectile.move_projectile("allProjectiles")
			tempProjectiles.clear()
			
			if spawnBlockProjectileNextTurn.size() > 10:
				spawnBlockProjectileNextTurn.clear()
			if !spawnBlockProjectileNextTurn.empty():
				#print("Projectile waiting in extra condition " + str(spawnBlockProjectileNextTurn) )
				var spawnBlockProjectileNextTurnTempCopy = spawnBlockProjectileNextTurn.duplicate()
				if !activatePuzzlePieceNextTurn.empty():
					var activatePuzzlePieceNextTurnTemp = activatePuzzlePieceNextTurn.duplicate()
					for puzzlePiece in activatePuzzlePieceNextTurnTemp:
						if puzzlePiece.activationDelay == 0:
							if !puzzlePiece.isActivated:
								activatedPuzzlePieces.append(puzzlePiece)
								puzzlePiece.activatePuzzlePiece()
								activatePuzzlePieceNextTurn.erase(puzzlePiece)
						else:
							puzzlePiece.activationDelay-=1
					activatePuzzlePieceNextTurnTemp.clear()
				
				for boxProjectile in spawnBlockProjectileNextTurnTempCopy:
					if boxProjectile.shootDelay == 0:
						#print("In boxprojectile shootdelay == 0 " + str(boxProjectile))
						if boxProjectile.get_node("PowerBlockModulate").get_modulate() == Color(0.65,0.65,1.0,1.0):
							boxProjectile.get_node("PowerBlockModulate").set_modulate(Color(randf(),randf(),randf(),1.0))
						else:
							boxProjectile.get_node("PowerBlockModulate").set_modulate(Color(0.65,0.65,1.0,1.0))
						#boxProjectile.get_node("PowerBlockModulate").set_deferred("modulate", "798aff")
						if boxProjectile == spawnBlockProjectileNextTurnTempCopy[spawnBlockProjectileNextTurnTempCopy.size()-1]:
							boxProjectile.spawnMagicFromBlock(true)
							#print("Here")
						else:
							boxProjectile.spawnMagicFromBlock(false)
							#print("there")
						spawnBlockProjectileNextTurn.erase(boxProjectile)
					else:
						boxProjectile.shootDelay-=1
				
				spawnBlockProjectileNextTurnTempCopy.clear()
						
			elif !activatePuzzlePieceNextTurn.empty():
				var activatePuzzlePieceNextTurnTemp = activatePuzzlePieceNextTurn.duplicate()
				for puzzlePiece in activatePuzzlePieceNextTurnTemp:
					if puzzlePiece.activationDelay == 0:
						if !puzzlePiece.isActivated:
							activatedPuzzlePieces.append(puzzlePiece)
							puzzlePiece.activatePuzzlePiece()
							activatePuzzlePieceNextTurn.erase(puzzlePiece)
					else:
						puzzlePiece.activationDelay-=1
				activatePuzzlePieceNextTurnTemp.clear()
				if projectilesInActiveRoom.empty():
					_on_projectiles_made_move()

						
#						if projectilesInActiveRoom.empty():
#							boxProjectile.shootDelay=0
#							_on_projectiles_made_move(boxProjectile)
		#print("Projectile type to be moved " + str(type))
		if type == "moveEnemyProjectiles":
			#print("Emmiting Player turn done signal")
			emit_signal("playerTurnDoneSignal")
		elif type == "movePlayerProjectiles":
			emit_signal("enemyTurnDoneSignal")
			#print("Emmiting Enemy turn done signal")
	if activeRoom == null: 
		pass
	elif activeRoom !=null && projectilesInActiveRoom.empty() && activeRoom.roomType != GlobalVariables.ROOM_TYPE.PUZZLEROOM:
		emit_signal("enemyTurnDoneSignal")
	elif activeRoom.roomType == GlobalVariables.ROOM_TYPE.PUZZLEROOM && projectilesInActiveRoom.empty() && spawnBlockProjectileNextTurn.empty():
		emit_signal("enemyTurnDoneSignal")
	elif activeRoom.roomType == GlobalVariables.ROOM_TYPE.PUZZLEROOM && !spawnBlockProjectileNextTurn.empty():
		#print("IN HERE")
		if projectilesInActiveRoom.empty():
			_on_projectiles_made_move()

func _on_Player_Attacked(player, attack_direction, attackDamage, attackType):
	randomize()
	#if player hits wall return 
	if get_cellv(world_to_map(player.position) + attack_direction) == TILETYPES.WALL || get_cellv(world_to_map(player.position) + attack_direction) == TILETYPES.DOOR || get_cellv(world_to_map(player.position) + attack_direction) == TILETYPES.UNLOCKEDDOOR:
		player.waitingForEventBeforeContinue = false
		return
	#sword attacks
	if(get_cellv(world_to_map(player.position) + attack_direction) == TILETYPES.ENEMY && attackType == GlobalVariables.ATTACKTYPE.SWORD):
		print("Woosh Player Sword Attack hit " + str(attackDamage))
		var attackedEnemy = get_cell_pawn(world_to_map(player.position) + attack_direction)
		attackedEnemy.inflictDamage(attackDamage, attackType, world_to_map(player.position) + attack_direction, mainPlayer)
				
	elif(get_cellv(world_to_map(player.position) + attack_direction) == TILETYPES.EMPTY && attackType == GlobalVariables.ATTACKTYPE.SWORD):
		match attackType:
			GlobalVariables.ATTACKTYPE.SWORD:
				print("Sword was used to attack")
				print("ZZZ Attack missed")
	#wand attacks
	#use wand on block in puzzle room 
	if  activeRoom != null && activeRoom.roomType == GlobalVariables.ROOM_TYPE.PUZZLEROOM && get_cellv(world_to_map(player.position) + attack_direction) == TILETYPES.BLOCK && attackType == GlobalVariables.ATTACKTYPE.MAGIC:
		player.end_player_turn()
		for projectile in projectilesInActiveRoom:
			set_cellv(world_to_map(projectile.position),get_tileset().find_tile_by_name("EMPTY")) 
			projectile.queue_free()
		projectilesInActiveRoom.clear()
		projectilesInActiveRoom.clear()
		player.playerBackupPosition = player.position
		player.get_node("Sprite").set_visible(false)
		set_cellv(world_to_map(player.position), get_tileset().find_tile_by_name("EMPTY")) 
		for puzzlePiece in activatedPuzzlePieces:
			puzzlePiece.isActivated=false
			puzzlePiece.get_node("Sprite").set_modulate(puzzlePiece.baseModulation)
		activatedPuzzlePieces.clear()
		var blockAttackedByMagic = get_cell_pawn(world_to_map(player.position) + attack_direction)
		player.position = activeRoom.doorRoomLeftMostCorner + map_to_world(activeRoom.roomSize - Vector2(1,1))
		for powerBlock in activeRoom.powerBlocksInRoom:
			#if powerBlock!=blockAttackedByMagic:
			powerBlock.get_node("PowerBlockModulate").set_deferred("modulate", "ffffff")
		blockAttackedByMagic.get_node("PowerBlockModulate").set_deferred("modulate", "798aff")
		#create ticking projectile for power block order
		var newTickingProjectile = MagicProjectile.instance()
		newTickingProjectile.connect("projectileMadeMove", self, "_on_projectiles_made_move")
		newTickingProjectile.create_ticking_projectile(activeRoom.doorRoomLeftMostCorner)
		add_child(newTickingProjectile)
		projectilesInActiveRoom.append(newTickingProjectile)
		blockAttackedByMagic.spawnMagicFromBlock(true)
	elif (get_cellv(world_to_map(player.position) + attack_direction*2) == TILETYPES.ENEMY && attackType == GlobalVariables.ATTACKTYPE.MAGIC):
		print("Woosh Player Wand Attack hit")
		var attackedEnemy = get_cell_pawn(world_to_map(player.position) + attack_direction*2)
		attackedEnemy.inflictDamage(attackDamage, attackType, world_to_map(player.position) + attack_direction*2)
	elif (get_cellv(world_to_map(player.position) + attack_direction*2) == TILETYPES.EMPTY && attackType == GlobalVariables.ATTACKTYPE.MAGIC):
		print("Magic was used to attack")
		var newMagicProjectile = MagicProjectile.instance()
		newMagicProjectile.connect("projectileMadeMove", self, "_on_projectiles_made_move")
		newMagicProjectile.position = player.position + map_to_world(attack_direction*2)
		newMagicProjectile.projectileType = GlobalVariables.PROJECTILETYPE.PLAYER
		newMagicProjectile.movementDirection = attack_direction
		newMagicProjectile.attackDamage = attackDamage
		newMagicProjectile.play_player_projectile_animation()
		add_child(newMagicProjectile)
		projectilesInActiveRoom.append(newMagicProjectile)
		set_cellv(world_to_map(newMagicProjectile.position), get_tileset().find_tile_by_name("MAGICPROJECTILE"))
		if activeRoom == null || activeRoom.roomCleared:
			newMagicProjectile.move_projectile("clearedRoomProjectile")
	elif (get_cellv(world_to_map(player.position) + attack_direction*2) == TILETYPES.MAGICPROJECTILE && attackType == GlobalVariables.ATTACKTYPE.MAGIC):
		if get_cell_pawn(world_to_map(player.position) + attack_direction*2).projectileType == GlobalVariables.PROJECTILETYPE.ENEMY:
			var projectileToErase = get_cell_pawn(world_to_map(player.position) + attack_direction*2)
			projectilesInActiveRoom.erase(projectileToErase)
			set_cellv(world_to_map(projectileToErase.position),get_tileset().find_tile_by_name("EMPTY")) 
			projectileToErase.queue_free()
		else:
			var newMagicProjectile = MagicProjectile.instance()
			newMagicProjectile.connect("projectileMadeMove", self, "_on_projectiles_made_move")
			newMagicProjectile.position = player.position + map_to_world(attack_direction*2)
			newMagicProjectile.projectileType = GlobalVariables.PROJECTILETYPE.PLAYER
			newMagicProjectile.movementDirection = attack_direction
			newMagicProjectile.play_player_projectile_animation()
			add_child(newMagicProjectile)
			projectilesInActiveRoom.append(newMagicProjectile)
			magicProjectileMagicProjectileInteraction(newMagicProjectile, get_cell_pawn(world_to_map(player.position) + attack_direction*2))
	#block generating attack 
	if(attackType == GlobalVariables.ATTACKTYPE.BLOCK):
		if get_cellv(world_to_map(player.position) + attack_direction) == TILETYPES.EMPTY:
			#print("Hitting EMPTY")
			player.waitingForEventBeforeContinue = false
			var newPowerBlock = PowerBlock.instance()
			if activeRoom != null && activeRoom.roomType == GlobalVariables.ROOM_TYPE.PUZZLEROOM:
				newPowerBlock.get_node("PowerBlockModulate/Sprite").set_frame(23)
			else:
				newPowerBlock.get_node("PowerBlockModulate/Sprite").set_frame(21)
			newPowerBlock.position = player.position + map_to_world(attack_direction)
			add_child(newPowerBlock)
			if(activeRoom != null):
				activeRoom.powerBlocksInRoom.append(newPowerBlock)
			set_cellv(world_to_map(player.position) + attack_direction, get_tileset().find_tile_by_name("BLOCK"))
		elif get_cellv(world_to_map(player.position) + attack_direction) == get_tileset().find_tile_by_name("BLOCK"):
			var powerBlockToDelete = get_cell_pawn(world_to_map(player.position) + attack_direction)
			#print("Hitting Block")
			if activeRoom != null:
				#print("In Puzzle room")
				if activeRoom.roomType == activeRoom.ROOM_TYPE.PUZZLEROOM:
					player.waitingForEventBeforeContinue = false
					activeRoom.powerBlocksInRoom.erase(powerBlockToDelete)
					powerBlockToDelete.queue_free()
					set_cellv(world_to_map(player.position) + attack_direction, get_tileset().find_tile_by_name("EMPTY"))
					
				if activeRoom.roomType == activeRoom.ROOM_TYPE.ENEMYROOM:
					#print("Calling block explode")
					if powerBlockToDelete.explodeBlock():
						pass
					else:
						#print("block not exploding")
						player.waitingForEventBeforeContinue = false
						activeRoom.powerBlocksInRoom.erase(powerBlockToDelete)
						powerBlockToDelete.queue_free()
						set_cellv(world_to_map(player.position) + attack_direction, get_tileset().find_tile_by_name("EMPTY"))
			else:
				#print("Calling block explode")
				if powerBlockToDelete.explodeBlock():
					player.waitingForEventBeforeContinue = true
				else:
					#print("block not exploding")
					player.waitingForEventBeforeContinue = false
					if activeRoom!= null:
						activeRoom.powerBlocksInRoom.erase(powerBlockToDelete)
					powerBlockToDelete.queue_free()
					set_cellv(world_to_map(player.position) + attack_direction, get_tileset().find_tile_by_name("EMPTY"))
		else:
			#print("Waiting in else")
			player.waitingForEventBeforeContinue = false
	#hand attack
	if(attackType == GlobalVariables.ATTACKTYPE.HAND):
		if get_cellv(world_to_map(player.position) + attack_direction) == TILETYPES.BLOCK:
			var interactionBlock = get_cell_pawn(world_to_map(player.position) + attack_direction)
			if activeRoom == null || activeRoom != null && activeRoom.roomType == GlobalVariables.ROOM_TYPE.ENEMYROOM:
				interactionBlock.addCount()
			elif activeRoom.roomType == GlobalVariables.ROOM_TYPE.PUZZLEROOM:
				player.puzzleBlockInteraction = true
				activatedPuzzleBlock = interactionBlock

		elif get_cellv(world_to_map(player.position) + attack_direction) == TILETYPES.ENEMY:
			var enemyToSwap = get_cell_pawn(world_to_map(player.position) + attack_direction)
			enemyToSwap.position = player.position
			player.position = player.position + map_to_world(attack_direction)
			set_cellv(world_to_map(enemyToSwap.position), get_tileset().find_tile_by_name("ENEMY"))
			set_cellv(world_to_map(player.position), get_tileset().find_tile_by_name("PLAYER"))
			#player and enemy swap spaces
		elif get_cellv(world_to_map(player.position) + attack_direction) == TILETYPES.PUZZLEPIECE:
			var puzzlePieceToSwap = get_cell_pawn(world_to_map(player.position) + attack_direction)
			puzzlePieceToSwap.position = player.position
			player.position = player.position + map_to_world(attack_direction)
			set_cellv(world_to_map(puzzlePieceToSwap.position), get_tileset().find_tile_by_name("PUZZLEPIECE"))
			set_cellv(world_to_map(player.position), get_tileset().find_tile_by_name("PLAYER"))
			
			
func on_puzzle_Block_interaction(player, puzzleBlockDirection):
	activatedPuzzleBlock.interactPowerBlock(puzzleBlockDirection, activeRoom.roomType)
	
func on_Power_Block_explode(powerBlock):
	if get_cellv(world_to_map(powerBlock.position)+Vector2(1,0)) == get_tileset().find_tile_by_name("ENEMY"):
		get_cell_pawn(world_to_map(powerBlock.position)+Vector2(1,0)).inflictDamage(powerBlock.counters, GlobalVariables.ATTACKTYPE.BLOCK, world_to_map(powerBlock.position)+Vector2(1,0))
	if get_cellv(world_to_map(powerBlock.position)+Vector2(-1,0)) == get_tileset().find_tile_by_name("ENEMY"):
		get_cell_pawn(world_to_map(powerBlock.position)+Vector2(-1,0)).inflictDamage(powerBlock.counters, GlobalVariables.ATTACKTYPE.BLOCK, world_to_map(powerBlock.position)+Vector2(-1,0))
	if get_cellv(world_to_map(powerBlock.position)+Vector2(0,1)) == get_tileset().find_tile_by_name("ENEMY"):
		get_cell_pawn(world_to_map(powerBlock.position)+Vector2(0,1)).inflictDamage(powerBlock.counters, GlobalVariables.ATTACKTYPE.BLOCK, world_to_map(powerBlock.position)+Vector2(0,1))
	if get_cellv(world_to_map(powerBlock.position)+Vector2(0,-1)) == get_tileset().find_tile_by_name("ENEMY"):
		get_cell_pawn(world_to_map(powerBlock.position)+Vector2(0,-1)).inflictDamage(powerBlock.counters, GlobalVariables.ATTACKTYPE.BLOCK, world_to_map(powerBlock.position)+Vector2(0,-1))
	if get_cellv(world_to_map(powerBlock.position)+Vector2(1,1)) == get_tileset().find_tile_by_name("ENEMY"):
		get_cell_pawn(world_to_map(powerBlock.position)+Vector2(1,1)).inflictDamage(powerBlock.counters, GlobalVariables.ATTACKTYPE.BLOCK, world_to_map(powerBlock.position)+Vector2(1,1))
	if get_cellv(world_to_map(powerBlock.position)+Vector2(1,-1)) == get_tileset().find_tile_by_name("ENEMY"):
		get_cell_pawn(world_to_map(powerBlock.position)+Vector2(1,-1)).inflictDamage(powerBlock.counters, GlobalVariables.ATTACKTYPE.BLOCK, world_to_map(powerBlock.position)+Vector2(1,-1))
	if get_cellv(world_to_map(powerBlock.position)+Vector2(-1,1)) == get_tileset().find_tile_by_name("ENEMY"):
		get_cell_pawn(world_to_map(powerBlock.position)+Vector2(-1,1)).inflictDamage(powerBlock.counters, GlobalVariables.ATTACKTYPE.BLOCK, world_to_map(powerBlock.position)+Vector2(-1,1))
	if get_cellv(world_to_map(powerBlock.position)+Vector2(-1,-1)) == get_tileset().find_tile_by_name("ENEMY"):
		get_cell_pawn(world_to_map(powerBlock.position)+Vector2(-1,-1)).inflictDamage(powerBlock.counters, GlobalVariables.ATTACKTYPE.BLOCK, world_to_map(powerBlock.position)+Vector2(-1,-1))
	
	if activeRoom != null:
		activeRoom.powerBlocksInRoom.erase(powerBlock)
	powerBlock.queue_free()
	set_cellv(world_to_map(powerBlock.position), get_tileset().find_tile_by_name("EMPTY"))
	mainPlayer.waitingForEventBeforeContinue = false
	
func on_powerBlock_spawn_magic(powerBlock, signalSpawnMagic):
	var surroundedByObstaclesCount = 0
	var blockCanSpawnMagic = false
#	if onEndlessLoopStop >=20: 
#		onEndlessLoopStop = 0
#		return 
	mainPlayer.disablePlayerInput = true
	for direction in powerBlock.activeDirections:
		#print("Spawning magic")
		var newMagicProjectile = MagicProjectile.instance()
		newMagicProjectile.play_powerBlock_projectile_animation()
		newMagicProjectile.connect("projectileMadeMove", self, "_on_projectiles_made_move")
		match direction:
			GlobalVariables.DIRECTION.UP:
				newMagicProjectile.position = powerBlock.position+map_to_world(Vector2(0,-1))
				newMagicProjectile.movementDirection = Vector2(0,-1)
			GlobalVariables.DIRECTION.DOWN:
				newMagicProjectile.position = powerBlock.position+map_to_world(Vector2(0,1))
				newMagicProjectile.movementDirection = Vector2(0,1)
			GlobalVariables.DIRECTION.LEFT:
				newMagicProjectile.position = powerBlock.position+map_to_world(Vector2(-1,0))
				newMagicProjectile.movementDirection = Vector2(-1,0)
			GlobalVariables.DIRECTION.RIGHT:
				newMagicProjectile.position = powerBlock.position+map_to_world(Vector2(1,0))
				newMagicProjectile.movementDirection = Vector2(1,0)
		newMagicProjectile.projectileType = GlobalVariables.PROJECTILETYPE.POWERBLOCK
		if get_cellv(world_to_map(newMagicProjectile.position)) == get_tileset().find_tile_by_name("PUZZLEPIECE"):
			var activatedPuzzlePiece = get_cell_pawn(world_to_map(newMagicProjectile.position))
			if !activatePuzzlePieceNextTurn.has(activatedPuzzlePiece):
				activatePuzzlePieceNextTurn.append(activatedPuzzlePiece)
				if !projectilesInActiveRoom.empty():
					activatedPuzzlePiece.activationDelay = 0
				else:
					activatedPuzzlePiece.activationDelay = 0
			newMagicProjectile.queue_free()
		elif get_cellv(world_to_map(newMagicProjectile.position)) == get_tileset().find_tile_by_name("BLOCK"):
			var blockHit = get_cell_pawn(world_to_map(newMagicProjectile.position))
			if !spawnBlockProjectileNextTurn.has(blockHit):
				spawnBlockProjectileNextTurn.append(blockHit)
				if !projectilesInActiveRoom.empty():
					blockHit.shootDelay = 0
				else:
					blockHit.shootDelay = 0
			newMagicProjectile.queue_free()
		elif get_cellv(world_to_map(newMagicProjectile.position)+newMagicProjectile.movementDirection) == get_tileset().find_tile_by_name("PUZZLEPIECE"):
			var activatedPuzzlePiece = get_cell_pawn(world_to_map(newMagicProjectile.position)+newMagicProjectile.movementDirection)
			if !activatePuzzlePieceNextTurn.has(activatedPuzzlePiece):
				activatePuzzlePieceNextTurn.append(activatedPuzzlePiece)
				if !projectilesInActiveRoom.empty():
					activatedPuzzlePiece.activationDelay = 1
				else:
					activatedPuzzlePiece.activationDelay = 1
			newMagicProjectile.queue_free()
			
		elif get_cellv(world_to_map(newMagicProjectile.position)+newMagicProjectile.movementDirection) == get_tileset().find_tile_by_name("BLOCK"):
			var blockHit = get_cell_pawn(world_to_map(newMagicProjectile.position)+newMagicProjectile.movementDirection)
			if !spawnBlockProjectileNextTurn.has(blockHit):
				spawnBlockProjectileNextTurn.append(blockHit)
				if !projectilesInActiveRoom.empty():
					blockHit.shootDelay = 1
				else:
					blockHit.shootDelay = 1
			newMagicProjectile.queue_free()

		elif get_cellv(world_to_map(newMagicProjectile.position)) == get_tileset().find_tile_by_name("EMPTY") || get_cellv(world_to_map(newMagicProjectile.position)) == get_tileset().find_tile_by_name("PLAYER"):
			add_child(newMagicProjectile)
			projectilesInActiveRoom.append(newMagicProjectile)
			set_cellv(world_to_map(newMagicProjectile.position), get_tileset().find_tile_by_name("MAGICPROJECTILE"))
			newMagicProjectile.move_projectile("movePowerProjectile")
		else: 
			newMagicProjectile.queue_free()
	for projectile in projectilesInActiveRoom:
		if projectile.projectileType == GlobalVariables.PROJECTILETYPE.TICKERPROJECTILE && !projectile.tickAlreadyMoved:
			print("Moving ticking projectile")
			projectile.move_projectile("tickingProjectile")
			projectile.tickAlreadyMoved = true
	mainPlayer.disablePlayerInput = false

func cancel_magic_in_puzzle_room():
	if activeRoom != null && activeRoom.roomType == GlobalVariables.ROOM_TYPE.PUZZLEROOM && !projectilesInActiveRoom.empty():
		spawnBlockProjectileNextTurn.clear()
		cancelMagicPuzzelRoom = true
	
func _on_enemy_attacked(enemy, attackCell, attackType, attackDamage):
	if(get_cellv(attackCell) == TILETYPES.PLAYER):
		print("Woosh ENEMY Attack hit")
		var attackedPlayer = get_cell_pawn(attackCell)
		#if player died reset player ro starting room 
		if attackedPlayer.inflict_damage_playerDefeated(attackDamage, attackType):
			print("Batsuuum Player was defeated reset to start")
	elif (attackType == GlobalVariables.ATTACKTYPE.MAGIC):
		#spawn magic projectile
		if(get_cellv(world_to_map(map_to_world(attackCell)+GlobalVariables.tileOffset))==TILETYPES.EMPTY):
			var newMagicProjectile = MagicProjectile.instance()
			newMagicProjectile.connect("projectileMadeMove", self, "_on_projectiles_made_move")
			newMagicProjectile.position = map_to_world(attackCell)+GlobalVariables.tileOffset
			newMagicProjectile.movementDirection = attackCell-world_to_map(enemy.position)
			newMagicProjectile.projectileType = GlobalVariables.PROJECTILETYPE.ENEMY
			add_child(newMagicProjectile)
			projectilesInActiveRoom.append(newMagicProjectile)
			set_cellv(world_to_map(newMagicProjectile.position), get_tileset().find_tile_by_name("MAGICPROJECTILE"))
			newMagicProjectile.play_enemy_projectile_animation()

func _on_Player_Defeated(player):
	print("resetting player to start")
	set_cellv(world_to_map(player.position),get_tileset().find_tile_by_name("EMPTY")) 
	player.position = Vector2(80,80)
	player.inClearedRoom = true
	#todo: dont hardcode life
	player.lifePoints = 10
	mainPlayer.guiElements.set_health(10)
	MainCamera.set_camera_starting_room()
	emit_signal("enemyTurnDoneSignal")

	if(activeRoom != null && activeRoom.enemiesInRoom.size() != 0):
		#disable elements in room just left
		for element in activeRoom.enemiesInRoom:
			element.isDisabled = true
		for projectile in projectilesInActiveRoom:
			set_cellv(world_to_map(projectile.position),get_tileset().find_tile_by_name("EMPTY")) 
			projectile.queue_free()
		projectilesInActiveRoom.clear()
	activeRoom = null
					
					
func _on_enemy_defeated(enemy):
	enemy.queue_free()
	print("Batsuuum Enemy was defeated")
	#set room to cleared if all enemies were defeated
	if(activeRoom.enemiesInRoom.size() == 0):
		#delete all projectiles 
		for projectile in projectilesInActiveRoom:
			set_cellv(world_to_map(projectile.position),get_tileset().find_tile_by_name("EMPTY")) 
			projectile.queue_free()
		projectilesInActiveRoom.clear()
		emit_signal("enemyTurnDoneSignal")
		activeRoom.roomCleared=true
		mainPlayer.inClearedRoom = true
		if activeRoom.dropLoot():
			dropLootInActiveRoom()
	
func dropLootInActiveRoom():
	#create loot currently matching with closed doord 
	print(barrierKeysNoSolution)
	if !barrierKeysNoSolution.empty():
		#create key and spawn it on floor spawn one left of player if player is in the middle of the room
		var itemToGenerate = barrierKeysNoSolution[randi()%barrierKeysNoSolution.size()]
		barrierKeysSolutionSpawned.append(itemToGenerate)
		barrierKeysNoSolution.erase(itemToGenerate)
		var newItemPosition = activeRoom.doorRoomLeftMostCorner + map_to_world(activeRoom.roomSize/2)
		var itemPosMover = Vector2(0,1)
		while(get_cellv(world_to_map(newItemPosition)) == TILETYPES.PLAYER || get_cellv(world_to_map(newItemPosition)) == TILETYPES.PUZZLEPIECE):
			newItemPosition += map_to_world(itemPosMover)
			if itemPosMover.x >= itemPosMover.y:
				itemPosMover += Vector2(0,1)
			else:
				itemPosMover += Vector2(1,0)
		itemToGenerate.position = newItemPosition
		if get_cellv(world_to_map(itemToGenerate.position))==TILETYPES.BLOCK:
			get_cell_pawn(world_to_map(itemToGenerate.position)).queue_free()
		if  get_cellv(world_to_map(newItemPosition)) == TILETYPES.ENEMY:
			get_cell_pawn(world_to_map(itemToGenerate.position)).queue_free()
		add_child(itemToGenerate)
		set_cellv(world_to_map(itemToGenerate.position), get_tileset().find_tile_by_name("ITEM"))
			#set type of item 
	else:
		var newItem = Item.instance()
		var newItemPosition = activeRoom.doorRoomLeftMostCorner + map_to_world(activeRoom.roomSize/2)
		var itemPosMover = Vector2(0,1)
		while(get_cellv(world_to_map(newItemPosition)) == TILETYPES.PLAYER || get_cellv(world_to_map(newItemPosition)) == TILETYPES.PUZZLEPIECE):
			newItemPosition += map_to_world(itemPosMover)
			if itemPosMover.x >= itemPosMover.y:
				itemPosMover += Vector2(0,1)
			else:
				itemPosMover += Vector2(1,0)
		newItem.position = newItemPosition
		if get_cellv(world_to_map(newItem.position))==TILETYPES.BLOCK:
			get_cell_pawn(world_to_map(newItem.position)).queue_free()
		if  get_cellv(world_to_map(newItemPosition)) == TILETYPES.ENEMY:
			get_cell_pawn(world_to_map(newItem.position)).queue_free()
		newItem.keyValue = str(0)
		newItem.setTexture(GlobalVariables.ITEMTYPE.POTION)
		add_child(newItem)
		set_cellv(world_to_map(newItem.position), get_tileset().find_tile_by_name("ITEM"))
		

func generate_keyValue_item(keyValue, modulation, type):
	var newItem = Item.instance()
	newItem.keyValue = keyValue
	newItem.modulation = modulation
	newItem.get_node("Sprite").set_modulate(newItem.modulation)
	newItem.itemType = type
	newItem.setTexture(type)
	barrierKeysNoSolution.append(newItem)
	
		
func create_starting_room(startingRoom=false):
	create_walls(null, startingRoom, true)
	update_bitmask_region()

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
		leftmostCorner = GlobalVariables.tileOffset
	else:
		var minRoomSize = roomSizeHorizontal

		match door.doorDirection:
			"LEFT":
				#see if there are any cross section and diasble this option to keep tiles from intersecting
				leftmostCorner=world_to_map(door.position-map_to_world(Vector2(minRoomSize, minRoomSize/2-evenOddModifier)))
				#print("LEFT LEftMost Corner " + str(leftmostCorner) + " door position " + str(world_to_map(door.position)))
				#check for wall up for room to be created 
				#print("LEFT Up Modifier : " + str(leftmostCorner-Vector2(0,1)) + " " + str(get_cellv(leftmostCorner-Vector2(0,1))))
				if(get_cellv(leftmostCorner-Vector2(0,1)) == TILETYPES.WALL):
					disableUp = true
				#check for wall down for room to be created 
				#print("LEFT Down modifier : " + str(leftmostCorner+Vector2(0,minRoomSize)) + " " + str(get_cellv(leftmostCorner+Vector2(0,minRoomSize))))
				if(get_cellv(leftmostCorner+Vector2(0,minRoomSize)) == TILETYPES.WALL):
					disableDown = true
				#check for wall long for room to be created 
				if(get_cellv(leftmostCorner-Vector2(1,0)) == TILETYPES.WALL):
					disableLong = true
				#print("LEFT LONG modifier : " + str(leftmostCorner-Vector2(1,0))+ " " + str(get_cellv(leftmostCorner-Vector2(1,0))))
				#randomize and create different room sizes and layout types
				if(get_cellv(leftmostCorner+Vector2(minRoomSize, minRoomSize)) == TILETYPES.WALL || get_cellv(leftmostCorner+Vector2(minRoomSize-1, minRoomSize)) == TILETYPES.WALL || get_cellv(leftmostCorner+Vector2(minRoomSize, minRoomSize-1)) == TILETYPES.WALL || get_cellv(leftmostCorner+Vector2(minRoomSize-1, minRoomSize-1)) == TILETYPES.WALL):
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
				if(get_cellv(leftmostCorner-Vector2(0,1)) == TILETYPES.WALL):
					disableUp = true
				#print("RIGHT Up Modifier : " + str(leftmostCorner-Vector2(0,1)) + " " + str(get_cellv(leftmostCorner-Vector2(0,1))))
				#check for wall down for room to be created 
				if(get_cellv(leftmostCorner+Vector2(0,minRoomSize)) == TILETYPES.WALL):
					disableDown = true
				#print("RIGHT Down modifier : " + str(leftmostCorner+Vector2(0,minRoomSize)) + " " + str(get_cellv(leftmostCorner+Vector2(0,minRoomSize))))
				#check for wall long for room to be created 
				if(get_cellv(leftmostCorner+Vector2(minRoomSize,0)) == TILETYPES.WALL):
					disableLong = true
				#print("RIGHT LONG modifier : " + str(leftmostCorner+Vector2(minRoomSize,0))+ " " + str(get_cellv(leftmostCorner+Vector2(minRoomSize,0))))
				if(get_cellv(leftmostCorner+Vector2(minRoomSize, minRoomSize)) == TILETYPES.WALL || get_cellv(leftmostCorner+Vector2(minRoomSize-1, minRoomSize)) == TILETYPES.WALL || get_cellv(leftmostCorner+Vector2(minRoomSize, minRoomSize-1)) == TILETYPES.WALL || get_cellv(leftmostCorner+Vector2(minRoomSize-1, minRoomSize-1)) == TILETYPES.WALL):
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
				if(get_cellv(leftmostCorner-Vector2(1,0)) == TILETYPES.WALL):
					disableLeft = true
				#print("UP Left Modifier : " + str(leftmostCorner-Vector2(1,0)) + " " + str(get_cellv(leftmostCorner-Vector2(1,0))))
				#check left bottom corner of minimum size plus 1 y tile 
				if(get_cellv(leftmostCorner+Vector2(minRoomSize,0)) == TILETYPES.WALL):
					disableRight = true
				#print("UP Right modifier : " + str(leftmostCorner+Vector2(minRoomSize,0)) + " " + str(get_cellv(leftmostCorner+Vector2(minRoomSize,0))))
				#randomize and create different room sizes and layout types 
				if(get_cellv(leftmostCorner-Vector2(0,1)) == TILETYPES.WALL):
					disableLong = true
				#print("UP LONG modifier : " + str(leftmostCorner-Vector2(0,1))+ " " + str(get_cellv(leftmostCorner-Vector2(0,1))))
				if(get_cellv(leftmostCorner+Vector2(minRoomSize, minRoomSize)) == TILETYPES.WALL || get_cellv(leftmostCorner+Vector2(minRoomSize-1, minRoomSize)) == TILETYPES.WALL || get_cellv(leftmostCorner+Vector2(minRoomSize, minRoomSize-1)) == TILETYPES.WALL || get_cellv(leftmostCorner+Vector2(minRoomSize-1, minRoomSize-1)) == TILETYPES.WALL):
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
				if(get_cellv(leftmostCorner-Vector2(1,0)) == TILETYPES.WALL):
					disableLeft = true
				#print("DOWN Left Modifier : " + str(leftmostCorner-Vector2(1,0)) + " " + str(get_cellv(leftmostCorner-Vector2(1,0))))
				#check left bottom corner of minimum size plus 1 y tile 
				if(get_cellv(leftmostCorner+Vector2(minRoomSize,0)) == TILETYPES.WALL):
					disableRight = true
				#print("DOWN Right modifier : " + str(leftmostCorner+Vector2(minRoomSize,0)) + " " + str(get_cellv(leftmostCorner+Vector2(minRoomSize,0))))
				#randomize and create different room sizes and layout types 
				if(get_cellv(leftmostCorner+Vector2(minRoomSize, minRoomSize)) == TILETYPES.WALL || get_cellv(leftmostCorner+Vector2(minRoomSize-1, minRoomSize)) == TILETYPES.WALL || get_cellv(leftmostCorner+Vector2(minRoomSize, minRoomSize-1)) == TILETYPES.WALL || get_cellv(leftmostCorner+Vector2(minRoomSize-1, minRoomSize-1)) == TILETYPES.WALL):
					disableLong = true
				#print("DOWN LONG modifier : "  + str(leftmostCorner+Vector2(0,minRoomSize))+ " " + str(get_cellv(leftmostCorner+Vector2(0,minRoomSize))))
				if(get_cellv(leftmostCorner+Vector2(minRoomSize, minRoomSize)) == TILETYPES.WALL):
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
			var spawn_pos = leftmostCorner + Vector2(horizontalAddcount*GlobalVariables.tileSize,verticalAddcount*GlobalVariables.tileSize)
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
				set_cellv(world_to_map(door.position) - Vector2(1,0), get_tileset().find_tile_by_name(match_Enum(TILETYPES.EMPTY)))
				object_pawn = get_cell_pawn(world_to_map(door.position) - Vector2(1,0))
			"RIGHT":
				set_cellv(world_to_map(door.position) + Vector2(1,0), get_tileset().find_tile_by_name(match_Enum(TILETYPES.EMPTY)))
				object_pawn = get_cell_pawn(world_to_map(door.position) + Vector2(1,0))
			"UP":
				set_cellv(world_to_map(door.position) - Vector2(0,1), get_tileset().find_tile_by_name(match_Enum(TILETYPES.EMPTY)))
				object_pawn = get_cell_pawn(world_to_map(door.position) - Vector2(0,1))
			"DOWN":
				set_cellv(world_to_map(door.position) + Vector2(0,1), get_tileset().find_tile_by_name(match_Enum(TILETYPES.EMPTY)))
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
				if (get_cellv(world_to_map(newDoor.position)-Vector2(1,0)) == TILETYPES.WALL):
					canCreateDoor = false
			"RIGHT":
				if (get_cellv(world_to_map(newDoor.position)+Vector2(1,0)) == TILETYPES.WALL):
					canCreateDoor = false
			"UP":
				if (get_cellv(world_to_map(newDoor.position)-Vector2(0,1)) == TILETYPES.WALL):
					canCreateDoor = false
			"DOWN":
				if (get_cellv(world_to_map(newDoor.position)+Vector2(0,1)) == TILETYPES.WALL):
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
		update_bitmask_region()
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
