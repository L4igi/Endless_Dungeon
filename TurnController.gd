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
var playerDefeatStop = false
var playerMovedDoor = false
var inRoomType = null
var powerBlockInterActionDone = true

func _ready():
	pass

func set_Grid_to_use(gridToUse):
	Grid = gridToUse

func check_turn_done_conditions():
#	print("playerTakeDamage " + str(playerTakeDamage.size()))
#	print("enemyTakeDamage " + str(enemyTakeDamage.size()))
#	print("projectileSpawned " + str(projectileSpawned.size()))
#	print("projectileInteraction " + str(projectileInteraction.size()))
#	print("currentTurnWaiting " + str(currentTurnWaiting))
	if playerTakeDamage.empty() && enemyTakeDamage.empty() && projectileSpawned.empty() && projectileInteraction.empty() && blocksExploding.empty() && puzzlePiecesToPattern.empty() && enemiesAttacking.empty():
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
				#print("playerProjectilesToMove " + str(playerProjectilesToMove))
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
	
func check_turn_progress():
	print(currentTurnWaiting)
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
		#print("Setting playerDefeatStop to false")
		playerDefeatStop = false
		GlobalVariables.turnController.enemiesToMove.clear()
		Grid.on_Player_Defeated()

func enemy_turn_done(enemy):
	enemiesToMove.erase(enemy)
#	currentTurnWaiting = GlobalVariables.CURRENTPHASE.ENEMY
	if check_turn_done_conditions():
		print("HOW often in enemy_turn_done")
		print("playerDefeatStop " + str(playerDefeatStop))
		if !playerDefeatStop:
			currentTurnWaiting = GlobalVariables.CURRENTPHASE.PLAYERPROJECTILE
			Grid.on_enemy_turn_done_confirmed()
		else:
			currentTurnWaiting = GlobalVariables.CURRENTPHASE.PLAYERDEFEAT
			player_defeat()

func player_projectiles_turn_done(projectile):
	playerProjectilesToMove.erase(projectile)
	#print("PROJECTILE " + str(projectile))
	#print("playerProjectilesToMove " + str(playerProjectilesToMove))
	if projectile!=null:
		for count in projectile.requestedMoveCount:
			playerProjectilesToMove.erase(projectile)
#	currentTurnWaiting = GlobalVariables.CURRENTPHASE.PLAYERPROJECTILE
	if check_turn_done_conditions():
		if !playerDefeatStop:
			#print("HERE SENDING")
			currentTurnWaiting = GlobalVariables.CURRENTPHASE.PLAYER
			Grid.on_player_projectile_turn_done_request_confirmed()
		else:
			currentTurnWaiting = GlobalVariables.CURRENTPHASE.PLAYERDEFEAT
			player_defeat()

func enemy_projectiles_turn_done(projectile):
	enemyProjectilesToMove.erase(projectile)
#	currentTurnWaiting = GlobalVariables.CURRENTPHASE.ENEMYPROJECTILE
	if projectile!=null:
		for count in projectile.requestedMoveCount:
			playerProjectilesToMove.erase(projectile)
	if check_turn_done_conditions():
		currentTurnWaiting = GlobalVariables.CURRENTPHASE.ENEMYATTACK
		#print("confirming turn done " + str(projectile))
		Grid.on_enemy_projectile_turn_done_request_confirmed()
#	else:
#		check_turn_progress()

func enemy_attacked_done(enemy):
	enemiesAttacking.erase(enemy)
	#print("after erasing enemy " + str(enemiesAttacking.size()))
	if check_turn_done_conditions():
		print("HOW often in after enemy attacked")
		print("playerDefeatStop " + str(playerDefeatStop))
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
	
func on_block_exploding(powerBlock):
	blocksExploding.erase(powerBlock)
	print(str(powerBlock))
	powerBlock.queue_free()
	check_turn_progress()

#all functions to make turn possible afterwards
func on_player_taken_damage(player):
	#push player here multiple times remove at array place [0] until empty
	playerTakeDamage.remove(0)
	
	check_turn_progress()

func on_enemy_taken_damage(enemy, deleting = false):
	enemyTakeDamage.erase(enemy)
	if deleting:
		enemy.queue_free()
	#print("ON enemy taken damage/defeated currentTurnWaiting " + str(currentTurnWaiting))
	check_turn_progress()

func on_projectile_spawned(projecitle):
	projectileSpawned.erase(projecitle)
	check_turn_progress()
	
func on_projectile_interaction(projectile, deleting = false):
	#print("in here after projectile interaction " + str(projectileInteraction))
	projectileInteraction.erase(projectile)
	#print("to delete projectileInteraction " + str(projectile))
	#print("in here after projectile interaction deleted" + str(projectileInteraction))
	if deleting:
		playerProjectilesToMove.erase(projectile)
		Grid.projectilesInActiveRoom.erase(projectile)
		projectile.queue_free()
	#print("projectile currentTurnWaiting " + str(currentTurnWaiting))
	check_turn_progress()





