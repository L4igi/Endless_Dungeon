extends Node

var playerTakeDamage = []
var enemyTakeDamage = []
var projectileSpawned = []
var projectileInteraction = []
var blocksExploding = []
var enemiesAttacking = []
var currentTurnWaiting = null
var Grid = null
var playersToMove = []
var enemiesToMove = []
var playerProjectilesToMove = []
var enemyProjectilesToMove = []
var puzzlePiecesToPattern = []
var countingBlocksToDelete = []
var playerDefeatStop = false
var playerMovedDoor = false
var inRoomType = null
var powerBlockInterActionDone = true
var queueDropLoot = false
var deleteHelpEnemy = []

func _ready():
	pass

func set_Grid_to_use(gridToUse):
	Grid = gridToUse

#if all conditions are met gives signals turn waiting to go
func check_turn_done_conditions():
	if playerTakeDamage.empty() && enemyTakeDamage.empty() && projectileSpawned.empty() && projectileInteraction.empty() && blocksExploding.empty() && puzzlePiecesToPattern.empty() && enemiesAttacking.empty() && countingBlocksToDelete.empty():
		match currentTurnWaiting:
			GlobalVariables.CURRENTPHASE.PLAYER:
				if Grid.mainPlayer.get_actions_left() == 0 && !playerMovedDoor:
					return true
				else:
					if playerMovedDoor:
						Grid.mainPlayer.movementCount = 0
						Grid.mainPlayer.attackCount = 0
						playerMovedDoor = false
					Grid.mainPlayer.checkNextAction = true
			GlobalVariables.CURRENTPHASE.ENEMY:
				if enemiesToMove.empty():
					return true
			GlobalVariables.CURRENTPHASE.PLAYERPROJECTILE:
				if playerProjectilesToMove.empty():
					return true
			GlobalVariables.CURRENTPHASE.ENEMYPROJECTILE:
				if enemyProjectilesToMove.empty():
					return true
			GlobalVariables.CURRENTPHASE.PLAYERDEFEAT:
				if enemyProjectilesToMove.empty() && enemiesToMove.empty() && enemiesAttacking.empty() && playerProjectilesToMove.empty():
					return true
			GlobalVariables.CURRENTPHASE.ENEMYATTACK:
				if enemiesAttacking.empty():
					return true
			GlobalVariables.CURRENTPHASE.PUZZLEPROJECTILE:
				if powerBlockInterActionDone:
					return true
			_:
				return true
	else:
		match currentTurnWaiting:
			GlobalVariables.CURRENTPHASE.PLAYER:
				Grid.mainPlayer.checkNextAction = false
	return false
	
#checks if current turn is still in progress 
func check_turn_progress():
	if check_turn_done_conditions():
		match currentTurnWaiting:
			GlobalVariables.CURRENTPHASE.PLAYER:
				player_turn_done(null)
			GlobalVariables.CURRENTPHASE.ENEMY:
				enemy_turn_done(null)
			GlobalVariables.CURRENTPHASE.ENEMYATTACK:
				enemy_attacked_done(null)
			GlobalVariables.CURRENTPHASE.PLAYERPROJECTILE:
				player_projectiles_turn_done(null)
			GlobalVariables.CURRENTPHASE.ENEMYPROJECTILE:
				enemy_projectiles_turn_done(null)
			GlobalVariables.CURRENTPHASE.PLAYERDEFEAT:
				player_defeat()
			_:
				return true
	
func player_turn_done(player):
	if queueDropLoot:
		queueDropLoot = false
		Grid.dropLootInActiveRoom()
	if check_turn_done_conditions():
		playersToMove.erase(player)
		playerDefeatStop = false
		if inRoomType == GlobalVariables.ROOM_TYPE.ENEMYROOM:
			currentTurnWaiting = GlobalVariables.CURRENTPHASE.ENEMYPROJECTILE
			Grid.on_player_turn_done_confirmed_enemy_room()
		elif inRoomType == GlobalVariables.ROOM_TYPE.PUZZLEROOM:
			currentTurnWaiting = GlobalVariables.CURRENTPHASE.PLAYER
			Grid.on_player_turn_done_confirmed_puzzle_room()
		elif inRoomType == GlobalVariables.ROOM_TYPE.EMPTYTREASUREROOM:
			currentTurnWaiting = GlobalVariables.CURRENTPHASE.PLAYER
			Grid.on_player_turn_done_confirmed_empty_treasure_room()
	else:
		check_turn_progress()
	
func player_defeat():
	playerDefeatStop = true
	if currentTurnWaiting == GlobalVariables.CURRENTPHASE.PLAYER:
		currentTurnWaiting = GlobalVariables.CURRENTPHASE.PLAYERDEFEAT
	playerTakeDamage.clear()
	if check_turn_done_conditions():
		playerDefeatStop = false
		GlobalVariables.turnController.enemiesToMove.clear()
		Grid.on_Player_Defeated()

func enemy_turn_done(enemy):
	enemiesToMove.erase(enemy)
	if check_turn_done_conditions():
		if !playerDefeatStop:
			currentTurnWaiting = GlobalVariables.CURRENTPHASE.PLAYERPROJECTILE
			Grid.on_enemy_turn_done_confirmed()
		else:
			currentTurnWaiting = GlobalVariables.CURRENTPHASE.PLAYERDEFEAT
			player_defeat()

func player_projectiles_turn_done(projectile):
	playerProjectilesToMove.erase(projectile)
	if projectile!=null:
		for count in projectile.requestedMoveCount:
			playerProjectilesToMove.erase(projectile)
	if check_turn_done_conditions():
		if !playerDefeatStop:
			currentTurnWaiting = GlobalVariables.CURRENTPHASE.PLAYER
			Grid.on_player_projectile_turn_done_request_confirmed()
		else:
			currentTurnWaiting = GlobalVariables.CURRENTPHASE.PLAYERDEFEAT
			player_defeat()

func enemy_projectiles_turn_done(projectile):
	enemyProjectilesToMove.erase(projectile)
	if projectile!=null:
		for count in projectile.requestedMoveCount:
			playerProjectilesToMove.erase(projectile)
	if check_turn_done_conditions():
		currentTurnWaiting = GlobalVariables.CURRENTPHASE.ENEMYATTACK
		Grid.on_enemy_projectile_turn_done_request_confirmed()

func enemy_attacked_done(enemy):
	enemiesAttacking.erase(enemy)
	if check_turn_done_conditions():
		if !deleteHelpEnemy.empty():
			for toDelete in deleteHelpEnemy:
				toDelete.queue_free()
			deleteHelpEnemy.clear()
		if !playerDefeatStop:
			currentTurnWaiting = GlobalVariables.CURRENTPHASE.ENEMY
			Grid.on_enemy_attack_done()
		else:
			currentTurnWaiting = GlobalVariables.CURRENTPHASE.PLAYERDEFEAT
			player_defeat()

func start_power_projectiles():
	powerBlockInterActionDone = false
	Grid.mainPlayer.checkNextAction = false
	currentTurnWaiting = GlobalVariables.CURRENTPHASE.PUZZLEPROJECTILE
	
func stop_power_projectiles():
	powerBlockInterActionDone = true
	Grid.mainPlayer.checkNextAction = true
	currentTurnWaiting = GlobalVariables.CURRENTPHASE.PLAYER
	check_turn_progress()
	
func puzzle_pattern_turn_done(puzzlePiece):
	puzzlePiecesToPattern.erase(puzzlePiece)
	check_turn_progress()
	
func on_counting_block_delete(countingBlock, delete):
	countingBlocksToDelete.erase(countingBlock)
	if delete:
		Grid.set_cellv(Grid.world_to_map(countingBlock.position),Grid.get_tileset().find_tile_by_name("FLOOR")) 
		countingBlock.queue_free()
	check_turn_progress()
	
func on_block_exploding(powerBlock):
	blocksExploding.erase(powerBlock)
	powerBlock.queue_free()
	check_turn_progress()

func on_player_taken_damage(player):
	playerTakeDamage.remove(0)
	
	check_turn_progress()

func on_enemy_taken_damage(enemy, deleting = false):
	print(enemyTakeDamage)
	print(enemy)
	enemyTakeDamage.erase(enemy)
	if deleting:
		enemiesToMove.erase(enemy)
		if !enemy.helpEnemy || currentTurnWaiting != GlobalVariables.CURRENTPHASE.ENEMYATTACK:
			enemy.queue_free()
		else:
			deleteHelpEnemy.append(enemy)
	check_turn_progress()

func on_projectile_spawned(projecitle):
	projectileSpawned.erase(projecitle)
	check_turn_progress()
	
func on_projectile_interaction(projectile, deleting = false):
	projectileInteraction.erase(projectile)
	if deleting:
		playerProjectilesToMove.erase(projectile)
		enemyProjectilesToMove.erase(projectile)
		Grid.projectilesInActiveRoom.erase(projectile)
		projectile.queue_free()
	check_turn_progress()
