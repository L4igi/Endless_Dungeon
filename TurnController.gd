extends Node

var playerTakeDamage = []
var enemyTakeDamage = []
var projectileSpawned = []
var projectileInteraction = []
var currentTurnWaiting = null
var Grid = null
var playersToMove = []
var enemiesToMove = []
var playerProjectilesToMove = []
var enemyProjectilesToMove = []
var playerDefeatStop = false

func _ready():
	pass # Replace with function body.

func set_Grid_to_use(gridToUse):
	Grid = gridToUse

func check_turn_done_conditions():
#	print("playerTakeDamage " + str(playerTakeDamage.size()))
#	print("enemyTakeDamage " + str(enemyTakeDamage.size()))
#	print("projectileSpawned " + str(projectileSpawned.size()))
#	print("projectileInteraction " + str(projectileInteraction.size()))
#	print("currentTurnWaiting " + str(currentTurnWaiting))
	if playerTakeDamage.empty() && enemyTakeDamage.empty() && projectileSpawned.empty() && projectileInteraction.empty():
		match currentTurnWaiting:
			GlobalVariables.CURRENTPHASE.PLAYER:
				if playersToMove.empty():
					return true
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
				if enemyProjectilesToMove.empty() && enemiesToMove.empty() && playerProjectilesToMove.empty():
					return true
			_:
				return true
	return false
	
func check_turn_progress():
	#print(currentTurnWaiting)
	if check_turn_done_conditions():
		match currentTurnWaiting:
			GlobalVariables.CURRENTPHASE.PLAYER:
				if Grid.mainPlayer.maxTurnActions:
					if Grid.mainPlayer.get_actions_left() == 0:
						player_turn_done(null)
					else:
						return true
			GlobalVariables.CURRENTPHASE.ENEMY:
				enemy_turn_done(null)
			GlobalVariables.CURRENTPHASE.PLAYERPROJECTILE:
				player_projectiles_turn_done(null)
			GlobalVariables.CURRENTPHASE.ENEMYPROJECTILE:
				enemy_projectiles_turn_done(null)
			GlobalVariables.CURRENTPHASE.PLAYERDEFEAT:
				player_defeat()
			_:
				return true
			
	
func player_next_action():
	if check_turn_done_conditions():
		return true
	return false

func clearAllWaiting():
	playerTakeDamage.clear()
	enemyTakeDamage.clear()
	projectileSpawned.clear()
	projectileInteraction.clear()
	playersToMove.clear()
	enemiesToMove.clear()
	playerProjectilesToMove.clear()
	enemyProjectilesToMove.clear()
	
func player_turn_done(player):
	playersToMove.erase(player)
	currentTurnWaiting = GlobalVariables.CURRENTPHASE.PLAYER
	if check_turn_done_conditions():
		currentTurnWaiting = GlobalVariables.CURRENTPHASE.ENEMYPROJECTILE
		Grid.on_player_turn_done_confirmed()
	else:
		check_turn_progress()

func player_defeat():
	if playerDefeatStop:
		playerDefeatStop = false
	else:
		playerDefeatStop = true
	print("ON PLAYER DEFEATED IN TURNCONTROLLER")
	if currentTurnWaiting == GlobalVariables.CURRENTPHASE.PLAYER:
		currentTurnWaiting = GlobalVariables.CURRENTPHASE.PLAYERDEFEAT
	playerTakeDamage.clear()
	if check_turn_done_conditions():
		playerDefeatStop = false
		Grid.on_Player_Defeated()
	else:
		check_turn_progress()

func enemy_turn_done(enemy):
	enemiesToMove.erase(enemy)
	currentTurnWaiting = GlobalVariables.CURRENTPHASE.ENEMY
	if check_turn_done_conditions():
		if !playerDefeatStop:
			currentTurnWaiting = GlobalVariables.CURRENTPHASE.PLAYERPROJECTILE
			Grid.on_enemy_turn_done_confirmed()
		else:
			currentTurnWaiting = GlobalVariables.CURRENTPHASE.PLAYERDEFEAT
			player_defeat()

func player_projectiles_turn_done(projectile):
	playerProjectilesToMove.erase(projectile)
	currentTurnWaiting = GlobalVariables.CURRENTPHASE.PLAYERPROJECTILE
	if check_turn_done_conditions():
		currentTurnWaiting = GlobalVariables.CURRENTPHASE.PLAYER
		Grid.on_player_projectile_turn_done_request_confirmed()
#	else:
#		check_turn_progress()

func enemy_projectiles_turn_done(projectile):
	enemyProjectilesToMove.erase(projectile)
	currentTurnWaiting = GlobalVariables.CURRENTPHASE.ENEMYPROJECTILE
	if check_turn_done_conditions():
		currentTurnWaiting = GlobalVariables.CURRENTPHASE.ENEMY
		print("confirming turn done " + str(projectile))
		Grid.on_enemy_projectile_turn_done_request_confirmed()
#	else:
#		check_turn_progress()
	
func exploding_block_turn_done():
	currentTurnWaiting = GlobalVariables.CURRENTPHASE.ENEMYPROJECTILE
	if check_turn_done_conditions():
		Grid.on_player_projectile_turn_done_request_confirmed()
#	else:
#		check_turn_progress()

#all functions to make turn possible afterwards
func on_player_taken_damage(player):
	#push player here multiple times remove at array place [0] until empty
	playerTakeDamage.remove(0)
	check_turn_progress()

func on_enemy_taken_damage(enemy, deleting = false):
	enemyTakeDamage.erase(enemy)
	if deleting:
		enemy.queue_free()
	check_turn_progress()

func on_projectile_spawned(projecitle):
	projectileSpawned.erase(projecitle)
	check_turn_progress()
	
func on_projectile_interaction(projectile, deleting = false):
	projectileInteraction.erase(projectile)
	if deleting:
		projectile.queue_free()
	check_turn_progress()





