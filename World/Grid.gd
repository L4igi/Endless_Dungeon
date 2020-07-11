#main control over the game 
#includes room creation logic 
#handles move requests and sets tiles to types 
#acts as centerpiece to connect the whole game 
#communicates with turn controller to handle interaction if safe

extends TileMap

enum TILETYPES { EMPTY, PLAYER, WALL, ENEMY, PUZZLEPIECE, ITEM, DOOR, UNLOCKEDDOOR, MAGICPROJECTILE, BLOCK, FLOOR, UPGRADECONTAINER, COUNTINGBLOCK}

var Enemy = preload("res://GameObjects/Enemy/Enemy.tscn")

var Wall = preload("res://GameObjects/Wall/Wall.tscn")

var Door = preload("res://GameObjects/Door/Door.tscn")

var Item = preload("res://GameObjects/Item/Item.tscn")

var MagicProjectile = preload("res://GameObjects/Projectile/MagicProjectile.tscn")

var PowerBlock = preload("res://GameObjects/PowerBlock/PowerBlock.tscn")

var Player = preload("res://GameObjects/Player/Player.tscn")

var PuzzlePiece = preload("res://GameObjects/Puzzle/PuzzlePiece.tscn")

var UpgradeContainer = preload("res://GameObjects/UpgradeContainer/UpgradeContainer.tscn")

var CountingBlock = preload("res://GameObjects/CountingBlock/CountingBlock.tscn")

var unlockDoorAudio = preload("res://World/WorldSprites/sfx_movement_dooropen2.wav")

var puzzleRoomClearedAudio = preload("res://World/WorldSprites/puzzle_room_clear.wav")

var roomDimensions = GlobalVariables.roomDimensions

var evenOddModifier = 0 

var currentNumberRoomsgenerated = 0

var numberRoomsBeenTo = 0

var numberRoomsCleared = 0

var startingRoomDoorsCount = 0

var activeRoom = null

var movedThroughDoor = false

var projectilesInActiveRoom = []

var barrierKeysNoSolution = []

var barrierKeysSolutionSpawned = []

var mainPlayer 

signal enemyTurnDoneSignal

signal puzzleBarrierDisableSignal (item, mainPlayer)

signal moveCameraSignal (activeRoom)

var spawnBlockProjectileNextTurn = []

var activatePuzzlePieceNextTurn = []

var activateCountingBlockNextTurn = []

var activatedPuzzleBlock 

var activatedPuzzlePieces = []

var playerEnemyProjectileArray = []

var puzzleProjectilesToMove = []

var tickingProjectile = null

var cancelMagicPuzzleRoom = false

var allEnemiesAlreadySaved = false

var bonusLootArray = []

var exitSpawned = false

var worldAudioStreamPlayer = AudioStreamPlayer2D.new()

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
		9:
			return "FLOOR"
		10:
			return "UPGRADECONTAINER"
		11:
			return "COUNTINGBLOCK"
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
		"FLOOR":
			TILETYPES.FLOOR = setTo
		"UPGRADECONTAINER":
			TILETYPES.UPGRADECONTAINER = setTo
		"COUNTINGBLOCK":
			TILETYPES.COUNTINGBLOCK = setTo
		"EMPTY":
			TILETYPES.EMPTY= -1
		_:
			pass
			
func _ready():
	add_child(worldAudioStreamPlayer)
	GlobalVariables.turnController.set_Grid_to_use(self)
	GlobalVariables.turnController.currentTurnWaiting = GlobalVariables.CURRENTPHASE.PLAYER
	GlobalVariables.turnController.inRoomType = GlobalVariables.ROOM_TYPE.ENEMYROOM
	if GlobalVariables.firstCall:
		GlobalVariables.firstCall=false
		var newPlayer = Player.instance()
		newPlayer.set_z_index(2)
		newPlayer.position = Vector2(112,112)
		newPlayer.set_name("Player")
		add_child(newPlayer)
		newPlayer.resetStats()
		get_node("Player").connect("playerAttacked", self, "_on_Player_Attacked")
		get_node("Player").connect("puzzleBlockInteractionSignal", self, "on_puzzle_Block_interaction")
		mainPlayer = get_node("Player")
		save_game()
	else:
		load_game()
#match tiles from tilemap to enum 
	for child in get_children():
		if !child is Camera2D && !child is AudioStreamPlayer2D:
			set_cellv(world_to_map(child.position), get_tileset().find_tile_by_name(match_Enum(child.type)))
	for element in TILETYPES:
		set_enum_index(element, get_tileset().find_tile_by_name(element))
	if(roomDimensions%2 == 0):
		evenOddModifier = 1
	create_starting_room(true)
	
	
func get_cell_pawn(coordinates):
	for node in get_children():
		if node is TextureRect:
			return
		else:
			if world_to_map(node.position) == coordinates:
				return(node)
				
#manages movement of objects and side effects of those 
func request_move(pawn, direction):
	var cell_start = world_to_map(pawn.position)
	
	var cell_target = cell_start + direction
		
	var cell_target_type = get_cellv(cell_target)

	if(match_Enum(pawn.type) == "PLAYER"):
		match cell_target_type:
			TILETYPES.EMPTY:
				return update_pawn_position(pawn, cell_start, cell_target)
			TILETYPES.FLOOR:
				return update_pawn_position(pawn, cell_start, cell_target)
			TILETYPES.ENEMY:
				pass
			TILETYPES.WALL:
				pass
			TILETYPES.ITEM:
				var object_pawn = get_cell_pawn(cell_target)
				if(object_pawn.itemType == GlobalVariables.ITEMTYPE.POTION):
					pawn.add_nonkey_items(object_pawn.itemType)
				elif object_pawn.itemType == GlobalVariables.ITEMTYPE.PUZZLESWITCH:
					emit_signal("puzzleBarrierDisableSignal", object_pawn, mainPlayer)
				elif object_pawn.itemType == GlobalVariables.ITEMTYPE.EXIT:
					GlobalVariables.maxDifficulty += 1
					save_game()
					GlobalVariables.currentFloor+=1
					GlobalVariables.maxNumberRooms = int(GlobalVariables.maxNumberRooms*1.5)
					if GlobalVariables.maxNumberRooms == 1:
						GlobalVariables.maxNumberRooms = 2
					if GlobalVariables.currentFloor%5 == 0:
						GlobalVariables.roomDimensions += 1
					get_tree().reload_current_scene()
				elif object_pawn.itemType == GlobalVariables.ITEMTYPE.COIN:
					pawn.add_nonkey_items(object_pawn.itemType, object_pawn.coinValue)
				elif object_pawn.itemType == GlobalVariables.ITEMTYPE.FILLUPHALFHEART:
					pawn.add_nonkey_items(object_pawn.itemType)
				elif object_pawn.itemType == GlobalVariables.ITEMTYPE.FILLUPHEART:
					pawn.add_nonkey_items(object_pawn.itemType)
				else:
					pawn.itemsInPosession.append(object_pawn)
					pawn.add_key_item_to_inventory(object_pawn)
				set_cellv(object_pawn.position, get_tileset().find_tile_by_name("FLOOR"))
				object_pawn.on_item_pickUp(activeRoom.doorRoomLeftMostCorner+Vector2(activeRoom.roomSize.x, 0))
				return update_pawn_position(pawn, cell_start, cell_target)
			TILETYPES.DOOR:
				var object_pawn = get_cell_pawn(cell_target)
				mainPlayer.playerWalkedThroughDoorPosition = object_pawn.position
				var requestDoorUnlockResult = object_pawn.request_door_unlock(pawn.itemsInPosession)
				if(requestDoorUnlockResult):
					if requestDoorUnlockResult is preload("res://GameObjects/Item/Item.gd"):
						object_pawn.on_use_key_item(requestDoorUnlockResult)
						mainPlayer.remove_key_item_from_inventory(requestDoorUnlockResult)
					#see if any other rooms are compleatly blocked by walls 
					object_pawn.unlock_Door()
					numberRoomsBeenTo += 1
					GlobalVariables.turnController.playerMovedDoor = true
					return update_pawn_position(pawn, cell_start, cell_target)
			TILETYPES.UNLOCKEDDOOR:
				mainPlayer.playerWalkedThroughDoorPosition = get_cell_pawn(cell_target).position
				GlobalVariables.turnController.playerMovedDoor = true
				return update_pawn_position(pawn, cell_start, cell_target)
			TILETYPES.MAGICPROJECTILE:
				var object_pawn = get_cell_pawn(cell_target)
				if object_pawn.projectileType == GlobalVariables.PROJECTILETYPE.PLAYER:
					projectilesInActiveRoom.erase(object_pawn)
					object_pawn.queue_free()
					return update_pawn_position(pawn, cell_start, cell_target)
				elif object_pawn.projectileType == GlobalVariables.PROJECTILETYPE.ENEMY:
					projectilesInActiveRoom.erase(object_pawn)
					set_cellv(world_to_map(object_pawn.position), get_tileset().find_tile_by_name("PLAYER"))
					object_pawn.play_projectile_animation(true, "attack")
					GlobalVariables.turnController.playerTakeDamage.append(mainPlayer)
					pawn.queueInflictDamage=true
					pawn.queueInflictEnemyType=GlobalVariables.ENEMYTYPE.MAGEENEMY
					pawn.enemyQueueAttackDamage = object_pawn.attackDamage
					pawn.enemyQueueAttackType = GlobalVariables.ATTACKTYPE.MAGIC
					return update_pawn_position(pawn, cell_start, cell_target)
			TILETYPES.BLOCK:
				return 
			TILETYPES.UPGRADECONTAINER:
				return 
			TILETYPES.COUNTINGBLOCK:
				return
					
	elif match_Enum(pawn.type) == "ENEMY":
		if get_cellv(cell_target+direction) == TILETYPES.DOOR || get_cellv(cell_target+direction) == TILETYPES.UNLOCKEDDOOR:
			return pawn.position 
		match cell_target_type:
			TILETYPES.EMPTY:
				return update_pawn_position(pawn, cell_start, cell_target)
			TILETYPES.FLOOR:
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
					set_cellv(world_to_map(tempMagicProjectile.position),get_tileset().find_tile_by_name("FLOOR"))
					tempMagicProjectile.play_projectile_animation(true, "attack", false, true)
					GlobalVariables.turnController.enemyTakeDamage.append(pawn)
					if GlobalVariables.turnController.currentTurnWaiting == GlobalVariables.CURRENTPHASE.PLAYER:
						pawn.inflictDamage(tempMagicProjectile.attackDamage, GlobalVariables.ATTACKTYPE.MAGIC, map_to_world(cell_target), mainPlayer, GlobalVariables.CURRENTPHASE.ENEMY)
					else:
						pawn.inflictDamage(tempMagicProjectile.attackDamage, GlobalVariables.ATTACKTYPE.MAGIC, map_to_world(cell_target), mainPlayer, GlobalVariables.turnController.currentTurnWaiting)
					return update_pawn_position(pawn, cell_start, cell_target)
				elif tempMagicProjectile.projectileType == GlobalVariables.PROJECTILETYPE.ENEMY && pawn.helpEnemy:
					projectilesInActiveRoom.erase(tempMagicProjectile)
					set_cellv(world_to_map(tempMagicProjectile.position), get_tileset().find_tile_by_name("ENEMY"))
					tempMagicProjectile.play_projectile_animation(true, "attack")
					GlobalVariables.turnController.enemyTakeDamage.append(pawn)
					pawn.inflictDamage(tempMagicProjectile.attackDamage, GlobalVariables.ATTACKTYPE.MAGIC, cell_target, mainPlayer, GlobalVariables.turnController.currentTurnWaiting)
					return update_pawn_position(pawn, cell_start, cell_target)
				else:
					tempMagicProjectile.play_projectile_animation(true,"delete")
					return update_pawn_position(pawn, cell_start, cell_target)
			TILETYPES.BLOCK:
				return pawn.position
			_:
				return pawn.position

	elif match_Enum(pawn.type) == "MAGICPROJECTILE":
		match cell_target_type:
			TILETYPES.EMPTY:
				if pawn.projectileType == GlobalVariables.PROJECTILETYPE.POWERBLOCK:
					return map_to_world(cell_target) + cell_size / GlobalVariables.isometricFactor
				return update_pawn_position(pawn, cell_start, cell_target)
			TILETYPES.FLOOR:
				if pawn.projectileType == GlobalVariables.PROJECTILETYPE.POWERBLOCK:
					return map_to_world(cell_target) + cell_size / GlobalVariables.isometricFactor
				return update_pawn_position(pawn, cell_start, cell_target)
			TILETYPES.ENEMY:
				var tempEnemy = get_cell_pawn(cell_target)
				if pawn.projectileType == GlobalVariables.PROJECTILETYPE.PLAYER:
					tempEnemy.hitByProjectile = pawn
					projectilesInActiveRoom.erase(pawn)
					if GlobalVariables.turnController.currentTurnWaiting == GlobalVariables.CURRENTPHASE.PLAYERPROJECTILE:
						pawn.deleteProjectilePlayAnimation = "attack"
					else:
						pawn.play_projectile_animation(false,"attack")
					set_cellv(world_to_map(pawn.position),get_tileset().find_tile_by_name("FLOOR")) 
					GlobalVariables.turnController.enemyTakeDamage.append(tempEnemy)
					tempEnemy.inflictDamage(pawn.attackDamage, GlobalVariables.ATTACKTYPE.MAGIC, cell_target, mainPlayer, GlobalVariables.CURRENTPHASE.ENEMYPROJECTILE)
					return
				elif pawn.projectileType == GlobalVariables.PROJECTILETYPE.ENEMY && tempEnemy.helpEnemy:
					GlobalVariables.turnController.enemyTakeDamage.append(tempEnemy)
					tempEnemy.inflictDamage(pawn.attackDamage, GlobalVariables.ATTACKTYPE.MAGIC, cell_target, mainPlayer, GlobalVariables.CURRENTPHASE.ENEMYPROJECTILE)
					projectilesInActiveRoom.erase(pawn)
					if GlobalVariables.turnController.currentTurnWaiting == GlobalVariables.CURRENTPHASE.ENEMYPROJECTILE:
						projectilesInActiveRoom.erase(pawn)
						pawn.deleteProjectilePlayAnimation = "delete"
						pawn.hitObstacleOnDelete = true
						set_cellv(world_to_map(pawn.position),get_tileset().find_tile_by_name("FLOOR")) 
					else:
						pawn.play_projectile_animation(false,"attack")
					set_cellv(world_to_map(pawn.position),get_tileset().find_tile_by_name("FLOOR")) 
				else:
					return pawn.position
			TILETYPES.PLAYER:
				var tempPlayer = get_cell_pawn(cell_target)
				if pawn.projectileType == GlobalVariables.PROJECTILETYPE.ENEMY:
					tempPlayer.inflict_damage_playerDefeated(pawn.attackDamage, GlobalVariables.ATTACKTYPE.MAGIC, GlobalVariables.ENEMYTYPE.MAGEENEMY)
					projectilesInActiveRoom.erase(pawn)
					if GlobalVariables.turnController.currentTurnWaiting == GlobalVariables.CURRENTPHASE.ENEMYPROJECTILE:
						projectilesInActiveRoom.erase(pawn)
						pawn.deleteProjectilePlayAnimation = "delete"
						pawn.hitObstacleOnDelete = true
						set_cellv(world_to_map(pawn.position),get_tileset().find_tile_by_name("FLOOR")) 
					else:
						pawn.play_projectile_animation(false,"attack")
					set_cellv(world_to_map(pawn.position),get_tileset().find_tile_by_name("FLOOR")) 
				elif activeRoom != null && activeRoom.roomType == GlobalVariables.ROOM_TYPE.PUZZLEROOM:
					set_cellv(cell_target, get_tileset().find_tile_by_name("MAGICPROJECTILE"))
					return map_to_world(cell_target)
				elif activeRoom == null:
					projectilesInActiveRoom.erase(pawn)
					pawn.deleteProjectilePlayAnimation = "delete"
					pawn.hitObstacleOnDelete = true
					set_cellv(world_to_map(pawn.position),get_tileset().find_tile_by_name("FLOOR")) 
				else:
					return pawn.position
			TILETYPES.WALL:
				projectilesInActiveRoom.erase(pawn)
				pawn.deleteProjectilePlayAnimation = "delete"
				pawn.hitObstacleOnDelete = true
				set_cellv(world_to_map(pawn.position),get_tileset().find_tile_by_name("FLOOR")) 
#				if activeRoom!= null && activeRoom.roomType == GlobalVariables.ROOM_TYPE.PUZZLEROOM && pawn.projectileType == GlobalVariables.PROJECTILETYPE.POWERBLOCK:
#					pawn.deleteProjectilePlayAnimation = "delete"
#				elif GlobalVariables.turnController.currentTurnWaiting == GlobalVariables.CURRENTPHASE.PLAYERPROJECTILE:
#					pawn.deleteProjectilePlayAnimation = "delete"
#				elif GlobalVariables.turnController.currentTurnWaiting == GlobalVariables.CURRENTPHASE.ENEMYPROJECTILE:
#					pawn.deleteProjectilePlayAnimation = "delete"
#				else:
				pawn.deleteProjectilePlayAnimation = "delete"
			TILETYPES.DOOR:
				projectilesInActiveRoom.erase(pawn)
				pawn.deleteProjectilePlayAnimation = "delete"
				pawn.hitObstacleOnDelete = true
				set_cellv(world_to_map(pawn.position),get_tileset().find_tile_by_name("FLOOR")) 
#				if activeRoom!= null && activeRoom.roomType == GlobalVariables.ROOM_TYPE.PUZZLEROOM && pawn.projectileType == GlobalVariables.PROJECTILETYPE.POWERBLOCK:
#					pawn.deleteProjectilePlayAnimation = "delete"
#				elif GlobalVariables.turnController.currentTurnWaiting == GlobalVariables.CURRENTPHASE.ENEMYPROJECTILE:
#					pawn.deleteProjectilePlayAnimation = "delete"
#				elif GlobalVariables.turnController.currentTurnWaiting == GlobalVariables.CURRENTPHASE.PLAYERPROJECTILE:
#					pawn.deleteProjectilePlayAnimation = "delete"
#				else:
				pawn.deleteProjectilePlayAnimation = "delete"
			TILETYPES.UNLOCKEDDOOR:
				projectilesInActiveRoom.erase(pawn)
				pawn.deleteProjectilePlayAnimation = "delete"
				pawn.hitObstacleOnDelete = true
				set_cellv(world_to_map(pawn.position),get_tileset().find_tile_by_name("FLOOR")) 
#				if activeRoom!= null && activeRoom.roomType == GlobalVariables.ROOM_TYPE.PUZZLEROOM && pawn.projectileType == GlobalVariables.PROJECTILETYPE.POWERBLOCK:
#					pawn.deleteProjectilePlayAnimation = "delete"
#				elif GlobalVariables.turnController.currentTurnWaiting == GlobalVariables.CURRENTPHASE.ENEMYPROJECTILE:
#					pawn.deleteProjectilePlayAnimation = "delete"
#				elif GlobalVariables.turnController.currentTurnWaiting == GlobalVariables.CURRENTPHASE.PLAYERPROJECTILE:
#					pawn.deleteProjectilePlayAnimation = "delete"
#				else:
				pawn.deleteProjectilePlayAnimation = "delete"
			TILETYPES.MAGICPROJECTILE:
				var targetProjectile = get_cell_pawn(cell_target)
				if pawn == null && targetProjectile == null:
					pass
				if pawn != null && targetProjectile!= null:
						if magic_projectile_magic_projectile_interaction(pawn, targetProjectile):
							if  pawn.requestedMoveCount < 2 && GlobalVariables.turnController.currentTurnWaiting == GlobalVariables.CURRENTPHASE.PLAYERPROJECTILE || pawn.requestedMoveCount < 2 && GlobalVariables.turnController.currentTurnWaiting == GlobalVariables.CURRENTPHASE.ENEMYPROJECTILE:
								pawn.requestedMoveCount+=1
								if GlobalVariables.turnController.currentTurnWaiting == GlobalVariables.CURRENTPHASE.PLAYERPROJECTILE:
									GlobalVariables.turnController.playerProjectilesToMove.append(pawn)
								if GlobalVariables.turnController.currentTurnWaiting == GlobalVariables.CURRENTPHASE.ENEMYPROJECTILE:
									GlobalVariables.turnController.enemyProjectilesToMove.append(pawn)
								return 
							else:
								projectilesInActiveRoom.erase(pawn)
								pawn.deleteProjectilePlayAnimation = "delete"
								pawn.hitObstacleOnDelete = true
								set_cellv(world_to_map(pawn.position),get_tileset().find_tile_by_name("FLOOR")) 
				return pawn.position
			TILETYPES.BLOCK:
				projectilesInActiveRoom.erase(pawn)
				pawn.deleteProjectilePlayAnimation = "delete"
				pawn.hitObstacleOnDelete = true
				set_cellv(world_to_map(pawn.position),get_tileset().find_tile_by_name("FLOOR")) 
				if activeRoom!= null && activeRoom.roomType == GlobalVariables.ROOM_TYPE.PUZZLEROOM && pawn.projectileType == GlobalVariables.PROJECTILETYPE.POWERBLOCK:
					if !spawnBlockProjectileNextTurn.has(get_cell_pawn(cell_target)):
						get_cell_pawn(cell_target).shootDelay = 1
						spawnBlockProjectileNextTurn.append(get_cell_pawn(cell_target))
					pawn.deleteProjectilePlayAnimation = "delete"
				elif GlobalVariables.turnController.currentTurnWaiting == GlobalVariables.CURRENTPHASE.ENEMYPROJECTILE:
					pawn.deleteProjectilePlayAnimation = "delete"
				elif GlobalVariables.turnController.currentTurnWaiting == GlobalVariables.CURRENTPHASE.PLAYERPROJECTILE:
					pawn.deleteProjectilePlayAnimation = "delete"
				else:
					pawn.play_projectile_animation(false,"delete")
			TILETYPES.PUZZLEPIECE:
				projectilesInActiveRoom.erase(pawn)
				pawn.deleteProjectilePlayAnimation = "delete"
				pawn.hitObstacleOnDelete = true
				set_cellv(world_to_map(pawn.position),get_tileset().find_tile_by_name("FLOOR")) 
				if pawn.projectileType == GlobalVariables.PROJECTILETYPE.POWERBLOCK:
					var activatedPuzzlePiece = get_cell_pawn(cell_target)
					if !activatedPuzzlePiece.isActivated:
						if !activatePuzzlePieceNextTurn.has(get_cell_pawn(cell_target)):
							get_cell_pawn(cell_target).activationDelay = 1
							activatePuzzlePieceNextTurn.append(get_cell_pawn(cell_target))
					pawn.deleteProjectilePlayAnimation = "delete"
				elif GlobalVariables.turnController.currentTurnWaiting == GlobalVariables.CURRENTPHASE.ENEMYPROJECTILE:
					pawn.deleteProjectilePlayAnimation = "delete"
				elif GlobalVariables.turnController.currentTurnWaiting == GlobalVariables.CURRENTPHASE.PLAYERPROJECTILE:
					pawn.deleteProjectilePlayAnimation = "delete"
				else:
					pawn.play_projectile_animation(false,"delete")
			TILETYPES.COUNTINGBLOCK:
				projectilesInActiveRoom.erase(pawn)
				pawn.deleteProjectilePlayAnimation = "delete"
				pawn.hitObstacleOnDelete = true
				set_cellv(world_to_map(pawn.position),get_tileset().find_tile_by_name("FLOOR")) 
				if pawn.projectileType == GlobalVariables.PROJECTILETYPE.POWERBLOCK:
					var activatedCountingBlock = get_cell_pawn(cell_target)
					if !activateCountingBlockNextTurn.has(get_cell_pawn(cell_target)):
						get_cell_pawn(cell_target).activationDelay = 1
						activateCountingBlockNextTurn.append(get_cell_pawn(cell_target))
					pawn.deleteProjectilePlayAnimation = "delete"
				elif GlobalVariables.turnController.currentTurnWaiting == GlobalVariables.CURRENTPHASE.ENEMYPROJECTILE:
					pawn.deleteProjectilePlayAnimation = "delete"
				elif GlobalVariables.turnController.currentTurnWaiting == GlobalVariables.CURRENTPHASE.PLAYERPROJECTILE:
					pawn.deleteProjectilePlayAnimation = "delete"
				else:
					pawn.play_projectile_animation(false,"delete")
			_:
				projectilesInActiveRoom.erase(pawn)
				if GlobalVariables.turnController.currentTurnWaiting == GlobalVariables.CURRENTPHASE.ENEMYPROJECTILE:
					pawn.deleteProjectilePlayAnimation = "delete"
				elif GlobalVariables.turnController.currentTurnWaiting == GlobalVariables.CURRENTPHASE.PLAYERPROJECTILE:
					pawn.deleteProjectilePlayAnimation = "delete"
				else:
					pawn.deleteProjectilePlayAnimation = "delete"
				set_cellv(world_to_map(pawn.position),get_tileset().find_tile_by_name("FLOOR")) 
				

#handles interaction between different projectile types
func magic_projectile_magic_projectile_interaction(magicProjectile1, magicProjectile2):
	#enemy enemy projectile interaction
	if magicProjectile1.projectileType == GlobalVariables.PROJECTILETYPE.ENEMY && magicProjectile2.projectileType == GlobalVariables.PROJECTILETYPE.ENEMY:
		return true
	#player enemy projectile interaction
	if magicProjectile1.projectileType == GlobalVariables.PROJECTILETYPE.PLAYER && magicProjectile2.projectileType == GlobalVariables.PROJECTILETYPE.ENEMY || magicProjectile1.projectileType == GlobalVariables.PROJECTILETYPE.ENEMY && magicProjectile2.projectileType == GlobalVariables.PROJECTILETYPE.PLAYER:
		if GlobalVariables.turnController.currentTurnWaiting == GlobalVariables.CURRENTPHASE.PLAYER:
			magicProjectile1.play_projectile_animation(false,"delete")
			magicProjectile2.play_projectile_animation(true,"delete")
		else:
			magicProjectile1.play_projectile_animation(false,"delete")
			magicProjectile2.play_projectile_animation(true,"delete")
		return false

	#player player projectile interaction
	if magicProjectile1.projectileType == GlobalVariables.PROJECTILETYPE.PLAYER && magicProjectile2.projectileType == GlobalVariables.PROJECTILETYPE.PLAYER:
		if GlobalVariables.turnController.currentTurnWaiting == GlobalVariables.CURRENTPHASE.PLAYERPROJECTILE:
			return true
		elif GlobalVariables.turnController.currentTurnWaiting == GlobalVariables.CURRENTPHASE.PLAYER:
			if magicProjectile1.isMiniProjectile && magicProjectile2.isMiniProjectile:
				magicProjectile1.play_projectile_animation(true,"delete")
				magicProjectile2.play_projectile_animation(true,"merge")
				
				return true
			elif magicProjectile1.isMiniProjectile || magicProjectile2.isMiniProjectile:
				magicProjectile1.play_projectile_animation(true,"delete")
				magicProjectile2.play_projectile_animation(true,"merge")
				return true
			else:
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
				magicProjectile1.play_projectile_animation(true,"mini")
				magicProjectile2.play_projectile_animation(true,"mini")
				return false
		
	# PuzzleProjectile puzzleprojectile interaction:
	elif magicProjectile1.projectileType == GlobalVariables.PROJECTILETYPE.POWERBLOCK && magicProjectile2.projectileType == GlobalVariables.PROJECTILETYPE.POWERBLOCK:
		print("Magic Projectile Magic Projectile Puzzle Room interaction")
		var magicProjectile1BackupPos = magicProjectile1.position 
		magicProjectile1.position = magicProjectile2.position 
		magicProjectile2.position = magicProjectile1BackupPos
		
#if movement is possible update cells in room
func update_pawn_position(pawn, cell_start, cell_target):
	var oldCellTargetType = get_cellv(cell_target)
	var oldCellTargetNode = get_cell_pawn(cell_target)
	set_cellv(cell_target, get_tileset().find_tile_by_name(match_Enum(pawn.type)))
	set_cellv(cell_start, TILETYPES.FLOOR)

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
				worldAudioStreamPlayer.stream = unlockDoorAudio
				worldAudioStreamPlayer.play()
				oldCellTargetNode.set_other_adjacent_room(activeRoom, direction)
				if !projectilesInActiveRoom.empty():
					var tempProjectiles = projectilesInActiveRoom.duplicate()
					for projectile in tempProjectiles:
						set_cellv(world_to_map(projectile.position),get_tileset().find_tile_by_name("FLOOR")) 
						projectile.queue_free()
					projectilesInActiveRoom.clear()
					tempProjectiles.clear()
				if(activeRoom != null):
					#disable elements in room just left
					if !activeRoom.enemiesInRoom.empty():
						for element in activeRoom.enemiesInRoom:
							element.isDisabled = true
							element.turn_off_danger_fields_on_exit_room()
							if element.attackRangeNode != null:
								element.attackRangeNode.queue_free()
								element.attackRangeNode = null
					#remove rojectiles in old room
				activeRoom = oldCellTargetNode
				if activeRoom != null:
					pawn.inRoomType = activeRoom.roomType
					GlobalVariables.turnController.inRoomType = activeRoom.roomType
					#enable elemnts in room just entered
					for element in activeRoom.enemiesInRoom:
						element.isDisabled = false
						element.enemyTurnDone=true
					if GlobalVariables.turnController.inRoomType == GlobalVariables.ROOM_TYPE.PUZZLEROOM:
						GlobalVariables.turnController.puzzlePiecesToPattern += activeRoom.puzzlePiecesInRoom
						print(GlobalVariables.turnController.puzzlePiecesToPattern.size())
						play_puzzlepiece_pattern()
					elif GlobalVariables.turnController.inRoomType == GlobalVariables.ROOM_TYPE.EMPTYTREASUREROOM:
						activeRoom.update_container_prices()
				else:
					pawn.inRoomType = null
					GlobalVariables.turnController.inRoomType = GlobalVariables.ROOM_TYPE.ENEMYROOM
			if(oldCellTargetType == get_tileset().find_tile_by_name("UNLOCKEDDOOR")):
				var tempProjectiles = projectilesInActiveRoom.duplicate()
				for projectile in tempProjectiles:
					set_cellv(world_to_map(projectile.position),get_tileset().find_tile_by_name("FLOOR")) 
					projectile.queue_free()
				projectilesInActiveRoom.clear()
				tempProjectiles.clear()
				if(activeRoom != null):
					adapt_game_difficulty()
					#disable elements in room just left
					if !activeRoom.enemiesInRoom.empty():
						for element in activeRoom.enemiesInRoom:
							element.isDisabled = true
							element.turn_off_danger_fields_on_exit_room()
							if element.attackRangeNode != null:
								element.attackRangeNode.queue_free()
								element.attackRangeNode = null
							#element.toggleVisibility(true)
					#remove rojectiles in old room
				activeRoom=oldCellTargetNode.get_room_by_movement_direction(direction)
				if activeRoom != null:
					pawn.inRoomType = activeRoom.roomType
					GlobalVariables.turnController.inRoomType = activeRoom.roomType
					#enable elements in entered room
					for element in activeRoom.enemiesInRoom:
						element.isDisabled = false
					if !activeRoom.enemiesInRoom.empty():
						activeRoom.enemiesInRoom[0].calc_enemy_attack_to(GlobalVariables.MOVEMENTATTACKCALCMODE.PREVIEW,activeRoom,0)
					if !activeRoom.roomCleared && GlobalVariables.turnController.inRoomType == GlobalVariables.ROOM_TYPE.PUZZLEROOM:
						GlobalVariables.turnController.puzzlePiecesToPattern += activeRoom.puzzlePiecesInRoom
						print(GlobalVariables.turnController.puzzlePiecesToPattern.size())
						play_puzzlepiece_pattern()
					if GlobalVariables.turnController.inRoomType == GlobalVariables.ROOM_TYPE.EMPTYTREASUREROOM:
						activeRoom.update_container_prices()
				else:
					pawn.inRoomType = null
			#update camera position 
			emit_signal("moveCameraSignal", activeRoom)
			#set player to be in cleared room
			if(activeRoom == null || activeRoom.roomType == GlobalVariables.ROOM_TYPE.EMPTYTREASUREROOM):
				pawn.inClearedRoom = true
				if activeRoom!= null && activeRoom.roomType == GlobalVariables.ROOM_TYPE.EMPTYTREASUREROOM && !activeRoom.roomCleared:
					if activeRoom.drop_loot():
						dropLootInActiveRoom()
					activeRoom.roomCleared = true
					activeRoom.roomType = GlobalVariables.ROOM_TYPE.EMPTYTREASUREROOM
			else:
				pawn.inClearedRoom = false
				
	return map_to_world(cell_target) + cell_size / GlobalVariables.isometricFactor
	
func create_puzzle_room(unlockedDoor):
	randomize()
	#minimum 4 maximum 6
	var randPieces = int(GlobalVariables.countPuzzleRoomsCleared/3-GlobalVariables.timesActivatedPuzzleWrong/5)
	if  randPieces >= int(4* GlobalVariables.globalDifficultyMultiplier):
		randPieces = int(4* GlobalVariables.globalDifficultyMultiplier)
	var puzzlePiecesToSpwan = randi()%(randPieces+1)+2
	for sizeModifier in range (9, GlobalVariables.roomDimensions+1):
		if sizeModifier%2 == 0:
			puzzlePiecesToSpwan+=1
	if unlockedDoor.roomSizeMultiplier == Vector2(1,2) || unlockedDoor.roomSizeMultiplier == Vector2(2,1):
		puzzlePiecesToSpwan = int(puzzlePiecesToSpwan*1.5)
	elif unlockedDoor.roomSizeMultiplier == Vector2(2,2):
		puzzlePiecesToSpwan = int(puzzlePiecesToSpwan*2.0)
	if puzzlePiecesToSpwan >= 11: 
		puzzlePiecesToSpwan = 11
	var calculateSpawnAgain = true
	var alreadyUsedColors = []
	var spawnCellArray = []
	var spawnCellX
	var spawnCellY
	var spawnCell 
	var barrierPuzzlePieceAlreadySpawned = false
	for puzzlePieces in puzzlePiecesToSpwan:
		calculateSpawnAgain = true
		while(calculateSpawnAgain == true):
			spawnCellX = randi()%(int(unlockedDoor.roomSize.x-2))+1
			spawnCellY = randi()%(int(unlockedDoor.roomSize.y-2))+1
			spawnCell = spawnCellX*spawnCellY
			calculateSpawnAgain = calculate_spawn_element(unlockedDoor, spawnCellX, spawnCellY, spawnCellArray, spawnCell)
		var colorToUse = Color(randf(),randf(),randf(),1.0)
		while alreadyUsedColors.has(colorToUse):
			colorToUse = Color(randf(),randf(),randf(),1.0)
		alreadyUsedColors.append(colorToUse)
		var newPuzzlePiece = PuzzlePiece.instance()
		newPuzzlePiece.set_z_index(2)
		if !barrierPuzzlePieceAlreadySpawned:
			newPuzzlePiece.make_puzzle_barrier(self, unlockedDoor)
		newPuzzlePiece.color = colorToUse
		newPuzzlePiece.position = unlockedDoor.doorRoomLeftMostCorner + map_to_world(Vector2(spawnCellX, spawnCellY))
		add_child(newPuzzlePiece)
		newPuzzlePiece.connect("puzzlePieceActivated", self, "_on_puzzle_piece_activated")
		newPuzzlePiece.connect("puzzlePlayedAnimation", GlobalVariables.turnController, "puzzle_pattern_turn_done")
		set_cellv(world_to_map(newPuzzlePiece.position), get_tileset().find_tile_by_name("PUZZLEPIECE"))
		unlockedDoor.puzzlePiecesInRoom.append(newPuzzlePiece)
#adds counting block to puzzle room for optional challange
	var countingBlocksRand = 80
	if GlobalVariables.countPuzzleRoomsCleared <= 2:
		countingBlocksRand = 0
	if countingBlocksRand < 50-int(GlobalVariables.puzzleBonusLootDropped*2): 
		countingBlocksRand = 0
	elif countingBlocksRand < 80-int(GlobalVariables.puzzleBonusLootDropped*2):
		countingBlocksRand = 1
	elif countingBlocksRand < 100-int(GlobalVariables.puzzleBonusLootDropped*2):
		countingBlocksRand = 2
	else:
		countingBlocksRand = 3
	for countingBlock in countingBlocksRand:
		calculateSpawnAgain = true
		while(calculateSpawnAgain == true):
			spawnCellX = randi()%(int(unlockedDoor.roomSize.x-2))+1
			spawnCellY = randi()%(int(unlockedDoor.roomSize.y-2))+1
			spawnCell = spawnCellX*spawnCellY
			calculateSpawnAgain = calculate_spawn_element(unlockedDoor, spawnCellX, spawnCellY, spawnCellArray, spawnCell)
		var newCountingBlock = CountingBlock.instance()
		newCountingBlock.set_z_index(2)
		newCountingBlock.position = unlockedDoor.doorRoomLeftMostCorner + map_to_world(Vector2(spawnCellX, spawnCellY))
		add_child(newCountingBlock)
		set_cellv(world_to_map(newCountingBlock.position), get_tileset().find_tile_by_name("COUNTINGBLOCK"))
		unlockedDoor.countingBlocksInRoom.append(newCountingBlock)
		
#checks if spawn position is possible
func calculate_spawn_element(unlockedDoor, spawnCellX, spawnCellY, spawnCellArray, spawnCell):
	var spawnCords = world_to_map(unlockedDoor.doorRoomLeftMostCorner) + Vector2(spawnCellX, spawnCellY)
	if get_cellv(spawnCords - Vector2(1,0)) == TILETYPES.DOOR || get_cellv(spawnCords - Vector2(-1,0)) == TILETYPES.DOOR || get_cellv(spawnCords - Vector2(0,1)) == TILETYPES.DOOR || get_cellv(spawnCords - Vector2(0,-1)) == TILETYPES.DOOR || get_cellv(spawnCords - Vector2(1,0)) == TILETYPES.UNLOCKEDDOOR || get_cellv(spawnCords - Vector2(-1,0)) == TILETYPES.UNLOCKEDDOOR || get_cellv(spawnCords - Vector2(0,1)) == TILETYPES.UNLOCKEDDOOR || get_cellv(spawnCords - Vector2(0,-1)) == TILETYPES.UNLOCKEDDOOR:
		pass
	elif get_cellv(spawnCords + Vector2(1,0)) == TILETYPES.WALL && get_cellv(spawnCords + Vector2(-1,0)) == TILETYPES.WALL || get_cellv(spawnCords + Vector2(0,1)) == TILETYPES.WALL && get_cellv(spawnCords + Vector2(0,-1)) == TILETYPES.WALL:
		pass
	elif get_cellv(spawnCords - Vector2(2,0)) == TILETYPES.DOOR || get_cellv(spawnCords - Vector2(-2,0)) == TILETYPES.DOOR || get_cellv(spawnCords - Vector2(0,2)) == TILETYPES.DOOR || get_cellv(spawnCords - Vector2(0,-2)) == TILETYPES.DOOR || get_cellv(spawnCords - Vector2(1,0)) == TILETYPES.UNLOCKEDDOOR || get_cellv(spawnCords - Vector2(-1,0)) == TILETYPES.UNLOCKEDDOOR || get_cellv(spawnCords - Vector2(0,1)) == TILETYPES.UNLOCKEDDOOR || get_cellv(spawnCords - Vector2(0,-1)) == TILETYPES.UNLOCKEDDOOR:
		pass
	elif spawnCellArray.has(spawnCell):
		pass
	else:
		spawnCellArray.append(spawnCell)
		return false
	return true

func play_puzzlepiece_pattern(onRoomEnter = true):
	activeRoom.puzzlePiecesInRoom[0].play_color(activeRoom.puzzlePiecesInRoom, 0, onRoomEnter)

#set up shop container in each empty treasure room 
func create_empty_treasure_room(unlockedDoor):
	var upgradeContainers = []
	#place upgrade machines in corners
	var actionUpContainer = UpgradeContainer.instance()
	actionUpContainer.position = unlockedDoor.doorRoomLeftMostCorner + map_to_world(Vector2(1,1))
	actionUpContainer.set_upgrade_container(GlobalVariables.UPGRADETYPE.ACTIONSUP)
	add_child(actionUpContainer)
	upgradeContainers.append(actionUpContainer)
	
	var bombUpContainer = UpgradeContainer.instance()
	bombUpContainer.position = unlockedDoor.doorRoomLeftMostCorner + map_to_world(Vector2(2,1))
	bombUpContainer.set_upgrade_container(GlobalVariables.UPGRADETYPE.BOMB)
	add_child(bombUpContainer)
	upgradeContainers.append(bombUpContainer)
	
	var flaskUpContainer = UpgradeContainer.instance()
	flaskUpContainer.position = unlockedDoor.doorRoomLeftMostCorner + map_to_world(Vector2(unlockedDoor.roomSize.x,0)) - map_to_world(Vector2(2,-1))
	flaskUpContainer.set_upgrade_container(GlobalVariables.UPGRADETYPE.FLASK)
	add_child(flaskUpContainer)
	upgradeContainers.append(flaskUpContainer)
	
	var heartUpContainer = UpgradeContainer.instance()
	heartUpContainer.position = unlockedDoor.doorRoomLeftMostCorner + map_to_world(Vector2(unlockedDoor.roomSize.x,0)) - map_to_world(Vector2(3,-1))
	heartUpContainer.set_upgrade_container(GlobalVariables.UPGRADETYPE.HEART)
	add_child(heartUpContainer)
	upgradeContainers.append(heartUpContainer)
	
	var heartFillContainer = UpgradeContainer.instance()
	heartFillContainer.position = unlockedDoor.doorRoomLeftMostCorner + map_to_world(Vector2(0,unlockedDoor.roomSize.y)) - map_to_world(Vector2(-2,2))
	heartFillContainer.set_upgrade_container(GlobalVariables.UPGRADETYPE.FILLHEART)
	add_child(heartFillContainer)
	upgradeContainers.append(heartFillContainer)
	
	var flaskFillContainer = UpgradeContainer.instance()
	flaskFillContainer.position = unlockedDoor.doorRoomLeftMostCorner + map_to_world(Vector2(0,unlockedDoor.roomSize.y)) - map_to_world(Vector2(-1,2))
	flaskFillContainer.set_upgrade_container(GlobalVariables.UPGRADETYPE.FILLFLASK)
	add_child(flaskFillContainer)
	upgradeContainers.append(flaskFillContainer)
	
	var swordContainer = UpgradeContainer.instance()
	swordContainer.position = unlockedDoor.doorRoomLeftMostCorner + map_to_world(unlockedDoor.roomSize) - map_to_world(Vector2(3,2))
	swordContainer.set_upgrade_container(GlobalVariables.UPGRADETYPE.SWORD)
	add_child(swordContainer)
	upgradeContainers.append(swordContainer)
	
	var magicContainer = UpgradeContainer.instance()
	magicContainer.position = unlockedDoor.doorRoomLeftMostCorner + map_to_world(unlockedDoor.roomSize) - map_to_world(Vector2(2,2))
	magicContainer.set_upgrade_container(GlobalVariables.UPGRADETYPE.MAGIC)
	add_child(magicContainer)
	upgradeContainers.append(magicContainer)
	
	for container in upgradeContainers:
		set_cellv(world_to_map(container.position), get_tileset().find_tile_by_name("UPGRADECONTAINER"))
	unlockedDoor.upgradeContainersInRoom = upgradeContainers.duplicate()
	upgradeContainers.clear()
	
#fills room with enemies dependent on difficulty level 
func create_enemy_room(unlockedDoor):
	randomize()
	var enemiesToSpawn = 1
	var mixEnemies = false
	var mixEnemiesAndMage = false
	var multipleMages = 0
	var totalDifficultyLevel = GlobalVariables.enemyBarrierDifficulty + GlobalVariables.enemyMageDifficulty + GlobalVariables.enemyNinjaDifficulty + GlobalVariables.enemyWarriorDifficulty
	if totalDifficultyLevel >= 6:
		enemiesToSpawn = int(totalDifficultyLevel/6)
		if enemiesToSpawn >= 4:
			enemiesToSpawn = 4
	if totalDifficultyLevel >=16:
		mixEnemies = true
	if GlobalVariables.enemyMageDifficulty >= 10:
		multipleMages += GlobalVariables.enemyMageDifficulty/10
	if totalDifficultyLevel >=25:
		mixEnemiesAndMage = true
	var enemyType = randi()%4
	#enemyType = 2
	print(enemyType)
	if enemyType == GlobalVariables.ENEMYTYPE.MAGEENEMY && multipleMages!= 0:
		enemiesToSpawn += randi()%(multipleMages+1)+1
		mixEnemies = false
	for sizeModifier in range (9, GlobalVariables.roomDimensions+1):
		if sizeModifier%2 == 0:
			enemiesToSpawn+=1
	if unlockedDoor.roomSizeMultiplier == Vector2(1,2) || unlockedDoor.roomSizeMultiplier == Vector2(2,1):
		enemiesToSpawn = int(enemiesToSpawn*1.5)
	elif unlockedDoor.roomSizeMultiplier == Vector2(2,2):
		enemiesToSpawn = int(enemiesToSpawn*2.0)
	if enemiesToSpawn < 1:
		enemiesToSpawn = 1
	var sizecounter = 0
	var mageEnemyCount = 0
	var spawnCellArray = []
	var spawnCellX
	var spawnCellY
	var spawnCell 
	var calculateSpawnAgain = true
	while enemiesToSpawn != 0: 
		calculateSpawnAgain = true
		while(calculateSpawnAgain == true):
			spawnCellX = randi()%(int(unlockedDoor.roomSize.x-2))+1
			spawnCellY = randi()%(int(unlockedDoor.roomSize.y-2))+1
			spawnCell = spawnCellX*spawnCellY
			calculateSpawnAgain = calculate_spawn_element(unlockedDoor, spawnCellX, spawnCellY, spawnCellArray, spawnCell)
				
		var newEnemy = Enemy.instance()
		add_child(newEnemy)
		newEnemy.set_z_index(2)
		newEnemy.position = unlockedDoor.doorRoomLeftMostCorner + map_to_world(Vector2(spawnCellX, spawnCellY))
		var generatedEnemyType = newEnemy.generateEnemy(enemyType, self, unlockedDoor)
		newEnemy.connect("enemyMadeMove", GlobalVariables.turnController, "enemy_turn_done")
		newEnemy.connect("enemyAttacked", self, "_on_enemy_attacked")
		newEnemy.connect("enemyDefeated", self, "_on_enemy_defeated")
		set_cellv(world_to_map(newEnemy.position), get_tileset().find_tile_by_name(match_Enum(newEnemy.type)))
		unlockedDoor.enemiesInRoom.append(newEnemy)
		if newEnemy.helpEnemy:
			enemiesToSpawn += 1
		if mixEnemies || mixEnemiesAndMage:
			enemyType = randi()%4
		enemiesToSpawn -= 1
	if unlockedDoor != null && !unlockedDoor.enemiesInRoom.empty():
		unlockedDoor.enemiesInRoom.sort_custom(EnemyPositionSorter, "sort_enemyArray_by_position")
		unlockedDoor.enemiesInRoom[0].calc_enemy_attack_to(GlobalVariables.MOVEMENTATTACKCALCMODE.PREVIEW, unlockedDoor, 0)

#sort enemy array to enemy y position to display danger areas in logical order
class EnemyPositionSorter:
	static func sort_enemyArray_by_position(a,b):
		if a != b:
			if a.position.y < b.position.y:
				return true
			elif a.position.y == b.position.y:
				if a.position.x < b.position.x:
					return true
			else:
				return false

#calculate movement direction for warrior enemy
#moves set steps in direction closest vector to player
func get_enemy_move_towards_player(enemy, movementCount):
	if movementCount > 3:
		movementCount = 3
	var stepsSet = false
	var distance = world_to_map(mainPlayer.position) - world_to_map(enemy.position)
	var returnVector = Vector2.ZERO
	if abs(distance.x) >= abs(distance.y):
		returnVector = Vector2(distance.x/abs(distance.x),0)
	else:
		returnVector = Vector2(0,distance.y/abs(distance.y))
	match returnVector:
		Vector2(1,0):
			enemy.movementdirection = GlobalVariables.DIRECTION.RIGHT
		Vector2(-1,0):
			enemy.movementdirection = GlobalVariables.DIRECTION.LEFT
		Vector2(0,1):
			enemy.movementdirection = GlobalVariables.DIRECTION.DOWN
		Vector2(0,-1):
			enemy.movementdirection = GlobalVariables.DIRECTION.UP
	#steps in front of certain objects 
	for steps in movementCount-1:
		if get_cellv(world_to_map(enemy.position)+(steps+1)*returnVector) == TILETYPES.PLAYER:
			return steps*returnVector
		if get_cellv(world_to_map(enemy.position)+(steps+1)*returnVector) == TILETYPES.MAGICPROJECTILE && get_cell_pawn(world_to_map(enemy.position)+(steps+1)*returnVector).projectileType == GlobalVariables.PROJECTILETYPE.ENEMY:
			return (steps+1)*returnVector
		if get_cellv(world_to_map(enemy.position)+(steps+1)*returnVector) != TILETYPES.FLOOR:
			if steps != 0: 
				return steps*returnVector
			stepsSet = true
			returnVector = Vector2.ZERO
			break
	#moves as far as possible if it's floor
	if !stepsSet:
		var count = movementCount
		while count >= 0:
			if get_cellv(world_to_map(enemy.position) + returnVector*count) == TILETYPES.FLOOR:
				return returnVector*count
			count -=1
	match enemy.movementdirection:
		GlobalVariables.DIRECTION.LEFT:
			if get_cellv(world_to_map(enemy.position)+Vector2(0,1)) == TILETYPES.FLOOR || get_cellv(world_to_map(enemy.position)+Vector2(0,1)) == TILETYPES.MAGICPROJECTILE:
				return Vector2(0,1)
			if get_cellv(world_to_map(enemy.position)+Vector2(0,-1)) == TILETYPES.FLOOR || get_cellv(world_to_map(enemy.position)+Vector2(0,-1)) == TILETYPES.MAGICPROJECTILE:
				return Vector2(0,-1)
		GlobalVariables.DIRECTION.RIGHT:
			if get_cellv(world_to_map(enemy.position)+Vector2(0,1)) == TILETYPES.FLOOR || get_cellv(world_to_map(enemy.position)+Vector2(0,1)) == TILETYPES.MAGICPROJECTILE:
				return Vector2(0,1)
			if get_cellv(world_to_map(enemy.position)+Vector2(0,-1)) == TILETYPES.FLOOR || get_cellv(world_to_map(enemy.position)+Vector2(0,-1)) == TILETYPES.MAGICPROJECTILE:
				return Vector2(0,-1)
		GlobalVariables.DIRECTION.UP:
			if get_cellv(world_to_map(enemy.position)+Vector2(1,0)) == TILETYPES.FLOOR || get_cellv(world_to_map(enemy.position)+Vector2(1,0)) == TILETYPES.MAGICPROJECTILE:
				return Vector2(1,0)
			if get_cellv(world_to_map(enemy.position)+Vector2(-1,0)) == TILETYPES.FLOOR || get_cellv(world_to_map(enemy.position)+Vector2(-1,0)) == TILETYPES.MAGICPROJECTILE:
				return Vector2(-1,0)
		GlobalVariables.DIRECTION.DOWN:
			if get_cellv(world_to_map(enemy.position)+Vector2(1,0)) == TILETYPES.FLOOR || get_cellv(world_to_map(enemy.position)+Vector2(1,0)) == TILETYPES.MAGICPROJECTILE:
				return Vector2(1,0)
			if get_cellv(world_to_map(enemy.position)+Vector2(-1,0)) == TILETYPES.FLOOR || get_cellv(world_to_map(enemy.position)+Vector2(-1,0)) == TILETYPES.MAGICPROJECTILE:
				return Vector2(-1,0)
	return returnVector
#calculate movement direction for warrior enemy
#moves diagonally through the room 
#adjusts movement range according to difficulty 
func get_enemy_move_ninja_pattern(enemy, movementdirection, moveCellCount):
	match movementdirection:
		GlobalVariables.DIRECTION.LEFT:
			if (get_cellv(world_to_map(enemy.position) + Vector2(-moveCellCount,-moveCellCount)) == TILETYPES.FLOOR || get_cellv(world_to_map(enemy.position) + Vector2(-moveCellCount,-moveCellCount)) == TILETYPES.MAGICPROJECTILE) && (world_to_map(enemy.position) + Vector2(-moveCellCount,-moveCellCount)).x > world_to_map(activeRoom.doorRoomLeftMostCorner).x && (world_to_map(enemy.position) + Vector2(-moveCellCount,-moveCellCount)).y > world_to_map(activeRoom.doorRoomLeftMostCorner).y && (world_to_map(enemy.position) + Vector2(-moveCellCount,-moveCellCount)).x < world_to_map(activeRoom.doorRoomLeftMostCorner).x+activeRoom.roomSize.x-1 && (world_to_map(enemy.position) + Vector2(-moveCellCount,-moveCellCount)).y < world_to_map(activeRoom.doorRoomLeftMostCorner).y+activeRoom.roomSize.y-1:
				return Vector2(-moveCellCount,-moveCellCount)
			if (get_cellv(world_to_map(enemy.position) + Vector2(-moveCellCount,moveCellCount)) == TILETYPES.FLOOR || get_cellv(world_to_map(enemy.position) + Vector2(-moveCellCount,moveCellCount)) == TILETYPES.MAGICPROJECTILE) && (world_to_map(enemy.position) + Vector2(-moveCellCount,moveCellCount)).x > world_to_map(activeRoom.doorRoomLeftMostCorner).x && (world_to_map(enemy.position) + Vector2(-moveCellCount,moveCellCount)).y > world_to_map(activeRoom.doorRoomLeftMostCorner).y && (world_to_map(enemy.position) + Vector2(-moveCellCount,moveCellCount)).x < world_to_map(activeRoom.doorRoomLeftMostCorner).x+activeRoom.roomSize.x-1 && (world_to_map(enemy.position) + Vector2(-moveCellCount,moveCellCount)).y < world_to_map(activeRoom.doorRoomLeftMostCorner).y+activeRoom.roomSize.y-1:
				return Vector2(-moveCellCount,moveCellCount)
			if enemy.ninjaEnemyCheckedDirections == 1 && moveCellCount == 1:
				return Vector2.ZERO
			enemy.ninjaEnemyCheckedDirections+=1
			if moveCellCount == 1:
				enemy.movementdirection = GlobalVariables.DIRECTION.RIGHT
				return get_enemy_move_ninja_pattern(enemy,enemy.movementdirection,enemy.movementCount)
			elif moveCellCount > 1:
				return get_enemy_move_ninja_pattern(enemy,enemy.movementdirection,moveCellCount-1)
		GlobalVariables.DIRECTION.RIGHT:
			if (get_cellv(world_to_map(enemy.position) + Vector2(moveCellCount,moveCellCount)) == TILETYPES.FLOOR || get_cellv(world_to_map(enemy.position) + Vector2(moveCellCount,moveCellCount)) == TILETYPES.MAGICPROJECTILE) && (world_to_map(enemy.position) + Vector2(moveCellCount,moveCellCount)).x > world_to_map(activeRoom.doorRoomLeftMostCorner).x && (world_to_map(enemy.position) + Vector2(moveCellCount,moveCellCount)).y > world_to_map(activeRoom.doorRoomLeftMostCorner).y && (world_to_map(enemy.position) + Vector2(moveCellCount,moveCellCount)).x < world_to_map(activeRoom.doorRoomLeftMostCorner).x+activeRoom.roomSize.x-1 && (world_to_map(enemy.position) + Vector2(moveCellCount,moveCellCount)).y < world_to_map(activeRoom.doorRoomLeftMostCorner).y+activeRoom.roomSize.y-1:
				return Vector2(moveCellCount,moveCellCount)
			if (get_cellv(world_to_map(enemy.position) + Vector2(moveCellCount,-moveCellCount)) == TILETYPES.FLOOR || get_cellv(world_to_map(enemy.position) + Vector2(moveCellCount,-moveCellCount)) == TILETYPES.MAGICPROJECTILE) && (world_to_map(enemy.position) + Vector2(moveCellCount,-moveCellCount)).x > world_to_map(activeRoom.doorRoomLeftMostCorner).x && (world_to_map(enemy.position) + Vector2(moveCellCount,-moveCellCount)).y > world_to_map(activeRoom.doorRoomLeftMostCorner).y && (world_to_map(enemy.position) + Vector2(moveCellCount,-moveCellCount)).x < world_to_map(activeRoom.doorRoomLeftMostCorner).x+activeRoom.roomSize.x-1 && (world_to_map(enemy.position) + Vector2(moveCellCount,-moveCellCount)).y < world_to_map(activeRoom.doorRoomLeftMostCorner).y+activeRoom.roomSize.y-1:
				return Vector2(moveCellCount,-moveCellCount)
			if enemy.ninjaEnemyCheckedDirections == 1:
				return Vector2.ZERO
			enemy.ninjaEnemyCheckedDirections+=1
			enemy.movementdirection = GlobalVariables.DIRECTION.LEFT
			if moveCellCount == 1:
				enemy.movementdirection = GlobalVariables.DIRECTION.LEFT
				return get_enemy_move_ninja_pattern(enemy,enemy.movementdirection,enemy.movementCount)
			elif moveCellCount > 1:
				return get_enemy_move_ninja_pattern(enemy,enemy.movementdirection,moveCellCount-1)
		GlobalVariables.DIRECTION.UP:
			if (get_cellv(world_to_map(enemy.position) + Vector2(moveCellCount,-moveCellCount)) == TILETYPES.FLOOR || get_cellv(world_to_map(enemy.position) + Vector2(moveCellCount,-moveCellCount)) == TILETYPES.MAGICPROJECTILE)&& (world_to_map(enemy.position) + Vector2(moveCellCount,-moveCellCount)).x > world_to_map(activeRoom.doorRoomLeftMostCorner).x && (world_to_map(enemy.position) + Vector2(moveCellCount,-moveCellCount)).y > world_to_map(activeRoom.doorRoomLeftMostCorner).y && (world_to_map(enemy.position) + Vector2(moveCellCount,-moveCellCount)).x < world_to_map(activeRoom.doorRoomLeftMostCorner).x+activeRoom.roomSize.x-1 && (world_to_map(enemy.position) + Vector2(moveCellCount,-moveCellCount)).y < world_to_map(activeRoom.doorRoomLeftMostCorner).y+activeRoom.roomSize.y-1:
				return Vector2(moveCellCount,-moveCellCount)
			if (get_cellv(world_to_map(enemy.position) + Vector2(-moveCellCount,-moveCellCount)) == TILETYPES.FLOOR || get_cellv(world_to_map(enemy.position) + Vector2(-moveCellCount,-moveCellCount)) == TILETYPES.MAGICPROJECTILE) && (world_to_map(enemy.position) + Vector2(-moveCellCount,-moveCellCount)).x > world_to_map(activeRoom.doorRoomLeftMostCorner).x && (world_to_map(enemy.position) + Vector2(-moveCellCount,-moveCellCount)).y > world_to_map(activeRoom.doorRoomLeftMostCorner).y && (world_to_map(enemy.position) + Vector2(-moveCellCount,-moveCellCount)).x < world_to_map(activeRoom.doorRoomLeftMostCorner).x+activeRoom.roomSize.x-1 && (world_to_map(enemy.position) + Vector2(-moveCellCount,-moveCellCount)).y < world_to_map(activeRoom.doorRoomLeftMostCorner).y+activeRoom.roomSize.y-1:
				return Vector2(-moveCellCount,-moveCellCount)
			if enemy.ninjaEnemyCheckedDirections == 1 && moveCellCount == 1:
				return Vector2.ZERO
			enemy.ninjaEnemyCheckedDirections+=1
			enemy.movementdirection = GlobalVariables.DIRECTION.DOWN
			if moveCellCount == 1:
				enemy.movementdirection = GlobalVariables.DIRECTION.DOWN
				return get_enemy_move_ninja_pattern(enemy,enemy.movementdirection,enemy.movementCount)
			elif moveCellCount > 1:
				return get_enemy_move_ninja_pattern(enemy,enemy.movementdirection,moveCellCount-1)
		GlobalVariables.DIRECTION.DOWN:
			if (get_cellv(world_to_map(enemy.position) + Vector2(-moveCellCount,moveCellCount)) == TILETYPES.FLOOR || get_cellv(world_to_map(enemy.position) + Vector2(-moveCellCount,moveCellCount)) == TILETYPES.MAGICPROJECTILE) && (world_to_map(enemy.position) + Vector2(-moveCellCount,moveCellCount)).x > world_to_map(activeRoom.doorRoomLeftMostCorner).x && (world_to_map(enemy.position) + Vector2(-moveCellCount,moveCellCount)).y > world_to_map(activeRoom.doorRoomLeftMostCorner).y && (world_to_map(enemy.position) + Vector2(-moveCellCount,moveCellCount)).x < world_to_map(activeRoom.doorRoomLeftMostCorner).x+activeRoom.roomSize.x-1 && (world_to_map(enemy.position) + Vector2(-moveCellCount,moveCellCount)).y < world_to_map(activeRoom.doorRoomLeftMostCorner).y+activeRoom.roomSize.y-1:
				return Vector2(-moveCellCount,moveCellCount)
			if (get_cellv(world_to_map(enemy.position) + Vector2(moveCellCount,moveCellCount)) == TILETYPES.FLOOR || get_cellv(world_to_map(enemy.position) + Vector2(moveCellCount,moveCellCount)) == TILETYPES.MAGICPROJECTILE) && (world_to_map(enemy.position) + Vector2(moveCellCount,moveCellCount)).x > world_to_map(activeRoom.doorRoomLeftMostCorner).x && (world_to_map(enemy.position) + Vector2(moveCellCount,moveCellCount)).y > world_to_map(activeRoom.doorRoomLeftMostCorner).y && (world_to_map(enemy.position) + Vector2(moveCellCount,moveCellCount)).x < world_to_map(activeRoom.doorRoomLeftMostCorner).x+activeRoom.roomSize.x-1 && (world_to_map(enemy.position) + Vector2(moveCellCount,moveCellCount)).y < world_to_map(activeRoom.doorRoomLeftMostCorner).y+activeRoom.roomSize.y-1:
				return Vector2(moveCellCount,moveCellCount)
			if enemy.ninjaEnemyCheckedDirections == 1 && moveCellCount == 1:
				return Vector2.ZERO
			enemy.ninjaEnemyCheckedDirections=1
			enemy.movementdirection = GlobalVariables.DIRECTION.UP
			if moveCellCount == 1:
				enemy.movementdirection = GlobalVariables.DIRECTION.UP
				return get_enemy_move_ninja_pattern(enemy,enemy.movementdirection,enemy.movementCount)
			elif moveCellCount > 1:
				return get_enemy_move_ninja_pattern(enemy,enemy.movementdirection,moveCellCount-1)
				
#manages turncontroller requests and actions 
#in grid script to easier access variables and functions 
func _on_Enemy_Turn_Done_Request(enemy):
	GlobalVariables.turnController.enemy_turn_done(enemy)
	
func on_enemy_turn_done_confirmed():
	if activeRoom != null:
		if !activeRoom.enemiesInRoom.empty():
			activeRoom.enemiesInRoom.sort_custom(EnemyPositionSorter, "sort_enemyArray_by_position")
			activeRoom.enemiesInRoom[0].calc_enemy_attack_to(GlobalVariables.MOVEMENTATTACKCALCMODE.PREVIEW, activeRoom, 0)
	for projectile in projectilesInActiveRoom:
		if projectile.projectileType == GlobalVariables.PROJECTILETYPE.PLAYER:
			GlobalVariables.turnController.playerProjectilesToMove.append(projectile)
	if GlobalVariables.turnController.playerProjectilesToMove.empty():
		GlobalVariables.turnController.player_projectiles_turn_done(null)
	else:
		GlobalVariables.turnController.playerProjectilesToMove[0].calc_projectiles_move_to(GlobalVariables.MOVEMENTATTACKCALCMODE.ACTION, 0, "player")
		var playerProjectilesToMoveCopy = GlobalVariables.turnController.playerProjectilesToMove.duplicate()
		for projectile in playerProjectilesToMoveCopy:
			projectile.move_projectile()
		playerProjectilesToMoveCopy.clear()

func on_player_turn_done_confirmed_puzzle_room():
	GlobalVariables.turnsTakenInPuzzleRoom+=1
	GlobalVariables.turnController.currentTurnWaiting = GlobalVariables.CURRENTPHASE.PLAYER
	emit_signal("enemyTurnDoneSignal")
	
func on_player_turn_done_confirmed_empty_treasure_room():
	GlobalVariables.turnController.currentTurnWaiting = GlobalVariables.CURRENTPHASE.PLAYER
	on_player_turn_done_confirmed_enemy_room()
	
func on_player_turn_done_confirmed_enemy_room():
	GlobalVariables.turnsTakenInEnemyRoom += 1
	mainPlayer.playerBackupPosition = mainPlayer.position
	for projectile in projectilesInActiveRoom:
		if projectile.projectileType == GlobalVariables.PROJECTILETYPE.ENEMY:
			GlobalVariables.turnController.enemyProjectilesToMove.append(projectile)
	if GlobalVariables.turnController.enemyProjectilesToMove.empty():
		GlobalVariables.turnController.enemy_projectiles_turn_done(null)
	else:
		GlobalVariables.turnController.enemyProjectilesToMove[0].calc_projectiles_move_to(GlobalVariables.MOVEMENTATTACKCALCMODE.ACTION, 0, "enemy")
		var tempEnenmyProjectiles = GlobalVariables.turnController.enemyProjectilesToMove.duplicate()
		for projectile in tempEnenmyProjectiles:
			projectile.move_projectile()
		tempEnenmyProjectiles.clear()
	
func on_player_projectile_turn_done_request_confirmed():
	GlobalVariables.turnController.currentTurnWaiting = GlobalVariables.CURRENTPHASE.PLAYER
	emit_signal("enemyTurnDoneSignal")

func on_enemy_projectile_turn_done_request_confirmed():
	if activeRoom != null:
		for enemy in activeRoom.enemiesInRoom:
			GlobalVariables.turnController.enemiesAttacking.append(enemy)
	var tempEnenmyToAttack = GlobalVariables.turnController.enemiesAttacking.duplicate()
	if tempEnenmyToAttack.empty():
		GlobalVariables.turnController.enemy_turn_done(null)
	else:
		for enemy in tempEnenmyToAttack:
			enemy.make_enemy_turn()
		GlobalVariables.turnController.enemiesAttacking[0].calc_enemy_attack_to(GlobalVariables.MOVEMENTATTACKCALCMODE.ACTION,activeRoom, 0)
		for enemy in tempEnenmyToAttack:
			enemy.enemyAttack()
	tempEnenmyToAttack.clear()

func on_enemy_attack_done():
	if activeRoom != null:
		for enemy in activeRoom.enemiesInRoom:
			GlobalVariables.turnController.enemiesToMove.append(enemy)
	var tempEnenmyToMove = GlobalVariables.turnController.enemiesToMove.duplicate()
	if tempEnenmyToMove.empty():
		GlobalVariables.turnController.enemy_turn_done(null)
	else:
		GlobalVariables.turnController.enemiesToMove[0].calc_enemy_move_to(GlobalVariables.MOVEMENTATTACKCALCMODE.ACTION,activeRoom, 0)
		print("making enemy move")
		for enemy in tempEnenmyToMove:
			enemy.enemyMovement()
	tempEnenmyToMove.clear()
	
func _on_ticking_projectile_made_move(projectile, projectileType):
	if cancelMagicPuzzleRoom:
		cancel_magic_in_puzzle_room()
	else:
		for projectile in projectilesInActiveRoom:
			puzzleProjectilesToMove.append(projectile)
		if puzzleProjectilesToMove.empty():
			_on_projectiles_made_move()
		else:
			for projectile in puzzleProjectilesToMove:
				projectile.move_projectile(GlobalVariables.PROJECTILETYPE.POWERBLOCK)

func _on_puzzle_piece_activated():
#check if puzzle pieces were cleared in right order 
	if activatedPuzzlePieces.size() == activeRoom.puzzlePiecesInRoom.size():
		var puzzlePieceIsBarrier = false
		for puzzlePiece in activatedPuzzlePieces:
			if puzzlePiece.isBarrier:
				puzzlePieceIsBarrier = true
		if activatedPuzzlePieces == activeRoom.puzzlePiecesInRoom && !activeRoom.roomCleared && !puzzlePieceIsBarrier:
			activatedPuzzlePieces[0].get_node("AudioStreamPlayer2D").stream = puzzleRoomClearedAudio
			activatedPuzzlePieces[0].get_node("AudioStreamPlayer2D").play()
			activeRoom.roomCleared=true
			mainPlayer.inClearedRoom = true
			GlobalVariables.countPuzzleRoomsCleared += 1
			if activeRoom.drop_loot():
				#drop extra coins if countingblocks were solved 
				var tempCountingBlocks = activeRoom.countingBlocksInRoom.duplicate()
				for countBlock in activeRoom.countingBlocksInRoom:
					GlobalVariables.turnController.countingBlocksToDelete.append(countBlock)
					if countBlock.checkLootDrop() == "penny":
						var bonusCoin = Item.instance()
						bonusCoin.position = countBlock.position
						bonusLootArray.append(bonusCoin)
						GlobalVariables.puzzleBonusLootDropped+=1
						countBlock.playAnimation("penny")
					elif countBlock.checkLootDrop() == "nickel":
						var bonusCoin = Item.instance()
						bonusCoin.position = countBlock.position
						bonusLootArray.append(bonusCoin)
						GlobalVariables.puzzleBonusLootDropped+=2
						bonusCoin.make_nickel()
						countBlock.playAnimation("nickel")
					else:
						countBlock.playAnimation("nothing")
				tempCountingBlocks.clear()
				for puzzlePiece in activatedPuzzlePieces:
					puzzlePiece.play_wrong_right_animation(true)
				GlobalVariables.turnController.queueDropLoot = true
			cancelMagicPuzzleRoom = true
			for projectile in projectilesInActiveRoom:
				projectile.get_node("Sprite").set_visible(false)
#if puzzle pieces were activated in wrong order 
		else:
			if !activeRoom.roomCleared:
				GlobalVariables.timesActivatedPuzzleWrong+=1
#				if puzzlePieceIsBarrier:
#					print("try again after activating puzzle piece barrier")
#				else:
#					print("try again activated in wrong order")
				for puzzlePiece in activatedPuzzlePieces:
						puzzlePiece.play_wrong_right_animation(false)
						
#in puzzle rooms delete all projectiles on player input after all interactions are handled 
func cancel_magic_in_puzzle_room():
	cancelMagicPuzzleRoom = false
	mainPlayer.canRepeatPuzzlePattern = true
	spawnBlockProjectileNextTurn.clear()
	activatePuzzlePieceNextTurn.clear()
	activateCountingBlockNextTurn.clear()
	var tempProjectiles = projectilesInActiveRoom.duplicate()
	for projectile in tempProjectiles:
		set_cellv(world_to_map(projectile.position),get_tileset().find_tile_by_name("FLOOR")) 
		projectile.queue_free()
	projectilesInActiveRoom.clear()
	puzzleProjectilesToMove.clear()
	tempProjectiles.clear()
	tickingProjectile.queue_free()
	tickingProjectile = null
	if !activeRoom.roomCleared:
		for puzzlePiece in activatedPuzzlePieces:
			puzzlePiece.isActivated = false
			if !puzzlePiece.isBarrier:
				puzzlePiece.get_node("AnimationPlayer").play("Idle")
				puzzlePiece.get_node("Sprite").set_self_modulate(puzzlePiece.baseModulation)
		for countBlock in activeRoom.countingBlocksInRoom:
			countBlock.reset_count()
	set_cellv(world_to_map(mainPlayer.position), get_tileset().find_tile_by_name("PLAYER"))
	GlobalVariables.turnController.stop_power_projectiles()
	
func _on_projectiles_made_move(projectile=null):
	if projectile!=null:
		puzzleProjectilesToMove.erase(projectile)
		if projectile.deleteProjectilePlayAnimation != null:
			GlobalVariables.turnController.on_projectile_interaction(projectile, true)

	if puzzleProjectilesToMove.empty():
		if activeRoom != null && activeRoom.roomType == GlobalVariables.ROOM_TYPE.PUZZLEROOM:
			var tempProjectiles = projectilesInActiveRoom.duplicate()
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
								puzzlePiece.activate_puzzle_piece()
								activatePuzzlePieceNextTurn.erase(puzzlePiece)
						else:
							puzzlePiece.activationDelay-=1
					activatePuzzlePieceNextTurnTemp.clear()

				if !activateCountingBlockNextTurn.empty():
					var activateCountingBlockNextTurnTemp = activateCountingBlockNextTurn.duplicate()
					for countBlock in activateCountingBlockNextTurnTemp:
						if countBlock.activationDelay == 0:
							countBlock.decrease_count()
							activateCountingBlockNextTurn.erase(countBlock)
						else:
							countBlock.activationDelay-=1
					activateCountingBlockNextTurnTemp.clear()
				
				for boxProjectile in spawnBlockProjectileNextTurnTempCopy:
					if boxProjectile.shootDelay == 0:
						boxProjectile.get_node("AudioStreamPlayer2D").stream = load("res://GameObjects/PowerBlock/activatePowerBlock.wav")
						boxProjectile.get_node("AudioStreamPlayer2D").play()
						#print("In boxprojectile shootdelay == 0 " + str(boxProjectile))
						if boxProjectile.get_node("PowerBlockModulate").get_modulate() == Color(0.65,0.65,1.0,1.0):
							boxProjectile.get_node("PowerBlockModulate").set_modulate(Color(randf(),randf(),randf(),1.0))
						else:
							boxProjectile.get_node("PowerBlockModulate").set_modulate(Color(0.65,0.65,1.0,1.0))
						#boxProjectile.get_node("PowerBlockModulate").set_deferred("modulate", "798aff")
						if boxProjectile == spawnBlockProjectileNextTurnTempCopy[spawnBlockProjectileNextTurnTempCopy.size()-1]:
							boxProjectile.spawn_magic_from_block(true)
							#print("Here")
						else:
							boxProjectile.spawn_magic_from_block(false)
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
							puzzlePiece.activate_puzzle_piece()
							activatePuzzlePieceNextTurn.erase(puzzlePiece)
					else:
						puzzlePiece.activationDelay-=1
				activatePuzzlePieceNextTurnTemp.clear()
				if !activateCountingBlockNextTurn.empty():
									var activateCountingBlockNextTurnTemp = activateCountingBlockNextTurn.duplicate()
									for countBlock in activateCountingBlockNextTurnTemp:
										if countBlock.activationDelay == 0:
											countBlock.decrease_count()
											activateCountingBlockNextTurn.erase(countBlock)
										else:
											countBlock.activationDelay-=1
									activateCountingBlockNextTurnTemp.clear()
			elif !activateCountingBlockNextTurn.empty():
					var activateCountingBlockNextTurnTemp = activateCountingBlockNextTurn.duplicate()
					for countBlock in activateCountingBlockNextTurnTemp:
						if countBlock.activationDelay == 0:
							countBlock.decrease_count()
							activateCountingBlockNextTurn.erase(countBlock)
						else:
							countBlock.activationDelay-=1
					activateCountingBlockNextTurnTemp.clear()
					
		if tickingProjectile != null:
			tickingProjectile.move_projectile(GlobalVariables.PROJECTILETYPE.TICKERPROJECTILE)

#handle player attack types and interactions 
func _on_Player_Attacked(player, attack_direction, attackDamage, attackType):
	randomize()
	if get_cellv(world_to_map(player.position) + attack_direction) == TILETYPES.WALL || get_cellv(world_to_map(player.position) + attack_direction) == TILETYPES.DOOR || get_cellv(world_to_map(player.position) + attack_direction) == TILETYPES.UNLOCKEDDOOR:
		return
	#activate upgrade container
	if get_cellv(world_to_map(player.position) + attack_direction) == TILETYPES.UPGRADECONTAINER:
		get_cell_pawn(world_to_map(player.position) + attack_direction).do_upgrade(player)
		return
	match attackType:
		GlobalVariables.ATTACKTYPE.SWORD:
			player_sword_attack(player, attack_direction, attackDamage, attackType)
		GlobalVariables.ATTACKTYPE.MAGIC:
			player_magic_attack(player, attack_direction, attackDamage, attackType)
		GlobalVariables.ATTACKTYPE.BLOCK:
			player_block_attack(player, attack_direction, attackDamage, attackType)
		GlobalVariables.ATTACKTYPE.HAND:
			player_hand_attack(player, attack_direction, attackDamage, attackType)

func player_sword_attack(player, attack_direction, attackDamage, attackType):
	if get_cellv(world_to_map(player.position) + attack_direction) == TILETYPES.ENEMY && attackType:
		print("Woosh Player Sword Attack hit " + str(attackDamage))
		var attackedEnemy = get_cell_pawn(world_to_map(player.position) + attack_direction)
		GlobalVariables.turnController.enemyTakeDamage.append(attackedEnemy)
		attackedEnemy.inflictDamage(attackDamage, attackType, world_to_map(player.position) + attack_direction, mainPlayer, GlobalVariables.CURRENTPHASE.PLAYER)
		
	elif get_cellv(world_to_map(player.position) + attack_direction) == TILETYPES.FLOOR && attackType:
		match attackType:
			GlobalVariables.ATTACKTYPE.SWORD:
				pass

func player_magic_attack(player, attack_direction, attackDamage, attackType):
	#use magic on block in puzzle room 
	if  activeRoom != null && activeRoom.roomType == GlobalVariables.ROOM_TYPE.PUZZLEROOM && get_cellv(world_to_map(player.position) + attack_direction) == TILETYPES.BLOCK:
		player.end_player_turn()
		player.canRepeatPuzzlePattern = false
		GlobalVariables.turnController.start_power_projectiles()
		for projectile in projectilesInActiveRoom:
			set_cellv(world_to_map(projectile.position),get_tileset().find_tile_by_name("FLOOR")) 
			projectile.queue_free()
		projectilesInActiveRoom.clear()
		set_cellv(world_to_map(player.position), get_tileset().find_tile_by_name("FLOOR")) 
		for puzzlePiece in activatedPuzzlePieces:
			if !activeRoom.roomCleared:
				puzzlePiece.isActivated=false
				puzzlePiece.get_node("Sprite").set_modulate(puzzlePiece.baseModulation)
		activatedPuzzlePieces.clear()
		var blockAttackedByMagic = get_cell_pawn(world_to_map(player.position) + attack_direction)
		for powerBlock in activeRoom.powerBlocksInRoom:
			powerBlock.get_node("PowerBlockModulate").set_deferred("modulate", "ffffff")
		blockAttackedByMagic.get_node("PowerBlockModulate").set_deferred("modulate", "798aff")
		#create ticking projectile for power block order
		if tickingProjectile == null:
			var newTickingProjectile = MagicProjectile.instance()
			newTickingProjectile.projectileType = GlobalVariables.PROJECTILETYPE.TICKERPROJECTILE
			newTickingProjectile.connect("projectileMadeMove", self, "_on_projectiles_made_move")
			newTickingProjectile.connect("tickingProjectileMadeMove", self, "_on_ticking_projectile_made_move")
			newTickingProjectile.create_ticking_projectile(activeRoom.doorRoomLeftMostCorner)
			add_child(newTickingProjectile)
			tickingProjectile = newTickingProjectile
			newTickingProjectile.move_projectile(GlobalVariables.PROJECTILETYPE.TICKERPROJECTILE)
		blockAttackedByMagic.spawn_magic_from_block(true)
	#magic enemy direct interaction
	elif get_cellv(world_to_map(player.position) + attack_direction*2) == TILETYPES.ENEMY:
		var attackedEnemy = get_cell_pawn(world_to_map(player.position) + attack_direction*2)
		var newMagicProjectile = MagicProjectile.instance()
		newMagicProjectile.set_z_index(5)
		newMagicProjectile.projectileType = GlobalVariables.PROJECTILETYPE.PLAYER
		newMagicProjectile.get_node("Sprite").set_frame(17)
		newMagicProjectile.position = player.position + map_to_world(attack_direction*2)
		add_child(newMagicProjectile)
		newMagicProjectile.play_projectile_animation(true, "attack")
		GlobalVariables.turnController.enemyTakeDamage.append(attackedEnemy)
		attackedEnemy.inflictDamage(attackDamage, attackType, world_to_map(player.position) + attack_direction*2, mainPlayer, GlobalVariables.CURRENTPHASE.PLAYER)
	#spawn magic projectile if target tile is floor
	elif get_cellv(world_to_map(player.position) + attack_direction*2) == TILETYPES.FLOOR:
		var newMagicProjectile = MagicProjectile.instance()
		newMagicProjectile.set_z_index(5)
		newMagicProjectile.get_node("Sprite").set_frame(17)
		newMagicProjectile.connect("playerEnemieProjectileMadeMove", GlobalVariables.turnController, "player_projectiles_turn_done")
		newMagicProjectile.position = player.position + map_to_world(attack_direction*2)
		newMagicProjectile.projectileType = GlobalVariables.PROJECTILETYPE.PLAYER
		newMagicProjectile.movementDirection = attack_direction
		newMagicProjectile.attackDamage = attackDamage
		newMagicProjectile.play_player_projectile_animation()
		add_child(newMagicProjectile)
		projectilesInActiveRoom.append(newMagicProjectile)
		set_cellv(world_to_map(newMagicProjectile.position), get_tileset().find_tile_by_name("MAGICPROJECTILE"))
	#magic projectile interacting with other magic projectile
	elif get_cellv(world_to_map(player.position) + attack_direction*2) == TILETYPES.MAGICPROJECTILE:
		if get_cell_pawn(world_to_map(player.position) + attack_direction*2).projectileType == GlobalVariables.PROJECTILETYPE.ENEMY:
			var projectileToErase = get_cell_pawn(world_to_map(player.position) + attack_direction*2)
			var newMagicProjectile = MagicProjectile.instance()
			newMagicProjectile.set_z_index(5)
			newMagicProjectile.projectileType = GlobalVariables.PROJECTILETYPE.PLAYER
			newMagicProjectile.get_node("Sprite").set_frame(17)
			newMagicProjectile.position = player.position + map_to_world(attack_direction*2)
			add_child(newMagicProjectile)
			newMagicProjectile.play_projectile_animation(true, "attack")
			projectilesInActiveRoom.erase(projectileToErase)
			set_cellv(world_to_map(projectileToErase.position),get_tileset().find_tile_by_name("FLOOR")) 
			projectileToErase.queue_free()
		else:
			var newMagicProjectile = MagicProjectile.instance()
			newMagicProjectile.set_z_index(5)
			newMagicProjectile.connect("playerEnemieProjectileMadeMove", GlobalVariables.turnController, "player_projectiles_turn_done")
			newMagicProjectile.position = player.position + map_to_world(attack_direction*2)
			newMagicProjectile.projectileType = GlobalVariables.PROJECTILETYPE.PLAYER
			newMagicProjectile.movementDirection = attack_direction
			add_child(newMagicProjectile)
			projectilesInActiveRoom.append(newMagicProjectile)
			newMagicProjectile.play_player_projectile_animation()
			magic_projectile_magic_projectile_interaction(newMagicProjectile, get_cell_pawn(world_to_map(player.position) + attack_direction*2))

func player_block_attack(player, attack_direction, attackDamage, attackType):
	#spawn new bloock if tile is floor
	if get_cellv(world_to_map(player.position) + attack_direction) == TILETYPES.FLOOR:
		player.waitingForEventBeforeContinue = false
		var newPowerBlock = PowerBlock.instance()
		if activeRoom != null && activeRoom.roomType == GlobalVariables.ROOM_TYPE.PUZZLEROOM:
			newPowerBlock.get_node("PowerBlockModulate/Sprite").set_frame(23)
		else:
			newPowerBlock.get_node("PowerBlockModulate/Sprite").set_frame(21)
		newPowerBlock.position = player.position + map_to_world(attack_direction)
		add_child(newPowerBlock)
		newPowerBlock.set_z_index(2)
		if(activeRoom != null):
			activeRoom.powerBlocksInRoom.append(newPowerBlock)
		set_cellv(world_to_map(player.position) + attack_direction, get_tileset().find_tile_by_name("BLOCK"))
	#interact with block in different room types 
	elif get_cellv(world_to_map(player.position) + attack_direction) == get_tileset().find_tile_by_name("BLOCK"):
		var powerBlockToDelete = get_cell_pawn(world_to_map(player.position) + attack_direction)
		if activeRoom != null:
			if activeRoom.roomType == GlobalVariables.ROOM_TYPE.PUZZLEROOM:
				player.waitingForEventBeforeContinue = false
				activeRoom.powerBlocksInRoom.erase(powerBlockToDelete)
				powerBlockToDelete.queue_free()
				set_cellv(world_to_map(player.position) + attack_direction, get_tileset().find_tile_by_name("FLOOR"))
			elif activeRoom.roomType == GlobalVariables.ROOM_TYPE.ENEMYROOM:
				if powerBlockToDelete.explode_block():
					pass
				else:
					player.waitingForEventBeforeContinue = false
					activeRoom.powerBlocksInRoom.erase(powerBlockToDelete)
					powerBlockToDelete.queue_free()
					set_cellv(world_to_map(player.position) + attack_direction, get_tileset().find_tile_by_name("FLOOR"))
			elif activeRoom.roomType == GlobalVariables.ROOM_TYPE.EMPTYTREASUREROOM:
				if powerBlockToDelete.explode_block():
					player.waitingForEventBeforeContinue = true
				else:
					player.waitingForEventBeforeContinue = false
					if activeRoom!= null:
						activeRoom.powerBlocksInRoom.erase(powerBlockToDelete)
					powerBlockToDelete.queue_free()
					set_cellv(world_to_map(player.position) + attack_direction, get_tileset().find_tile_by_name("FLOOR"))
			
		else:
			if powerBlockToDelete.explode_block():
				player.waitingForEventBeforeContinue = true
			else:
				player.waitingForEventBeforeContinue = false
				if activeRoom!= null:
					activeRoom.powerBlocksInRoom.erase(powerBlockToDelete)
				powerBlockToDelete.queue_free()
				set_cellv(world_to_map(player.position) + attack_direction, get_tileset().find_tile_by_name("FLOOR"))
	else:
		player.waitingForEventBeforeContinue = false
		

func player_hand_attack(player, attack_direction, attackDamage, attackType):
	#hand interaction on block 
	if get_cellv(world_to_map(player.position) + attack_direction) == TILETYPES.BLOCK:
		var interactionBlock = get_cell_pawn(world_to_map(player.position) + attack_direction)
		if activeRoom == null || activeRoom != null && activeRoom.roomType == GlobalVariables.ROOM_TYPE.ENEMYROOM || activeRoom != null && activeRoom.roomType == GlobalVariables.ROOM_TYPE.EMPTYTREASUREROOM:
			for restCount in attackDamage:
				interactionBlock.add_count()
		elif activeRoom.roomType == GlobalVariables.ROOM_TYPE.PUZZLEROOM:
			player.puzzleBlockInteraction = true
			activatedPuzzleBlock = interactionBlock
	#swap position player enemy 
	elif get_cellv(world_to_map(player.position) + attack_direction) == TILETYPES.ENEMY:
		var enemyToSwap = get_cell_pawn(world_to_map(player.position) + attack_direction)
		enemyToSwap.position = player.position
		player.position = player.position + map_to_world(attack_direction)
		set_cellv(world_to_map(enemyToSwap.position), get_tileset().find_tile_by_name("ENEMY"))
		set_cellv(world_to_map(player.position), get_tileset().find_tile_by_name("PLAYER"))
		enemyToSwap.calc_enemy_attack_to(GlobalVariables.MOVEMENTATTACKCALCMODE.PREVIEW, activeRoom, 0)
	#swap position player puzzle piece 
	elif get_cellv(world_to_map(player.position) + attack_direction) == TILETYPES.PUZZLEPIECE:
		var puzzlePieceToSwap = get_cell_pawn(world_to_map(player.position) + attack_direction)
		puzzlePieceToSwap.position = player.position
		player.position = player.position + map_to_world(attack_direction)
		set_cellv(world_to_map(puzzlePieceToSwap.position), get_tileset().find_tile_by_name("PUZZLEPIECE"))
		set_cellv(world_to_map(player.position), get_tileset().find_tile_by_name("PLAYER"))
	#swap position player countingblock
	elif get_cellv(world_to_map(player.position) + attack_direction) == TILETYPES.COUNTINGBLOCK:
		var puzzlePieceToSwap = get_cell_pawn(world_to_map(player.position) + attack_direction)
		puzzlePieceToSwap.position = player.position
		player.position = player.position + map_to_world(attack_direction)
		set_cellv(world_to_map(puzzlePieceToSwap.position), get_tileset().find_tile_by_name("COUNTINGBLOCK"))
		set_cellv(world_to_map(player.position), get_tileset().find_tile_by_name("PLAYER"))
	#swap position player magicprojectile 
	elif get_cellv(world_to_map(player.position) + attack_direction) == TILETYPES.MAGICPROJECTILE:
		var magicProjectileToSwap = get_cell_pawn(world_to_map(player.position) + attack_direction)
		magicProjectileToSwap.position = player.position
		player.position = player.position + map_to_world(attack_direction)
		set_cellv(world_to_map(magicProjectileToSwap.position), get_tileset().find_tile_by_name("MAGICPROJECTILE"))
		set_cellv(world_to_map(player.position), get_tileset().find_tile_by_name("PLAYER"))
		
func on_puzzle_Block_interaction(player, puzzleBlockDirection):
	activatedPuzzleBlock.interact_power_block(puzzleBlockDirection, activeRoom.roomType)
	
func on_Power_Block_explode(powerBlock):
	var blocksHitByExplosion = []
	var enemiesHitByExplosion = []
	if get_cellv(world_to_map(powerBlock.position)+Vector2(1,0)) == get_tileset().find_tile_by_name("ENEMY"):
		enemiesHitByExplosion.append(get_cell_pawn(world_to_map(powerBlock.position)+Vector2(1,0)))
	if get_cellv(world_to_map(powerBlock.position)+Vector2(-1,0)) == get_tileset().find_tile_by_name("ENEMY"):
		enemiesHitByExplosion.append(get_cell_pawn(world_to_map(powerBlock.position)+Vector2(-1,0)))
	if get_cellv(world_to_map(powerBlock.position)+Vector2(0,1)) == get_tileset().find_tile_by_name("ENEMY"):
		enemiesHitByExplosion.append(get_cell_pawn(world_to_map(powerBlock.position)+Vector2(0,1)))
	if get_cellv(world_to_map(powerBlock.position)+Vector2(0,-1)) == get_tileset().find_tile_by_name("ENEMY"):
		enemiesHitByExplosion.append(get_cell_pawn(world_to_map(powerBlock.position)+Vector2(0,-1)))
	if get_cellv(world_to_map(powerBlock.position)+Vector2(1,1)) == get_tileset().find_tile_by_name("ENEMY"):
		enemiesHitByExplosion.append(get_cell_pawn(world_to_map(powerBlock.position)+Vector2(1,1)))
	if get_cellv(world_to_map(powerBlock.position)+Vector2(1,-1)) == get_tileset().find_tile_by_name("ENEMY"):
		enemiesHitByExplosion.append(get_cell_pawn(world_to_map(powerBlock.position)+Vector2(1,-1)))
	if get_cellv(world_to_map(powerBlock.position)+Vector2(-1,1)) == get_tileset().find_tile_by_name("ENEMY"):
		enemiesHitByExplosion.append(get_cell_pawn(world_to_map(powerBlock.position)+Vector2(-1,1)))
	if get_cellv(world_to_map(powerBlock.position)+Vector2(-1,-1)) == get_tileset().find_tile_by_name("ENEMY"):
		enemiesHitByExplosion.append(get_cell_pawn(world_to_map(powerBlock.position)+Vector2(-1,-1)))

	if get_cellv(world_to_map(powerBlock.position)+Vector2(1,0)) == get_tileset().find_tile_by_name("BLOCK"):
		blocksHitByExplosion.append(get_cell_pawn(world_to_map(powerBlock.position)+Vector2(1,0)))
	if get_cellv(world_to_map(powerBlock.position)+Vector2(-1,0)) == get_tileset().find_tile_by_name("BLOCK"):
		blocksHitByExplosion.append(get_cell_pawn(world_to_map(powerBlock.position)+Vector2(-1,0)))
	if get_cellv(world_to_map(powerBlock.position)+Vector2(0,1)) == get_tileset().find_tile_by_name("BLOCK"):
		blocksHitByExplosion.append(get_cell_pawn(world_to_map(powerBlock.position)+Vector2(0,1)))
	if get_cellv(world_to_map(powerBlock.position)+Vector2(0,-1)) == get_tileset().find_tile_by_name("BLOCK"):
		blocksHitByExplosion.append(get_cell_pawn(world_to_map(powerBlock.position)+Vector2(0,-1)))
	if get_cellv(world_to_map(powerBlock.position)+Vector2(1,1)) == get_tileset().find_tile_by_name("BLOCK"):
		blocksHitByExplosion.append(get_cell_pawn(world_to_map(powerBlock.position)+Vector2(1,1)))
	if get_cellv(world_to_map(powerBlock.position)+Vector2(1,-1)) == get_tileset().find_tile_by_name("BLOCK"):
		blocksHitByExplosion.append(get_cell_pawn(world_to_map(powerBlock.position)+Vector2(1,-1)))
	if get_cellv(world_to_map(powerBlock.position)+Vector2(-1,1)) == get_tileset().find_tile_by_name("BLOCK"):
		blocksHitByExplosion.append(get_cell_pawn(world_to_map(powerBlock.position)+Vector2(-1,1)))
	if get_cellv(world_to_map(powerBlock.position)+Vector2(-1,-1)) == get_tileset().find_tile_by_name("BLOCK"):
		blocksHitByExplosion.append(get_cell_pawn(world_to_map(powerBlock.position)+Vector2(-1,-1)))
		
	for enemy in enemiesHitByExplosion:
		GlobalVariables.turnController.enemyTakeDamage.append(enemy)
		enemy.inflictDamage(powerBlock.counters * mainPlayer.powerBlockAttackDamage, GlobalVariables.ATTACKTYPE.BLOCK, world_to_map(enemy.position), mainPlayer, GlobalVariables.CURRENTPHASE.PLAYER)
	enemiesHitByExplosion.clear()
	
	for block in blocksHitByExplosion:
		block.explode_block()
	blocksHitByExplosion.clear()  
	if activeRoom != null:
		activeRoom.powerBlocksInRoom.erase(powerBlock)
	set_cellv(world_to_map(powerBlock.position), get_tileset().find_tile_by_name("FLOOR"))
	GlobalVariables.turnController.on_block_exploding(powerBlock)
	
#if powerBlock is activated in puzzle rooms spawns projectiles
func on_powerBlock_spawn_magic(powerBlock, signalSpawnMagic):
	var surroundedByObstaclesCount = 0
	var blockCanSpawnMagic = false
	mainPlayer.disablePlayerInput = true
	for direction in powerBlock.activeDirections:
		var newMagicProjectile = MagicProjectile.instance()
		newMagicProjectile.set_z_index(5)
		add_child(newMagicProjectile)
		newMagicProjectile.projectileType = GlobalVariables.PROJECTILETYPE.POWERBLOCK
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
		#activationDelay handles right spawn rate of projectiles 
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
			projectilesInActiveRoom.append(newMagicProjectile)
			var activatedPuzzlePiece = get_cell_pawn(world_to_map(newMagicProjectile.position)+newMagicProjectile.movementDirection)
			if !activatePuzzlePieceNextTurn.has(activatedPuzzlePiece):
				activatePuzzlePieceNextTurn.append(activatedPuzzlePiece)
				if !projectilesInActiveRoom.empty():
					activatedPuzzlePiece.activationDelay = 1
				else:
					activatedPuzzlePiece.activationDelay = 1
			newMagicProjectile.deleteProjectilePlayAnimation="delete"
			
		elif get_cellv(world_to_map(newMagicProjectile.position)+newMagicProjectile.movementDirection) == get_tileset().find_tile_by_name("BLOCK"):
			projectilesInActiveRoom.append(newMagicProjectile)
			var blockHit = get_cell_pawn(world_to_map(newMagicProjectile.position)+newMagicProjectile.movementDirection)
			if !spawnBlockProjectileNextTurn.has(blockHit):
				spawnBlockProjectileNextTurn.append(blockHit)
				if !projectilesInActiveRoom.empty():
					blockHit.shootDelay = 1
				else:
					blockHit.shootDelay = 1
			newMagicProjectile.deleteProjectilePlayAnimation="delete"
		
		elif get_cellv(world_to_map(newMagicProjectile.position)) == get_tileset().find_tile_by_name("COUNTINGBLOCK"):
			var activatedCountBlock = get_cell_pawn(world_to_map(newMagicProjectile.position))
			if !activateCountingBlockNextTurn.has(activatedCountBlock):
				activateCountingBlockNextTurn.append(activatedCountBlock)
				if !projectilesInActiveRoom.empty():
					activatedCountBlock.activationDelay = 0
				else:
					activatedCountBlock.activationDelay = 0
			newMagicProjectile.queue_free()
			
		elif get_cellv(world_to_map(newMagicProjectile.position)+newMagicProjectile.movementDirection) == get_tileset().find_tile_by_name("COUNTINGBLOCK"):
			projectilesInActiveRoom.append(newMagicProjectile)
			var activatedCountBlock = get_cell_pawn(world_to_map(newMagicProjectile.position)+newMagicProjectile.movementDirection)
			if !activateCountingBlockNextTurn.has(activatedCountBlock):
				activateCountingBlockNextTurn.append(activatedCountBlock)
				if !projectilesInActiveRoom.empty():
					activatedCountBlock.activationDelay = 1
				else:
					activatedCountBlock.activationDelay = 1
			newMagicProjectile.deleteProjectilePlayAnimation="delete"
			
		elif get_cellv(world_to_map(newMagicProjectile.position)) == get_tileset().find_tile_by_name("FLOOR") || get_cellv(world_to_map(newMagicProjectile.position)) == get_tileset().find_tile_by_name("PLAYER"):
			projectilesInActiveRoom.append(newMagicProjectile)
		else: 
			newMagicProjectile.play_projectile_animation(false, "delete")
			
	mainPlayer.disablePlayerInput = false
	
func _on_enemy_attacked(enemy, attackCell, attackType, attackDamage, attackCellArray=null):
	var attackCellSingleAttack = null
	if attackCell.size()>=1:
		attackCellSingleAttack = attackCell[0]
		for cell in attackCell:
			if get_cellv(cell) == TILETYPES.PLAYER:
				attackCellSingleAttack = cell
	#attacks cells that were targeted in calculation 
	if attackCellSingleAttack != null && attackType != GlobalVariables.ATTACKTYPE.MAGIC:
		var attackedNode = get_cell_pawn(attackCellSingleAttack)
		print(attackedNode)
		if get_cellv(attackCellSingleAttack) == TILETYPES.PLAYER:
			attackedNode.inflict_damage_playerDefeated(attackDamage, attackType, enemy.enemyType)
		elif get_cellv(attackCellSingleAttack) == TILETYPES.ENEMY && get_cell_pawn(attackCellSingleAttack).helpEnemy:
			attackedNode.inflictDamage(attackDamage, attackType, attackCellSingleAttack, mainPlayer, GlobalVariables.CURRENTPHASE.ENEMYATTACK)
		else:
			GlobalVariables.turnController.on_enemy_taken_damage(attackedNode)
		
	elif attackType == GlobalVariables.ATTACKTYPE.MAGIC && !attackCell.empty():
		for cell in attackCell:
			var attackedNode = get_cell_pawn(cell)
			var newMagicProjectile = MagicProjectile.instance()
			newMagicProjectile.set_z_index(2)
			newMagicProjectile.projectileType = GlobalVariables.PROJECTILETYPE.ENEMY
			newMagicProjectile.get_node("Sprite").set_frame(0)
			newMagicProjectile.position = map_to_world(cell)+GlobalVariables.tileOffset
			add_child(newMagicProjectile)
			newMagicProjectile.play_projectile_animation(true, "attack")
			attackCellArray.erase(cell)
			if get_cellv(cell) == TILETYPES.PLAYER:
				attackedNode.inflict_damage_playerDefeated(attackDamage, attackType, enemy.enemyType)
			elif get_cellv(cell) == TILETYPES.ENEMY && attackedNode.helpEnemy:
				attackedNode.inflictDamage(attackDamage, attackType, cell, mainPlayer, GlobalVariables.CURRENTPHASE.ENEMYATTACK)
			else:
				GlobalVariables.turnController.on_enemy_taken_damage(attackedNode)
			
	#spawns magic projectiles that did not hit object 
	if (attackType == GlobalVariables.ATTACKTYPE.MAGIC):
		for attackCell in attackCellArray:
			if(get_cellv(attackCell)==TILETYPES.FLOOR):
				var newMagicProjectile = MagicProjectile.instance()
				newMagicProjectile.set_z_index(5)
				newMagicProjectile.get_node("Sprite").set_frame(0)
				newMagicProjectile.connect("playerEnemieProjectileMadeMove", GlobalVariables.turnController, "enemy_projectiles_turn_done")
				newMagicProjectile.position = map_to_world(attackCell)+GlobalVariables.tileOffset
				newMagicProjectile.movementDirection = Vector2(0,0)
				newMagicProjectile.projectileType = GlobalVariables.PROJECTILETYPE.ENEMY
				add_child(newMagicProjectile)
				projectilesInActiveRoom.append(newMagicProjectile)
				set_cellv(world_to_map(newMagicProjectile.position), get_tileset().find_tile_by_name("MAGICPROJECTILE"))
				newMagicProjectile.play_enemy_projectile_animation()

#after all interactions are done resets player to start and resets stats
func on_Player_Defeated():
	if activeRoom != null:
		for enemy in activeRoom.enemiesInRoom:
			enemy.isDisabled=true
			enemy.turn_off_danger_fields_on_exit_room()
		set_cellv(world_to_map(mainPlayer.position),get_tileset().find_tile_by_name("FLOOR")) 
		emit_signal("moveCameraSignal", null)
		mainPlayer.do_on_player_defeated()

	if(activeRoom != null && activeRoom.enemiesInRoom.size() != 0):
		#disable elements in room just left
		for element in activeRoom.enemiesInRoom:
			element.isDisabled = true
			element.turn_off_danger_fields_on_exit_room()
	for projectile in projectilesInActiveRoom:
		set_cellv(world_to_map(projectile.position),get_tileset().find_tile_by_name("FLOOR")) 
		projectile.queue_free()
	projectilesInActiveRoom.clear()
	activeRoom = null
	mainPlayer.get_node("Sprite").set_visible(true)
					
					
func _on_enemy_defeated(enemy):
	activeRoom.enemiesInRoom.erase(enemy)
	#if all enemies are defeated reset room to cleared
	if activeRoom.enemiesInRoom.size() == 0:
		#delete all projectiles 
		for projectile in projectilesInActiveRoom:
			set_cellv(world_to_map(projectile.position),get_tileset().find_tile_by_name("FLOOR")) 
			projectile.queue_free()
		projectilesInActiveRoom.clear()
		if activeRoom.drop_loot() && !activeRoom.roomCleared:
			GlobalVariables.turnController.queueDropLoot = true
		activeRoom.roomCleared=true
		mainPlayer.inClearedRoom = true
		allEnemiesAlreadySaved = false
		GlobalVariables.turnController.on_enemy_taken_damage(enemy, true)
		GlobalVariables.countEnemyRoomsCleared += 1
		return 
	#if you were able to save help enemy it eliminates itself and gives extra reward
	else:
		var allSaved = 0
		for enemy in activeRoom.enemiesInRoom:
			if enemy.helpEnemy:
				allSaved+=1
		if allSaved == activeRoom.enemiesInRoom.size() && !allEnemiesAlreadySaved:
			allEnemiesAlreadySaved = true
			#so that all help enemies play defeated animation in each current phase 
			GlobalVariables.turnController.currentTurnWaiting = GlobalVariables.CURRENTPHASE.ENEMYATTACK
			for enemy in activeRoom.enemiesInRoom:
				var bonusCoin = Item.instance()
				bonusCoin.position = enemy.position
				bonusLootArray.append(bonusCoin)
				GlobalVariables.enemyBonusLootDropped+=1
				GlobalVariables.turnController.enemyTakeDamage.append(enemy)
				enemy.inflictDamage(100, GlobalVariables.ATTACKTYPE.SAVED, world_to_map(enemy.position), mainPlayer, GlobalVariables.turnController.currentTurnWaiting)
	GlobalVariables.turnController.on_enemy_taken_damage(enemy, true)
	
func dropLootInActiveRoom():
	dropBonusLoot()
	#create loot currently matching with closed doord 
	#calculating chance of dropping key item 
	var dropKeyItem = false
	if currentNumberRoomsgenerated-numberRoomsCleared >= 1:
		dropKeyItem = true
	elif currentNumberRoomsgenerated-numberRoomsCleared > 0:
		if randi()%100 > randi()%30+20:
			dropKeyItem = true
	if !barrierKeysNoSolution.empty() && dropKeyItem:
		#create key and spawn it on floor spawn one left of player if player is in the middle of the room
		var itemToGenerate = barrierKeysNoSolution[randi()%barrierKeysNoSolution.size()]
		barrierKeysSolutionSpawned.append(itemToGenerate)
		barrierKeysNoSolution.erase(itemToGenerate)
		var newItemPosition = activeRoom.doorRoomLeftMostCorner + map_to_world(activeRoom.roomSize/2)
		var itemPosMover = Vector2(0,1)
		while get_cellv(world_to_map(newItemPosition)) == TILETYPES.PLAYER || get_cellv(world_to_map(newItemPosition)) == TILETYPES.PUZZLEPIECE || get_cellv(world_to_map(newItemPosition)) == TILETYPES.ITEM:
			newItemPosition += map_to_world(itemPosMover)
			if itemPosMover.x >= itemPosMover.y:
				itemPosMover += Vector2(0,1)
			else:
				itemPosMover += Vector2(1,0)
		itemToGenerate.position = newItemPosition
		if get_cellv(world_to_map(itemToGenerate.position))==TILETYPES.BLOCK:
			activeRoom.powerBlocksInRoom.erase(get_cell_pawn(world_to_map(itemToGenerate.position)))
			get_cell_pawn(world_to_map(itemToGenerate.position)).queue_free()
		if  get_cellv(world_to_map(newItemPosition)) == TILETYPES.ENEMY:
			get_cell_pawn(world_to_map(itemToGenerate.position)).queue_free()
		add_child(itemToGenerate)
		set_cellv(world_to_map(itemToGenerate.position), get_tileset().find_tile_by_name("ITEM"))
#moves item around room until empty spot is found 
	else:
		var newItem = Item.instance()
		newItem.set_z_index(1)
		var newItemPosition = activeRoom.doorRoomLeftMostCorner + map_to_world(activeRoom.roomSize/2)
		var itemPosMover = Vector2(0,1)
		while(get_cellv(world_to_map(newItemPosition)) == TILETYPES.PLAYER || get_cellv(world_to_map(newItemPosition)) == TILETYPES.PUZZLEPIECE) || get_cellv(world_to_map(newItemPosition)) == TILETYPES.ITEM:
			newItemPosition += map_to_world(itemPosMover)
			if itemPosMover.x >= itemPosMover.y:
				itemPosMover += Vector2(0,1)
			else:
				itemPosMover += Vector2(1,0)
		newItem.position = newItemPosition
		if get_cellv(world_to_map(newItem.position))==TILETYPES.BLOCK:
			activeRoom.powerBlocksInRoom.erase(get_cell_pawn(world_to_map(newItem.position)))
			get_cell_pawn(world_to_map(newItem.position)).queue_free()
		if  get_cellv(world_to_map(newItemPosition)) == TILETYPES.ENEMY:
			get_cell_pawn(world_to_map(newItem.position)).queue_free()
		newItem.keyValue = str(0)
		var spawnedExit = false
		#spawns exit if in last room and exit not spawned
		if numberRoomsCleared == GlobalVariables.maxNumberRooms && !exitSpawned:
			newItem.setTexture(GlobalVariables.ITEMTYPE.EXIT)
			exitSpawned = true
			spawnedExit = true
		#the closer to max rooms spawned the higher the chance of an exit spawning 
		elif numberRoomsCleared >= GlobalVariables.maxNumberRooms*0.7 && !exitSpawned:
			if randi()%(GlobalVariables.maxNumberRooms - numberRoomsCleared) == 0:
				newItem.setTexture(GlobalVariables.ITEMTYPE.EXIT)
				exitSpawned = true
				spawnedExit = true
		#drop nonkey item with varying chances 
		if !spawnedExit:
			var nonKeyItemToDrop = randi()%100
			if nonKeyItemToDrop < 5:
				newItem.setTexture(GlobalVariables.ITEMTYPE.COIN)
				newItem.get_node("Sprite").set_scale(Vector2(0.5,0.5))
				newItem.get_node("Sprite").set_offset(Vector2(0,10))
				newItem.keyValue = str(0)
				newItem.make_nickel()
			elif nonKeyItemToDrop < (40*GlobalVariables.globalDifficultyMultiplier):
				newItem.setTexture(GlobalVariables.ITEMTYPE.COIN)
				newItem.get_node("Sprite").set_scale(Vector2(0.5,0.5))
				newItem.get_node("Sprite").set_offset(Vector2(0,10))
				newItem.keyValue = str(0)
			elif nonKeyItemToDrop < 70:
				newItem.setTexture(GlobalVariables.ITEMTYPE.FILLUPHALFHEART)
			elif nonKeyItemToDrop < 95:
				newItem.setTexture(GlobalVariables.ITEMTYPE.FILLUPHEART)
			else:
				newItem.setTexture(GlobalVariables.ITEMTYPE.POTION)
		add_child(newItem)
		set_cellv(world_to_map(newItem.position), get_tileset().find_tile_by_name("ITEM"))

#if bonus objectives successfully cleared drop bonus loot 
func dropBonusLoot():
	for object in bonusLootArray:
		object.set_z_index(1)
		object.get_node("Sprite").set_scale(Vector2(0.5,0.5))
		object.get_node("Sprite").set_offset(Vector2(0,10))
		object.keyValue = str(0)
		if object.coinValue == 5:
			object.make_nickel()
		else:
			object.setTexture(GlobalVariables.ITEMTYPE.COIN)
		add_child(object)
		set_cellv(world_to_map(object.position), get_tileset().find_tile_by_name("ITEM"))
		
#if a barrier is created create corresponding key item to drop 
func generate_keyValue_item(keyValue, modulation, type, barrierRoom):
	var newItem = Item.instance()
	newItem.set_z_index(1)
	newItem.keyValue = keyValue
	newItem.modulation = modulation
	newItem.get_node("Sprite").set_modulate(newItem.modulation)
	newItem.itemType = type
	newItem.setTexture(type)
	barrierKeysNoSolution.append(newItem)
	barrierRoom.setBoxMapItems(newItem)
	
func create_starting_room(startingRoom=false):
	create_walls(null, startingRoom, true)
	update_bitmask_region()

func create_walls (door = null, startingRoom = false, createDoors = false):
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
	var disableSmall = false
	var horizontalRandom = randi()%2+1
	var verticalRandom = randi()%2+1
	#creates rooms according to the chosen option 
	match GlobalVariables.globaleRoomLayout:
		GlobalVariables.ROOMLAYOUT.MIXED:
			horizontalRandom = randi()%2+1
			verticalRandom = randi()%2+1
		GlobalVariables.ROOMLAYOUT.SMALL:
			horizontalRandom = 1
			verticalRandom = 1
		GlobalVariables.ROOMLAYOUT.BIG:
			horizontalRandom = 2
			verticalRandom = 2
		GlobalVariables.ROOMLAYOUT.BIGSMALL:
			disableSmall = true
			while horizontalRandom == 1 && verticalRandom == 2 || horizontalRandom == 2 && verticalRandom == 1:
				horizontalRandom = randi()%2+1
				verticalRandom = randi()%2+1
		GlobalVariables.ROOMLAYOUT.LONG:
			while horizontalRandom == 1 && verticalRandom == 1 || horizontalRandom == 2 && verticalRandom == 2:
				horizontalRandom = randi()%2+1
				verticalRandom = randi()%2+1
		GlobalVariables.ROOMLAYOUT.SMALLLONG:
			while horizontalRandom == 2 && verticalRandom == 2:
				horizontalRandom = randi()%2+1
				verticalRandom = randi()%2+1
		GlobalVariables.ROOMLAYOUT.BIGLONG:
			while horizontalRandom == 1 && verticalRandom == 1:
				horizontalRandom = randi()%2+1
				verticalRandom = randi()%2+1
	#defines direction room is build towards if not small room 
	var randUpDown = randi()%2+1
	var randLeftRight = randi()%2+1
	#guarantee one direction if rooms must be big and starting room has more than 2 doors
	#otherwise overlaps 
	if startingRoomDoorsCount > 2 && GlobalVariables.globaleRoomLayout == GlobalVariables.ROOMLAYOUT.BIG:
		randUpDown = 1
		randLeftRight = 1
	if(startingRoom):
		leftmostCorner = GlobalVariables.tileOffset
	else:
		var minRoomSize = roomSizeHorizontal
		
		match door.doorDirection:
			"LEFT":
				#see if there are any cross section and diasble this option to keep tiles from intersecting
				leftmostCorner=world_to_map(door.position-map_to_world(Vector2(minRoomSize, minRoomSize/2-evenOddModifier)))
				if(get_cellv(leftmostCorner-Vector2(0,1)) == TILETYPES.WALL):
					disableUp = true
				#check for wall down for room to be created 
				if(get_cellv(leftmostCorner+Vector2(0,minRoomSize)) == TILETYPES.WALL):
					disableDown = true
				#check for wall long for room to be created 
				if(get_cellv(leftmostCorner-Vector2(1,0)) == TILETYPES.WALL):
					disableLong = true
				#randomize and create different room sizes and layout types
				if(get_cellv(leftmostCorner+Vector2(minRoomSize, minRoomSize)) == TILETYPES.WALL && get_cellv(leftmostCorner+Vector2(minRoomSize-1, minRoomSize)) == TILETYPES.WALL && get_cellv(leftmostCorner+Vector2(minRoomSize, minRoomSize-1)) == TILETYPES.WALL && get_cellv(leftmostCorner+Vector2(minRoomSize-1, minRoomSize-1)) == TILETYPES.WALL):
					disableBig = true
				if(disableBig == true && horizontalRandom == 2 && horizontalRandom == 2):
					if(randi()%2+1 == 1):
						verticalRandom = 1 
						horizontalRandom = randi()%2+1
					else:
						verticalRandom = randi()%2+1
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
				if(horizontalRandom == 2 && verticalRandom == 2):
					if(randUpDown==1):
						leftmostCorner=door.position-map_to_world(Vector2(roomSizeHorizontal, roomSizeVertical - roomSizeVertical/4 - 1))
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
				#set room size and door leftmost corner in door connecting to room to be used for further room creation
				door.doorRoomLeftMostCorner = leftmostCorner
				door.doorLocationDirection = "LEFT"
				door.roomSizeMultiplier = Vector2(horizontalRandom, verticalRandom)
				door.roomSize = Vector2(roomSizeHorizontal, roomSizeVertical)
			"RIGHT":
				if randUpDown == 1 && GlobalVariables.globaleRoomLayout == GlobalVariables.ROOMLAYOUT.BIG:
					randUpDown=2
				leftmostCorner=world_to_map(door.position+map_to_world(Vector2(1,0)-Vector2(0, minRoomSize/2 - evenOddModifier)))
				if(get_cellv(leftmostCorner-Vector2(0,1)) == TILETYPES.WALL):
					disableUp = true
				if(get_cellv(leftmostCorner+Vector2(0,minRoomSize)) == TILETYPES.WALL):
					disableDown = true
				if(get_cellv(leftmostCorner+Vector2(minRoomSize,0)) == TILETYPES.WALL):
					disableLong = true
				if(get_cellv(leftmostCorner+Vector2(minRoomSize, minRoomSize)) == TILETYPES.WALL && get_cellv(leftmostCorner+Vector2(minRoomSize-1, minRoomSize)) == TILETYPES.WALL && get_cellv(leftmostCorner+Vector2(minRoomSize, minRoomSize-1)) == TILETYPES.WALL && get_cellv(leftmostCorner+Vector2(minRoomSize-1, minRoomSize-1)) == TILETYPES.WALL):
					disableBig = true
				if(disableBig == true && horizontalRandom == 2 && horizontalRandom == 2):
					if(randi()%2+1 == 1):
						verticalRandom = 1 
						horizontalRandom = randi()%2+1
					else:
						verticalRandom = randi()%2+1
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
				
				if(horizontalRandom == 2 && verticalRandom == 2):
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
				door.doorRoomLeftMostCorner = leftmostCorner
				door.doorLocationDirection = "RIGHT"
				door.roomSizeMultiplier = Vector2(horizontalRandom, verticalRandom)
				door.roomSize = Vector2(roomSizeHorizontal, roomSizeVertical)
			"UP":
				if randLeftRight == 1 && GlobalVariables.globaleRoomLayout == GlobalVariables.ROOMLAYOUT.BIG:
					randLeftRight = 2
				leftmostCorner=world_to_map(door.position-map_to_world(Vector2(minRoomSize/2  - evenOddModifier, minRoomSize)))
				if(get_cellv(leftmostCorner-Vector2(1,0)) == TILETYPES.WALL):
					disableLeft = true
				if(get_cellv(leftmostCorner+Vector2(minRoomSize,0)) == TILETYPES.WALL):
					disableRight = true
				if(get_cellv(leftmostCorner-Vector2(0,1)) == TILETYPES.WALL):
					disableLong = true
				if(get_cellv(leftmostCorner+Vector2(minRoomSize, minRoomSize)) == TILETYPES.WALL && get_cellv(leftmostCorner+Vector2(minRoomSize-1, minRoomSize)) == TILETYPES.WALL && get_cellv(leftmostCorner+Vector2(minRoomSize, minRoomSize-1)) == TILETYPES.WALL && get_cellv(leftmostCorner+Vector2(minRoomSize-1, minRoomSize-1)) == TILETYPES.WALL):
					disableBig = true
				if(disableBig == true && horizontalRandom == 2 && horizontalRandom == 2):
					if(randi()%2+1 == 1):
						verticalRandom = 1 
						horizontalRandom = randi()%2+1
					else:
						verticalRandom = randi()%2+1
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
				
				if(horizontalRandom == 2 && verticalRandom == 2):
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
				door.doorRoomLeftMostCorner = leftmostCorner
				door.doorLocationDirection = "UP"
				door.roomSizeMultiplier = Vector2(horizontalRandom, verticalRandom)
				door.roomSize = Vector2(roomSizeHorizontal, roomSizeVertical)
			"DOWN":
				leftmostCorner=world_to_map(door.position-map_to_world(Vector2(minRoomSize/2 - evenOddModifier, -1)))
				if(get_cellv(leftmostCorner-Vector2(1,0)) == TILETYPES.WALL):
					disableLeft = true
				if(get_cellv(leftmostCorner+Vector2(minRoomSize,0)) == TILETYPES.WALL):
					disableRight = true
				if get_cellv(leftmostCorner+Vector2(0, minRoomSize)) == TILETYPES.WALL:
					disableLong = true
				if(get_cellv(leftmostCorner+Vector2(minRoomSize, minRoomSize)) == TILETYPES.WALL && get_cellv(leftmostCorner+Vector2(minRoomSize-1, minRoomSize)) == TILETYPES.WALL && get_cellv(leftmostCorner+Vector2(minRoomSize, minRoomSize-1)) == TILETYPES.WALL && get_cellv(leftmostCorner+Vector2(minRoomSize-1, minRoomSize-1)) == TILETYPES.WALL):
					disableBig = true
				
				if(disableBig == true && horizontalRandom == 2 && horizontalRandom == 2):
					if(randi()%2+1 == 1):
						verticalRandom = 1 
						horizontalRandom = randi()%2+1
					else:
						verticalRandom = randi()%2+1
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

				if(horizontalRandom == 2 && verticalRandom == 2):
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
				door.doorRoomLeftMostCorner = leftmostCorner
				door.doorLocationDirection = "DOWN"
				door.roomSizeMultiplier = Vector2(horizontalRandom, verticalRandom)
				door.roomSize = Vector2(roomSizeHorizontal, roomSizeVertical)
	
	#create wall tiles by looping horizontan and vertical 
	var verticalAddcount = 0
	while verticalAddcount < roomSizeVertical:
		var horizontalAddcount = 0
		while horizontalAddcount < roomSizeHorizontal:
			var spawn_pos = leftmostCorner + Vector2(horizontalAddcount*GlobalVariables.tileSize,verticalAddcount*GlobalVariables.tileSize)
			var newWallPiece = Wall.instance()
			newWallPiece.set_z_index(2)
			#rotate corner tiles
			if spawn_pos == leftmostCorner:
				newWallPiece.set_Texture("corner", 0)
			elif spawn_pos == leftmostCorner + Vector2((roomSizeHorizontal-1)*GlobalVariables.tileSize,0):
				newWallPiece.set_Texture("corner", 90)
			elif spawn_pos == leftmostCorner + Vector2((roomSizeHorizontal-1)*GlobalVariables.tileSize, (roomSizeVertical-1)*GlobalVariables.tileSize):
				newWallPiece.set_Texture("corner", 180)
			elif spawn_pos == leftmostCorner + Vector2(0, (roomSizeVertical-1)*GlobalVariables.tileSize):
				newWallPiece.set_Texture("corner", 270)
			
			elif spawn_pos.x == leftmostCorner.x + (roomSizeHorizontal-1)*GlobalVariables.tileSize && spawn_pos.y > leftmostCorner.y && spawn_pos.y < leftmostCorner.y + (roomSizeVertical-1)*GlobalVariables.tileSize:
				newWallPiece.set_Texture("wall", 90)
			elif spawn_pos.x < leftmostCorner.x + (roomSizeHorizontal-1)*GlobalVariables.tileSize && spawn_pos.x > leftmostCorner.x && spawn_pos.y == leftmostCorner.y + (roomSizeVertical-1)*GlobalVariables.tileSize:
				newWallPiece.set_Texture("wall", 180)
			elif spawn_pos.x == leftmostCorner.x && spawn_pos.y > leftmostCorner.y && spawn_pos.y < leftmostCorner.y + (roomSizeVertical-1)*GlobalVariables.tileSize:
				newWallPiece.set_Texture("wall", 270)
				
			add_child(newWallPiece)
			newWallPiece.position = spawn_pos
			set_cellv(world_to_map(newWallPiece.position), get_tileset().find_tile_by_name(match_Enum(newWallPiece.type)))
			if(verticalAddcount==0 || verticalAddcount==roomSizeVertical-1 || horizontalAddcount==roomSizeHorizontal-1):
				horizontalAddcount+=1
			else:
				horizontalAddcount=roomSizeHorizontal-1
		verticalAddcount+=1
	
	#set all tiles within room to floor
	for countHorizontal in range (1, roomSizeHorizontal-1):
		for countVert in range (1, roomSizeVertical-1):
			var floorSpawnPos =  leftmostCorner + Vector2(countHorizontal*GlobalVariables.tileSize, countVert*GlobalVariables.tileSize)
			set_cellv(world_to_map(floorSpawnPos), get_tileset().find_tile_by_name("FLOOR"))
	
	#replace wall pieces with floor if a door connects them
	if(startingRoom == false):
		var object_pawn = null
		match door.doorDirection:
			"LEFT":
				set_cellv(world_to_map(door.position) - Vector2(1,0), get_tileset().find_tile_by_name("FLOOR"))
				object_pawn = get_cell_pawn(world_to_map(door.position) - Vector2(1,0))
			"RIGHT":
				set_cellv(world_to_map(door.position) + Vector2(1,0), get_tileset().find_tile_by_name("FLOOR"))
				object_pawn = get_cell_pawn(world_to_map(door.position) + Vector2(1,0))
			"UP":
				set_cellv(world_to_map(door.position) - Vector2(0,1), get_tileset().find_tile_by_name("FLOOR"))
				object_pawn = get_cell_pawn(world_to_map(door.position) - Vector2(0,1))
			"DOWN":
				set_cellv(world_to_map(door.position) + Vector2(0,1), get_tileset().find_tile_by_name("FLOOR"))
				object_pawn = get_cell_pawn(world_to_map(door.position) + Vector2(0,1))
		if(object_pawn != null):
			object_pawn.queue_free()
		
	if(createDoors == true):
		create_doors(leftmostCorner, startingRoom, roomSizeHorizontal, roomSizeVertical)


func create_doors(roomLeftMostCorner, startingRoom=false, roomSizeHorizontal = 13, roomSizeVertical = 13, roomsizeMultiplier = Vector2(1,1), doorLocationDirection = "LEFT"):
	randomize()
	roomSizeHorizontal = roomSizeHorizontal-1
	roomSizeVertical = roomSizeVertical-1
	var doorLocationDirectionsArray = ["LEFT", "RIGHT", "UP", "DOWN"]
	var doorLocationArray = []
	var doorArray = []
	var doorCount = 3
	var canCreateDoor = true
	var doorEvenOddModifier = 0
	var doorLocationsRemoved = []
	#move door location if room dimensions are even
	if(evenOddModifier == 0):
		doorEvenOddModifier = 1
	#create up to 4 doors in starting room 
	if startingRoom:
		doorCount = randi()%4+1
	#only up to three rooms in adjacent rooms
	if doorCount == 0 && numberRoomsBeenTo == currentNumberRoomsgenerated-1:
		doorCount = randi()%3+1
	#if maximum number of rooms created don't spawn doors
	if (doorCount + currentNumberRoomsgenerated) > GlobalVariables.maxNumberRooms:
		print(currentNumberRoomsgenerated)
		if GlobalVariables.maxNumberRooms-currentNumberRoomsgenerated == 0:
			doorCount = 0
		else:
			doorCount = randi()%(GlobalVariables.maxNumberRooms-currentNumberRoomsgenerated)+1
	if !startingRoom:
		remove_opposite_doorlocation(doorLocationDirectionsArray, doorLocationDirection)

#create doors at all chosen locations
	while doorCount > 0: 
		var doorLocation = randi()%doorLocationDirectionsArray.size()-1
		doorLocationArray.append(doorLocationDirectionsArray[doorLocation])
		doorLocationsRemoved.append(doorLocationDirectionsArray[doorLocation])
		doorLocationDirectionsArray.erase(doorLocationDirectionsArray[doorLocation])
		doorCount-=1
	for element in doorLocationArray:
		var newDoor = Door.instance()
		newDoor.set_z_index(5)
		var alternateSpawnLocation = false
		if(randi()%2+1 == 1):
			alternateSpawnLocation = true
		canCreateDoor = can_create_door(element, newDoor, roomLeftMostCorner, roomsizeMultiplier, roomSizeHorizontal, roomSizeVertical, doorEvenOddModifier, alternateSpawnLocation)
		print(world_to_map(newDoor.position)-Vector2(roomDimensions*2,0))
		if(!canCreateDoor):
			if alternateSpawnLocation:
				alternateSpawnLocation = false
			else: 
				alternateSpawnLocation = true
			if !can_create_door(element, newDoor, roomLeftMostCorner, roomsizeMultiplier, roomSizeHorizontal, roomSizeVertical, doorEvenOddModifier, alternateSpawnLocation):
				doorLocationArray+=doorLocationsRemoved
				doorCount += doorLocationsRemoved.size()
				
#stop door creation if maximum number of rooms reached
		if(currentNumberRoomsgenerated >= GlobalVariables.maxNumberRooms):
			canCreateDoor=false
		if(canCreateDoor == true):
			add_child(newDoor)
			#delete the wall piece before creating the door
			var object_pawn = get_cell_pawn(world_to_map(newDoor.position))
			object_pawn.queue_free()
			set_cellv(world_to_map(newDoor.position), get_tileset().find_tile_by_name(match_Enum(newDoor.type)))
			get_cell(world_to_map(newDoor.position).x, world_to_map(newDoor.position).y)
			doorArray.append(newDoor)
		
		#failsave create exit in room if no other alternative is left 
		if !canCreateDoor && currentNumberRoomsgenerated == numberRoomsBeenTo:
			#todo: maybe numberofroomsgenerated -1 check later 
			print("creating exit")
			newDoor.createExit = true

	if startingRoom:
		startingRoomDoorsCount = doorArray.size()
	for door in doorArray:
		currentNumberRoomsgenerated+=1
		if !startingRoom:
			door.make_door_barrier(self)
		create_walls(door, false, false)
		door.setBoxMapBG()
		door.rotate_door_sprite()
		update_bitmask_region()
	startingRoomDoorsCount = 0 

#checks if doors can be created for each direction
func can_create_door(element, newDoor, roomLeftMostCorner, roomsizeMultiplier, roomSizeHorizontal, roomSizeVertical, doorEvenOddModifier, alternateSpawnLocation):
	randomize()
	var locationToSpawnModifier = Vector2.ZERO
	match element:
		"LEFT":
			match roomsizeMultiplier:
				Vector2(1,1):
					locationToSpawnModifier = Vector2(0, int(roomSizeVertical/(2*roomsizeMultiplier.y)))
				Vector2(2,1):
					locationToSpawnModifier = Vector2(0, int(roomSizeVertical/(2*roomsizeMultiplier.y)))
				Vector2(1,2):
					locationToSpawnModifier = Vector2(0, int(roomSizeVertical/(2*roomsizeMultiplier.y)))
					if(alternateSpawnLocation):
						locationToSpawnModifier = Vector2(0, int(3*roomSizeVertical/(2*roomsizeMultiplier.y)+doorEvenOddModifier))
				Vector2(2,2):
					locationToSpawnModifier = Vector2(0, int(roomSizeVertical/(2*roomsizeMultiplier.y)))
					if(alternateSpawnLocation):
						locationToSpawnModifier = Vector2(0, int(3*roomSizeVertical/(2*roomsizeMultiplier.y)+doorEvenOddModifier))
			newDoor.doorDirection = "LEFT"
		"RIGHT":
			match roomsizeMultiplier:
				Vector2(1,1):
					locationToSpawnModifier = Vector2(roomSizeHorizontal, int(roomSizeVertical/(2*roomsizeMultiplier.y)))
				Vector2(2,1):
					locationToSpawnModifier = Vector2(roomSizeHorizontal, int(roomSizeVertical/(2*roomsizeMultiplier.y)))
				Vector2(1,2):
					locationToSpawnModifier = Vector2(roomSizeHorizontal, int(roomSizeVertical/(2*roomsizeMultiplier.y)))
					if(alternateSpawnLocation):
						locationToSpawnModifier = Vector2(roomSizeHorizontal, int(3*roomSizeVertical/(2*roomsizeMultiplier.y)+doorEvenOddModifier))
				Vector2(2,2):
					locationToSpawnModifier = Vector2(roomSizeHorizontal, int(roomSizeVertical/(2*roomsizeMultiplier.y)))
					if(alternateSpawnLocation):
						locationToSpawnModifier = Vector2(roomSizeHorizontal, int(3*roomSizeVertical/(2*roomsizeMultiplier.y)+doorEvenOddModifier))
			newDoor.doorDirection = "RIGHT"
		"UP":
			match roomsizeMultiplier:
				Vector2(1,1):
					locationToSpawnModifier = Vector2(int(roomSizeHorizontal/(2*roomsizeMultiplier.x)), 0)
				Vector2(2,1):
					locationToSpawnModifier = Vector2(int(roomSizeHorizontal/(2*roomsizeMultiplier.x)), 0)
					if(alternateSpawnLocation):
						locationToSpawnModifier = Vector2(int(3*roomSizeHorizontal/(2*roomsizeMultiplier.x))+doorEvenOddModifier, 0)
				Vector2(1,2):
					locationToSpawnModifier = Vector2(int(roomSizeHorizontal/(2*roomsizeMultiplier.x)), 0)
				Vector2(2,2):
					if(alternateSpawnLocation):
						locationToSpawnModifier = Vector2(int(3*roomSizeHorizontal/(2*roomsizeMultiplier.x))+doorEvenOddModifier, 0)
					locationToSpawnModifier = Vector2(int(roomSizeHorizontal/(2*roomsizeMultiplier.x)), 0)
			newDoor.doorDirection = "UP"
		"DOWN":
			match roomsizeMultiplier:
				Vector2(1,1):
					locationToSpawnModifier = Vector2(int(roomSizeHorizontal/(2*roomsizeMultiplier.x)), roomSizeVertical)
				Vector2(2,1):
					locationToSpawnModifier = Vector2(int(roomSizeHorizontal/(2*roomsizeMultiplier.x)), roomSizeVertical)
					if(alternateSpawnLocation):
						locationToSpawnModifier = Vector2(int(3*roomSizeHorizontal/(2*roomsizeMultiplier.x)+doorEvenOddModifier), roomSizeVertical)
				Vector2(1,2):
					locationToSpawnModifier = Vector2(int(roomSizeHorizontal/(2*roomsizeMultiplier.x)), roomSizeVertical)
				Vector2(2,2):
					locationToSpawnModifier = Vector2(int(roomSizeHorizontal/(2*roomsizeMultiplier.x)), roomSizeVertical)
					if(alternateSpawnLocation):
						locationToSpawnModifier = Vector2(int(3*roomSizeHorizontal/(2*roomsizeMultiplier.x)+doorEvenOddModifier), roomSizeVertical)
			newDoor.doorDirection = "DOWN"
	
	newDoor.position = roomLeftMostCorner + map_to_world(locationToSpawnModifier)
	
	if GlobalVariables.globaleRoomLayout == GlobalVariables.ROOMLAYOUT.BIG:
		match element:
			"LEFT":
				if get_cellv(world_to_map(newDoor.position)-Vector2(1,0)) == TILETYPES.WALL || get_cellv(world_to_map(newDoor.position)-Vector2(roomDimensions*2,0)) ==TILETYPES.FLOOR:
					return false
				return true
			"RIGHT":
				if get_cellv(world_to_map(newDoor.position)+Vector2(1,0)) == TILETYPES.WALL || get_cellv(world_to_map(newDoor.position)+Vector2(roomDimensions*2,0)) ==TILETYPES.FLOOR:
					return false
				return true
			"UP":
				if get_cellv(world_to_map(newDoor.position)-Vector2(0,1)) == TILETYPES.WALL || get_cellv(world_to_map(newDoor.position)-Vector2(0,roomDimensions*2)) ==TILETYPES.FLOOR:
					return false
				return true
			"DOWN":
				if get_cellv(world_to_map(newDoor.position)+Vector2(0,1)) == TILETYPES.WALL || get_cellv(world_to_map(newDoor.position)+Vector2(0,roomDimensions*2)) ==TILETYPES.FLOOR:
					return false
				return true
	else:
		match element:
			"LEFT":
				if (get_cellv(world_to_map(newDoor.position)-Vector2(1,0)) == TILETYPES.WALL):
					return false
				return true
			"RIGHT":
				if (get_cellv(world_to_map(newDoor.position)+Vector2(1,0)) == TILETYPES.WALL):
					return false
				return true
			"UP":
				if (get_cellv(world_to_map(newDoor.position)-Vector2(0,1)) == TILETYPES.WALL):
					return false
				return true
			"DOWN":
				if (get_cellv(world_to_map(newDoor.position)+Vector2(0,1)) == TILETYPES.WALL):
					return false
				return true

#removes door location mirrored to door entered
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

#checks if door barriere can be created without hard locking the game 
func manage_barrier_creation(barrierType):
	var countLockedDoors = 0
	if barrierType == GlobalVariables.BARRIERTYPE.DOOR:
		countLockedDoors = 1
	for barrier in barrierKeysNoSolution:
		if barrier.itemType == GlobalVariables.ITEMTYPE.KEY:
			countLockedDoors +=1
	var roomsPossibleSolution = currentNumberRoomsgenerated-numberRoomsCleared-countLockedDoors-1
	if barrierKeysNoSolution.size () < roomsPossibleSolution:
		return true
	return false

#called on move through unlockedDoor 
#on player turn done adjust enemy difficulty
func adapt_game_difficulty():
	if GlobalVariables.chosenDifficulty == GlobalVariables.DIFFICULTYLEVELS.AUTO:
		#adjust globalDifficultyMultiplyer accordingly
		var totalHitCount = GlobalVariables.hitByBarrier + GlobalVariables.hitByMage + GlobalVariables.hitByWarrior + GlobalVariables.hitByNinja
		var totalEnemiesDefeatesCount = GlobalVariables.enemyBarrierDifficulty + GlobalVariables.enemyWarriorDifficulty + GlobalVariables.enemyMageDifficulty + GlobalVariables.enemyNinjaDifficulty
		if totalHitCount > (totalEnemiesDefeatesCount+10):
			GlobalVariables.globalDifficultyMultiplier = 1.0 - (totalHitCount - totalEnemiesDefeatesCount)/100
			if GlobalVariables.globalDifficultyMultiplier < GlobalVariables.minDifficulty:
				GlobalVariables.globalDifficultyMultiplier = GlobalVariables.minDifficulty
		elif totalEnemiesDefeatesCount > (totalHitCount+10):
			GlobalVariables.globalDifficultyMultiplier = 1.0 + (totalHitCount - totalEnemiesDefeatesCount)/100
			if GlobalVariables.globalDifficultyMultiplier > GlobalVariables.maxDifficulty:
				GlobalVariables.globalDifficultyMultiplier = GlobalVariables.maxDifficulty
	if activeRoom != null && !activeRoom.enemiesInRoom.empty():
		for enemy in activeRoom.enemiesInRoom:
			enemy.adapt_difficulty()

# Note: This can be called from anywhere inside the tree. This function is
# path independent.
# Go through everything in the persist category and ask them to return a
# dict of relevant variables
#taken from the godot docuemtnation
func save_game():
	print("Saving game")
	var save_game = File.new()
	save_game.open("user://savegame.save", File.WRITE)
	var save_nodes = get_tree().get_nodes_in_group("Persist")
	for node in save_nodes:
		print("saved node " +str(node.name))
		# Check the node is an instanced scene so it can be instanced again during load
		if node.filename.empty():
			print("persistent node '%s' is not an instanced scene, skipped" % node.name)
			continue

		# Check the node has a save function
		if !node.has_method("save"):
			print("persistent node '%s' is missing a save() function, skipped" % node.name)
			continue

		# Call the node's save function
		var node_data = node.call("save")

		# Store the save dictionary as a new line in the save file
		save_game.store_line(to_json(node_data))
	save_game.close()

# Note: This can be called from anywhere inside the tree. This function
# is path independent.
func load_game():
	print(OS.get_user_data_dir())
	var save_game = File.new()
	if not save_game.file_exists("user://savegame.save"):
		return false # Error! We don't have a save to load.

	# We need to revert the game state so we're not cloning objects
	# during loading. This will vary wildly depending on the needs of a
	# project, so take care with this step.
	# For our example, we will accomplish this by deleting saveable objects.
	var save_nodes = get_tree().get_nodes_in_group("Persist")
	for i in save_nodes:
		i.queue_free()

	# Load the file line by line and process that dictionary to restore
	# the object it represents.
	save_game.open("user://savegame.save", File.READ)
	while save_game.get_position() < save_game.get_len():
		# Get the saved dictionary from the next line in the save file
		var node_data = parse_json(save_game.get_line())

		# Firstly, we need to create the object and add it to the tree and set its position.
		var new_object = load(node_data["filename"]).instance()
		get_node(node_data["parent"]).add_child(new_object)
		mainPlayer = new_object
		new_object.set_z_index(2)
		new_object.position = Vector2(112,112)
		new_object.set_name("Player")
		get_node("Player").connect("playerAttacked", self, "_on_Player_Attacked")
		get_node("Player").connect("puzzleBlockInteractionSignal", self, "on_puzzle_Block_interaction")

		# Now we set the remaining variables.
		for i in node_data.keys():
			if i == "filename" or i == "parent":
				continue
			new_object.set(i, node_data[i])
		new_object.update_gui_elements()
	save_game.close()
	return true
