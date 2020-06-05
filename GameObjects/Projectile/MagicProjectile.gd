extends Node2D

onready var Grid = get_parent()

enum CELL_TYPES{PLAYER=0, WALL=1, ENEMY=2, PUZZLEPIECE=3, ITEM=4, DOOR=5, UNLOCKEDDOOR=6, MAGICPROJECTILE=7, BLOCK=8}
export(CELL_TYPES) var type = CELL_TYPES.MAGICPROJECTILE

var movementDirection 
var attackDamage = 4
var projectileType = null
var isMiniProjectile = false
var tickAlreadyMoved = false
var deleteProjectilePlayAnimation = null
var moveTo = null
var requestedMoveCount = 0

signal projectileMadeMove (type)

signal playerEnemieProjectileMadeMove (projectile ,type, projectileArray)

func _ready():
	pass
	
func calc_projectiles_move_to(calcMode, count):
	if(projectileType == GlobalVariables.PROJECTILETYPE.ENEMY || projectileType == GlobalVariables.PROJECTILETYPE.PLAYER):
		var cell_target = Grid.world_to_map(position) + movementDirection
		if calcMode == GlobalVariables.MOVEMENTATTACKCALCMODE.PREVIEW:
			var target_position = Grid.map_to_world(cell_target) + Grid.cell_size / GlobalVariables.isometricFactor
			if target_position:
				moveTo = target_position
			count+=1
			if count >= Grid.playerEnemyProjectileArray.size():
				return
			else:
				Grid.playerEnemyProjectileArray[count].calc_projectiles_move_to(GlobalVariables.MOVEMENTATTACKCALCMODE.PREVIEW, count)
		elif calcMode == GlobalVariables.MOVEMENTATTACKCALCMODE.ACTION:
			var target_position = Grid.request_move(self, movementDirection)
			if target_position && deleteProjectilePlayAnimation==null:
				moveTo = target_position
			else:
				moveTo = null
			count+=1
			if count >= Grid.playerEnemyProjectileArray.size():
				return
			else:
				Grid.playerEnemyProjectileArray[count].calc_projectiles_move_to(GlobalVariables.MOVEMENTATTACKCALCMODE.ACTION, count)
		
func move_projectile(type = null):
	if projectileType == GlobalVariables.PROJECTILETYPE.ENEMY || projectileType == GlobalVariables.PROJECTILETYPE.PLAYER && type == null:
		if moveTo :
			$Tween.interpolate_property(self, "position", position, moveTo , 0.5, Tween.TRANS_LINEAR, Tween.EASE_IN)
			$Tween.start()
			yield($Tween, "tween_completed")
			if deleteProjectilePlayAnimation == null:
				emit_signal("playerEnemieProjectileMadeMove",self, projectileType)
			else:
				play_projectile_animation(false, deleteProjectilePlayAnimation)
		else:
			play_projectile_animation(false, "delete")

	elif projectileType == GlobalVariables.PROJECTILETYPE.POWERBLOCK:
		var target_position = Grid.request_move(self, movementDirection)
		if(target_position):
			$Tween.interpolate_property(self, "position", position, target_position , 0.5, Tween.TRANS_LINEAR, Tween.EASE_IN)
			$Tween.start()
			yield($Tween, "tween_completed")
		emit_signal("projectileMadeMove",projectileType)
		
	elif projectileType == GlobalVariables.PROJECTILETYPE.TICKERPROJECTILE:
		var target_position = position + movementDirection
		movementDirection = movementDirection*-1
		$Tween.interpolate_property(self, "position", position, target_position , 0.5, Tween.TRANS_LINEAR, Tween.EASE_IN)
		$Tween.start()
		yield($Tween, "tween_completed")
		emit_signal("projectileMadeMove",projectileType)
		
	elif type == "allProjectiles":
		var target_position = Grid.request_move(self, movementDirection)
		if(target_position):
			$Tween.interpolate_property(self, "position", position, target_position , 0.5, Tween.TRANS_LINEAR, Tween.EASE_IN)
			$Tween.start()
			yield($Tween, "tween_completed")
			position = target_position
			emit_signal("projectileMadeMove",projectileType)
			
	elif type == "clearedRoomProjectile":
		var target_position = Grid.request_move(self, movementDirection)
		if(target_position):
			$Tween.interpolate_property(self, "position", position, target_position , 0.1, Tween.TRANS_LINEAR, Tween.EASE_IN)
			$Tween.start()
			yield($Tween, "tween_completed")
			position = target_position
			move_projectile("clearedRoomProjectile")
		else:
			play_projectile_animation(false, deleteProjectilePlayAnimation)
			emit_signal("projectileMadeMove",projectileType)
	else:
		emit_signal("projectileMadeMove",projectileType)

func play_player_projectile_animation():
	$AnimationPlayer.play("shoot")
	
func play_enemy_projectile_animation():
	#print("Animationplayer enemy shoot")
	$AnimationPlayer.play("enemy_shoot")

func play_powerBlock_projectile_animation():
	$AnimationPlayer.play("powerblock_shoot")

func play_projectile_animation(onSpot=true, projectileAnimation="attack", projectileInteraction = false):
	#print("ProjectileAnimation " + str(projectileAnimation))
	var animationMode = 1
	if Grid.activeRoom == null || Grid.activeRoom != null && Grid.activeRoom.roomCleared || Grid.currentActivePhase != GlobalVariables.CURRENTPHASE.PLAYERPROJECTILE && Grid.currentActivePhase != GlobalVariables.CURRENTPHASE.ENEMYPROJECTILE && Grid.currentActivePhase == GlobalVariables.CURRENTPHASE.PLAYER || Grid.currentActivePhase == GlobalVariables.CURRENTPHASE.ENEMY:
		animationMode = 1
		if Grid.currentActivePhase == GlobalVariables.CURRENTPHASE.ENEMY:
			Grid.mainPlayer.waitingForEventBeforeContinue = true
		#print("Phase1")
	elif Grid.activeRoom != null && Grid.activeRoom.roomType == GlobalVariables.ROOM_TYPE.PUZZLEROOM:
		animationMode = 2
		#print("Phase2")
	else:
		animationMode = 3
		#print("Phase3")
	
	var animationToPlay = projectileAnimation
	match projectileAnimation : 
		"delete":
			if projectileType == GlobalVariables.PROJECTILETYPE.ENEMY:
				animationToPlay = "EnemyProjectileDelete"
			elif projectileType == GlobalVariables.PROJECTILETYPE.PLAYER:
				animationToPlay = "PlayerProjectileDelete"
			elif projectileType == GlobalVariables.PROJECTILETYPE.POWERBLOCK:
				animationToPlay = "PowerBlockProjectileDelete"
		"attack":
			if projectileType == GlobalVariables.PROJECTILETYPE.ENEMY:
				animationToPlay = "enemyProjectileAttack"
			elif projectileType == GlobalVariables.PROJECTILETYPE.PLAYER:
				animationToPlay = "playerProjectileAttack"
		"merge":
			if projectileType == GlobalVariables.PROJECTILETYPE.ENEMY:
				animationToPlay = "enemy_shoot"
			elif projectileType == GlobalVariables.PROJECTILETYPE.PLAYER:
				isMiniProjectile = false
				attackDamage = 1.0
				animationToPlay = "playerPoweredUpProjectile"
				
	set_process(false)
	$AnimationPlayer.play(animationToPlay)
	if !onSpot:
		$Tween.interpolate_property($Sprite, "position", Vector2(), movementDirection*GlobalVariables.tileSize, $AnimationPlayer.current_animation_length, Tween.TRANS_LINEAR, Tween.EASE_IN)
		$Tween.start()
	yield($AnimationPlayer, "animation_finished")
	set_process(true)
	if projectileAnimation == "merge": 
		#play idle animation 
		if projectileType == GlobalVariables.PROJECTILETYPE.ENEMY:
			$AnimationPlayer.play("enemy_shoot")
		elif projectileType == GlobalVariables.PROJECTILETYPE.PLAYER:
			print("playing shoot " + str(projectileAnimation))
			$AnimationPlayer.play("shoot")
	#player enemy phase
	elif animationMode == 1:
		Grid.projectilesInActiveRoom.erase(self)
		if projectileType == GlobalVariables.PROJECTILETYPE.ENEMY && Grid.currentActivePhase == GlobalVariables.CURRENTPHASE.PLAYER:
			Grid.set_cellv(Grid.world_to_map(position),Grid.get_tileset().find_tile_by_name("FLOOR"))
#		if projectileType == GlobalVariables.PROJECTILETYPE.PLAYER && Grid.currentActivePhase == GlobalVariables.CURRENTPHASE.ENEMY:
#			Grid.set_cellv(Grid.world_to_map(position),Grid.get_tileset().find_tile_by_name("FLOOR"))
		self.queue_free()
		if Grid.currentActivePhase == GlobalVariables.CURRENTPHASE.ENEMY:
			Grid.mainPlayer.waitingForEventBeforeContinue = false
	#puzzle room interactions
	elif animationMode == 2:
		Grid.projectilesInActiveRoom.erase(self)
		#Grid.set_cellv(Grid.world_to_map(position)+movementDirection,Grid.get_tileset().find_tile_by_name("FLOOR"))
		self.queue_free()
	#projectile phase
	elif animationMode == 3:
		Grid.projectilesInActiveRoom.erase(self)
		if projectileInteraction:
			Grid.set_cellv(Grid.world_to_map(position),Grid.get_tileset().find_tile_by_name("FLOOR"))
			Grid.on_projectiles_interactions_done(self)
		else:
			emit_signal("playerEnemieProjectileMadeMove",self, projectileType)
		self.queue_free()
	
func create_mini_projectile(projectile, mainPlayer, currentPhase):
	if currentPhase == GlobalVariables.CURRENTPHASE.PLAYER:
		mainPlayer.waitingForEventBeforeContinue = true
	isMiniProjectile = true
	attackDamage = 0.5
	if projectile == 1:
		$AnimationPlayer.play("mini1shoot")
	if projectile == 2:
		$AnimationPlayer.play("mini2shoot")
		
	if currentPhase == GlobalVariables.CURRENTPHASE.PLAYER:
		print ("IN mini projectile movement")
		var target_position = Grid.request_move(self, movementDirection)
		if target_position:
			$Tween.interpolate_property(self, "position", position, target_position , 0.5, Tween.TRANS_LINEAR, Tween.EASE_IN)
			$Tween.start()
			yield($Tween, "tween_completed")
		mainPlayer.waitingForEventBeforeContinue = false
			

func create_ticking_projectile(currentRoomLeftMostCorner):
	projectileType = GlobalVariables.PROJECTILETYPE.TICKERPROJECTILE
	position = currentRoomLeftMostCorner
	movementDirection = Vector2(0,1)
	$Sprite.set_visible(false)
	
