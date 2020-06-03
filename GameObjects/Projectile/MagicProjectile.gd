extends Node2D

onready var Grid = get_parent()

enum CELL_TYPES{PLAYER=0, WALL=1, ENEMY=2, PUZZLEPIECE=3, ITEM=4, DOOR=5, UNLOCKEDDOOR=6, MAGICPROJECTILE=7, BLOCK=8}
export(CELL_TYPES) var type = CELL_TYPES.MAGICPROJECTILE

var movementDirection 
var attackDamage = 1
var projectileType = null
var isMiniProjectile = false
var tickAlreadyMoved = false
var deleteProjectilePlayAnimation = null
var moveTo = null

signal projectileMadeMove (type)

signal playerEnemieProjectileMadeMove (projectile ,type, projectileArray)

func _ready():
	pass
	
func calc_projectiles_move_to(calcMode):
	if(projectileType == GlobalVariables.PROJECTILETYPE.ENEMY || projectileType == GlobalVariables.PROJECTILETYPE.PLAYER):
		var cell_target = Grid.world_to_map(position) + movementDirection
		if calcMode == GlobalVariables.MOVEMENTATTACKCALCMODE.PREVIEW:
			var target_position = Grid.map_to_world(cell_target) + Grid.cell_size / GlobalVariables.isometricFactor
			if target_position:
				moveTo = target_position
		elif calcMode == GlobalVariables.MOVEMENTATTACKCALCMODE.ACTION:
			var target_position = Grid.request_move(self, movementDirection)
			if target_position:
				moveTo = target_position
			else:
				moveTo = null
		
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
			play_projectile_animation(false, deleteProjectilePlayAnimation)

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

func play_projectile_animation(onSpot=true, projectileAnimation="playerProjectileAttack"):
	#print(Grid.currentActivePhase)
	var animationMode = 1
	if Grid.activeRoom == null || Grid.activeRoom != null && Grid.activeRoom.roomCleared || Grid.currentActivePhase != GlobalVariables.CURRENTPHASE.PROJECTILE && Grid.currentActivePhase == GlobalVariables.CURRENTPHASE.PLAYER || Grid.currentActivePhase == GlobalVariables.CURRENTPHASE.ENEMY:
		animationMode = 1
	elif Grid.activeRoom != null && Grid.activeRoom.roomType == GlobalVariables.ROOM_TYPE.PUZZLEROOM:
		animationMode = 2
	else:
		animationMode = 3
		
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
	elif animationMode == 1:
		Grid.projectilesInActiveRoom.erase(self)
		self.queue_free()
	elif animationMode == 2:
		Grid.projectilesInActiveRoom.erase(self)
		self.queue_free()
	elif animationMode == 3:
		emit_signal("playerEnemieProjectileMadeMove",self, projectileType)
	
func create_mini_projectile(projectile, mainPlayer, currentPhase):
	if currentPhase == GlobalVariables.CURRENTPHASE.PLAYER:
		mainPlayer.disablePlayerInput = true
	isMiniProjectile = true
	attackDamage = 0.5
	if projectile == 1:
		$AnimationPlayer.play("mini1shoot")
	if projectile == 2:
		$AnimationPlayer.play("mini2shoot")
		
	if currentPhase == GlobalVariables.CURRENTPHASE.PLAYER:
		print ("IN mini projectile movement")
		var target_position = Grid.request_move(self, movementDirection)
		if(target_position):
			$Tween.interpolate_property(self, "position", position, target_position , 0.5, Tween.TRANS_LINEAR, Tween.EASE_IN)
			$Tween.start()
			yield($Tween, "tween_completed")
		mainPlayer.disablePlayerInput = false
			

func create_ticking_projectile(currentRoomLeftMostCorner):
	projectileType = GlobalVariables.PROJECTILETYPE.TICKERPROJECTILE
	position = currentRoomLeftMostCorner
	movementDirection = Vector2(0,1)
	$Sprite.set_visible(false)
	
