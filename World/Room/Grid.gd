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

var roomDimensions = GlobalVariables.roomDimensions

var evenOddModifier = 0 

var currentNumberRoomsgenerated = 0

var numberRoomsBeenTo = 0

var numberRoomsCleared = 0

var numberRoomsSurroundedByWalls = 0

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

var enemiesHitByExplosion = []

var mainPlayer 

signal enemyTurnDoneSignal

signal puzzleBarrierDisableSignal (item, mainPlayer)

signal moveCameraSignal (activeRoom)

var projectilesToDeleteTurnEnd = []

var spawnBlockProjectileNextTurn = []

var activatePuzzlePieceNextTurn = []

var activatedPuzzleBlock 

var magicProjectileLoopLevel = 0

var puzzlePiecesAnimationDoneCounter = 0

var puzzleAnimationPlaying = false

var activatedPuzzlePieces = []

var onEndlessLoopStop = 0

var powerBlockSpawnDone = true

var exitMagicBlockLoopOnWallHitNumber = 0

var onEndlessLoopStopGlobal = 0

var playerEnemyProjectileArray = []

var enemiesToMoveArray = []

var waitingForProjectileInteraction = []

var waitingForEnemyDefeat = []

var puzzleProjectilesToMove = []

var tickingProjectile = null

var cancelMagicPuzzleRoom = false

var allEnemiesAlreadySaved = false

var bonusLootArray = []

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
	GlobalVariables.turnController.set_Grid_to_use(self)
	#todo replace with cleared room later on 
	GlobalVariables.turnController.currentTurnWaiting = GlobalVariables.CURRENTPHASE.PLAYER
	GlobalVariables.turnController.inRoomType = GlobalVariables.ROOM_TYPE.ENEMYROOM
	if GlobalVariables.firstCall:
		GlobalVariables.firstCall=false
		var newPlayer = Player.instance()
		newPlayer.set_z_index(2)
		newPlayer.position = Vector2(80,80)
		newPlayer.set_name("Player")
		add_child(newPlayer)
		get_node("Player").connect("playerAttacked", self, "_on_Player_Attacked")
		get_node("Player").connect("puzzleBlockInteractionSignal", self, "on_puzzle_Block_interaction")
	#	get_parent().get_node("MainCamera").connect_grid_camera_signal()
		mainPlayer = get_node("Player")
	else:
		load_game()
	for child in get_children():
		if !child is Camera2D:
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
		if node is TextureRect:
			return
		else:
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
			TILETYPES.FLOOR:
				return update_pawn_position(pawn, cell_start, cell_target)
			TILETYPES.ENEMY:
				pass
			TILETYPES.WALL:
				pass
			TILETYPES.ITEM:
				var object_pawn = get_cell_pawn(cell_target)
				print("Picking up Item")
				#print("Item spawned key value " + str(object_pawn.keyValue))
				#add additional items with || 
				if(object_pawn.itemType == GlobalVariables.ITEMTYPE.POTION):
					pawn.add_nonkey_items(object_pawn.itemType)
				elif object_pawn.itemType == GlobalVariables.ITEMTYPE.PUZZLESWITCH:
					emit_signal("puzzleBarrierDisableSignal", object_pawn, mainPlayer)
				elif object_pawn.itemType == GlobalVariables.ITEMTYPE.EXIT:
					save_game()
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
				#print("Player picket up item")
				#pawn.queue_free()
				#print("Player has Items in posession " + str(pawn.itemsInPosession))
				return update_pawn_position(pawn, cell_start, cell_target)
				return pawn.position
			TILETYPES.DOOR:
				var object_pawn = get_cell_pawn(cell_target)
				var requestDoorUnlockResult = object_pawn.request_door_unlock(pawn.itemsInPosession)
				if(requestDoorUnlockResult):
					if requestDoorUnlockResult is preload("res://GameObjects/Item/Item.gd"):
						object_pawn.on_use_key_item(requestDoorUnlockResult)
						mainPlayer.remove_key_item_from_inventory(requestDoorUnlockResult)
					#see if any other rooms are compleatly blocked by walls 
					object_pawn.unlock_Door(enemyRoomChance, puzzleRoomChance, emptyTreasureRoomChance)
					numberRoomsBeenTo += 1
					GlobalVariables.turnController.playerMovedDoor = true
					return update_pawn_position(pawn, cell_start, cell_target)
			TILETYPES.UNLOCKEDDOOR:
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
					#pawn.inflict_damage_playerDefeated(object_pawn.attackDamage, GlobalVariables.ATTACKTYPE.MAGIC)
					GlobalVariables.turnController.playerTakeDamage.append(mainPlayer)
					pawn.queueInflictDamage=true
					pawn.enemyQueueAttackDamage = object_pawn.attackDamage
					pawn.enemyQueueAttackType = GlobalVariables.ATTACKTYPE.MAGIC
					return update_pawn_position(pawn, cell_start, cell_target)
			TILETYPES.BLOCK:
				return 
			TILETYPES.UPGRADECONTAINER:
				return 
			TILETYPES.COUNTINGBLOCK:
				return
					
				
#	if(pawn.type == TILETYPES.ENEMY):
	elif match_Enum(pawn.type) == "ENEMY":
		# add other enemies moving freely in the room 
		if get_cellv(cell_target+direction) == TILETYPES.DOOR || get_cellv(cell_target+direction) == TILETYPES.UNLOCKEDDOOR:
			return pawn.position 

#		if pawn.enemyType == GlobalVariables.ENEMYTYPE.MAGEENEMY:
#			#set mageenmy goal directly 
#			cell_target = direction
#			cell_target_type = get_cellv(cell_target)
#		#print("MOVED enemy in room")
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
					tempMagicProjectile.play_projectile_animation(true, "attack")
					GlobalVariables.turnController.enemyTakeDamage.append(pawn)
					pawn.inflictDamage(tempMagicProjectile.attackDamage, GlobalVariables.ATTACKTYPE.MAGIC, map_to_world(cell_target), mainPlayer, GlobalVariables.CURRENTPHASE.ENEMY)
#					if pawn.enemyDefeated:
#						#print("Enemy defeated")
#						return update_pawn_position(pawn, cell_start, cell_target)
#					else:
#						#todo fix here things enemy enemy proejctile
#						print("IN HERE ENEMY MOVED ON ENEMY MAGIC PROJECTILE")
#						projectilesInActiveRoom.erase(tempMagicProjectile)
#						tempMagicProjectile.play_projectile_animation(true, "delete")
#						#set_cellv(world_to_map(tempMagicProjectile.position),get_tileset().find_tile_by_name("FLOOR"))
					return update_pawn_position(pawn, cell_start, cell_target)
				elif tempMagicProjectile.projectileType == GlobalVariables.PROJECTILETYPE.ENEMY && pawn.helpEnemy:
					projectilesInActiveRoom.erase(tempMagicProjectile)
					set_cellv(world_to_map(tempMagicProjectile.position), get_tileset().find_tile_by_name("ENEMY"))
					tempMagicProjectile.play_projectile_animation(true, "attack")
					GlobalVariables.turnController.enemyTakeDamage.append(pawn)
					pawn.inflictDamage(tempMagicProjectile.attackDamage, GlobalVariables.ATTACKTYPE.MAGIC, cell_target, mainPlayer, GlobalVariables.CURRENTPHASE.ENEMY)
					return update_pawn_position(pawn, cell_start, cell_target)
				else:
					tempMagicProjectile.play_projectile_animation(true,"delete")
#					if pawn.helpEnemy:
#						print("INFLICTING DAMAGE IN PAWN MAGICPROJECTILE")
#						GlobalVariables.turnController.enemyTakeDamage.append(self)
#						pawn.inflictDamage(tempMagicProjectile.attackDamage, GlobalVariables.ATTACKTYPE.MAGIC, map_to_world(cell_target), mainPlayer, GlobalVariables.CURRENTPHASE.ENEMY)
					return update_pawn_position(pawn, cell_start, cell_target)
			TILETYPES.BLOCK:
				return pawn.position
			_:
				return pawn.position

	elif match_Enum(pawn.type) == "MAGICPROJECTILE":
		#print("MOVED enemy in room")
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
#						waitingForEnemyDefeat.append(tempEnemy)
					else:
						pawn.play_projectile_animation(false,"attack")
					set_cellv(world_to_map(pawn.position),get_tileset().find_tile_by_name("FLOOR")) 
					#pawn.waitingForEventBeforeContinue = true
					GlobalVariables.turnController.enemyTakeDamage.append(tempEnemy)
					tempEnemy.inflictDamage(pawn.attackDamage, GlobalVariables.ATTACKTYPE.MAGIC, cell_target, mainPlayer, GlobalVariables.CURRENTPHASE.ENEMYPROJECTILE)
					#projectilesMadeMoveCounter+=1
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
#					GlobalVariables.turnController.playerTakeDamage.append(mainPlayer)
					tempPlayer.inflict_damage_playerDefeated(pawn.attackDamage, GlobalVariables.ATTACKTYPE.MAGIC)
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
					#set_cellv(world_to_map(pawn.position),get_tileset().find_tile_by_name("EMPTY")) 
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
				if activeRoom!= null && activeRoom.roomType == GlobalVariables.ROOM_TYPE.PUZZLEROOM && pawn.projectileType == GlobalVariables.PROJECTILETYPE.POWERBLOCK:
					pawn.deleteProjectilePlayAnimation = "delete"
				elif GlobalVariables.turnController.currentTurnWaiting == GlobalVariables.CURRENTPHASE.PLAYERPROJECTILE:
					pawn.deleteProjectilePlayAnimation = "delete"
				elif GlobalVariables.turnController.currentTurnWaiting == GlobalVariables.CURRENTPHASE.ENEMYPROJECTILE:
					pawn.deleteProjectilePlayAnimation = "delete"
				else:
					pawn.deleteProjectilePlayAnimation = "delete"
				#print("Deleting magic projectile " + str(projectilesInActiveRoom.size()))
			TILETYPES.DOOR:
				projectilesInActiveRoom.erase(pawn)
				pawn.deleteProjectilePlayAnimation = "delete"
				pawn.hitObstacleOnDelete = true
				set_cellv(world_to_map(pawn.position),get_tileset().find_tile_by_name("FLOOR")) 
				if activeRoom!= null && activeRoom.roomType == GlobalVariables.ROOM_TYPE.PUZZLEROOM && pawn.projectileType == GlobalVariables.PROJECTILETYPE.POWERBLOCK:
					pawn.deleteProjectilePlayAnimation = "delete"
				elif GlobalVariables.turnController.currentTurnWaiting == GlobalVariables.CURRENTPHASE.ENEMYPROJECTILE:
					pawn.deleteProjectilePlayAnimation = "delete"
				elif GlobalVariables.turnController.currentTurnWaiting == GlobalVariables.CURRENTPHASE.PLAYERPROJECTILE:
					pawn.deleteProjectilePlayAnimation = "delete"
				else:
					pawn.deleteProjectilePlayAnimation = "delete"
			TILETYPES.UNLOCKEDDOOR:
				projectilesInActiveRoom.erase(pawn)
				pawn.deleteProjectilePlayAnimation = "delete"
				pawn.hitObstacleOnDelete = true
				set_cellv(world_to_map(pawn.position),get_tileset().find_tile_by_name("FLOOR")) 
				if activeRoom!= null && activeRoom.roomType == GlobalVariables.ROOM_TYPE.PUZZLEROOM && pawn.projectileType == GlobalVariables.PROJECTILETYPE.POWERBLOCK:
					pawn.deleteProjectilePlayAnimation = "delete"
				elif GlobalVariables.turnController.currentTurnWaiting == GlobalVariables.CURRENTPHASE.ENEMYPROJECTILE:
					pawn.deleteProjectilePlayAnimation = "delete"
				elif GlobalVariables.turnController.currentTurnWaiting == GlobalVariables.CURRENTPHASE.PLAYERPROJECTILE:
					pawn.deleteProjectilePlayAnimation = "delete"
				else:
					pawn.deleteProjectilePlayAnimation = "delete"
			TILETYPES.MAGICPROJECTILE:
				var targetProjectile = get_cell_pawn(cell_target)
				if pawn == null && targetProjectile == null:
					print("NUUUUUUULLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLL")
				if pawn != null && targetProjectile!= null:
#					if pawn.projectileType != GlobalVariables.PROJECTILETYPE.ENEMY || targetProjectile.projectileType != GlobalVariables.PROJECTILETYPE.ENEMY:
						if magicProjectileMagicProjectileInteraction(pawn, targetProjectile):
							#print("here interacting")
							if  pawn.requestedMoveCount < 2 && GlobalVariables.turnController.currentTurnWaiting == GlobalVariables.CURRENTPHASE.PLAYERPROJECTILE || pawn.requestedMoveCount < 2 && GlobalVariables.turnController.currentTurnWaiting == GlobalVariables.CURRENTPHASE.ENEMYPROJECTILE:
								pawn.requestedMoveCount+=1
								if GlobalVariables.turnController.currentTurnWaiting == GlobalVariables.CURRENTPHASE.PLAYERPROJECTILE:
									GlobalVariables.turnController.playerProjectilesToMove.append(pawn)
								if GlobalVariables.turnController.currentTurnWaiting == GlobalVariables.CURRENTPHASE.ENEMYPROJECTILE:
									GlobalVariables.turnController.enemyProjectilesToMove.append(pawn)
	#							playerEnemyProjectileArray.append(pawn)
								#print(pawn.requestedMoveCount)
								return 
							else:
								projectilesInActiveRoom.erase(pawn)
								pawn.deleteProjectilePlayAnimation = "delete"
								pawn.hitObstacleOnDelete = true
#								if pawn.projectileType != GlobalVariables.PROJECTILETYPE.ENEMY
								set_cellv(world_to_map(pawn.position),get_tileset().find_tile_by_name("FLOOR")) 
#					else:
#						print("HERE INTERACTING ENEMY")
#						projectilesInActiveRoom.erase(pawn)
#						pawn.deleteProjectilePlayAnimation = "delete"
#						pawn.hitObstacleOnDelete = false
#						#set_cellv(world_to_map(pawn.position),get_tileset().find_tile_by_name("FLOOR")) 
#				else:
#					if GlobalVariables.turnController.currentTurnWaiting == GlobalVariables.CURRENTPHASE.PLAYERPROJECTILE:
#	#						print(GlobalVariables.turnController.playerProjectilesToMove.size())
#						var tempProjectileArray = GlobalVariables.turnController.playerProjectilesToMove.duplicate()
#						for projectile in tempProjectileArray:
#							if projectile.moveTo!=null && projectile != pawn:
#								#print(world_to_map(projectile.moveTo))
#								#print(cell_target)
#								if world_to_map(projectile.moveTo) == cell_target:
#									pawn.play_projectile_animation(true,"delete")
#									projectile.play_projectile_animation(true,"merge")
#									return update_pawn_position(pawn, cell_start, cell_target)
#					elif GlobalVariables.turnController.currentTurnWaiting == GlobalVariables.CURRENTPHASE.ENEMYPROJECTILE:
#						var tempProjectileArray = GlobalVariables.turnController.enemyProjectilesToMove.duplicate()
#						for projectile in tempProjectileArray:
#							if projectile.moveTo!=null && projectile != pawn:
#								#print(world_to_map(projectile.moveTo))
#								#print(cell_target)
#								if world_to_map(projectile.moveTo) == cell_target:
#									pawn.play_projectile_animation(true,"delete")
#									projectile.play_projectile_animation(true,"delete")
#									return update_pawn_position(pawn, cell_start, cell_target)
				return pawn.position
#				return update_pawn_position(pawn, cell_start, cell_target)
			TILETYPES.BLOCK:
				print("IN ON BLOCK INTERACTION")
				projectilesInActiveRoom.erase(pawn)
				pawn.deleteProjectilePlayAnimation = "delete"
				pawn.hitObstacleOnDelete = true
				set_cellv(world_to_map(pawn.position),get_tileset().find_tile_by_name("FLOOR")) 
				if activeRoom!= null && activeRoom.roomType == GlobalVariables.ROOM_TYPE.PUZZLEROOM && pawn.projectileType == GlobalVariables.PROJECTILETYPE.POWERBLOCK:
#					get_cell_pawn(cell_target).spawnMagicFromBlock()
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
				get_cell_pawn(cell_target).decrease_count()
			_:
				projectilesInActiveRoom.erase(pawn)
				if GlobalVariables.turnController.currentTurnWaiting == GlobalVariables.CURRENTPHASE.ENEMYPROJECTILE:
					pawn.deleteProjectilePlayAnimation = "delete"
				elif GlobalVariables.turnController.currentTurnWaiting == GlobalVariables.CURRENTPHASE.PLAYERPROJECTILE:
					pawn.deleteProjectilePlayAnimation = "delete"
				else:
					pawn.deleteProjectilePlayAnimation = "delete"
				set_cellv(world_to_map(pawn.position),get_tileset().find_tile_by_name("FLOOR")) 
				

func magicProjectileMagicProjectileInteraction(magicProjectile1, magicProjectile2):
	#enemy enemy projectile interaction
	if magicProjectile1.projectileType == GlobalVariables.PROJECTILETYPE.ENEMY && magicProjectile2.projectileType == GlobalVariables.PROJECTILETYPE.ENEMY:
#		magicProjectile1.play_projectile_animation(true,"delete")
#		magicProjectile2.play_projectile_animation(false,"delete")
#		set_cellv(world_to_map(magicProjectile1.position),get_tileset().find_tile_by_name("FLOOR")) 
		#print("HERE INTERACTING enemy enemy projectile")
		return true
		#magicProjectile1.movementDirection *=-1
	#player enemy projectile interaction
	if magicProjectile1.projectileType == GlobalVariables.PROJECTILETYPE.PLAYER && magicProjectile2.projectileType == GlobalVariables.PROJECTILETYPE.ENEMY || magicProjectile1.projectileType == GlobalVariables.PROJECTILETYPE.ENEMY && magicProjectile2.projectileType == GlobalVariables.PROJECTILETYPE.PLAYER:
		if GlobalVariables.turnController.currentTurnWaiting == GlobalVariables.CURRENTPHASE.PLAYER:
			magicProjectile1.play_projectile_animation(false,"delete")
			magicProjectile2.play_projectile_animation(true,"delete")
		else:
			magicProjectile1.play_projectile_animation(true,"delete")
			magicProjectile2.play_projectile_animation(true,"delete")
		return false

	#player player projectile interaction
	if magicProjectile1.projectileType == GlobalVariables.PROJECTILETYPE.PLAYER && magicProjectile2.projectileType == GlobalVariables.PROJECTILETYPE.PLAYER:
		if GlobalVariables.turnController.currentTurnWaiting == GlobalVariables.CURRENTPHASE.PLAYERPROJECTILE:
			return true
#		print("Player projectiles hit each other " + str(magicProjectile1.movementDirection))
#		#if magicProjectile1.movementDirection == magicProjectile2.movementDirection:
		elif GlobalVariables.turnController.currentTurnWaiting == GlobalVariables.CURRENTPHASE.PLAYER:
			#print("Projectiles " + str(magicProjectile1.isMiniProjectile) + "  " + str(magicProjectile2.isMiniProjectile) )
			if magicProjectile1.isMiniProjectile && magicProjectile2.isMiniProjectile:
				#set_cellv(world_to_map(magicProjectile2.position),get_tileset().find_tile_by_name("FLOOR")) 
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
			#todo maybe change back to only erase magicprojectile1
#			if currentActivePhase == GlobalVariables.CURRENTPHASE.ENEMYPROJECTILE || currentActivePhase == GlobalVariables.CURRENTPHASE.PLAYERPROJECTILE:
#				playerEnemyProjectileArray.erase(magicProjectile2)
#	#			playerEnemyProjectileArray.erase(magicProjectile1)
#				playerEnemyProjectileArray.push_front(magicProjectile2)
#				playerEnemyProjectileArray.push_front(magicProjectile1)
				return false
		
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
				oldCellTargetNode.set_other_adjacent_room(activeRoom, direction)
				if !projectilesInActiveRoom.empty():
					#print("projectiles in active room not empty")
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
					print (activeRoom.enemiesInRoom)
					for element in activeRoom.enemiesInRoom:
						element.isDisabled = false
						element.enemyTurnDone=true
					if GlobalVariables.turnController.inRoomType == GlobalVariables.ROOM_TYPE.PUZZLEROOM:
						GlobalVariables.turnController.puzzlePiecesToPattern += activeRoom.puzzlePiecesInRoom
						print(GlobalVariables.turnController.puzzlePiecesToPattern.size())
						play_puzzlepiece_pattern()
					elif GlobalVariables.turnController.inRoomType == GlobalVariables.ROOM_TYPE.EMPTYTREASUREROOM:
						activeRoom.updateContainerPrices()
				else:
					pawn.inRoomType = null
					#todo change to empty cleared room whatevs
					GlobalVariables.turnController.inRoomType = GlobalVariables.ROOM_TYPE.ENEMYROOM
					#print ("Player in Room " + str(pawn.inRoomType))
			if(oldCellTargetType == get_tileset().find_tile_by_name("UNLOCKEDDOOR")):
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
							#element.toggleVisibility(true)
					#remove rojectiles in old room
				activeRoom=oldCellTargetNode.get_room_by_movement_direction(direction)
				if activeRoom != null:
					pawn.inRoomType = activeRoom.roomType
					GlobalVariables.turnController.inRoomType = activeRoom.roomType
					#print ("Player in Room " + str(pawn.inRoomType))
					for element in activeRoom.enemiesInRoom:
						element.isDisabled = false
					if !activeRoom.enemiesInRoom.empty():
						activeRoom.enemiesInRoom[0].calc_enemy_attack_to(GlobalVariables.MOVEMENTATTACKCALCMODE.PREVIEW,activeRoom,0)
					if !activeRoom.roomCleared && GlobalVariables.turnController.inRoomType == GlobalVariables.ROOM_TYPE.PUZZLEROOM:
						GlobalVariables.turnController.puzzlePiecesToPattern += activeRoom.puzzlePiecesInRoom
						print(GlobalVariables.turnController.puzzlePiecesToPattern.size())
						play_puzzlepiece_pattern()
					if GlobalVariables.turnController.inRoomType == GlobalVariables.ROOM_TYPE.EMPTYTREASUREROOM:
						activeRoom.updateContainerPrices()
				else:
					pawn.inRoomType = null
					#print ("Player in Room " + str(pawn.inRoomType))
						
			#update camera position 
			emit_signal("moveCameraSignal", activeRoom)

			#let player move freely if room is cleared
			if(activeRoom == null || activeRoom.roomType == GlobalVariables.ROOM_TYPE.EMPTYTREASUREROOM):
				pawn.inClearedRoom = true
				if activeRoom!= null && activeRoom.roomType == GlobalVariables.ROOM_TYPE.EMPTYTREASUREROOM && !activeRoom.roomCleared:
					if activeRoom.dropLoot():
						dropLootInActiveRoom()
					activeRoom.roomCleared = true
					activeRoom.roomType = GlobalVariables.ROOM_TYPE.EMPTYTREASUREROOM
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

func create_puzzle_room(unlockedDoor):
	randomize()
	#minimum 4 maximum 6
	var puzzlePiecesToSpwan = 1
#	var puzzlePiecesToSpwan = randi()%3+4
	print("Random rolled result : " + str(puzzlePiecesToSpwan))
	var calculateSpawnAgain = true
	var alreadyUsedColors = []
	var spawnCellArray = []
	var spawnCellX
	var spawnCellY
	var spawnCell 
	var barrierPuzzlePieceAlreadySpawned = false
	print ("Puzzlelepieces to spawn " + str(puzzlePiecesToSpwan))
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
		
		var colorToUse = Color(randf(),randf(),randf(),1.0)
		while alreadyUsedColors.has(colorToUse):
			colorToUse = Color(randf(),randf(),randf(),1.0)
		alreadyUsedColors.append(colorToUse)
		var newPuzzlePiece = PuzzlePiece.instance()
		newPuzzlePiece.set_z_index(2)
		#todo: barrier possibility
		if !barrierPuzzlePieceAlreadySpawned:
			newPuzzlePiece.makePuzzleBarrier(self, unlockedDoor)
		newPuzzlePiece.color = colorToUse
		newPuzzlePiece.position = unlockedDoor.doorRoomLeftMostCorner + map_to_world(Vector2(spawnCellX, spawnCellY))
		add_child(newPuzzlePiece)
		newPuzzlePiece.connect("puzzlePieceActivated", self, "_on_puzzle_piece_activated")
		newPuzzlePiece.connect("puzzlePlayedAnimation", GlobalVariables.turnController, "puzzle_pattern_turn_done")
		set_cellv(world_to_map(newPuzzlePiece.position), get_tileset().find_tile_by_name("PUZZLEPIECE"))
		unlockedDoor.puzzlePiecesInRoom.append(newPuzzlePiece)
		#spawn additional counting blocks for bonus loot
	var countingBlocksRand = randi()%3
	for countingBlock in countingBlocksRand:
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
		var newCountingBlock = CountingBlock.instance()
		newCountingBlock.set_z_index(2)
		newCountingBlock.position = unlockedDoor.doorRoomLeftMostCorner + map_to_world(Vector2(spawnCellX, spawnCellY))
		add_child(newCountingBlock)
		set_cellv(world_to_map(newCountingBlock.position), get_tileset().find_tile_by_name("COUNTINGBLOCK"))
		unlockedDoor.countingBlocksInRoom.append(newCountingBlock)

func play_puzzlepiece_pattern():
	print("Play puzzle pattern")
	activeRoom.puzzlePiecesInRoom[0].playColor(activeRoom.puzzlePiecesInRoom, 0)

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
	
func create_enemy_room(unlockedDoor):
	randomize()
	#add adjustment for enemy amount 
	#-2 because of walls on both sides
	var enemiesToSpawn = 3
#	if unlockedDoor.roomSizeMultiplier == Vector2(1,1):
#		enemiesToSpawn = randi()%3+1
#	elif unlockedDoor.roomSizeMultiplier == Vector2(2,2):
#		enemiesToSpawn = randi()%5+1
	var sizecounter = 0
	var mageEnemyCount = 0
	var spawnCellArray = []
	var spawnCellX
	var spawnCellY
	var spawnCell 
	var calculateSpawnAgain = true
	for enemie in enemiesToSpawn: 
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
				
		var newEnemy = Enemy.instance()
		add_child(newEnemy)
		newEnemy.set_z_index(2)
		#create enemy typ here (enemy. createEnemyType
		newEnemy.position = unlockedDoor.doorRoomLeftMostCorner + map_to_world(Vector2(spawnCellX, spawnCellY))
		var generatedEnemyType = newEnemy.generateEnemy(mageEnemyCount, self, unlockedDoor)
		if(generatedEnemyType == GlobalVariables.ENEMYTYPE.MAGEENEMY):
			mageEnemyCount += 1
		newEnemy.connect("enemyMadeMove", GlobalVariables.turnController, "enemy_turn_done")
		newEnemy.connect("enemyAttacked", self, "_on_enemy_attacked")
		newEnemy.connect("enemyDefeated", self, "_on_enemy_defeated")
#		newEnemy.calc_enemy_move_to(GlobalVariables.MOVEMENTATTACKCALCMODE.PREVIEW, unlockedDoor,0)
		set_cellv(world_to_map(newEnemy.position), get_tileset().find_tile_by_name(match_Enum(newEnemy.type)))
		unlockedDoor.enemiesInRoom.append(newEnemy)
	if unlockedDoor != null && !unlockedDoor.enemiesInRoom.empty():
		unlockedDoor.enemiesInRoom[0].calc_enemy_attack_to(GlobalVariables.MOVEMENTATTACKCALCMODE.PREVIEW, unlockedDoor, 0)

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
	
func get_enemy_move_mage_pattern(enemy, movementdirection, rommToCalc):
	#return corner of the room according to movementdirection
	match movementdirection:
		GlobalVariables.DIRECTION.MIDDLE:
			return world_to_map(rommToCalc.doorRoomLeftMostCorner)+ Vector2(int(rommToCalc.roomSize.x/2), int(rommToCalc.roomSize.y/2))
		GlobalVariables.DIRECTION.RIGHT:
			return world_to_map(rommToCalc.doorRoomLeftMostCorner)+ Vector2(rommToCalc.roomSize.x-2,1)
		GlobalVariables.DIRECTION.DOWN:
			return world_to_map(rommToCalc.doorRoomLeftMostCorner)+ Vector2(rommToCalc.roomSize.x-2,rommToCalc.roomSize.y-2)
		GlobalVariables.DIRECTION.LEFT:
			return world_to_map(rommToCalc.doorRoomLeftMostCorner)+ Vector2(1,rommToCalc.roomSize.y-2)
		GlobalVariables.DIRECTION.UP:
			return world_to_map(rommToCalc.doorRoomLeftMostCorner)+ Vector2(1,1)
	return Vector2.ZERO
			
func _on_Enemy_Turn_Done_Request(enemy):
	GlobalVariables.turnController.enemy_turn_done(enemy)
	
func on_enemy_turn_done_confirmed():
	if activeRoom != null:
		if !activeRoom.enemiesInRoom.empty():
			activeRoom.enemiesInRoom[0].calc_enemy_attack_to(GlobalVariables.MOVEMENTATTACKCALCMODE.PREVIEW, activeRoom, 0)
			#print("Moving " + str(currentEnemy) + " enemies left to move " + str(enemiesToMoveArray.size()))
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
	GlobalVariables.turnController.currentTurnWaiting = GlobalVariables.CURRENTPHASE.PLAYER
	emit_signal("enemyTurnDoneSignal")
	
func on_player_turn_done_confirmed_empty_treasure_room():
	GlobalVariables.turnController.currentTurnWaiting = GlobalVariables.CURRENTPHASE.PLAYER
	on_player_turn_done_confirmed_enemy_room()
#	emit_signal("enemyTurnDoneSignal")
	
func on_player_turn_done_confirmed_enemy_room():
#	if movedThroughDoor:
#		return
	mainPlayer.playerBackupPosition = mainPlayer.position
		#go through all projectiles in room and select enemy projectiles
	for projectile in projectilesInActiveRoom:
		if projectile.projectileType == GlobalVariables.PROJECTILETYPE.ENEMY:
			GlobalVariables.turnController.enemyProjectilesToMove.append(projectile)
	if GlobalVariables.turnController.enemyProjectilesToMove.empty():
		GlobalVariables.turnController.enemy_projectiles_turn_done(null)
	else:
		GlobalVariables.turnController.enemyProjectilesToMove[0].calc_projectiles_move_to(GlobalVariables.MOVEMENTATTACKCALCMODE.ACTION, 0, "enemy")
		var tempEnenmyProjectiles = GlobalVariables.turnController.enemyProjectilesToMove.duplicate()
		print("tempEnenmyProjectiles size " +  str(tempEnenmyProjectiles.size()))
		for projectile in tempEnenmyProjectiles:
			projectile.move_projectile()
		tempEnenmyProjectiles.clear()

func _on_puzzle_piece_activated():
	#print ("activated puzzle pieces size " + str(activatedPuzzlePieces.size()) + " active puzzle pieces in room " + str(activeRoom.puzzlePiecesInRoom.size()))
	if activatedPuzzlePieces.size() == activeRoom.puzzlePiecesInRoom.size():
		var puzzlePieceIsBarrier = false
		for puzzlePiece in activatedPuzzlePieces:
			if puzzlePiece.isBarrier:
				puzzlePieceIsBarrier = true
		if activatedPuzzlePieces == activeRoom.puzzlePiecesInRoom && !activeRoom.roomCleared && !puzzlePieceIsBarrier:
			print("Activated in right order")
#			cancelMagicPuzzleRoom = true
			activeRoom.roomCleared=true
			mainPlayer.inClearedRoom = true
			#delete all projectiles 
			if activeRoom.dropLoot():
				var tempCountingBlocks = activeRoom.countingBlocksInRoom.duplicate()
				for countBlock in activeRoom.countingBlocksInRoom:
					GlobalVariables.turnController.countingBlocksToDelete.append(countBlock)
					if countBlock.checkLootDrop() == "penny":
						var bonusCoin = Item.instance()
						bonusCoin.position = countBlock.position
						bonusLootArray.append(bonusCoin)
						countBlock.playAnimation("penny")
					elif countBlock.checkLootDrop() == "nickel":
						var bonusCoin = Item.instance()
						bonusCoin.make_nickel()
						bonusCoin.position = countBlock.position
						bonusLootArray.append(bonusCoin)
						countBlock.playAnimation("nickel")
					else:
						countBlock.playAnimation("nothing")
				tempCountingBlocks.clear()
				for puzzlePiece in activatedPuzzlePieces:
					puzzlePiece.playWrongWriteAnimation(true)
				GlobalVariables.turnController.queueDropLoot = true
			cancel_magic_in_puzzle_room()
		else:
			if !activeRoom.roomCleared:
				if puzzlePieceIsBarrier:
					print("try again after activating puzzle piece barrier")
				else:
					print("try again activated in wrong order")
				for puzzlePiece in activatedPuzzlePieces:
						puzzlePiece.playWrongWriteAnimation(false)
	
func on_player_projectile_turn_done_request_confirmed():
	GlobalVariables.turnController.currentTurnWaiting = GlobalVariables.CURRENTPHASE.PLAYER
	emit_signal("enemyTurnDoneSignal")

func on_enemy_projectile_turn_done_request_confirmed():
	#get all enmies in active Room
	if activeRoom != null:
		for enemy in activeRoom.enemiesInRoom:
			#print("current enemy to append " + str(enemy) + " enemy position " + str(world_to_map(enemy.position)) + (" enemy type cell value ") + str(get_cellv(world_to_map(enemy.position))))
			GlobalVariables.turnController.enemiesAttacking.append(enemy)
	#move all enemies in active Room
	var tempEnenmyToAttack = GlobalVariables.turnController.enemiesAttacking.duplicate()
	if tempEnenmyToAttack.empty():
		GlobalVariables.turnController.enemy_turn_done(null)
	else:
		for enemy in tempEnenmyToAttack:
			enemy.make_enemy_turn()
		GlobalVariables.turnController.enemiesAttacking[0].calc_enemy_attack_to(GlobalVariables.MOVEMENTATTACKCALCMODE.ACTION,activeRoom, 0)
		print("making enemy attack")
		for enemy in tempEnenmyToAttack:
			enemy.enemyAttack()
	tempEnenmyToAttack.clear()

func on_enemy_attack_done():
	#get all enmies in active Room
	if activeRoom != null:
		for enemy in activeRoom.enemiesInRoom:
			#print("current enemy to append " + str(enemy) + " enemy position " + str(world_to_map(enemy.position)) + (" enemy type cell value ") + str(get_cellv(world_to_map(enemy.position))))
			GlobalVariables.turnController.enemiesToMove.append(enemy)
	#move all enemies in active Room
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
	#print("CancelMagicPuzzelRoom status " + str(cancelMagicPuzzleRoom))
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
#	projectile.move_projectile(projectileType)

func cancel_magic_in_puzzle_room():
	cancelMagicPuzzleRoom = false
	spawnBlockProjectileNextTurn.clear()
	activatePuzzlePieceNextTurn.clear()
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
		#print("Projectiles made move " + str(projectilesMadeMoveCounter) + " projectiles in puzzleProjectilesToMove " + str(puzzleProjectilesToMove.size())) 

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
		if tickingProjectile != null:
			tickingProjectile.move_projectile(GlobalVariables.PROJECTILETYPE.TICKERPROJECTILE)
#	elif activeRoom.roomType == GlobalVariables.ROOM_TYPE.PUZZLEROOM && projectilesInActiveRoom.empty() && spawnBlockProjectileNextTurn.empty():
#		emit_signal("enemyTurnDoneSignal")
#	elif activeRoom.roomType == GlobalVariables.ROOM_TYPE.PUZZLEROOM && !spawnBlockProjectileNextTurn.empty():
#		#print("IN HERE")
#		if projectilesInActiveRoom.empty():
#			_on_projectiles_made_move()

func _on_Player_Attacked(player, attack_direction, attackDamage, attackType):
	randomize()
	#if player hits wall return 
	if get_cellv(world_to_map(player.position) + attack_direction) == TILETYPES.WALL || get_cellv(world_to_map(player.position) + attack_direction) == TILETYPES.DOOR || get_cellv(world_to_map(player.position) + attack_direction) == TILETYPES.UNLOCKEDDOOR:
		return
	#activate upgrade container
	elif get_cellv(world_to_map(player.position) + attack_direction) == TILETYPES.UPGRADECONTAINER:
		get_cell_pawn(world_to_map(player.position) + attack_direction).do_upgrade(player)
		return
	#sword attacks
	if get_cellv(world_to_map(player.position) + attack_direction) == TILETYPES.ENEMY && attackType == GlobalVariables.ATTACKTYPE.SWORD:
		print("Woosh Player Sword Attack hit " + str(attackDamage))
		var attackedEnemy = get_cell_pawn(world_to_map(player.position) + attack_direction)
		GlobalVariables.turnController.enemyTakeDamage.append(attackedEnemy)
		attackedEnemy.inflictDamage(attackDamage, attackType, world_to_map(player.position) + attack_direction, mainPlayer, GlobalVariables.CURRENTPHASE.PLAYER)
		
	elif(get_cellv(world_to_map(player.position) + attack_direction) == TILETYPES.FLOOR && attackType == GlobalVariables.ATTACKTYPE.SWORD):
		match attackType:
			GlobalVariables.ATTACKTYPE.SWORD:
				print("Sword was used to attack")
				print("ZZZ Attack missed")
	#wand attacks
	#use wand on block in puzzle room 
	if  activeRoom != null && activeRoom.roomType == GlobalVariables.ROOM_TYPE.PUZZLEROOM && get_cellv(world_to_map(player.position) + attack_direction) == TILETYPES.BLOCK && attackType == GlobalVariables.ATTACKTYPE.MAGIC:
		player.end_player_turn()
		GlobalVariables.turnController.start_power_projectiles()
		for projectile in projectilesInActiveRoom:
			set_cellv(world_to_map(projectile.position),get_tileset().find_tile_by_name("FLOOR")) 
			projectile.queue_free()
		projectilesInActiveRoom.clear()
		#player.playerBackupPosition = player.position
		#player.get_node("Sprite").set_visible(false)
		set_cellv(world_to_map(player.position), get_tileset().find_tile_by_name("FLOOR")) 
		for puzzlePiece in activatedPuzzlePieces:
			if !activeRoom.roomCleared:
				puzzlePiece.isActivated=false
				puzzlePiece.get_node("Sprite").set_modulate(puzzlePiece.baseModulation)
		activatedPuzzlePieces.clear()
		var blockAttackedByMagic = get_cell_pawn(world_to_map(player.position) + attack_direction)
		#player.position = activeRoom.doorRoomLeftMostCorner + map_to_world(activeRoom.roomSize - Vector2(1,1))
		for powerBlock in activeRoom.powerBlocksInRoom:
			#if powerBlock!=blockAttackedByMagic:
			powerBlock.get_node("PowerBlockModulate").set_deferred("modulate", "ffffff")
		blockAttackedByMagic.get_node("PowerBlockModulate").set_deferred("modulate", "798aff")
		#create ticking projectile for power block order+
		if tickingProjectile == null:
			var newTickingProjectile = MagicProjectile.instance()
			newTickingProjectile.projectileType = GlobalVariables.PROJECTILETYPE.TICKERPROJECTILE
			newTickingProjectile.connect("projectileMadeMove", self, "_on_projectiles_made_move")
			newTickingProjectile.connect("tickingProjectileMadeMove", self, "_on_ticking_projectile_made_move")
			newTickingProjectile.create_ticking_projectile(activeRoom.doorRoomLeftMostCorner)
			add_child(newTickingProjectile)
			tickingProjectile = newTickingProjectile
			newTickingProjectile.move_projectile(GlobalVariables.PROJECTILETYPE.TICKERPROJECTILE)
		blockAttackedByMagic.spawnMagicFromBlock(true)
	elif (get_cellv(world_to_map(player.position) + attack_direction*2) == TILETYPES.ENEMY && attackType == GlobalVariables.ATTACKTYPE.MAGIC):
		print("Woosh Player Wand Attack hit")
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
	elif (get_cellv(world_to_map(player.position) + attack_direction*2) == TILETYPES.FLOOR && attackType == GlobalVariables.ATTACKTYPE.MAGIC):
		print("Magic was used to attack")
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
#		if activeRoom == null || activeRoom.roomCleared:
#			newMagicProjectile.move_projectile("clearedRoomProjectile")
	elif (get_cellv(world_to_map(player.position) + attack_direction*2) == TILETYPES.MAGICPROJECTILE && attackType == GlobalVariables.ATTACKTYPE.MAGIC):
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
			print("Player player projectile interaction")
			var newMagicProjectile = MagicProjectile.instance()
			newMagicProjectile.set_z_index(5)
			newMagicProjectile.connect("playerEnemieProjectileMadeMove", GlobalVariables.turnController, "player_projectiles_turn_done")
			newMagicProjectile.position = player.position + map_to_world(attack_direction*2)
			newMagicProjectile.projectileType = GlobalVariables.PROJECTILETYPE.PLAYER
			newMagicProjectile.movementDirection = attack_direction
			add_child(newMagicProjectile)
			projectilesInActiveRoom.append(newMagicProjectile)
			newMagicProjectile.play_player_projectile_animation()
			magicProjectileMagicProjectileInteraction(newMagicProjectile, get_cell_pawn(world_to_map(player.position) + attack_direction*2))
	#block generating attack 
	if(attackType == GlobalVariables.ATTACKTYPE.BLOCK):
		if get_cellv(world_to_map(player.position) + attack_direction) == TILETYPES.FLOOR:
			#print("Hitting EMPTY")
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
		elif get_cellv(world_to_map(player.position) + attack_direction) == get_tileset().find_tile_by_name("BLOCK"):
			var powerBlockToDelete = get_cell_pawn(world_to_map(player.position) + attack_direction)
			#print("Hitting Block")
			if activeRoom != null:
				#print("In Puzzle room")
				if activeRoom.roomType == GlobalVariables.ROOM_TYPE.PUZZLEROOM:
					player.waitingForEventBeforeContinue = false
					activeRoom.powerBlocksInRoom.erase(powerBlockToDelete)
					powerBlockToDelete.queue_free()
					set_cellv(world_to_map(player.position) + attack_direction, get_tileset().find_tile_by_name("FLOOR"))
					
				elif activeRoom.roomType == GlobalVariables.ROOM_TYPE.ENEMYROOM:
					#print("Calling block explode")
					if powerBlockToDelete.explodeBlock():
						pass
					else:
						#print("block not exploding")
						player.waitingForEventBeforeContinue = false
						activeRoom.powerBlocksInRoom.erase(powerBlockToDelete)
						powerBlockToDelete.queue_free()
						set_cellv(world_to_map(player.position) + attack_direction, get_tileset().find_tile_by_name("FLOOR"))
				
				elif activeRoom.roomType == GlobalVariables.ROOM_TYPE.EMPTYTREASUREROOM:
					if powerBlockToDelete.explodeBlock():
						player.waitingForEventBeforeContinue = true
					else:
						#print("block not exploding")
						player.waitingForEventBeforeContinue = false
						if activeRoom!= null:
							activeRoom.powerBlocksInRoom.erase(powerBlockToDelete)
						powerBlockToDelete.queue_free()
						set_cellv(world_to_map(player.position) + attack_direction, get_tileset().find_tile_by_name("FLOOR"))
				
			else:
				if powerBlockToDelete.explodeBlock():
					player.waitingForEventBeforeContinue = true
				else:
					#print("block not exploding")
					player.waitingForEventBeforeContinue = false
					if activeRoom!= null:
						activeRoom.powerBlocksInRoom.erase(powerBlockToDelete)
					powerBlockToDelete.queue_free()
					set_cellv(world_to_map(player.position) + attack_direction, get_tileset().find_tile_by_name("FLOOR"))
		else:
			#print("Waiting in else")
			player.waitingForEventBeforeContinue = false
	#hand attack
	if(attackType == GlobalVariables.ATTACKTYPE.HAND):
		if get_cellv(world_to_map(player.position) + attack_direction) == TILETYPES.BLOCK:
			var interactionBlock = get_cell_pawn(world_to_map(player.position) + attack_direction)
			if activeRoom == null || activeRoom != null && activeRoom.roomType == GlobalVariables.ROOM_TYPE.ENEMYROOM || activeRoom != null && activeRoom.roomType == GlobalVariables.ROOM_TYPE.EMPTYTREASUREROOM:
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
			enemyToSwap.calc_enemy_attack_to(GlobalVariables.MOVEMENTATTACKCALCMODE.PREVIEW, activeRoom, 0)
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
		enemiesHitByExplosion.append(get_cell_pawn(world_to_map(powerBlock.position)+Vector2(1,0)))
	if get_cellv(world_to_map(powerBlock.position)+Vector2(-1,0)) == get_tileset().find_tile_by_name("ENEMY"):
		enemiesHitByExplosion.append(get_cell_pawn(world_to_map(powerBlock.position)+Vector2(-1,0)))
	if get_cellv(world_to_map(powerBlock.position)+Vector2(0,1)) == get_tileset().find_tile_by_name("ENEMY"):
		GlobalVariables.turnController.enemyTakeDamage.append(get_cell_pawn(world_to_map(powerBlock.position)+Vector2(-1,-1)))
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
	
	for enemy in enemiesHitByExplosion:
		GlobalVariables.turnController.enemyTakeDamage.append(enemy)
		enemy.inflictDamage(powerBlock.counters * mainPlayer.powerBlockAttackDamage, GlobalVariables.ATTACKTYPE.BLOCK, world_to_map(enemy.position), mainPlayer, GlobalVariables.CURRENTPHASE.PLAYER)
	enemiesHitByExplosion.clear()
	if activeRoom != null:
		activeRoom.powerBlocksInRoom.erase(powerBlock)
	set_cellv(world_to_map(powerBlock.position), get_tileset().find_tile_by_name("FLOOR"))
	GlobalVariables.turnController.on_block_exploding(powerBlock)
	
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
		if get_cellv(world_to_map(newMagicProjectile.position)) == get_tileset().find_tile_by_name("PUZZLEPIECE"):
			var activatedPuzzlePiece = get_cell_pawn(world_to_map(newMagicProjectile.position))
			if !activatePuzzlePieceNextTurn.has(activatedPuzzlePiece):
				activatePuzzlePieceNextTurn.append(activatedPuzzlePiece)
				if !projectilesInActiveRoom.empty():
					activatedPuzzlePiece.activationDelay = 0
				else:
					activatedPuzzlePiece.activationDelay = 0
			#newMagicProjectile.play_projectile_animation(false, "delete")
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

		elif get_cellv(world_to_map(newMagicProjectile.position)) == get_tileset().find_tile_by_name("FLOOR") || get_cellv(world_to_map(newMagicProjectile.position)) == get_tileset().find_tile_by_name("PLAYER"):
			projectilesInActiveRoom.append(newMagicProjectile)
			#set_cellv(world_to_map(newMagicProjectile.position), get_tileset().find_tile_by_name("MAGICPROJECTILE"))
			#newMagicProjectile.move_projectile("movePowerProjectile")
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
		
	if attackCellSingleAttack != null && attackType != GlobalVariables.ATTACKTYPE.MAGIC:
		print("Woosh ENEMY Attack hit")
		var attackedNode = get_cell_pawn(attackCellSingleAttack)
		print(attackedNode)
		if get_cellv(attackCellSingleAttack) == TILETYPES.PLAYER:
			attackedNode.inflict_damage_playerDefeated(attackDamage, attackType)
		elif get_cellv(attackCellSingleAttack) == TILETYPES.ENEMY && get_cell_pawn(attackCellSingleAttack).helpEnemy:
			print("ATTACKING HELP ENEMY no Magic")
			attackedNode.inflictDamage(attackDamage, attackType, attackCellSingleAttack, mainPlayer, GlobalVariables.CURRENTPHASE.ENEMYATTACK)
		
	elif attackType == GlobalVariables.ATTACKTYPE.MAGIC && !attackCell.empty():
		for cell in attackCell:
			print("Woosh ENEMY MAGE BIG hit")
			var attackedNode = get_cell_pawn(cell)
			var newMagicProjectile = MagicProjectile.instance()
			newMagicProjectile.set_z_index(5)
			newMagicProjectile.projectileType = GlobalVariables.PROJECTILETYPE.ENEMY
			newMagicProjectile.get_node("Sprite").set_frame(0)
			newMagicProjectile.position = map_to_world(cell)+GlobalVariables.tileOffset
			add_child(newMagicProjectile)
			newMagicProjectile.play_projectile_animation(true, "attack")
			attackCellArray.erase(cell)
			if get_cellv(cell) == TILETYPES.PLAYER:
				attackedNode.inflict_damage_playerDefeated(attackDamage, attackType)
			elif get_cellv(cell) == TILETYPES.ENEMY && attackedNode.helpEnemy:
				print("ATTACKING HELP ENEMY Magic")
				attackedNode.inflictDamage(attackDamage, attackType, cell, mainPlayer, GlobalVariables.CURRENTPHASE.ENEMYATTACK)
			
	if (attackType == GlobalVariables.ATTACKTYPE.MAGIC):
		#spawn magic projectile
		#print("ENEMY POSITION " + str(world_to_map(enemy.position)))
		for attackCell in attackCellArray:
			#print("NewMagicProjectile Position " + str(attackCell))
			if(get_cellv(attackCell)==TILETYPES.FLOOR):
				var newMagicProjectile = MagicProjectile.instance()
				newMagicProjectile.set_z_index(5)
				newMagicProjectile.get_node("Sprite").set_frame(0)
				newMagicProjectile.connect("playerEnemieProjectileMadeMove", GlobalVariables.turnController, "enemy_projectiles_turn_done")
				newMagicProjectile.position = map_to_world(attackCell)+GlobalVariables.tileOffset
				var movementDirectionRandom = 0
				match movementDirectionRandom:
					0:
						newMagicProjectile.movementDirection = Vector2(1,0)
					1:
						newMagicProjectile.movementDirection = Vector2(-1,0)
					2:
						newMagicProjectile.movementDirection = Vector2(0,1)
					3:
						newMagicProjectile.movementDirection = Vector2(0,-1)
				newMagicProjectile.projectileType = GlobalVariables.PROJECTILETYPE.ENEMY
				add_child(newMagicProjectile)
				projectilesInActiveRoom.append(newMagicProjectile)
				set_cellv(world_to_map(newMagicProjectile.position), get_tileset().find_tile_by_name("MAGICPROJECTILE"))
				newMagicProjectile.play_enemy_projectile_animation()

func on_Player_Defeated():
	print("resetting player to start")
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
					
					
func _on_enemy_defeated(enemy):
	activeRoom.enemiesInRoom.erase(enemy)
	if activeRoom.enemiesInRoom.size() == 0:
		#delete all projectiles 
		for projectile in projectilesInActiveRoom:
			set_cellv(world_to_map(projectile.position),get_tileset().find_tile_by_name("FLOOR")) 
			projectile.queue_free()
		projectilesInActiveRoom.clear()
		if activeRoom.dropLoot() && !activeRoom.roomCleared:
			GlobalVariables.turnController.queueDropLoot = true
		activeRoom.roomCleared=true
		mainPlayer.inClearedRoom = true
		allEnemiesAlreadySaved = false
		GlobalVariables.turnController.on_enemy_taken_damage(enemy, true)
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
				GlobalVariables.turnController.enemyTakeDamage.append(enemy)
				enemy.inflictDamage(100, GlobalVariables.ATTACKTYPE.SAVED, world_to_map(enemy.position), mainPlayer, GlobalVariables.turnController.currentTurnWaiting)
	GlobalVariables.turnController.on_enemy_taken_damage(enemy, true)
	
func dropLootInActiveRoom():
	dropBonusLoot()
	#create loot currently matching with closed doord 
	#calculating chance of dropping key item 
	var dropKeyItem = false
	print("currentNumberRoomsgenerated-numberRoomsCleared " + str(currentNumberRoomsgenerated-numberRoomsCleared))
	if currentNumberRoomsgenerated-numberRoomsCleared == 0:
		dropKeyItem = true
	elif currentNumberRoomsgenerated-numberRoomsCleared > 0:
		if randi()%100 > randi()%30+20:
			dropKeyItem = true
			print("DROPKEYITEM")
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
		print("newitem position " + str(world_to_map(itemToGenerate.position)))
		if get_cellv(world_to_map(itemToGenerate.position))==TILETYPES.BLOCK:
			activeRoom.powerBlocksInRoom.erase(get_cell_pawn(world_to_map(itemToGenerate.position)))
			get_cell_pawn(world_to_map(itemToGenerate.position)).queue_free()
		if  get_cellv(world_to_map(newItemPosition)) == TILETYPES.ENEMY:
			get_cell_pawn(world_to_map(itemToGenerate.position)).queue_free()
		add_child(itemToGenerate)
		set_cellv(world_to_map(itemToGenerate.position), get_tileset().find_tile_by_name("ITEM"))
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
		if numberRoomsCleared == GlobalVariables.maxNumberRooms:
			newItem.setTexture(GlobalVariables.ITEMTYPE.EXIT)
		else:
			var nonKeyItemToDrop = randi()%100
			if nonKeyItemToDrop < 50:
				newItem.setTexture(GlobalVariables.ITEMTYPE.FILLUPHALFHEART)
			elif nonKeyItemToDrop < 85:
				newItem.setTexture(GlobalVariables.ITEMTYPE.FILLUPHEART)
			else:
				newItem.setTexture(GlobalVariables.ITEMTYPE.POTION)
		add_child(newItem)
		set_cellv(world_to_map(newItem.position), get_tileset().find_tile_by_name("ITEM"))

func dropBonusLoot():
	for object in bonusLootArray:
		object.set_z_index(1)
		object.get_node("Sprite").set_scale(Vector2(0.5,0.5))
		object.get_node("Sprite").set_offset(Vector2(0,10))
		object.keyValue = str(0)
		object.setTexture(GlobalVariables.ITEMTYPE.COIN)
		add_child(object)
		set_cellv(world_to_map(object.position), get_tileset().find_tile_by_name("ITEM"))
		
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
	#todo:calculate actual position of leftmost corner wall tile of the room
	randomize()
	#GlobalVariables.roomDimensions = randi()%10+5
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
			newWallPiece.set_z_index(2)
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
			#print("VerticalAddAcc " + str(verticalAddcount) + " horaddacc " + str(horizontalAddcount))
			if(verticalAddcount==0 || verticalAddcount==roomSizeVertical-1 || horizontalAddcount==roomSizeHorizontal-1):
				horizontalAddcount+=1
			else:
				horizontalAddcount=roomSizeHorizontal-1
		verticalAddcount+=1
	
	for countHor in range (1, roomSizeHorizontal-1):
		for countVert in range (1, roomSizeVertical-1):
			var floorSpawnPos =  leftmostCorner + Vector2(countHor*GlobalVariables.tileSize, countVert*GlobalVariables.tileSize)
			set_cellv(world_to_map(floorSpawnPos), get_tileset().find_tile_by_name("FLOOR"))
	
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


func create_doors(roomLeftMostCorner, startingRoom=false, roomSizeHorizontal = 13, roomSizeVertical = 13, roomsizeMultiplyer = Vector2(1,1), doorLocationDirection = "LEFT"):
	randomize()
	roomSizeHorizontal = roomSizeHorizontal-1
	roomSizeVertical = roomSizeVertical-1
	var doorLocationDirectionsArray = ["LEFT", "RIGHT", "UP", "DOWN"]
	var doorLocationArray = []
	var doorArray = []
	var doorCount = randi()%4
	var canCreateDoor = true
	var doorEvenOddModifier = 0
	var doorLocationsRemoved = []
			
	if(evenOddModifier == 0):
		doorEvenOddModifier = 1
	#todo: include remaning doors numbers
	if startingRoom:
		doorCount = randi()%3+1
		print(doorCount)
	
	if doorCount == 0 && numberRoomsBeenTo == currentNumberRoomsgenerated-1:
		doorCount = randi()%3+1
	
	if (doorCount + currentNumberRoomsgenerated) > GlobalVariables.maxNumberRooms:
		print(currentNumberRoomsgenerated)
		if GlobalVariables.maxNumberRooms-currentNumberRoomsgenerated == 0:
			doorCount = 0
		else:
			doorCount = randi()%(GlobalVariables.maxNumberRooms-currentNumberRoomsgenerated)+1
	if !startingRoom:
		remove_opposite_doorlocation(doorLocationDirectionsArray, doorLocationDirection)
#		doorCount = 3
#		print("DoorCount " + str(doorCount))
#		print("DoorLocationSize " + str(doorLocationDirectionsArray.size()))

	while doorCount > 0: 
		var doorLocation = randi()%doorLocationDirectionsArray.size()-1
		#var doorLocation = 3
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
		canCreateDoor = can_create_door(element, newDoor, roomLeftMostCorner, roomsizeMultiplyer, roomSizeHorizontal, roomSizeVertical, doorEvenOddModifier, alternateSpawnLocation)
		if(!canCreateDoor):
			if alternateSpawnLocation:
				alternateSpawnLocation = false
			else: 
				alternateSpawnLocation = true
			if !can_create_door(element, newDoor, roomLeftMostCorner, roomsizeMultiplyer, roomSizeHorizontal, roomSizeVertical, doorEvenOddModifier, alternateSpawnLocation):
				doorLocationArray+=doorLocationsRemoved
				doorCount += doorLocationsRemoved.size()
				

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
		
	for door in doorArray:
		currentNumberRoomsgenerated+=1
		if !startingRoom:
			door.makeDoorBarrier(self)
		#print(currentNumberRoomsgenerated)
		create_walls(door, false, false)
		door.setBoxMapBG()
		door.rotateDoor()
		update_bitmask_region()
		#print(str(newDoor.position) + " element "+ str(element))

func can_create_door(element, newDoor, roomLeftMostCorner, roomsizeMultiplyer, roomSizeHorizontal, roomSizeVertical, doorEvenOddModifier, alternateSpawnLocation):
	randomize()
	var locationToSpawnModifier = Vector2.ZERO
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
	
	newDoor.position = roomLeftMostCorner + map_to_world(locationToSpawnModifier)

	
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



func manage_barrier_creation(barrierType):
	#make it one considering this one wants to become a barrier 
	var countLockedDoors = 0
	if barrierType == GlobalVariables.BARRIERTYPE.DOOR:
		countLockedDoors = 1
	for barrier in barrierKeysNoSolution:
		if barrier.itemType == GlobalVariables.ITEMTYPE.KEY:
			countLockedDoors +=1
	var roomsPossibleSolution = currentNumberRoomsgenerated-numberRoomsCleared-countLockedDoors-1
#	print("Rooms possible Solution Drop " + str(roomsPossibleSolution))
#	print("Current number rooms generated " + str(currentNumberRoomsgenerated))
#	print("Current number rooms cleared " + str(numberRoomsCleared))
#	print("Current Barriers with no Solution Spawned " +str(barrierKeysNoSolution.size()))
	if barrierKeysNoSolution.size () < roomsPossibleSolution:
		return true
	return false


# Note: This can be called from anywhere inside the tree. This function is
# path independent.
# Go through everything in the persist category and ask them to return a
# dict of relevant variables
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
		new_object.position = Vector2(80,80)
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
